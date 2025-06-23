# SimpleSwap

This project implements a basic decentralized exchange (DEX) on the Ethereum blockchain using Solidity. It allows users to:

- Deploy two ERC-20 tokens.
- Add and remove liquidity to/from a liquidity pool.
- Swap tokens via an Automated Market Maker (AMM) mechanism.
- Receive LP tokens representing their share of the pool.

## 🧠 Technologies

- Solidity ^0.8.20
- OpenZeppelin Contracts (ERC20 standard)
- Remix IDE
- Etherscan (for verification)
- GitHub (documentation)

## 📁 Contracts

The `contracts/` folder includes the following:

- `TokenA.sol` — Standard ERC-20 token used for testing.
- `TokenB.sol` — Second ERC-20 token used for pool creation.
- `SimpleSwap.sol` — The DEX contract. Handles liquidity, swaps, and LP token minting.

## 📌 Features

- Mint and approve tokens (ERC-20).
- Provide liquidity to a pool of two tokens.
- Receive LP tokens representing liquidity share.
- Remove liquidity and redeem tokens.
- Swap tokens using constant product formula.

## 🔗 Etherscan

Verified contract (SimpleSwap):  
[https://sepolia.etherscan.io/address/0x35d93BEC7AB652D7C87390c0438fB16Bb26F7193](https://sepolia.etherscan.io/address/0x35d93BEC7AB652D7C87390c0438fB16Bb26F7193)

## 🚀 Deployment Steps

1. Deploy `TokenA` and `TokenB` from Remix.
2. Approve the `SimpleSwap` contract to spend tokens.
3. Deploy `SimpleSwap` with name and symbol (e.g., `"Simple LP Token"`, `"SLP"`).
4. Use `addLiquidity` and `removeLiquidity` to interact with the pool.
5. Use `swapExactTokensForTokens` to swap one token for another.

## 👨‍💻 Author

Cristian Olivé  
Course: Solidity Ethereum Developer Pack  
Module 3 Practical Assignment

