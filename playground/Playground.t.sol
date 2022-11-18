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
        uint256 totalBorrowAmount = bentoBox.toAmount(address(fei), elasticBorrow, false) / 1e18;
        console2.log(string.concat("total collateral -> ", Strings.toString(bentoBox.toAmount(address(xSushi), totalCollateralShare, false) / 1e18), ' xSushi'));
        console2.log(string.concat("total asset unborrowed -> ", Strings.toString(bentoBox.toAmount(address(fei), elasticAsset, false) / 1e18), ' fei'));
        console2.log(string.concat("total asset borrowed -> ", Strings.toString(totalBorrowAmount), ' fei'));
        
        // Check User collateral Amounts
        address[49] memory userList = [
            0xF731507F0d5C150905d2004931a56703eD7dFE0E,
            0x224e69025A2f705C8f31EFB6694398f8Fd09ac5C,
            0xB0707a3Ba4D6b16cbc7d197F4061Ec2D1C77b16E,
            0xFF93A561A5e9446728E0Bf13f5b821f9a3E815fc,
            0x8Ea44af9e3Ca45bf886295A3E08110705Cf23Bd4,
            0xD1134f6e28AB3b75500378b47250d6d88E0C1BB0,
            0x27924d608013eED8EB40A2e3B8eae4D8e9162a72,
            0xDBFB40E6cf563b93abC5f5126E2b245dfD37237e,
            0x326A29360cE676B9fcc9D788267a9Fa4f7e8803C,
            0x1715Fdf5069d2695a7f4F51E51C134e911f3816b,
            0x6d115eBa88c03b0700fe12b59b4b1FBdF6C00333,
            0xb1D106a0A7726B233abEA001Ab3fae22f355f448,
            0x613849978AC8B53D596bbd2Eba860b619a067e2D,
            0x78F1b4984Ea680615347b2df8164b2824D3c83f0,
            0x73Ea5b1AB2F4a36556B0A57381ed0101643615f3,
            0x22d6307C8648d3281C4D73F7d036b9c8Df058024,
            0x9C258268d067ed41C7E6e6042671CE416713FBDE,
            0x385BAe68690c1b86e2f1Ad75253d080C14fA6e16,
            0xE2388f22cf5e328C197D6530663809cc0408a510,
            0xC3598d91844B061195136600AD243b077Cc164e2,
            0x7df6C4aA3144d6f5335f49bF8383f3deE6ca7334,
            0x8D7A5FEDf55B68625b2e5953f8203B029cb9c44e,
            0x0277d07Ae3E082182E45Cc5a5c2C909a82d1B39c,
            0x0A4ea2fdfaD07d035fA20Cf13B7e8813ac5DcA22,
            0x4bb4c1B0745ef7B4642fEECcd0740deC417ca0a0,
            0xE60458f765bc61e78940c5A275e9523D1f049690,
            0x725BB9099C7eA9f0473a4b4906338712e7c935e4,
            0xaFD5e59951397CB58F9f4847Adb212480331aD50,
            0x26b11a2497381ef5e28BcFCF881185791Ba11A5d,
            0x0bF069969A5C004824f78d8321A1599707C1919A,
            0x31AdfBf4F653bcdC3A12c889fa721eE76605fFa8,
            0x94c941ADf626494036D970B26470501fFca57B4b,
            0x54A33C7d2aD57802330848d2e108013A76BEEAFc,
            0xEF91B2BfdA210664732B625155B817009b6BE330,
            0x4B5871E50C22B2fE0E83BF3344eed7F7C5526f14,
            0x9C511E0ba08785034Dc9E45697E37b0f38612Fb5,
            0xEB3a2df5CF24FE375a82b9c63224C18fc9CDB482,
            0x325A7662F95FCA40ff3653688C86eb7A3e62404e,
            0x7F1091Fc4e107071aC9a7a8b7C63b81e0035D409,
            0xe120bEc89CfF4F6098CCE686437babdC87C325f8,
            0x2E3DF863F4B8c0aaB3D63648701F33A3aa0C33D8,
            0x05133c490f9f33e53059AB33a7289d074c7E1e44,
            0xF14662B6B7eDFEBe645D783AFEF03A6CE615dfe0,
            0x66641D903Db3Bcad08D66Cb222eD0a6205421Ec7,
            0x357dfdC34F93388059D2eb09996d80F233037cBa,
            0x9D80283bcd33874460e1942bA3605476efeF8287,
            0x2a8178Ed43C6b867d612cA55B6fAdCc8Eb2AaBab,
            0x7bEbf3d7eb8351edea30564D07f17cDa22e65467,
            0xFF2779E68e24b725c625F514Acb36736a23391e8
        ];

        console2.log('--- User Data ---');
        for (uint256 i = 0; i < userList.length; i++) {
            console2.log(string.concat('--- ', Strings.toHexString(userList[i]), ' ---'));
            console2.log(string.concat("total collateral amount -> ", Strings.toString(bentoBox.toAmount(address(xSushi), pair.userCollateralShare(userList[i]), false))));
            //console2.log(string.concat("total collateral amount -> ", Strings.toString(bentoBox.toAmount(address(xSushi), pair.userCollateralShare(userList[i]), false)), ' xSushi'));
            console2.log(string.concat("total borrow part -> ", Strings.toString(pair.userBorrowPart(userList[i]))));
            console2.log(string.concat("total borrow amount -> ", Strings.toString(pair.userBorrowPart(userList[i]) * elasticBorrow / baseBorrow)));
        
        }


    }
}