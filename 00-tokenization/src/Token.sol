// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {ERC721} from "@openzeppelin/contracts/token/ERC721/ERC721.sol";

contract Token is ERC721 {
	uint256 private nextTokenId;
	constructor() ERC721("Ethereum Speedrun Token", "EST") {}

	function mint(address recipient) public {
		uint256 tokenId = nextTokenId;
		nextTokenId++;

		_safeMint(recipient, tokenId);
	}
}
