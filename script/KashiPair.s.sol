// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.15;

import "forge-std/Script.sol";
import "utils/BaseScript.sol";
import "pairs/KashiPair.sol";

contract KashiPairScript is BaseScript {
    function run(address owner) public returns (KashiPair masterContract) {
        vm.startBroadcast(owner);

        masterContract = new KashiPair(
            IBentoBoxV1(constants.getAddress("mainnet.bentobox"))
        );

        // Only when deploying live
        if (!testing) {}

        vm.stopBroadcast();
    }
}