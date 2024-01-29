// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.12;

import "./CarbonNeutral.sol";

contract CarbonNeutralPool {
    CarbonNeutral public immutable emissions;
    CarbonNeutral public immutable offset;

    constructor() {
        emissions = new CarbonNeutral();
        offset = new CarbonNeutral();
    }

    function mintEmissions(
        address recipient, // 배출자
        uint256 applicationId, // 배출 출처
        uint256 amount // 배출량
    ) external {
        /** @todo you should check function called by application not a human */
        emissions.mint(recipient, applicationId, amount);
    }

    function mintOffset(
        address recipient, // 상쇄자
        uint256 applicationId, // 상쇄 대상
        uint256 amount // 상쇄량
    ) external {
        /** @todo you should check function called by application not a human */
        offset.mint(recipient, applicationId, amount);
    }
}
