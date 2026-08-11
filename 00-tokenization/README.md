# 00 — Tokenization

**You can see a diagram of the concepts explored in this lesson in docs/**

Foundry implementation of the Speedrun Ethereum tokenization challenge, focused on understanding ERC-721 state, ownership, authorization, and EVM execution rather than simply reproducing the reference implementation.

## What This Project Does

`Token.sol` implements a basic ERC-721 NFT using OpenZeppelin Contracts.

The contract supports:

- Sequential token minting
- ERC-721 ownership and balance tracking
- Token transfers
- Per-token approvals
- Standard ERC-721 authorization behavior

Token IDs are assigned sequentially using contract state maintained by `nextTokenId`.

## What I Tested

The Foundry test suite covers:

- Minting a token and verifying ownership
- Minting multiple tokens and verifying balances
- Transferring a token between accounts
- Rejecting unauthorized transfers
- Approving another account for a specific token
- Allowing an approved account to perform a transfer
- Verifying approval, ownership, and balance state after transitions

The tests use Foundry cheatcodes such as `vm.prank()` and `vm.expectRevert()` to simulate different callers and verify both valid and invalid state transitions.

## Local Chain Testing

The contract was also deployed to a local Anvil Ethereum node and interacted with using Cast.

The local workflow was:

1. Deploy the contract with `forge create`
2. Read contract state using `cast call`
3. Mint an NFT using a signed `cast send` transaction
4. Verify ownership and balances
5. Transfer the NFT between Anvil accounts
6. Verify the resulting on-chain state

This provided a second layer of validation beyond the isolated Foundry unit tests.

## Key Concepts Explored

### Contract State

The project demonstrates the distinction between:

- Contract deployment
- ERC-721 token creation
- Token ownership
- Account balances
- Authorization state

A deployed `Token` contract may exist without any NFTs having been minted.

### State Transitions

Minting and transferring are treated as explicit transitions between contract states.

For example:

    mint(beaver)

    ownerOf(0)        -> beaver
    balanceOf(beaver) -> 1

Followed by:

    transferFrom(beaver, bob, 0)

    ownerOf(0)        -> bob
    balanceOf(beaver) -> 0
    balanceOf(bob)    -> 1

Tests verify the resulting state rather than assuming a successful transaction produced the intended result.

### Authorization

ERC-721 ownership and authorization are separate concepts.

An NFT owner can transfer their token directly or authorize another address to transfer a specific token using `approve()`.

The project tests both unauthorized transfer rejection and successful transfers performed by approved accounts.

### Events

Minting emits the standard ERC-721 `Transfer` event with the zero address as the source:

    0x000...000 -> recipient

Normal transfers emit the same event between the previous and new owner.

These events provide an observable record of ERC-721 state transitions without storing the complete ownership history inside each token.

## Development Stack

- Solidity
- Foundry
- Forge
- Cast
- Anvil
- OpenZeppelin Contracts

## Running the Project

Build:

    forge build

Run tests:

    forge test

Run tests with detailed EVM traces:

    forge test -vvvv

Start a local Ethereum development node:

    anvil

## Project Status

Backend and contract portion complete.

The original Speedrun Ethereum challenge also includes a frontend for interacting with the NFT contract. That portion is intentionally deferred while I continue through the contract-focused challenges.

A frontend may be added later as part of a larger Ethereum application.

## Context

This project is part of my Ethereum development workspace for working through Speedrun Ethereum concepts using Foundry.

The goal is not simply to complete each challenge, but to understand the contract architecture, EVM state transitions, authorization model, testing methodology, and deployment workflow behind each implementation.
