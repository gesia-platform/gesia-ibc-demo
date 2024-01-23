// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.12;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "./IBCAppBase.sol";
import "../core/25-handler/IBCHandler.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import {Height} from "../proto/Client.sol";

contract CarbonOffsetVoucher is ERC1155, IBCAppBase, Ownable {
    uint64 private constant TIMEOUT_HEIGHT = 10_000;

    IBCHandler private immutable ibcHandler;

    constructor(
        IBCHandler ibcHandler_
    ) ERC1155("https://gesiaplatform.com/vouchers/{id}.json") {
        ibcHandler = ibcHandler_;
    }

    function mint(
        address account,
        uint256 id,
        uint256 amount
    ) external onlyOwner {
        _mint(account, id, amount, "");
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

        bytes memory packet = _encode(tokenId, account, receiver, amount);

        ibcHandler.sendPacket(
            sourcePort,
            sourceChannel,
            Height.Data({revision_number: 0, revision_height: TIMEOUT_HEIGHT}),
            0,
            packet
        );
    }

    // just return a received message as packet acknowledgement
    function onRecvPacket(
        Packet.Data calldata packet,
        address
    ) external virtual override onlyIBC returns (bytes memory acknowledgement) {
        (
            uint256 tokenId,
            address sender,
            address receiver,
            uint256 amount
        ) = _decode(packet.data);

        acknowledgement = new bytes(1);

        _mint(receiver, tokenId, amount, "");

        acknowledgement[0] = 0x01;
        return acknowledgement;
    }

    // ensure that the message returned by the packet receiver matches the one sent
    function onAcknowledgementPacket(
        Packet.Data calldata packet,
        bytes calldata acknowledgement,
        address
    ) external virtual override onlyIBC {
        (
            uint256 tokenId,
            address sender,
            address receiver,
            uint256 amount
        ) = _decode(packet.data);

        if (acknowledgement[0] != 0x01) {
            // Note: refund
            _mint(sender, tokenId, amount, "");
        }
    }

    function hexStringToAddress(
        string memory addrHexString
    ) internal pure returns (address) {
        bytes memory addrBytes = bytes(addrHexString);
        if (addrBytes.length != 42) {
            return (address(0));
        } else if (addrBytes[0] != "0" || addrBytes[1] != "x") {
            return (address(0));
        }
        uint256 addr = 0;
        unchecked {
            for (uint256 i = 2; i < 42; i++) {
                uint256 c = uint256(uint8(addrBytes[i]));
                if (c >= 48 && c <= 57) {
                    addr = addr * 16 + (c - 48);
                } else if (c >= 97 && c <= 102) {
                    addr = addr * 16 + (c - 87);
                } else if (c >= 65 && c <= 70) {
                    addr = addr * 16 + (c - 55);
                } else {
                    return (address(0));
                }
            }
        }
        return (address(uint160(addr)));
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

    function _encode(
        uint256 tokenId,
        address sender,
        address receiver,
        uint256 amount
    ) internal pure returns (bytes memory) {
        bytes memory data = new bytes(104);

        assembly {
            // first 32 bytes allocated for length of data
            mstore(add(data, 32), tokenId)

            // left 20bytes replace to content
            mstore(add(data, 64), shl(96, sender))

            mstore(add(data, 84), shl(96, receiver))

            mstore(add(data, 104), amount)
        }

        return data;
    }

    function _decode(
        bytes memory data
    )
        internal
        pure
        returns (
            uint256 tokenId,
            address sender,
            address receiver,
            uint256 amount
        )
    {
        assembly {
            tokenId := mload(add(data, 32))

            sender := mload(add(data, 52))

            receiver := mload(add(data, 72))

            amount := mload(add(data, 104))
        }
    }
}
