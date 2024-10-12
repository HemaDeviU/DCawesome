//SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

import "./Strategy.sol";

contract Core {
    mapping(address => address) public userStrategies;
    event StrategyDeployed(address indexed user, address indexed StrategyContract);
    address public usdc;
    constructor(address _usdcAddress){
        usdc = _usdcAddress;
    }

    function createMyStrategy(address destinationWallet, uint256 destinationChain) external
    {
        //require
        Strategy strategy = new Strategy(destinationWallet, destinationChain, usdc);
        userStrategies[msg.sender] = address(strategy);
        emit StrategyDeployed(msg.sender, address(strategy));
    }
    function getStrategy(address user) public view returns (address)
    {
        return userStrategies[user];
    }
}