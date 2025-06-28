# SimpleSwap - Automated Market Maker (AMM)

This project implements a simplified version of Uniswap V2 using Solidity, featuring core Automated Market Maker (AMM) functionalities including token swaps, liquidity pools, and LP token issuance.

## 📌 Overview

- Decentralized exchange mechanism based on the constant product formula `x * y = k`
- Add and remove liquidity from token pairs
- Swap between any two ERC-20 tokens
- Mint and burn LP tokens representing shares in the liquidity pool

## 🚀 Contracts

| Contract    | Address (Sepolia) |
|-------------|-------------------|
| SimpleSwap  | `0x7DcfaF18E983446aa59f723333Cfb355e91b354b` |
| Token A     | `0x3113f2E6732b8Cef92b0a5C50Ecb5Ae51b10F247` |
| Token B     | `0xFdb204e5b025AfD3c7a8E52007aC792f71509d28` |

## 🛠 Built With

- [Solidity 0.8.20](https://docs.soliditylang.org/)
- [OpenZeppelin Contracts](https://docs.openzeppelin.com/contracts)
- Remix IDE + MetaMask (for deployment and testing)

## ✅ Features

- `addLiquidity(tokenA, tokenB, amountADesired, amountBDesired, ...)`
- `removeLiquidity(tokenA, tokenB, liquidity, ...)`
- `swapExactTokensForTokens(amountIn, amountOutMin, path, ...)`
- `getPrice(tokenA, tokenB)`
- `getAmountOut(amountIn, reserveIn, reserveOut)`

## 📄 NatSpec Comments

All public and external functions in `SimpleSwap.sol` include [NatSpec documentation](https://docs.soliditylang.org/en/v0.8.20/natspec-format.html) to describe inputs, outputs, and behavior.

Example:
```solidity
/**
 * @notice Calculates output amount for a given input
 * @param amountIn Input token amount
 * @param reserveIn Reserve of input token
 * @param reserveOut Reserve of output token
 * @return amountOut Expected output amount
 */
function getAmountOut(...) external pure returns (uint256)
