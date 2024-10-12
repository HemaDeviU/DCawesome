// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {AutomationCompatibleInterface} from "@chainlink/interfaces/AutomationCompatibleInterface.sol";
import {AggregatorV3Interface} from "@chainlink/shared/interfaces/AggregatorV3Interface.sol";
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";


contract Strategy is Ownable {
    mapping(address => uint256) public userBalances; 
    AggregatorV3Interface internal dataFeed;
    address public chainlinkAutomationRegistry;

    struct DCAIN {
        address dcaINoutToken1;
        address dcaINoutToken2;
        address dcaINoutToken3;
        uint256 dcaAmount;
        uint256 frequency;
        uint256 lastExecution;
        bool paused;
    }
    
    struct DCAOUT {
        address dcaOUToutToken;
        address targetToken;
        uint256 priceTarget;
        uint256 frequency;
        uint256 lastExecution;
        bool paused;
    }

    DCAIN public DCAINStrategy;
    DCAOUT public DCAOUTStrategy;

    address public destinationWallet;
    uint256 public destinationChain;
    address public usdc;

    constructor(address _destinationWallet,uint256 _destinationChain, address _usdcAddress)
    {
        // owner = _owner;
        usdc = _usdcAddress;
        destinationWallet = _destinationWallet;
        destinationChain = _destinationChain;
        dataFeed = AggregatorV3Interface(
            0x1b44F3514812d835EB1BDB0acB33d3fA3351Ee43
        );
    }

    function setDCAINStrategy(address _dcaINoutToken1,address _dcaINoutToken2,address _dcaINoutToken3,uint256 _frequency) public
    { 
        DCAINStrategy = DCAIN({dcaINoutToken1: _dcaINoutToken1,
        dcaINoutToken2: _dcaINoutToken2,
        dcaINoutToken3: _dcaINoutToken3,
        frequency: 1 minutes, 
        dcaAmount: 100,
        lastExecution: block.timestamp,
        paused: true
        }); 
        //emit
    }

     function setDCAOUTStrategy(address _outToken,address _targetToken,uint256 _priceTarget) public
    { 
        DCAOUTStrategy = DCAOUT({
        dcaOUToutToken: _outToken,
        targetToken: _targetToken,
        priceTarget: _priceTarget,
        frequency: 5 minutes, 
        lastExecution: block.timestamp,
        paused: true
        });

        //emit
    }
    function deposit(address token, uint256 amount) external {
        require(amount > 0, "Amount must be greater than 0");
        IERC20(token).transferFrom(msg.sender, address(this), amount);
        userBalances[token] += amount;
        // emit Deposited(msg.sender, token, amount);
    }
      function takeProfits(address token, uint256 amount) external {
        require(userBalances[token] >= amount, "Insufficient balance");
        userBalances[token] -= amount;
        address user = payable(msg.sender);
        IERC20(token).transfer(user, amount);
        // emit ProfitsRealized(user, amount);
    }

    //DCAOUT executions

    function checkUpkeep(
        bytes calldata /* checkData */
    )
        external
        view
        returns (bool upkeepNeeded, bytes memory /* performData */)
    {
        bool timepassed = block.timestamp - DCAOUTStrategy.lastExecution > DCAOUTStrategy.frequency;
        bool targetPriceReached = (uint256(getChainlinkDataFeedLatestAnswer()) >= DCAOUTStrategy.priceTarget);
        upkeepNeeded = (!DCAOUTStrategy.paused && timepassed && targetPriceReached);
    }

    function getChainlinkDataFeedLatestAnswer() public view returns (int256) {
        (
            /* uint80 roundID */,
            int answer,
            /*uint startedAt*/,
            /*uint timeStamp*/,
            /*uint80 answeredInRound*/
        ) = dataFeed.latestRoundData();
        return answer;
    }

    function performUpkeep(bytes calldata /* performData */) external {
        if ((block.timestamp - DCAINStrategy.lastExecution) > DCAINStrategy.frequency) {
            DCAINStrategy.lastExecution = block.timestamp;
            executeDCAOUT(); //sell order with 1 inch
        }
    }

    function executeDCAOUT() public 
    {
        

    }

    function executeDCAIN() public 
    {   
        uint256 count = 0;

        if(DCAINStrategy.dcaINoutToken1 != address(0)) {
            count ++;
        }

        if(DCAINStrategy.dcaINoutToken2 != address(0)) {
            count ++;
        }

        if(DCAINStrategy.dcaINoutToken3 != address(0)) {
            count ++;
        }

        swapUSDC(count);
    }

    function swapUSDC(uint256 count) public {

        uint256 usdcBal = ERC20(usdc).balanceOf(address(this));

        uint256 share = usdcBal/count;

        for (uint256 i = 0; i < count; i++) {
            swap(share);
        }
    }

    function swap(uint256 amount) public {

    }

    
    


    //DCAIN executions




    function pauseDCAIN() external {
        DCAINStrategy.paused = true;
        // emit DCAINPaused(msg.sender);
    }

    function resumeDCAIN() external {
        DCAINStrategy.paused = false;
        // emit DCAINResumed(msg.sender);
    }
    function pauseDCAOUT() external {
        DCAOUTStrategy.paused = true;
        // emit DCAOUTPaused(msg.sender);
    }

    function resumeDCAOUT() external {
        DCAOUTStrategy.paused = false;
        // emit DCAOUTResumed(msg.sender);
    }

 


}