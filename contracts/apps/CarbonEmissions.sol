// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.12;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "./CarbonNeutralApplication.sol";

/** for each emissions category */
contract CarbonEmissions is ERC1155 {
    address public immutable calculator;
    CarbonNeutralApplication public immutable carbonNeutralApplication;

    string public name;
    string public symbol;

    /**
     *
     * @param _name The emissions categroy name.
     * @param _symbol The emissions categroy simbol.
     * @param _calculator The related(category) calculator contract that deployed on-chain.
     * @param _carbonNeutralApplication The IBC Application contract that deployed on-chain.
     */

    constructor(
        string memory _name,
        string memory _symbol,
        address _calculator,
        address _carbonNeutralApplication
    ) ERC1155("") {
        name = _name;
        symbol = _symbol;

        calculator = _calculator;

        carbonNeutralApplication = CarbonNeutralApplication(
            _carbonNeutralApplication
        );

        address[2] memory addresses = carbonNeutralApplication
            .approvalAddresses();

        super.setApprovalForAll(addresses[0], true);
        super.setApprovalForAll(addresses[1], true);
    }

    /** 계산 후 호출 */
    function mint(
        address from,
        uint256 emissionsTokenAmount,
        uint256 applicationTokenId,
        string memory sourceChannel
    ) external {
        require(msg.sender == calculator, "not a call from calculator.");

        address carbonEmitter = from;

        super._mint(
            carbonEmitter,
            applicationTokenId,
            emissionsTokenAmount,
            ""
        );

        // Note: Since the timing is unclear, mint is immediately sent to neutral.
        carbonNeutralApplication.transferEmissionsToNeutral(
            address(this),
            applicationTokenId,
            carbonEmitter,
            emissionsTokenAmount,
            sourceChannel
        );
    }
}
