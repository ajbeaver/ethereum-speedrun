# 01 — Crowdfunding

A minimal Ethereum crowdfunding contract built with Solidity and Foundry.

This project explores how a smart contract can hold ETH, track contributions, enforce a funding deadline, and resolve into one of two outcomes: creator withdrawal or contributor refunds.

## Contract Model

A creator deploys a campaign with:

- A funding goal
- A campaign duration

Contributors may send ETH to the contract while the campaign is active. The contract records both the total amount raised and the amount contributed by each address.

After the deadline:

- If the funding goal was reached, the creator may withdraw the funds.
- If the funding goal was not reached, contributors may reclaim their individual contributions.

## State

The contract maintains:

- `creator` — address that deployed the campaign
- `goal` — amount of ETH required for a successful campaign
- `deadline` — timestamp after which the campaign ends
- `totalRaised` — total ETH contributed
- `contributions` — mapping of contributor addresses to contributed amounts
- `withdrawn` — records whether a successful campaign has already been withdrawn

## State Transitions

### Contribute

Before the deadline, an address may contribute ETH.

A valid contribution:

1. Increases `contributions[msg.sender]`
2. Increases `totalRaised`
3. Increases the ETH balance held by the contract

Zero-value contributions and contributions made after the deadline are rejected.

### Successful Campaign

After the deadline, if:

`totalRaised >= goal`

the creator may withdraw the contract's ETH balance.

Withdrawal is restricted to the creator and may only occur once.

### Failed Campaign

After the deadline, if:

`totalRaised < goal`

contributors may independently reclaim their recorded contributions.

Before sending ETH back, the contract sets the caller's recorded contribution to zero. This follows the Checks-Effects-Interactions pattern and prevents the same contribution from being refunded multiple times through reentrant execution.

## Testing

The Foundry test suite covers the major state transitions and invalid operations.

Current coverage includes:

- Successful contribution
- Zero-value contribution rejection
- Contribution after deadline rejection
- Successful creator withdrawal
- Withdrawal before deadline rejection
- Withdrawal when the goal was not reached
- Withdrawal by a non-creator
- Double withdrawal rejection
- Successful contributor refund
- Refund before deadline rejection
- Refund after successful campaign rejection
- Double refund rejection

Run the suite with:

    forge test

For detailed execution traces:

    forge test -vvvv

## Security Concepts

This project introduces several important smart-contract security concepts.

### Checks-Effects-Interactions

Functions that transfer ETH follow the general ordering:

    Checks
      ↓
    Effects
      ↓
    Interactions

The contract verifies that an operation is permitted, updates its internal state, and only then performs an external call.

This is particularly important during refunds because the recipient may itself be a smart contract capable of executing code when ETH is received.

### Reverts and Atomicity

Invalid state transitions use `require()` to revert.

A revert rolls back the entire transaction, including state changes made earlier during execution. This allows the contract to update internal state before an external interaction without permanently corrupting that state if the interaction fails.

### Block Timestamps

Campaign deadlines use `block.timestamp`.

Ethereum timestamps should not be treated as a precision clock and validators have limited influence over them. For a crowdfunding deadline measured in days, this is acceptable because the contract only needs to determine whether execution occurs before or at/after the campaign deadline.

## Architecture

The project architecture and campaign state flow are documented in:

`../docs/01-diagram.svg`

![Crowdfunding contract architecture](../docs/01-diagram.svg)

## Tooling

- Solidity `0.8.35`
- Foundry
- Forge
- Anvil
- Cast

## Next Step

Deploy the contract to a local Anvil chain and exercise both campaign outcomes using separate accounts for the creator and contributors.
