# 🌀 SimpleSwap - Solidity Token Swap Contract

This repository contains a simplified decentralized exchange (DEX) smart contract written in Solidity for educational purposes.

## 🚀 Features

- Add and remove liquidity for a pair of ERC-20 tokens.
- Automatically mint and burn LP tokens.
- Token swapping based on an AMM (Automated Market Maker) formula.
- Cleanly structured and commented using NatSpec.

## 🛠 Contract Information

**Sepolia testnet address:**  
[`0x35d93BEC7AB652D7C87390c0438fB16Bb26F7193`](https://sepolia.etherscan.io/address/0x35d93BEC7AB652D7C87390c0438fB16Bb26F7193#code)

## 🧪 How to Test

1. Deploy two ERC-20 tokens (`TokenA.sol` and `TokenB.sol`)
2. Deploy the `SimpleSwap.sol` contract
3. Approve `SimpleSwap` to spend tokens from each token contract
4. Add liquidity using `addLiquidity()`
5. Test swapping with `swapExactTokensForTokens()`
6. Optionally test `removeLiquidity()` to retrieve assets

## 📚 Stack

- Solidity ^0.8.20
- OpenZeppelin ERC-20 libraries
- Remix IDE
- Etherscan (for contract verification)

## 📂 Files

- `contracts/SimpleSwap.sol`: Core swap and liquidity logic.
- `contracts/TokenA.sol`: ERC20 mock token for testing.
- `contracts/TokenB.sol`: ERC20 mock token for testing.

## 🧑‍🎓 Educational Context

This contract was developed for an academic Solidity course as a practice exercise in smart contract development, token interactions, and testnet deployment.

---

💡 Feel free to fork this repository for your own experimentation.
