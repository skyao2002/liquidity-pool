// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "src/BreadSwap.sol";
import "src/Breads.sol";

contract AmmTest is Test {
    BreadSwap public amm;
    Sour public establishedSRB;
    Rye public establishedRIB;

    address p1;
    address p2;
    address p3;

    function setUp() public {
        amm = new BreadSwap();
        establishedSRB = new Sour();
        establishedRIB = new Rye();
        p1 = address(this);
        p2 = address(0x102);
        p3 = address(0x103);

        establishedSRB.mint(p1, 10000);
        establishedRIB.mint(p1, 10000);

        establishedSRB.mint(p2, 10000);
        establishedRIB.mint(p2, 10000);

        establishedSRB.mint(p3, 10000);
        establishedRIB.mint(p3, 10000);
    }

    function testBread() public {
        // starting the pool with 5:6 ratio
        establishedSRB.approve(address(amm), 50);
        establishedRIB.approve(address(amm), 60);
        amm.deposit(address(establishedSRB), address(establishedRIB), 50, 60);
        assertEq(amm.getMyBalance(), 100);

        // increasing supply to 55:66
        establishedSRB.approve(address(amm), 5);
        establishedRIB.approve(address(amm), 6);
        amm.deposit(address(establishedSRB), address(establishedRIB),5,6);
        // deposit / totalA = 5 / 50 = 0.1 of the pool; thus 0.1*100 = 10
        assertEq(amm.getMyBalance(), 110);
        
        // test that bad ration will fail
        establishedSRB.approve(address(amm), 10);
        establishedRIB.approve(address(amm), 20);
        vm.expectRevert(BadRatio.selector);
        amm.deposit(address(establishedSRB), address(establishedRIB),10,20);

        // increase supply to 70:84 from different supplier p2
        vm.prank(p2);
        establishedSRB.approve(address(amm), 15);
        vm.prank(p2);
        establishedRIB.approve(address(amm), 18);
        vm.prank(p2);
        amm.deposit(address(establishedSRB), address(establishedRIB),15,18);
        vm.prank(p2);
        assertEq(amm.getMyBalance(), 30);

        // test using a token not in the pool will fail
        establishedSRB.approve(address(amm), 5);
        establishedRIB.approve(address(amm), 6);
        vm.expectRevert(WrongAssets.selector);
        amm.deposit(address(establishedSRB), address(100000),5,6);

        // TVL locked by pool of tokenA is 70
        assertEq(amm.getTVL(address(establishedSRB)), 70);

        // to contribute 30 of tokenA, you must contribute 36 of tokenB
        assertEq(amm.getEquivalentTokenEsitmate(address(establishedSRB), 30), 36);

        // now lets say that tokenA starts to crash, people want to swap out tokenA for tokenB
        vm.prank(p3);
        establishedSRB.approve(address(amm), 35);
        vm.prank(p3);
        amm.swap(address(establishedSRB), 35);
        // K = 70*84 = 5880 ; tokenA post swap = 105 ; token B postswap = 5880 / 105 = 56 ; token B recieved = 84-56 = 28
        assert(establishedSRB.balanceOf(p3) == 9965 && establishedRIB.balanceOf(p3) == 10028);


        // now tokenA spikes, people want to swap tokenB for tokenA
        vm.prank(p3);
        establishedRIB.approve(address(amm), 100);
        vm.prank(p3);
        amm.swap(address(establishedRIB), 100);
        // K = 105*56 = 5880 ; tokenB post swap = 156 ; token A postswap = 5880 / 156 = 37 ; token A recieved = 105-37 = 68
        assertEq(establishedSRB.balanceOf(p3), 10033);
        assertEq(establishedRIB.balanceOf(p3), 9928);


        // p1 wants to withdraw 80 shares
        amm.withdraw(80);
        // tokenA withdrawn = 80 * 37 / 140 = 21
        // tokenB withdrawn = 89
        // the supplier ended with more tokenB even though it is currently more favorable to own tokenA
        assertEq(establishedSRB.balanceOf(p1), 10000-55+21);
        assertEq(establishedRIB.balanceOf(p1), 10000-66+89);
        assertEq(amm.getMyBalance(), 30);
    }
}
