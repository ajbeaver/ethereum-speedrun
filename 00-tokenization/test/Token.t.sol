// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test} from "forge-std/Test.sol";
import {Token} from "../src/Token.sol";

contract TokenTest is Test {
	Token token;
	address beaver = address(0x1);
	address bob = address(0x2);
	
	function setUp() public {
		token = new Token();
	}

	function testMint() public {
		token.mint(beaver);

		assertEq(token.ownerOf(0), beaver);
		assertEq(token.balanceOf(beaver), 1);
	}

	function testMultipleMints() public {
		token.mint(beaver);
		token.mint(beaver);

		assertEq(token.ownerOf(0), beaver);
		assertEq(token.ownerOf(0), beaver);
		assertEq(token.balanceOf(beaver), 2);
	}

	function testTransfer() public {
		token.mint(beaver);

		vm.prank(beaver);
		token.transferFrom(beaver, bob, 0);
		assertEq(token.ownerOf(0), bob);
		assertEq(token.balanceOf(beaver), 0);
		assertEq(token.balanceOf(bob), 1);
	}

	function testCannotTransferSomeoneElsesToken() public {
		token.mint(beaver);

		vm.prank(bob);
		vm.expectRevert();

		token.transferFrom(beaver, bob, 0);
	}

	function testApprovedAccountCanTransfer() public {
		token.mint(beaver);

		vm.prank(beaver);
		token.approve(bob, 0);

		assertEq(token.getApproved(0), bob);
		
		vm.prank(bob);
		token.transferFrom(beaver, bob, 0);

		assertEq(token.ownerOf(0), bob);
		assertEq(token.balanceOf(beaver), 0);
		assertEq(token.balanceOf(bob), 1);
	}
}
