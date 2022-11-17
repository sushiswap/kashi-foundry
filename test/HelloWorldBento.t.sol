// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.15;

import "solbase/tokens/ERC20/ERC20.sol";
import "utils/BaseTest.sol";
import "interfaces/IBentoBoxV1.sol";
import "interfaces/IOracle.sol";

import {console2} from "forge-std/console2.sol";

contract HelloWorldBento is BaseTest {
    IBentoBoxV1 public bentoBox;
    ERC20 public sushi;
    ERC20 public usdc;
    IOracle chainLinkOracle;

    function setUp() public override {
        forkMainnet(15973087);
        super.setUp();
        
        bentoBox = IBentoBoxV1(constants.getAddress("mainnet.bentobox"));
        chainLinkOracle = IOracle(constants.getAddress("mainnet.oracle.chainlinkV2"));

        //console2.log(address(chainLinkOracle));
        
        sushi = ERC20(constants.getAddress("mainnet.sushi"));
        usdc = ERC20(constants.getAddress("mainnet.usdc"));

        bytes memory sushiUsdcOracleData = abi.encode(
            constants.getAddress("mainnet.chainlink.usdc.eth"),
            constants.getAddress("mainnet.chainlink.sushi.eth"),
            1000000
        );

        //console2.logBytes(sushiUsdcOracleData);

        uint256 usdcSushiRate = chainLinkOracle.peekSpot(sushiUsdcOracleData);

        //console2.log(usdcSushiRate);

        address sushiWhale = 0xcBE6B83e77cdc011Cc18F6f0Df8444E5783ed982;
        vm.startPrank(sushiWhale);
        sushi.approve(address(bentoBox), type(uint256).max);
        bentoBox.deposit(address(sushi), sushiWhale, sushiWhale, 100 ether, 0);
        vm.stopPrank();
    }

    function testHelloWorld() public {
        address sushiWhale = 0xcBE6B83e77cdc011Cc18F6f0Df8444E5783ed982;
        uint256 helloBalance = bentoBox.balanceOf(address(sushi), sushiWhale);
        assertEq(helloBalance, bentoBox.toShare(address(sushi), 100 ether, false));
    }
}