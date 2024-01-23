// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.12;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "./IBCAppBase.sol";
import "../core/25-handler/IBCHandler.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import {Height} from "../proto/Client.sol";
import {CarbonOffsetVoucherPacket} from "../proto/CarbonOffsetVoucherPacket.sol";

contract CarbonOffsetVoucher is ERC1155, IBCAppBase, Ownable {
    uint64 private constant TIMEOUT_HEIGHT = 10_000;

    IBCHandler private immutable ibcHandler;

    constructor(
        IBCHandler ibcHandler_
    ) ERC1155("https://game.example/api/item/{id}.json") {
        ibcHandler = ibcHandler_;
    }

    function mint(
        address account,
        uint256 id,
        uint256 amount
    ) external onlyOwner {
        _mint(account, id, amount, "");
    }

    function _bytesToAddress(
        bytes memory data
    ) private pure returns (address addr) {
        assembly {
            addr := div(mload(add(data, 32)), 0x1000000000000000000000000)
        }
    }

    function sendTransfer(
        address account, // from address
        uint256 tokenId,
        uint256 amount,
        address receiver, // dest chain receiver address
        string calldata sourcePort,
        string calldata sourceChannel
    ) external {
        require(
            account == _msgSender() || isApprovedForAll(account, _msgSender()),
            "you donot have permission to transfer from account."
        );

        // you have to escrow not directly burning if you want lock while transfered dest chain.
        _burn(account, tokenId, amount);

        // pack data
        bytes memory packetData = CarbonOffsetVoucherPacket.encode(
            CarbonOffsetVoucherPacket.Data({
                amount: amount,
                sender: abi.encodePacked(account),
                receiver: abi.encodePacked(receiver),
                id: tokenId
            })
        );

        ibcHandler.sendPacket(
            sourcePort,
            sourceChannel,
            Height.Data({revision_number: 0, revision_height: TIMEOUT_HEIGHT}),
            0,
            packetData
        );
    }

    // just return a received message as packet acknowledgement
    function onRecvPacket(
        Packet.Data calldata packet,
        address
    ) external virtual override onlyIBC returns (bytes memory acknowledgement) {
        CarbonOffsetVoucherPacket.Data memory data = CarbonOffsetVoucherPacket
            .decode(packet.data);

        acknowledgement = new bytes(1);

        _mint(_bytesToAddress(data.receiver), data.id, data.amount, "");
        acknowledgement[0] = 0x01;
        return acknowledgement;
    }

    // ensure that the message returned by the packet receiver matches the one sent
    function onAcknowledgementPacket(
        Packet.Data calldata packet,
        bytes calldata acknowledgement,
        address
    ) external virtual override onlyIBC {
        if (acknowledgement[0] != 0x01) {
            /** 실패 */
            CarbonOffsetVoucherPacket.Data
                memory data = CarbonOffsetVoucherPacket.decode(packet.data);

            _mint(_bytesToAddress(data.receiver), data.id, data.amount, "");
        }
    }

    // onlyIBC modifier checks if a caller matches `ibcAddress()`
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
}
