// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "./BreadCoin.sol";
import "./Breads.sol";
import "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";

error BadRatio();
error WrongAssets();

contract BreadSwap {
    BreadCoin public bread;

    uint64 public totalShares;
    address public tokenA;
    address public tokenB;
    uint64 public totalTokenA;
    uint64 public totalTokenB;
    uint64 public K;

    constructor() {
        bread = new BreadCoin();
    }

    function getMyBalance() public view returns (uint256) {
        return bread.balanceOf(msg.sender);
    }

    // user must first approve the amount of each token to be transferred by this contract
    function deposit(address _tokenA, address _tokenB, uint64 _amtTokenA, uint64 _amtTokenB) public {
        uint64 userShares = 0;
        if (totalShares == 0) {
            // case when first deposit is triggered
            userShares = 100;
            tokenA = _tokenA;
            tokenB = _tokenB;
        } else if (tokenA != _tokenA || tokenB != _tokenB) {
            revert WrongAssets();
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

        IERC20(_tokenA).transferFrom(msg.sender, address(this), _amtTokenA);
        IERC20(_tokenB).transferFrom(msg.sender, address(this), _amtTokenB);

        totalTokenA += _amtTokenA;
        totalTokenB += _amtTokenB;
        K = totalTokenA * totalTokenB;
        totalShares += userShares;

        // mint tokens and share w depositer
        bread.mint(msg.sender, uint(userShares));
    }

    function helloworld() public pure returns (string memory) {
        return "hello world";
    }
}
