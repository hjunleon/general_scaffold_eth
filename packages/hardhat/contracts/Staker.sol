pragma solidity >=0.6.0 <0.8.0;

import "hardhat/console.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

import "./ExampleExternalContract.sol";

contract Staker {
    ExampleExternalContract public exampleExternalContract;

    constructor(address exampleExternalContractAddress) public {
        exampleExternalContract = ExampleExternalContract(exampleExternalContractAddress);
    }

    mapping ( address => uint256 ) public balances;
    uint256 public constant threshold = 1 ether;
    uint256 public deadline = block.timestamp + 0.2 minutes;

    /// Boolean set if threshold is not reached by the deadline
    bool public openForWithdraw;
    bool public hasExecute = false;

    event Stake(address,uint256);

    function timeLeft() view external returns(uint256){
      if (block.timestamp >= deadline){
        return 0;
      }
      return deadline - block.timestamp;
    }

    modifier _deadline_not_passed(){
      require(this.timeLeft() > 0);
      _;
    }

    function stake() public payable _deadline_not_passed{
        balances[msg.sender] += msg.value;
        emit Stake(msg.sender, msg.value);
    }

    function get_total_balance() view public returns(uint256){
        return address(this).balance;
    }

    modifier _can_execute() {
      require(!hasExecute);
      require(block.timestamp >= deadline);
      require(get_total_balance() >= threshold);
      _;
    }


    function execute() external payable _can_execute{
        hasExecute = true;
        exampleExternalContract.complete{value: address(this).balance}();
    }

    modifier _can_withdraw(address payable _staker){
        require(this.timeLeft() == 0 && get_total_balance() < threshold);
        require(abi.encodePacked(balances[_staker]).length > 0);
        _;
    }



    function withdraw(address payable _staker ) external _can_withdraw(_staker){
        uint256 userBalance = balances[_staker];
        balances[_staker]  = 0;
        (bool sent, ) = _staker.call{value: userBalance}("");  //bytes memory data
        require(sent, "Failed to send Ether");
    } 

    

    // function receive() public payable {
        
    // }
    receive() external payable {
        stake();
    }
}

