// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.12;

import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";
import {Height} from "../../proto/Client.sol";
import {ConnectionEnd} from "../../proto/Connection.sol";
import {Channel, ChannelCounterparty} from "../../proto/Channel.sol";
import {IBCHeight} from "../02-client/IBCHeight.sol";
import {IBCConnectionLib} from "../03-connection/IBCConnectionLib.sol";
import {IIBCChannelHandshake} from "../04-channel/IIBCChannel.sol";
import {IBCCommitment} from "../24-host/IBCCommitment.sol";
import {IIBCModule} from "../26-router/IIBCModule.sol";
import {IBCModuleManager} from "../26-router/IBCModuleManager.sol";
import {IBCChannelLib} from "./IBCChannelLib.sol";

/**
 * @dev IBCChannelHandshake is a contract that implements [ICS-4](https://github.com/cosmos/ibc/tree/main/spec/core/ics-004-channel-and-packet-semantics).
 */
contract IBCChannelHandshake is IBCModuleManager, IIBCChannelHandshake {
    using IBCHeight for Height.Data;

    /**
     * @dev channelOpenInit is called by a module to initiate a channel opening handshake with a module on another chain.
     */
    function channelOpenInit(IIBCChannelHandshake.MsgChannelOpenInit calldata msg_)
        external
        returns (string memory, string memory)
    {
        require(msg_.channel.connection_hops.length == 1, "connection_hops length must be 1");
        ConnectionEnd.Data storage connection = connections[msg_.channel.connection_hops[0]];
        require(
            connection.versions.length == 1, "single version must be negotiated on connection before opening channel"
        );
        require(
            IBCConnectionLib.verifySupportedFeature(
                connection.versions[0], IBCChannelLib.toString(msg_.channel.ordering)
            ),
            "feature not supported"
        );
        require(msg_.channel.state == Channel.State.STATE_INIT, "channel state must STATE_INIT");
        require(bytes(msg_.channel.counterparty.channel_id).length == 0, "counterparty channel_id must be empty");

        string memory channelId = generateChannelIdentifier();
        initializeSequences(msg_.portId, channelId);

        IIBCModule module = lookupModuleByPort(msg_.portId);
        string memory version = module.onChanOpenInit(
            IIBCModule.MsgOnChanOpenInit({
                order: msg_.channel.ordering,
                connectionHops: msg_.channel.connection_hops,
                portId: msg_.portId,
                channelId: channelId,
                counterparty: msg_.channel.counterparty,
                version: msg_.channel.version
            })
        );
        claimCapability(channelCapabilityPath(msg_.portId, channelId), address(module));
        writeChannel(
            msg_.portId,
            channelId,
            msg_.channel.state,
            msg_.channel.ordering,
            msg_.channel.counterparty,
            msg_.channel.connection_hops,
            version
        );
        emit GeneratedChannelIdentifier(channelId);
        return (channelId, version);
    }

    /**
     * @dev channelOpenTry is called by a module to accept the first step of a channel opening handshake initiated by a module on another chain.
     */
    function channelOpenTry(IIBCChannelHandshake.MsgChannelOpenTry calldata msg_)
        external
        returns (string memory, string memory)
    {
        require(msg_.channel.connection_hops.length == 1, "connection_hops length must be 1");
        ConnectionEnd.Data storage connection = connections[msg_.channel.connection_hops[0]];
        require(connection.state == ConnectionEnd.State.STATE_OPEN, "connection state must be STATE_OPEN");
        require(
            connection.versions.length == 1, "single version must be negotiated on connection before opening channel"
        );
        require(
            IBCConnectionLib.verifySupportedFeature(
                connection.versions[0], IBCChannelLib.toString(msg_.channel.ordering)
            ),
            "feature not supported"
        );
        require(msg_.channel.state == Channel.State.STATE_TRYOPEN, "channel state must be STATE_TRYOPEN");

        Channel.Data memory expectedChannel = Channel.Data({
            state: Channel.State.STATE_INIT,
            ordering: msg_.channel.ordering,
            counterparty: ChannelCounterparty.Data({port_id: msg_.portId, channel_id: ""}),
            connection_hops: getCounterpartyHops(msg_.channel.connection_hops[0]),
            version: msg_.counterpartyVersion
        });
        require(
            verifyChannelState(
                connection,
                msg_.proofHeight,
                msg_.proofInit,
                msg_.channel.counterparty.port_id,
                msg_.channel.counterparty.channel_id,
                Channel.encode(expectedChannel)
            ),
            "failed to verify channel state"
        );

        string memory channelId = generateChannelIdentifier();
        initializeSequences(msg_.portId, channelId);

        IIBCModule module = lookupModuleByPort(msg_.portId);
        string memory version = module.onChanOpenTry(
            IIBCModule.MsgOnChanOpenTry({
                order: msg_.channel.ordering,
                connectionHops: msg_.channel.connection_hops,
                portId: msg_.portId,
                channelId: channelId,
                counterparty: msg_.channel.counterparty,
                counterpartyVersion: msg_.counterpartyVersion
            })
        );
        claimCapability(channelCapabilityPath(msg_.portId, channelId), address(module));
        writeChannel(
            msg_.portId,
            channelId,
            msg_.channel.state,
            msg_.channel.ordering,
            msg_.channel.counterparty,
            msg_.channel.connection_hops,
            version
        );
        emit GeneratedChannelIdentifier(channelId);
        return (channelId, version);
    }

    /**
     * @dev channelOpenAck is called by the handshake-originating module to acknowledge the acceptance of the initial request by the counterparty module on the other chain.
     */
    function channelOpenAck(IIBCChannelHandshake.MsgChannelOpenAck calldata msg_) external {
        Channel.Data storage channel = channels[msg_.portId][msg_.channelId];
        require(channel.state == Channel.State.STATE_INIT, "channel state should be INIT");

        ConnectionEnd.Data storage connection = connections[channel.connection_hops[0]];
        require(connection.state == ConnectionEnd.State.STATE_OPEN, "connection state is not OPEN");
        require(channel.connection_hops.length == 1);

        Channel.Data memory expectedChannel = Channel.Data({
            state: Channel.State.STATE_TRYOPEN,
            ordering: channel.ordering,
            counterparty: ChannelCounterparty.Data({port_id: msg_.portId, channel_id: msg_.channelId}),
            connection_hops: getCounterpartyHops(channel.connection_hops[0]),
            version: msg_.counterpartyVersion
        });
        require(
            verifyChannelState(
                connection,
                msg_.proofHeight,
                msg_.proofTry,
                channel.counterparty.port_id,
                msg_.counterpartyChannelId,
                Channel.encode(expectedChannel)
            ),
            "failed to verify channel state"
        );
        channel.state = Channel.State.STATE_OPEN;
        channel.version = msg_.counterpartyVersion;
        channel.counterparty.channel_id = msg_.counterpartyChannelId;
        updateChannelCommitment(msg_.portId, msg_.channelId);
        lookupModuleByPort(msg_.portId).onChanOpenAck(
            IIBCModule.MsgOnChanOpenAck({
                portId: msg_.portId,
                channelId: msg_.channelId,
                counterpartyVersion: msg_.counterpartyVersion
            })
        );
    }

    /**
     * @dev channelOpenConfirm is called by the counterparty module to close their end of the channel, since the other end has been closed.
     */
    function channelOpenConfirm(IIBCChannelHandshake.MsgChannelOpenConfirm calldata msg_) external {
        Channel.Data storage channel = channels[msg_.portId][msg_.channelId];
        require(channel.state == Channel.State.STATE_TRYOPEN, "channel state is not TRYOPEN");

        ConnectionEnd.Data storage connection = connections[channel.connection_hops[0]];
        require(connection.state == ConnectionEnd.State.STATE_OPEN, "connection state is not OPEN");
        require(channel.connection_hops.length == 1);

        Channel.Data memory expectedChannel = Channel.Data({
            state: Channel.State.STATE_OPEN,
            ordering: channel.ordering,
            counterparty: ChannelCounterparty.Data({port_id: msg_.portId, channel_id: msg_.channelId}),
            connection_hops: getCounterpartyHops(channel.connection_hops[0]),
            version: channel.version
        });
        require(
            verifyChannelState(
                connection,
                msg_.proofHeight,
                msg_.proofAck,
                channel.counterparty.port_id,
                channel.counterparty.channel_id,
                Channel.encode(expectedChannel)
            ),
            "failed to verify channel state"
        );
        channel.state = Channel.State.STATE_OPEN;
        updateChannelCommitment(msg_.portId, msg_.channelId);
        lookupModuleByPort(msg_.portId).onChanOpenConfirm(
            IIBCModule.MsgOnChanOpenConfirm({portId: msg_.portId, channelId: msg_.channelId})
        );
    }

    /**
     * @dev channelCloseInit is called by either module to close their end of the channel. Once closed, channels cannot be reopened.
     */
    function channelCloseInit(IIBCChannelHandshake.MsgChannelCloseInit calldata msg_) external {
        Channel.Data storage channel = channels[msg_.portId][msg_.channelId];
        require(channel.state != Channel.State.STATE_CLOSED, "channel state is already CLOSED");

        ConnectionEnd.Data storage connection = connections[channel.connection_hops[0]];
        require(connection.state == ConnectionEnd.State.STATE_OPEN, "connection state is not OPEN");

        channel.state = Channel.State.STATE_CLOSED;
        updateChannelCommitment(msg_.portId, msg_.channelId);
        lookupModuleByPort(msg_.portId).onChanCloseInit(
            IIBCModule.MsgOnChanCloseInit({portId: msg_.portId, channelId: msg_.channelId})
        );
    }

    /**
     * @dev channelCloseConfirm is called by the counterparty module to close their end of the
     * channel, since the other end has been closed.
     */
    function channelCloseConfirm(IIBCChannelHandshake.MsgChannelCloseConfirm calldata msg_) external {
        Channel.Data storage channel = channels[msg_.portId][msg_.channelId];
        require(channel.state != Channel.State.STATE_CLOSED, "channel state is already CLOSED");

        require(channel.connection_hops.length == 1);
        ConnectionEnd.Data storage connection = connections[channel.connection_hops[0]];
        require(connection.state == ConnectionEnd.State.STATE_OPEN, "connection state is not OPEN");

        Channel.Data memory expectedChannel = Channel.Data({
            state: Channel.State.STATE_CLOSED,
            ordering: channel.ordering,
            counterparty: ChannelCounterparty.Data({port_id: msg_.portId, channel_id: msg_.channelId}),
            connection_hops: getCounterpartyHops(channel.connection_hops[0]),
            version: channel.version
        });
        require(
            verifyChannelState(
                connection,
                msg_.proofHeight,
                msg_.proofInit,
                channel.counterparty.port_id,
                channel.counterparty.channel_id,
                Channel.encode(expectedChannel)
            ),
            "failed to verify channel state"
        );
        channel.state = Channel.State.STATE_CLOSED;
        updateChannelCommitment(msg_.portId, msg_.channelId);
        lookupModuleByPort(msg_.portId).onChanCloseConfirm(
            IIBCModule.MsgOnChanCloseConfirm({portId: msg_.portId, channelId: msg_.channelId})
        );
    }

    /**
     * @dev writeChannel writes a channel which has successfully passed the OpenInit or OpenTry handshake step.
     */
    function writeChannel(
        string calldata portId,
        string memory channelId,
        Channel.State state,
        Channel.Order order,
        ChannelCounterparty.Data calldata counterparty,
        string[] calldata connectionHops,
        string memory version
    ) internal {
        Channel.Data storage channel = channels[portId][channelId];
        channel.state = state;
        channel.ordering = order;
        channel.counterparty = counterparty;
        for (uint256 i = 0; i < connectionHops.length; i++) {
            channel.connection_hops.push(connectionHops[i]);
        }
        channel.version = version;
        updateChannelCommitment(portId, channelId);
    }

    function updateChannelCommitment(string memory portId, string memory channelId) private {
        commitments[IBCCommitment.channelCommitmentKey(portId, channelId)] =
            keccak256(Channel.encode(channels[portId][channelId]));
    }

    /* Verification functions */

    function verifyChannelState(
        ConnectionEnd.Data storage connection,
        Height.Data calldata height,
        bytes calldata proof,
        string memory portId,
        string memory channelId,
        bytes memory channelBytes
    ) private returns (bool) {
        return checkAndGetClient(connection.client_id).verifyMembership(
            connection.client_id,
            height,
            0,
            0,
            proof,
            connection.counterparty.prefix.key_prefix,
            IBCCommitment.channelPath(portId, channelId),
            channelBytes
        );
    }

    /* Internal functions */

    function initializeSequences(string memory portId, string memory channelId) internal {
        nextSequenceSends[portId][channelId] = 1;
        nextSequenceRecvs[portId][channelId] = 1;
        nextSequenceAcks[portId][channelId] = 1;
        commitments[IBCCommitment.nextSequenceRecvCommitmentKey(portId, channelId)] =
            keccak256(abi.encodePacked((bytes8(uint64(1)))));
    }

    function getCounterpartyHops(string memory connectionId) internal view returns (string[] memory hops) {
        hops = new string[](1);
        hops[0] = connections[connectionId].counterparty.connection_id;
        return hops;
    }

    function generateChannelIdentifier() private returns (string memory) {
        string memory identifier = string(abi.encodePacked("channel-", Strings.toString(nextChannelSequence)));
        nextChannelSequence++;
        return identifier;
    }
}
