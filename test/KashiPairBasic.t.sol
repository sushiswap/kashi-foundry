// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.15;

import "utils/BaseTest.sol";
import "interfaces/IBentoBoxV1.sol";
import "interfaces/IKashiPair.sol";
import "pairs/KashiPair.sol";
import "utils/KashiPairLib.sol";
import "script/KashiPair.s.sol";
import "BoringSolidity/libraries/BoringRebase.sol";

contract KashiBasicTest is BaseTest {
    using RebaseLibrary for Rebase;

    IBentoBoxV1 public bentoBox;
    IKashiPair public pair;
    KashiPair public masterContract;
    ERC20 public sushi;
    ERC20 public usdc;

    function setUp() public override {
        forkMainnet(15973087);
        super.setUp();

        KashiPairScript script = new KashiPairScript();
        script.setTesting(true);
        masterContract = script.run();

        bentoBox = IBentoBoxV1(constants.getAddress("mainnet.bentobox"));
        sushi = ERC20(constants.getAddress("mainnet.sushi"));
        usdc = ERC20(constants.getAddress("mainnet.usdc"));

        //todo: can throw this in the utils/KashiPairLib and compute on fly probably
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

        vm.stopPrank();

        address sushiWhale = constants.getAddress("mainnet.whale.sushi");
        vm.startPrank(sushiWhale);
        sushi.approve(address(bentoBox), type(uint256).max);
        bentoBox.deposit(address(sushi), sushiWhale, sushiWhale, 100 ether, 0);
        vm.stopPrank();
    }

    function testKashiPairDeployed() public {
        IStrictERC20 asset = IStrictERC20(address(pair.asset()));
        IStrictERC20 collateral = IStrictERC20(address(pair.collateral()));

        assertEq(address(asset), address(usdc));
        assertEq(address(collateral), address(sushi));
        assertEq(address(pair.bentoBox()), address(bentoBox));
        assertEq(pair.decimals(), asset.decimals());
        assertEq(pair.exchangeRate(), 0);
        assertEq(address(pair.oracle()), constants.getAddress("mainnet.oracle.chainlinkV2"));  
    } 

    function testKashiPairLendAndRemove() public {
        address user = constants.getAddress("mainnet.whale.usdc");
        
        uint256 lentAmount = 1 gwei; // 1000 usdc
        uint256 shareLent = bentoBox.toShare(address(usdc), lentAmount, false);
        
        // lend 1000 usdc
        _lend(user, usdc, lentAmount);
        
        (uint128 baseAsset, uint128 elasticAsset) = pair.totalAsset();
        uint256 userLent = pair.balanceOf(address(user));

        assertEq(baseAsset, shareLent);
        assertEq(elasticAsset, shareLent);
        assertEq(userLent, shareLent);
        
        // withdraw the 1000 usdc lent back to wallet
        // note: actual amount withdrawn will be a 1000 units less than withdrawn b/c of Kashi: below minimum check
        uint256 sharesWithdrawn = _removeAsset(user, address(usdc), lentAmount, true);
        assertEq(sharesWithdrawn, shareLent - 1000);
    }

    function testKashiPairBorrow() public {
        uint256 lentAmount = 100 gwei; // 100,000 usdc
        uint256 collateralAmount = 100000 ether; // 100,000 sushi
        uint256 borrowAmount = 1 gwei; // 1,000 usdc

        uint256 preOracleSpot = pair.oracle().peekSpot(pair.oracleData());

        // lend
        address lender = constants.getAddress("mainnet.whale.usdc");
        _lend(lender, usdc, lentAmount);
        
        // add collateral
        address borrower = constants.getAddress("mainnet.whale.sushi");
        _addCollateral(borrower, sushi, collateralAmount);

        // borrow and withdraw out of bento
        (uint256 part, uint256 share) = _borrow(borrower, borrowAmount, true);
        
        assertEq(preOracleSpot, pair.exchangeRate());
        assertEq(borrowAmount, bentoBox.toAmount(address(usdc), share, true));

        // check balance of borrower for asset borrower & withdrawn
        // todo: checkin on why dust amount didn't follow out (you don't get exact amount borrower and a small unit is included)
        console2.log(usdc.balanceOf(borrower));
        
        //todo: figure out how to test user's borrow part properly
        //uint256 userBorrowPart = pair.userBorrowPart(borrower);

        assertEq(pair.totalSupply(), bentoBox.toShare(address(usdc), lentAmount, false));
        assertEq(pair.balanceOf(lender), bentoBox.toShare(address(usdc), lentAmount, false));
        assertEq(pair.totalCollateralShare(), bentoBox.toShare(address(sushi), collateralAmount, false));
        assertEq(pair.userCollateralShare(borrower), bentoBox.toShare(address(sushi), collateralAmount, false));
    }

    function testUserInsolvent() public {
        uint256 lentAmount = 100 gwei; // 100,000 usdc
        uint256 collateralAmount = 100000 ether; // 100,000 sushi
        uint256 borrowAmount = 1 gwei; // 1,000 usdc

        uint256 preOracleSpot = pair.oracle().peekSpot(pair.oracleData());

        // lend
        address lender = constants.getAddress("mainnet.whale.usdc");
        _lend(lender, usdc, lentAmount);
        
        // add collateral
        address borrower = constants.getAddress("mainnet.whale.sushi");
        _addCollateral(borrower, sushi, collateralAmount);

        // borrow and withdraw out of bento
        (uint256 part, uint256 share) = _borrow(borrower, borrowAmount, true);
        
        assertEq(preOracleSpot, pair.exchangeRate());
        assertEq(borrowAmount, bentoBox.toAmount(address(usdc), share, true));

        // roll ahead 10 blocks
        advanceBlocks(10);

        // mock oracle exchangeRate change
        uint256 mockedRate = preOracleSpot * 1000;
        _mockOracle(mockedRate);

        // try to do another borrow, expect to revert
        vm.expectRevert(bytes("KashiPair: user insolvent"));
        pair.borrow(borrower, borrowAmount);
        vm.clearMockedCalls();
    }

    function _mockOracle(uint256 mockedRate) private {
        vm.mockCall(
            address(pair.oracle()),
            abi.encodeWithSelector(IOracle.get.selector, pair.oracleData()),
            abi.encode(true, mockedRate)
        );
    }

    function _borrow(address account, uint256 amount, bool transferOut) private returns (uint256 part, uint256 share) {
        vm.startPrank(account);

        uint256 borrowShare = bentoBox.toShare(address(pair.asset()), amount, false);
        (uint128 baseAsset, ) = pair.totalAsset();
        uint128 diff = baseAsset - uint128(borrowShare);
        if (diff < 1000) {
            amount -= 1000;
        }

        (part, share) = pair.borrow(account, amount);

        if (transferOut) {
            bentoBox.withdraw(address(pair.asset()), account, account, 0, share);
        }

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
}