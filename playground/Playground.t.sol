// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.15;

import "forge-std/Script.sol";
import "utils/BaseTest.sol";

import "interfaces/IBentoBoxV1.sol";
import "interfaces/IKashiPair.sol";
import "interfaces/IOracle.sol";
import "solbase/tokens/ERC20/ERC20.sol";

import {console2} from "forge-std/console2.sol";
import "openzeppelin-contracts/utils/Strings.sol";

/// @dev A Script to run any kind of quick test
contract Playground is BaseTest {
    
    IBentoBoxV1 public bentoBox;
    IKashiPair public pair;
    address public pairAddy = 0xF2028069Cd88F75FCBCfE215c70fe6d77CB80B10;
    ERC20 public fei;
    ERC20 public xSushi;
    
    function test() public {
        forkMainnet(15997764);
        super.setUp();

        bentoBox = IBentoBoxV1(constants.getAddress("mainnet.bentobox"));
        fei = ERC20(0x956F47F50A910163D8BF957Cf5846D573E7f87CA);
        xSushi = ERC20(0x8798249c2E607446EfB7Ad49eC89dD1865Ff4272);
        pair = IKashiPair(pairAddy);


        // Let's looky
        uint256 exchangeRate = pair.exchangeRate();
        IOracle oracle = pair.oracle();
        (uint128 elasticAsset, uint128 baseAsset) = pair.totalAsset();
        (uint128 elasticBorrow, uint128 baseBorrow) = pair.totalBorrow();
        uint256 totalCollateralShare = pair.totalCollateralShare();
        (uint256 interestPerSec, uint64 lastAccrued, uint128 feesEarnedFrac) = pair.accrueInfo();


        // Check Data
        console2.log('--- Pair Data ---');
        console2.log(string.concat("ExchangeRate -> ", Strings.toString(exchangeRate)));
        console2.log(string.concat("elasticAsset -> ", Strings.toString(elasticAsset)));
        console2.log(string.concat("baseAsset -> ", Strings.toString(baseAsset)));
        console2.log(string.concat("elasticBorrow -> ", Strings.toString(elasticBorrow)));
        console2.log(string.concat("baseBorrw -> ", Strings.toString(baseBorrow)));
        console2.log(string.concat("totalCollateralShare -> ", Strings.toString(totalCollateralShare)));
        //console2.log(interestPerSec);
        console2.log(string.concat("Borrow APR -> ", Strings.toString((interestPerSec * 100 * 86400 * 365) / 1e18), "%"));
        console2.log(string.concat("lastAccrued -> ", Strings.toString(lastAccrued)));
        console2.log(string.concat("feesEarnedFrac -> ", Strings.toString(feesEarnedFrac)));
        
        
        // Check Oracle
        console2.log('--- Oracle Data ---');
        uint256 spotRate = oracle.peekSpot(pair.oracleData());
        console2.log(string.concat("spotRate -> ", Strings.toString(spotRate)));
        
        // Check Amounts
        console2.log('--- Amounts Data ---');
        console2.log(string.concat("total collateral -> ", Strings.toString(bentoBox.toAmount(address(xSushi), totalCollateralShare, false) / 1e18), ' xSushi'));
        console2.log(string.concat("total asset unborrowed -> ", Strings.toString(bentoBox.toAmount(address(fei), elasticAsset, false) / 1e18), ' fei'));
        console2.log(string.concat("total asset borrowed -> ", Strings.toString(bentoBox.toAmount(address(fei), elasticBorrow, false) / 1e18), ' fei'));
        
        // Check User collateral Amounts
        

    }
}