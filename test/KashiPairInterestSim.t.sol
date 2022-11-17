// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.15;

import "utils/BaseTest.sol";
import "openzeppelin-contracts/utils/Strings.sol";
import {console2} from "forge-std/console2.sol";


contract KashiPairInterestSim is BaseTest {

    function setUp() public override {
        forkMainnet(15973087);
        super.setUp();


    }

    function testInterestModel1() public {
        // Snapshots every 8 hours over 30 day period
        uint256 snapshotInterval = 12; // in hours
        uint256 daysToSimulate = 30; // days to simulate
        uint256 iterationsToRun = (24 / snapshotInterval) * daysToSimulate;

        for(uint256 i = 0; i < iterationsToRun; i++) {
            console2.log(string(abi.encode('--- snapshot ', Strings.toString(i), '-----')));
            console2.log(block.timestamp);
            advanceTime(snapshotInterval * (1 hours));
            console2.log(block.timestamp);
        }


    }
    

    // Snapshots every 8 hours over 30 day period
    // maybe can set this so we can run different simulations for different periods & snapshot periods





}