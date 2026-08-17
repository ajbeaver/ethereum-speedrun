// SPDX-Licese-Identifier: MIT
pragma solidity ^0.8.35;

import {Test} from "forge-std/Test.sol";
import {Crowdfund} from "../src/Crowdfund.sol";

contract RefundAttacker {
	Crowdfund public crowdfund;
	bool public attemptedReentry;

	constructor(Crowdfund _crowdfund) {
		crowdfund = _crowdfund;
	}

	function contribute() external payable {
		crowdfund.contribute{value: msg.value}();
	}

	function attackRefund() external {
		crowdfund.refund();
	}

	receive() external payable {
		if (!attemptedReentry) {
			attemptedReentry = true;

			try crowdfund.refund() {
			} catch {
			}
		}
	}
}

contract WithdrawAttacker {
	Crowdfund public crowdfund;
	bool public attemptedReentry;

	constructor() {
		crowdfund = new Crowdfund(10 ether, 7 days);
	}

	function attackWithdraw() external {
		crowdfund.withdraw();
	}

	receive() external payable {
		if (!attemptedReentry) {
			attemptedReentry = true;

			try crowdfund.withdraw() {
			} catch {
			}
		}
	}
}

contract CrowdfundTest is Test {
	Crowdfund crowdfund;

	address beaver = address(0x1);
	address bob = address(0x2);

	function setUp() public {
		crowdfund = new Crowdfund(10 ether, 7 days);
		vm.deal(beaver, 100 ether);
		vm.deal(bob, 100 ether);	
	}

	receive() external payable {}
	
	function testContribution() public {
		vm.prank(beaver);
		crowdfund.contribute{value: 1 ether}();

		assertEq(crowdfund.contributions(beaver), 1 ether);
		assertEq(crowdfund.totalRaised(), 1 ether);
		assertEq(address(crowdfund).balance, 1 ether);
	}

	function testCannotContributeAfterDeadline() public {
		vm.warp(crowdfund.deadline() + 1);

		vm.prank(beaver);
		vm.expectRevert();

		crowdfund.contribute{value: 1 ether}();
	}

	function testCannotContributeZero() public {
		vm.prank(beaver);
		vm.expectRevert();

		crowdfund.contribute{value: 0}();
	}

	function testCreatorCanWithdrawAfterSuccessfulCampaign() public {
		vm.prank(beaver);
		crowdfund.contribute{value: 10 ether}();

		vm.warp(crowdfund.deadline() + 1);
		uint256 creatorBalanceBefore = address(this).balance;
		uint256 contractBalanceBefore = address(crowdfund).balance;

		crowdfund.withdraw();

		assertTrue(crowdfund.withdrawn());
		assertEq(address(crowdfund).balance, 0);
		assertEq(address(this).balance, creatorBalanceBefore + contractBalanceBefore);
	}

	function testCreatorCannotWithdrawBeforeDeadline() public {
		vm.prank(beaver);
		crowdfund.contribute{value: 10 ether}();

		vm.expectRevert();
		crowdfund.withdraw();
	}

	function testCreatorCannotWithdrawIfGoalIsNotReached() public {
		vm.prank(beaver);
		crowdfund.contribute{value: 5 ether}();

		vm.warp(crowdfund.deadline() + 1);

		vm.expectRevert();
		crowdfund.withdraw();
	}

	function testNonCreatorCannotWithdraw() public {
		vm.prank(beaver);
		crowdfund.contribute{value: 10 ether}();

		vm.warp(crowdfund.deadline() + 1);

		vm.prank(beaver);
		vm.expectRevert();

		crowdfund.withdraw();
	}

	function testCreatorCannotWithdrawTwice() public {
		vm.prank(beaver);
		crowdfund.contribute{value: 10 ether}();

		vm.warp(crowdfund.deadline() + 1);

		crowdfund.withdraw();

		vm.expectRevert();
		crowdfund.withdraw();
	}

	function testContributorCanRefundAfterFailedCampaign() public {
	    vm.prank(beaver);
	    crowdfund.contribute{value: 3 ether}();
	
	    vm.warp(crowdfund.deadline() + 1);
	
	    uint256 beaverBalanceBefore = beaver.balance;
	    uint256 contractBalanceBefore = address(crowdfund).balance;
	
	    vm.prank(beaver);
	    crowdfund.refund();
	
	    assertEq(crowdfund.contributions(beaver), 0);
	    assertEq(address(crowdfund).balance, contractBalanceBefore - 3 ether);
	    assertEq(beaver.balance, beaverBalanceBefore + 3 ether);
	}

	function testContributorCannotRefundBeforeDeadline() public {
	    vm.prank(beaver);
	    crowdfund.contribute{value: 3 ether}();
	
	    vm.prank(beaver);
	    vm.expectRevert();
	    crowdfund.refund();
	}
	
	function testContributorCannotRefundIfGoalReached() public {
	    vm.prank(beaver);
	    crowdfund.contribute{value: 10 ether}();
	
	    vm.warp(crowdfund.deadline() + 1);
	
	    vm.prank(beaver);
	    vm.expectRevert();
	    crowdfund.refund();
	}
	
	function testContributorCannotRefundTwice() public {
	    vm.prank(beaver);
	    crowdfund.contribute{value: 3 ether}();
	
	    vm.warp(crowdfund.deadline() + 1);
	
	    vm.prank(beaver);
	    crowdfund.refund();
	
	    vm.prank(beaver);
	    vm.expectRevert();
	    crowdfund.refund();
	}

	function testCannotContributeAtDeadline() public {
		vm.warp(crowdfund.deadline());

		vm.prank(beaver);
		vm.expectRevert();

		crowdfund.contribute{value: 10 ether}();
	}

	function testMultipleContributorsAccounting() public {
		vm.prank(beaver);
		crowdfund.contribute{value: 3 ether}();

		vm.prank(bob);
		crowdfund.contribute{value: 7 ether}();

		assertEq(crowdfund.contributions(beaver), 3 ether);
		assertEq(crowdfund.contributions(bob), 7 ether);
		assertEq(address(crowdfund).balance, 10 ether);
	}

	function testRefundReentrancy() public {
		RefundAttacker attacker = new RefundAttacker(crowdfund);

		attacker.contribute{value: 3 ether}();

		vm.warp(crowdfund.deadline());

		attacker.attackRefund();

		assertEq(address(attacker).balance, 3 ether);
		assertEq(crowdfund.contributions(address(attacker)), 0);
	}

	function testWithdrawReentrancy() public {
		WithdrawAttacker attacker = new WithdrawAttacker();
		Crowdfund attackerCrowdfund = attacker.crowdfund();

		vm.prank(beaver);
		attackerCrowdfund.contribute{value: 10 ether}();

		vm.warp(crowdfund.deadline());

		attacker.attackWithdraw();

		assertEq(address(attacker).balance, 10 ether);
		assertEq(address(attackerCrowdfund).balance, 0);
		assertTrue(attackerCrowdfund.withdrawn());
	}
}
