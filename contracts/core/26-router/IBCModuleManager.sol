// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.12;

import {Context} from "@openzeppelin/contracts/utils/Context.sol";
import {IBCHost} from "../24-host/IBCHost.sol";
import {IIBCModule} from "./IIBCModule.sol";

/**
 * @dev IBCModuleManager is a contract that provides the functions defined in [ICS 5](https://github.com/cosmos/ibc/tree/main/spec/core/ics-005-port-allocation) and [ICS 26](https://github.com/cosmos/ibc/tree/main/spec/core/ics-026-routing-module).
 */
contract IBCModuleManager is IBCHost, Context {
    /**
     * @dev lookupModuleByPort will return the IBCModule along with the capability associated with a given portID
     */
    function lookupModuleByPort(string memory portId) internal view virtual returns (IIBCModule) {
        address module = lookupModule(portCapabilityPath(portId));
        require(module != address(0), "module not found");
        return IIBCModule(module);
    }

    /**
     * @dev lookupModuleByChannel will return the IBCModule along with the capability associated with a given channel defined by its portID and channelID
     */
    function lookupModuleByChannel(string memory portId, string memory channelId)
        internal
        view
        virtual
        returns (IIBCModule)
    {
        address module = lookupModule(channelCapabilityPath(portId, channelId));
        require(module != address(0), "module not found");
        return IIBCModule(module);
    }

    /**
     * @dev claimCapability allows the IBC app module to claim a capability that core IBC passes to it
     */
    function claimCapability(string memory name, address addr) internal {
        require(capabilities[name] == address(0), "capability already claimed");
        capabilities[name] = addr;
    }

    /**
     * @dev authenticateCapability attempts to authenticate a given name from a caller.
     * It allows for a caller to check that a capability does in fact correspond to a particular name.
     */
    function authenticateCapability(string memory name) internal view returns (bool) {
        return _msgSender() == capabilities[name];
    }

    /**
     * @dev lookupModule will return the IBCModule addresses bound to a given name.
     */
    function lookupModule(string memory name) internal view returns (address) {
        return capabilities[name];
    }

    /**
     * @dev portCapabilityPath returns the path under which owner module address associated with a port should be stored.
     */
    function portCapabilityPath(string memory portId) internal pure returns (string memory) {
        return portId;
    }

    /**
     * @dev channelCapabilityPath returns the path under which module address associated with a port and channel should be stored.
     */
    function channelCapabilityPath(string memory portId, string memory channelId)
        internal
        pure
        returns (string memory)
    {
        return string.concat(portId, "/", channelId);
    }

    /**
     * @dev validatePortIdentifier validates a port identifier string
     *     check if the string consist of characters in one of the following categories only:
     *     - Alphanumeric
     *     - `.`, `_`, `+`, `-`, `#`
     *     - `[`, `]`, `<`, `>`
     */
    function validatePortIdentifier(bytes memory portId) internal pure returns (bool) {
        if (portId.length < 2 || portId.length > 128) {
            return false;
        }
        unchecked {
            for (uint256 i = 0; i < portId.length; i++) {
                uint256 c = uint256(uint8(portId[i]));
                if (
                    // a-z
                    (c >= 0x61 && c <= 0x7A)
                    // 0-9
                    || (c >= 0x30 && c <= 0x39)
                    // A-Z
                    || (c >= 0x41 && c <= 0x5A)
                    // ".", "_", "+", "-"
                    || (c == 0x2E || c == 0x5F || c == 0x2B || c == 0x2D)
                    // "#", "[", "]", "<", ">"
                    || (c == 0x23 || c == 0x5B || c == 0x5D || c == 0x3C || c == 0x3E)
                ) {
                    continue;
                }
            }
        }
        return true;
    }
}
