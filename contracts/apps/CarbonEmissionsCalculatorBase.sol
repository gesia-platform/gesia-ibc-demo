// SPDX-License-Identifier: MIT

pragma solidity ^0.8.12;

/**
 * @dev Interface that must be implemented by smart contracts in order to receive
 * ERC-1155 token transfers.
 */
abstract contract CarbonEmissionsCalculatorBase {
    /**
     *
     * @param carbonEmissions The carbonEmissions(IERC1155 Implementioned) interconnected contracts of the same emission category as the calculator.
     contract address who's emission carbon from application.
     * @param from The user who's emission carbon from application.
     * @param amount The result of calculated from calculator. (Tons unit)
     * @param applicationId The AppId that requested emissions calculation.
     * @param sourceChannel The channelId value set by the selected IBC relayer.
     */
    function onCalculated(
        address carbonEmissions,
        address from,
        uint256 amount,
        uint256 applicationId,
        string memory sourceChannel
    ) internal virtual {}
}
