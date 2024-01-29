// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.12;

import "./IBCAppBase.sol";
import "./CarbonNeutralPool.sol";
import "../core/25-handler/IBCHandler.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";

import {Height} from "../proto/Client.sol";

contract CarbonNeutralApplication is IBCAppBase {
    string private constant IBC_PORT_EMISSIONS = "emissions";
    bytes32 private constant IBC_PORT_EMISSIONS_HASH =
        keccak256(abi.encodePacked(IBC_PORT_EMISSIONS));

    string private constant IBC_PORT_OFFSET = "offset";
    bytes32 private constant IBC_PORT_OFFSET_HASH =
        keccak256(abi.encodePacked(IBC_PORT_OFFSET));

    CarbonNeutralPool private immutable carbonNeutralPool; // exists only insantiated from neutral chain

    IBCHandler private immutable ibcHandler; // ibc handler insantiated to each chain
    address private immutable escrowAddress; // for transfer between chains

    constructor(IBCHandler _ibcHandler, CarbonNeutralPool _carbonNeutralPool) {
        ibcHandler = _ibcHandler;
        carbonNeutralPool = _carbonNeutralPool;

        /** @todo it should be escrow contract not application self */
        escrowAddress = address(this);
    }

    modifier onlyNotNeutralMerkle() {
        require(
            address(carbonNeutralPool) == address(0),
            "only not neutral merkle can be call."
        );
        _;
    }

    modifier onlyNeutralMerkle() {
        require(
            address(carbonNeutralPool) != address(0),
            "only neutral merkle can be call."
        );
        _;
    }

     /**
     * 배출 머클에서 중립 머클로
     */
    function transferEmissionsToNeutral(
        address carbonEmissions,
        uint256 applicationTokenId,
        address carbonEmitter,
        uint256 emissionsTokenAmount,
        string memory sourceChannel
    ) external onlyNotNeutralMerkle {
        // 1. lock to escrow
        IERC1155(carbonEmissions).safeTransferFrom(
            carbonEmitter,
            escrowAddress,
            applicationTokenId,
            emissionsTokenAmount,
            ""
        );

        // 2. send packet
        bytes memory packet = encodeEmissionsPacket(
            applicationTokenId,
            carbonEmissions,
            carbonEmitter,
            emissionsTokenAmount
        );

        ibcHandler.sendPacket(
            IBC_PORT_EMISSIONS,
            sourceChannel,
            Height.Data({revision_number: 0, revision_height: 10_000}),
            0,
            packet
        );

        /** Post processing in onAcknowledgementPacket below */
    }

    /**
     * 상쇄 머클에서 중립 머클로
     *
     * @param carbonOffset The CarbonERC1155 contract that is donatable consumer-level offset token.
     * @param donator The donator(token holder).
     * @param projectTokenId The tokenId(projectId) want to donate, owned by donator.
     * @param donationTokenAmount The tokenAmount want to donate, enough for donator.
     * @param applicationTokenId The applicationId want to donate. (id is managed at emissions or offset or frontend)
     * @param sourceChannel The IBC channelId confirmed in expected IBC relayer
     */
    function transferOffsetToNeutral(
        address carbonOffset,
        address donator,
        uint256 projectTokenId,
        uint256 donationTokenAmount,
        uint256 applicationTokenId,
        string memory sourceChannel
    ) external onlyNotNeutralMerkle {
        // 1. lock to escrow
        IERC1155(carbonOffset).safeTransferFrom(
            donator,
            escrowAddress,
            projectTokenId,
            donationTokenAmount,
            ""
        );

        // 2. send packet
        bytes memory packet = encodeOffsetPacket(
            carbonOffset,
            donator,
            projectTokenId,
            donationTokenAmount,
            applicationTokenId
        );

        ibcHandler.sendPacket(
            IBC_PORT_OFFSET,
            sourceChannel,
            Height.Data({revision_number: 0, revision_height: 10_000}),
            0,
            packet
        );

        /** Post processing in onAcknowledgementPacket below */
    }

    function onAcknowledgementPacket(
        Packet.Data calldata packet,
        bytes calldata acknowledgement,
        address
    ) external virtual override onlyIBC onlyNotNeutralMerkle {
        bytes32 sourcePortHash = keccak256(
            abi.encodePacked(packet.source_port)
        );

        address carbonToken;
        address to;
        uint256 tokenId;
        uint256 amount;

        if (sourcePortHash == IBC_PORT_EMISSIONS_HASH) {
            (
                uint256 applicationTokenId,
                address carbonEmissions,
                address carbonEmitter,
                uint256 emissionsTokenAmount
            ) = decodeEmissionsPacket(packet.data);

            carbonToken = carbonEmissions;
            to = acknowledgement[0] == 0x01 ? address(this) : carbonEmitter;
            tokenId = applicationTokenId;
            amount = emissionsTokenAmount;
        } else if (sourcePortHash == IBC_PORT_OFFSET_HASH) {
            (
                address carbonOffset,
                address donator,
                uint256 projectTokenId,
                uint256 donationTokenAmount,
                uint256 applicationTokenId
            ) = decodeOffsetPacket(packet.data);

            carbonToken = carbonOffset;
            to = acknowledgement[0] == 0x01 ? address(this) : donator;
            tokenId = projectTokenId;
            amount = donationTokenAmount;
        }

        IERC1155(carbonToken).safeTransferFrom(
            escrowAddress,
            to,
            tokenId,
            amount,
            ""
        );
    }

    function onRecvPacket(
        Packet.Data calldata packet,
        address
    )
        external
        virtual
        override
        onlyIBC
        onlyNeutralMerkle
        returns (bytes memory acknowledgement)
    {
        acknowledgement = new bytes(1);

        bytes32 sourcePortHash = keccak256(
            abi.encodePacked(packet.source_port)
        );

        if (sourcePortHash == IBC_PORT_EMISSIONS_HASH) {
            (
                uint256 applicationTokenId,
                address carbonEmissions,
                address carbonEmitter,
                uint256 emissionsTokenAmount
            ) = decodeEmissionsPacket(packet.data);

            carbonNeutralPool.mintEmissions(
                carbonEmitter,
                applicationTokenId,
                emissionsTokenAmount
            );
            acknowledgement[0] = 0x01;
        } else if (sourcePortHash == IBC_PORT_OFFSET_HASH) {
            (
                address carbonOffset,
                address donator,
                uint256 projectTokenId,
                uint256 donationTokenAmount,
                uint256 applicationTokenId
            ) = decodeOffsetPacket(packet.data);

            carbonNeutralPool.mintOffset(
                donator,
                applicationTokenId,
                donationTokenAmount
            );
            acknowledgement[0] = 0x01;
        } else {
            acknowledgement[0] = 0x00;
        }

        return acknowledgement;
    }

    function encodeEmissionsPacket(
        uint256 applicationTokenId,
        address carbonEmissions,
        address carbonEmitter,
        uint256 emissionsTokenAmount
    ) internal pure returns (bytes memory) {
        bytes memory data = new bytes(104);

        assembly {
            mstore(add(data, 32), applicationTokenId)
            mstore(add(data, 64), shl(96, carbonEmissions))
            mstore(add(data, 84), shl(96, carbonEmitter))
            mstore(add(data, 104), emissionsTokenAmount)
        }

        return data;
    }

    function decodeEmissionsPacket(
        bytes memory data
    )
        internal
        pure
        returns (
            uint256 applicationTokenId,
            address carbonEmissions,
            address carbonEmitter,
            uint256 emissionsTokenAmount
        )
    {
        assembly {
            applicationTokenId := mload(add(data, 32))
            carbonEmissions := mload(add(data, 52))
            carbonEmitter := mload(add(data, 72))
            emissionsTokenAmount := mload(add(data, 104))
        }
    }

    function encodeOffsetPacket(
        address carbonOffset,
        address donator,
        uint256 projectTokenId,
        uint256 donationTokenAmount,
        uint256 applicationTokenId
    ) internal pure returns (bytes memory) {
        bytes memory data = new bytes(136);

        assembly {
            mstore(add(data, 32), shl(96, carbonOffset))
            mstore(add(data, 52), shl(96, donator))
            mstore(add(data, 72), projectTokenId)
            mstore(add(data, 104), donationTokenAmount)
            mstore(add(data, 136), applicationTokenId)
        }

        return data;
    }

    function decodeOffsetPacket(
        bytes memory data
    )
        internal
        pure
        returns (
            address carbonOffset,
            address donator,
            uint256 projectTokenId,
            uint256 donationTokenAmount,
            uint256 applicationTokenId
        )
    {
        assembly {
            carbonOffset := mload(add(data, 20))
            donator := mload(add(data, 40))
            projectTokenId := mload(add(data, 72))
            donationTokenAmount := mload(add(data, 104))
            applicationTokenId := mload(add(data, 136))
        }
    }

    function approvalAddresses() public view returns (address[2] memory) {
        return [address(this), escrowAddress];
    }

    function ibcAddress() public view virtual override returns (address) {
        return address(ibcHandler);
    }

    function onChanOpenInit(
        IIBCModule.MsgOnChanOpenInit calldata msg_
    ) external virtual override onlyIBC returns (string memory) {
        return "gesia";
    }

    function onChanOpenTry(
        IIBCModule.MsgOnChanOpenTry calldata msg_
    ) external virtual override onlyIBC returns (string memory) {
        return "gesia";
    }

    /** For escrow ERC1155Received */
    function onERC1155Received(
        address,
        address,
        uint256,
        uint256,
        bytes memory
    ) external pure returns (bytes4) {
        return this.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(
        address,
        address,
        uint256[] memory,
        uint256[] memory,
        bytes memory
    ) external pure returns (bytes4) {
        return this.onERC1155BatchReceived.selector;
    }
}
