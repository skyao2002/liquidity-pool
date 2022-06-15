// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "src/BreadSwap.sol";
import "src/Breads.sol";

contract AmmTest is Test {
    BreadSwap public amm;
    Sour public establishedSRB;
    Rye public establishedRIB;

    function setUp() public {
        amm = new BreadSwap();
        establishedSRB = new Sour();
        establishedRIB = new Rye();
        establishedSRB.mint(address(this), 10000);
        establishedRIB.mint(address(this), 10000);
    }

    function testSanity() public {
        string memory s = amm.helloworld();
        assertEq(s, "hello world");
    }

    function testDeposit() public {
        establishedSRB.approve(address(amm), 50);
        establishedRIB.approve(address(amm), 60);
        amm.deposit(address(establishedSRB), address(establishedRIB), 50, 60);
        assertEq(amm.getMyBalance(), 100);

        establishedSRB.approve(address(amm), 5);
        establishedRIB.approve(address(amm), 6);
        amm.deposit(address(establishedSRB), address(establishedRIB),5,6);
        // deposit / totalA = 5 / 50 = 0.1 of the pool; thus 0.1*100 = 10
        assertEq(amm.getMyBalance(), 110);
        
        establishedSRB.approve(address(amm), 10);
        establishedRIB.approve(address(amm), 20);
        vm.expectRevert(BadRatio.selector);
        amm.deposit(address(establishedSRB), address(establishedRIB),10,20);

        establishedSRB.approve(address(amm), 15);
        establishedRIB.approve(address(amm), 18);
        amm.deposit(address(establishedSRB), address(establishedRIB),15,18);
        assertEq(amm.getMyBalance(), 140);

        establishedSRB.approve(address(amm), 5);
        establishedRIB.approve(address(amm), 6);
        vm.expectRevert(WrongAssets.selector);
        amm.deposit(address(establishedSRB), address(100000),5,6);
    }
}
