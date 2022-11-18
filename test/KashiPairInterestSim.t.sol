// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.15;

import "utils/BaseTest.sol";
import "openzeppelin-contracts/utils/Strings.sol";
import "interfaces/IBentoBoxV1.sol";
import "interfaces/IKashiPair.sol";
import "pairs/KashiPair.sol";
import "utils/KashiPairLib.sol";
import "script/KashiPair.s.sol";



import {console2} from "forge-std/console2.sol";


contract KashiPairInterestSim is BaseTest {

    IBentoBoxV1 public bentoBox;
    IKashiPair public pair;
    KashiPair public masterContract;
    ERC20 public sushi;
    ERC20 public usdc;
    address lender;
    address borrower;

    function setUp() public override {
        forkMainnet(15973087);
        super.setUp();

        bentoBox = IBentoBoxV1(constants.getAddress("mainnet.bentobox"));
        sushi = ERC20(constants.getAddress("mainnet.sushi"));
        usdc = ERC20(constants.getAddress("mainnet.usdc"));
        
        KashiPairScript script = new KashiPairScript();
        script.setTesting(true);
        masterContract = script.run(bentoBox.owner());


        bytes memory sushiUsdcOracleData = abi.encode(
            constants.getAddress("mainnet.chainlink.usdc.eth"),
            constants.getAddress("mainnet.chainlink.sushi.eth"),
            1000000
        );

        vm.startPrank(bentoBox.owner());
        bentoBox.whitelistMasterContract(address(masterContract), true);
        pair = KashiPairLib.deployKashiPair(
            bentoBox,
            address(masterContract),
            sushi,
            usdc,
            IOracle(constants.getAddress("mainnet.oracle.chainlinkV2")),
            sushiUsdcOracleData
        );
        masterContract.setSwapper(ISwapper(constants.getAddress("mainnet.kashiV1.swapperV1")), true);
        masterContract.setFeeTo(bentoBox.owner());

        vm.stopPrank();


        uint256 lentAmount = 100 gwei; // 100,000 usdc
        uint256 collateralAmount = 300000 ether; // 300,000 sushi
        
        // supply 100,000 usdc to pair
        lender = constants.getAddress("mainnet.whale.usdc");
        _lend(lender, usdc, lentAmount);

        // add 300,000 sushi as collateral
        borrower = constants.getAddress("mainnet.whale.sushi");
        _addCollateral(borrower, sushi, collateralAmount);
    }

    function testInterestModel1() public {
        // Simulation 1 -- Ramp Utilization Up 10% every day to 100 break for 5 days then ramp down to 0 break for 5 days
        uint256 borrowAmount = 10 gwei;

        // Snapshots every 8 hours over 30 day period
        uint256 snapshotInterval = 12; // in hours
        uint256 daysToSimulate = 30; // days to simulate
        uint256 pausePeriod = 5; // 5 days
        uint256 iterationsToRun = (24 / snapshotInterval) * daysToSimulate;

        uint256 interestPerSecond;
        uint128 utilization;
        uint256 currentHour = 0;
        uint256 currentDay = 0;
        uint256 currentPausePeriod = 0;
        uint256 lastDay = 0;
        uint8 stage;
        for(uint256 i = 0; i < iterationsToRun; i++) {
            console2.log(string.concat(
                "--- Hour ",
                Strings.toString(currentHour),
                ', Day ',
                Strings.toString(currentDay),
                " ---"
            ));
            currentHour += snapshotInterval;
            currentDay = currentHour / 24;

            // print utilization / APR results
            (interestPerSecond, , ) = pair.accrueInfo();
            utilization = _getUtilization();

            console2.log(string.concat("Utilization -> ", Strings.toString(utilization), "%"));
            //console2.log(string.concat("Supply APR -> ", Strings.toString((interestPerSecond * utilization))));
            console2.log(string.concat("Borrow APR -> ", Strings.toString((interestPerSecond * 100 * 86400 * 365) / 1e18), "%"));

            // Borrow process
            // Set stage: 0 -> borrow ramp up
            //            1 -> last borrow
            //            2 -> pause period
            //            3 -> pay off debt (stays on this stage once hit)
            (uint128 elasticAsset, ) = pair.totalAsset();
            if (!(elasticAsset < borrowAmount) && stage != 2 && stage != 3) {
                stage = 0;
            } else if (utilization >= 99) {
                if (currentPausePeriod < pausePeriod) {
                    stage = 2;
                } else {
                    stage = 3;
                }
            }
            else if (stage != 2 && stage != 3) {
                stage = 1;
            }
            
            // do the process
            if (!(lastDay == currentDay) || currentDay == 0) {
                if (stage == 0) {
                    _borrow(borrower, borrowAmount, false);
                } else if (stage == 1) {
                    _borrow(borrower, elasticAsset, false);
                }  else if (stage == 2) {
                    currentPausePeriod += 1;
                } else {
                    if (utilization > 0 && bentoBox.balanceOf(address(usdc), borrower) > borrowAmount) {
                        _repay(borrower, borrowAmount, false);
                    }
                }
                lastDay = currentDay;
            }

            pair.accrue();
            advanceTime(snapshotInterval * (1 hours));
        }
    }


    function _getUtilization() private view returns (uint128) {
        (uint128 elasticBorrow , ) = pair.totalBorrow();
        (uint128 elasticAsset , ) = pair.totalAsset();

        return (elasticBorrow * 100) / (elasticAsset + elasticBorrow);
    }

    function _borrow(address account, uint256 amount, bool transferOut) private returns (uint256 part, uint256 share) {
        vm.startPrank(account);

        (part, share) = pair.borrow(account, amount);

        if (transferOut) {
            bentoBox.withdraw(address(pair.asset()), account, account, 0, share);
        }

        vm.stopPrank();
    }

    function _repay(address account, uint256 amount, bool transferIn) private returns (uint256 amountRepayed) {
        vm.startPrank(account);

        if (transferIn) {
            bentoBox.setMasterContractApproval(account, address(masterContract), true, 0, 0, 0);
            pair.asset().approve(address(bentoBox), amount);
            bentoBox.deposit(address(pair.asset()), account, account, amount, 0);    
        }

        uint256 shareRepay = bentoBox.toShare(address(pair.asset()), amount, false);
        amountRepayed = pair.repay(account, false, shareRepay);

        vm.stopPrank();
    }

    function _addCollateral(address account, ERC20 collateral, uint256 amount) private {
        vm.startPrank(account);
        bentoBox.setMasterContractApproval(account, address(masterContract), true, 0, 0, 0);

        collateral.approve(address(bentoBox), amount);
        ( , uint256 shareIn) = bentoBox.deposit(address(collateral), account, account, amount, 0);

        pair.addCollateral(account, false, shareIn);

        vm.stopPrank();
    }

    // todo: should prob rework this so I'm passing around pair instead of asset
    //       can help us separate so this so this can be a base tests for all types of kashi pairs
    function _removeAsset(address account, address asset, uint256 amount, bool transferOut) private returns (uint256 sharesRemoved){
        vm.startPrank(account);
        
        uint256 fraction = _toFraction(asset, bentoBox.toShare(asset, amount, false));

        (uint128 baseAsset, ) = pair.totalAsset();
        uint128 diff = baseAsset - uint128(fraction);
        if (diff < 1000) {
            fraction -= 1000;
        }

        sharesRemoved = pair.removeAsset(account, fraction);

        if (transferOut) {
            bentoBox.withdraw(asset, account, account, 0, sharesRemoved);
        }

        vm.stopPrank();
    }

    function _lend(address account, ERC20 asset, uint256 amount) private returns (uint256 fraction) {
        vm.startPrank(account);
        bentoBox.setMasterContractApproval(account, address(masterContract), true, 0, 0, 0);
        
        asset.approve(address(bentoBox), amount);
        ( , uint256 shareIn) = bentoBox.deposit(address(asset), account, account, amount, 0);
    
        fraction = pair.addAsset(account, false, shareIn);
        
        vm.stopPrank();
    }

    function _toFraction(address asset, uint256 share) private view returns (uint256 fraction){
        (uint128 baseAsset, uint128 elasticAsset) = pair.totalAsset();
        ( , uint128 elasticBorrow) = pair.totalBorrow();

        uint256 allShare = elasticAsset + bentoBox.toShare(asset, elasticBorrow, true);
        fraction = allShare == 0 ? share : (share * baseAsset) / allShare;
        return fraction;
    }




    // Snapshots every 8 hours over 30 day period
    // maybe can set this so we can run different simulations for different periods & snapshot periods





}