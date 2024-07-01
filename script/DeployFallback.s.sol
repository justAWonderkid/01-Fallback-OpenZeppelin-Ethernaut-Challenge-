
// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity 0.8.20;

import {Script} from "forge-std/Script.sol";
import {Fallback} from "../src/Fallback.sol";


contract DeployFallback is Script {

    Fallback fback;

    address public owner = makeAddr("owner");

    function run() external returns (Fallback) {
        vm.startBroadcast(owner);
        fback = new Fallback();
        vm.stopBroadcast();
        return fback;
    }

}