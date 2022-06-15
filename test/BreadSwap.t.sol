// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import {BreadSwap, BadRatio} from "src/BreadSwap.sol";

contract AmmTest is Test {
    BreadSwap amm;

    function setUp() public {
        amm = new BreadSwap();
    }

    function testSanity() public {
        string memory s = amm.helloworld();
        assertEq(s, "hello world");
    }

    function testDeposit() public {
        uint64 firstDep = amm.deposit(50,60);
        assertEq(firstDep, 100);

        uint64 secondDep = amm.deposit(5,6);
        // deposit / totalA = 5 / 50 = 0.1 of the pool; thus 0.1*100 = 10
        assertEq(secondDep, 10);

        uint64 thirdDep = amm.deposit(15,18);
        assertEq(thirdDep, 30);

        vm.expectRevert(BadRatio.selector);
        uint64 badDep = amm.deposit(10,20);
    }
}
