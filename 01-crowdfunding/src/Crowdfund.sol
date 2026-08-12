// SPDX-License-Identifier: MIT
pragma solidity ^0.8.35;

contract Crowdfund {
	address public creator;
	uint256 public goal;
	uint256 public deadline;
	uint256 public totalRaised;

	mapping(address => uint256) public contributions;

	bool public withdrawn;
	
	constructor(uint256 _goal, uint256 _duration) {
		creator = msg.sender;
		goal = _goal;
		deadline = block.timestamp + _duration;
	}

	function contribute() public payable {
		require(block.timestamp < deadline, "Campaign has ended");
		require(msg.value > 0, "Contribution must be greateer than zero");
		contributions[msg.sender] += msg.value;
		totalRaised += msg.value;
	}

	function withdraw() public {
		require(msg.sender == creator, "Only the creator can withdraw");
		require(block.timestamp >= deadline, "Campaign is still active");
		require(totalRaised >= goal, "Goal was not reached");
		require(!withdrawn, "Funds already withdrawn");

		withdrawn = true;
		
		uint256 amount = address(this).balance;
		(bool success, ) = payable(creator).call{value: amount}("");
		require(success, "Withdraw failed");
	}

	function refund() public {
		require(block.timestamp >= deadline, "Campaign is still active");
		require(totalRaised < goal, "Goal was reached");
		require(contributions[msg.sender] > 0, "No contributions to refund");

		uint256 amount = contributions[msg.sender];
		contributions[msg.sender] = 0;

		(bool success, ) = payable(msg.sender).call{value: amount}("");
		require(success, "Refund failed");
	}
}
