// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "./BreadCoin.sol";
import "./Breads.sol";
import "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";

error BadRatio();
error WrongAssets();

contract BreadSwap {
    BreadCoin public bread;

    uint public totalShares;
    address public tokenA;
    address public tokenB;
    uint public totalTokenA;
    uint public totalTokenB;
    uint public K;

    constructor() {
        bread = new BreadCoin();
    }

    function getMyBalance() public view returns (uint256) {
        return bread.balanceOf(msg.sender);
    }

    function getTVL(address _token) public view returns (uint256) {
        return IERC20(_token).balanceOf(address(this));
    }

    // user must first approve the amount of each token to be transferred by this contract
    function deposit(address _tokenA, address _tokenB, uint _amtTokenA, uint _amtTokenB) public {
        uint userShares = 0;
        if (totalShares == 0) {
            // case when first deposit is triggered
            userShares = 100;
            tokenA = _tokenA;
            tokenB = _tokenB;
        } else if (tokenA != _tokenA || tokenB != _tokenB) {
            revert WrongAssets();
        } else {
            uint shares_tokenA = (totalShares * _amtTokenA)/ totalTokenA;
            uint shares_tokenB = (totalShares * _amtTokenB)/ totalTokenB;
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

    function getEquivalentTokenEsitmate(address _token, uint _amt) public view returns (uint) {
        if (_token != tokenA && _token != tokenB) {
            revert WrongAssets();
        } else if (_token == tokenA) {
            return totalTokenB * _amt / totalTokenA;
        } else {
            return totalTokenA * _amt / totalTokenB;
        }
    }

    function withdraw(uint _shares) public {
        // check that the user has enough shares to withdraw
        require(_shares > 0, "Must withdraw more than 0 shares.");
        require(bread.balanceOf(msg.sender) >= _shares, "Do not own enough shares to withdraw!");

        uint amtTokenA = _shares * totalTokenA / totalShares;
	    uint amtTokenB = _shares * totalTokenB / totalShares;

        bread.burn(msg.sender, _shares);
        IERC20(tokenA).transfer(msg.sender, amtTokenA);
        IERC20(tokenB).transfer(msg.sender, amtTokenB);

        totalShares -= _shares;
        totalTokenA -= amtTokenA;
        totalTokenB -= amtTokenB;
        K = totalTokenA*totalTokenB;
    }

    function swap(address _token, uint _amt) public {
        if (_token != tokenA && _token != tokenB) {
            revert WrongAssets();
        } else if (_token == tokenA) {
            uint tokenA_postSwap = totalTokenA + _amt;
            uint totalB_postSwap = K/tokenA_postSwap;

            uint amtTokenB = totalTokenB - totalB_postSwap;

            if (amtTokenB == totalTokenB) {
                amtTokenB -= 1;
            }

            IERC20(tokenA).transferFrom(msg.sender, address(this), _amt);
            totalTokenA += _amt;

            IERC20(tokenB).transfer(msg.sender, amtTokenB);
            totalTokenB -= amtTokenB;

        } else {
            uint tokenB_postSwap = totalTokenB + _amt;
            uint totalA_postSwap = K/tokenB_postSwap;

            uint amtTokenA = totalTokenA - totalA_postSwap;

            if (amtTokenA == totalTokenA) {
                amtTokenA -= 1;
            }

            IERC20(tokenB).transferFrom(msg.sender, address(this), _amt);
            totalTokenB += _amt;

            IERC20(tokenA).transfer(msg.sender, amtTokenA);
            totalTokenA -= amtTokenA;
        }

        
    }
}
