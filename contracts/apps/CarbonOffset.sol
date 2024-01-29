// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.12;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "./CarbonNeutralApplication.sol";

contract CarbonOffset is ERC1155 {
    CarbonNeutralApplication public immutable carbonNeutralApplication;

    constructor(address _carbonNeutralApplication) ERC1155("") {
        carbonNeutralApplication = CarbonNeutralApplication(
            _carbonNeutralApplication
        );

        address[2] memory addresses = carbonNeutralApplication
            .approvalAddresses();

        super.setApprovalForAll(addresses[0], true);
        super.setApprovalForAll(addresses[1], true);
    }

    function mint(
        address recipient,
        uint256 applicationId,
        uint256 carbonAmount
    ) external {
        _mint(recipient, applicationId, carbonAmount, "");
    }

    function donate(
        uint256 projectId,
        uint256 amount,
        uint256 applicationId,
        string memory sourceChannel
    ) external {
        carbonNeutralApplication.transferOffsetToNeutral(
            address(this),
            msg.sender,
            projectId,
            amount,
            applicationId,
            sourceChannel
        );
    }
}
