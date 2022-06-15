// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "./BreadCoin.sol";

error BadRatio();

contract BreadSwap {
    BreadCoin public bread;

    uint64 public totalShares;
    uint64 public totalTokenA;
    uint64 public totalTokenB;
    uint64 public K;

    constructor() {

    }

    function deposit(uint64 _amtTokenA, uint64 _amtTokenB) public returns (uint64) {
        uint64 userShares = 0;
        if (totalShares == 0) {
            // case when first deposit is triggered
            userShares = 100;
        } else {
            uint64 shares_tokenA = (totalShares * _amtTokenA)/ totalTokenA;
            uint64 shares_tokenB = (totalShares * _amtTokenB)/ totalTokenB;
            if (shares_tokenA != shares_tokenB) {
                revert BadRatio();
            }
            // require(shares_tokenA == shares_tokenB, "Equal value of tokens must be provided on deposit");
            userShares = shares_tokenA;
        }

        require(userShares > 0, "Gotta contribute minimum threshold amount");

        totalTokenA += _amtTokenA;
        totalTokenB += _amtTokenB;
        K = totalTokenA * totalTokenB;
        totalShares += userShares;

        return userShares;
    }

    function helloworld() public pure returns (string memory) {
        return "hello world";
    }
}
