// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.12;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "./IBCAppBase.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import {Height} from "../proto/Client.sol";

contract CarbonNeutral is ERC1155, Ownable {
    constructor() ERC1155("") {}

    function mint(
        address recipient,
        uint256 tokenId,
        uint256 amount
    ) external onlyOwner {
        super._mint(recipient, tokenId, amount, "");
    }
}
