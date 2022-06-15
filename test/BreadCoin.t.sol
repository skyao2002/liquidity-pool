// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import {BreadCoin} from "src/BreadCoin.sol";

contract BreadCoinTest is Test {
    BreadCoin bread;

    function setUp() public {
        bread = new BreadCoin();
    }

    function testCoin() public {
        address p1 = address(this);
        bread.mint(p1, 100);
        assertEq(bread.totalSupply(), 100);

        address p2 = address(0);
        assert(bread.transfer(p2, 20));
        assertEq(bread.balanceOf(p2), 20);
        assertEq(bread.balanceOf(p1), 80);

        address p3 = address(1);
        bread.approve(p3, 50);
        assertEq(bread.allowance(p1, p3), 50);
        assertEq(bread.allowance(p1, p2), 0);

        vm.prank(p3);
        bread.transferFrom(p1, p2, 10);
        assertEq(bread.balanceOf(p2), 30);
    }
}
