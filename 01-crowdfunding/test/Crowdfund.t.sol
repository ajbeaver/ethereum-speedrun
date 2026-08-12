// SPDX-Licese-Identifier: MIT
pragma solidity ^0.8.35;

import {Test} from "forge-std/Test.sol";
import {Crowdfund} from "../src/Crowdfund.sol";

contract CrowdfundTest is Test {
	Crowdfund crowdfund;

	address beaver = address(0x1);

	function setUp() public {
		crowdfund = new Crowdfund(10 ether, 7 days);
		vm.deal(beaver, 100 ether);	
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
}
