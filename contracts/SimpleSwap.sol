// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";

/**
 * @title SimpleSwap - A Uniswap-like AMM implementation
 * @notice Enables token swaps and liquidity pools with LP tokens
 * @dev Uses constant product formula (x*y=k) without trading fees
 */
contract SimpleSwap is ERC20, ERC20Burnable {
    /// @dev Tracks reserves of tokenA for each token pair (tokenA => tokenB => reserve)
    mapping(address => mapping(address => uint256)) public reserveA;
    
    /// @dev Tracks reserves of tokenB for each token pair (tokenA => tokenB => reserve)
    mapping(address => mapping(address => uint256)) public reserveB;
    
    /// @notice Minimum LP tokens to mint (prevents pool manipulation)
    uint256 public constant MINIMUM_LIQUIDITY = 1000;

    /// @dev Initializes the LP token with name and symbol
    constructor() ERC20("Simple LP Token", "SLP") {}

    /**
     * @notice Adds liquidity to a token pair pool
     * @dev Mints LP tokens proportional to the liquidity added
     * @param tokenA Address of first token in the pair
     * @param tokenB Address of second token in the pair
     * @param amountADesired Max amount of tokenA to deposit
     * @param amountBDesired Max amount of tokenB to deposit
     * @param amountAMin Minimum acceptable amount of tokenA
     * @param amountBMin Minimum acceptable amount of tokenB
     * @param to Recipient address for LP tokens
     * @param deadline Transaction expiry timestamp
     * @return amountA Actual amount of tokenA deposited
     * @return amountB Actual amount of tokenB deposited
     * @return liquidity Amount of LP tokens minted
     */
    function addLiquidity(
        address tokenA,
        address tokenB,
        uint256 amountADesired,
        uint256 amountBDesired,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountA, uint256 amountB, uint256 liquidity) {
        require(block.timestamp <= deadline, "EXPIRED");
        require(tokenA != tokenB, "IDENTICAL_ADDRESSES");
        
        uint256 reserveA_ = reserveA[tokenA][tokenB];
        uint256 reserveB_ = reserveB[tokenA][tokenB];
        
        // For new pools, use desired amounts
        if (reserveA_ == 0 && reserveB_ == 0) {
            (amountA, amountB) = (amountADesired, amountBDesired);
            liquidity = sqrt(amountA * amountB);
            require(liquidity > MINIMUM_LIQUIDITY, "INSUFFICIENT_LIQUIDITY");
        } 
        // For existing pools, maintain ratio
        else {
            uint256 amountBOptimal = (amountADesired * reserveB_) / reserveA_;
            if (amountBOptimal <= amountBDesired) {
                require(amountBOptimal >= amountBMin, "INSUFFICIENT_B_AMOUNT");
                (amountA, amountB) = (amountADesired, amountBOptimal);
            } else {
                uint256 amountAOptimal = (amountBDesired * reserveA_) / reserveB_;
                require(amountAOptimal >= amountAMin, "INSUFFICIENT_A_AMOUNT");
                (amountA, amountB) = (amountAOptimal, amountBDesired);
            }
            liquidity = min(
                (amountA * totalSupply()) / reserveA_,
                (amountB * totalSupply()) / reserveB_
            );
        }
        
        // Transfer tokens and update reserves
        require(IERC20(tokenA).transferFrom(msg.sender, address(this), amountA), "TRANSFER_A_FAILED");
        require(IERC20(tokenB).transferFrom(msg.sender, address(this), amountB), "TRANSFER_B_FAILED");
        
        reserveA[tokenA][tokenB] += amountA;
        reserveB[tokenA][tokenB] += amountB;
        
        // Mint LP tokens
        _mint(to, liquidity);
    }

    /**
     * @notice Removes liquidity from a pool
     * @dev Burns LP tokens and returns proportional token amounts
     * @param tokenA Address of first token in the pair
     * @param tokenB Address of second token in the pair
     * @param liquidity Amount of LP tokens to burn
     * @param amountAMin Minimum acceptable amount of tokenA
     * @param amountBMin Minimum acceptable amount of tokenB
     * @param to Recipient address for withdrawn tokens
     * @param deadline Transaction expiry timestamp
     * @return amountA Amount of tokenA received
     * @return amountB Amount of tokenB received
     */
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountA, uint256 amountB) {
        require(block.timestamp <= deadline, "EXPIRED");
        require(balanceOf(msg.sender) >= liquidity, "INSUFFICIENT_LP");
        
        uint256 reserveA_ = reserveA[tokenA][tokenB];
        uint256 reserveB_ = reserveB[tokenA][tokenB];
        uint256 totalSupply_ = totalSupply();
        
        // Calculate proportional share of reserves
        amountA = (liquidity * reserveA_) / totalSupply_;
        amountB = (liquidity * reserveB_) / totalSupply_;
        
        require(amountA >= amountAMin && amountB >= amountBMin, "INSUFFICIENT_OUTPUT");
        
        // Burn LP tokens and update reserves
        _burn(msg.sender, liquidity);
        reserveA[tokenA][tokenB] -= amountA;
        reserveB[tokenA][tokenB] -= amountB;
        
        // Transfer tokens to recipient
        require(IERC20(tokenA).transfer(to, amountA), "TRANSFER_A_FAILED");
        require(IERC20(tokenB).transfer(to, amountB), "TRANSFER_B_FAILED");
    }

    /**
     * @notice Returns the current price ratio (tokenB/tokenA)
     * @dev Price is returned with 18 decimals precision
     * @param tokenA Address of base token
     * @param tokenB Address of quote token
     * @return price Price ratio scaled by 1e18
     */
    function getPrice(address tokenA, address tokenB) external view returns (uint256 price) {
        uint256 rA = reserveA[tokenA][tokenB];
        uint256 rB = reserveB[tokenA][tokenB];
        require(rA > 0 && rB > 0, "NO_RESERVES");
        return (rB * 1e18) / rA;
    }

    /**
     * @notice Calculates output amount for a given input
     * @dev Uses constant product formula (x*y=k)
     * @param amountIn Input token amount
     * @param reserveIn Reserve of input token
     * @param reserveOut Reserve of output token
     * @return amountOut Expected output amount
     */
    function getAmountOut(
        uint256 amountIn,
        uint256 reserveIn,
        uint256 reserveOut
    ) external pure returns (uint256) {
        require(reserveIn > 0 && reserveOut > 0, "INSUFFICIENT_RESERVES");
        return (amountIn * reserveOut) / (reserveIn + amountIn);
    }

    /**
     * @notice Performs a token swap
     * @dev Ensures output meets minimum requirement and updates reserves
     * @param amountIn Exact input amount
     * @param amountOutMin Minimum acceptable output amount
     * @param path Array with [inputToken, outputToken]
     * @param to Recipient address
     * @param deadline Transaction expiry timestamp
     * @return amounts Array containing [inputAmount, outputAmount]
     */
    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts) {
        require(path.length == 2, "INVALID_PATH");
        require(block.timestamp <= deadline, "EXPIRED");

        address tokenIn = path[0];
        address tokenOut = path[1];

        uint256 reserveIn = reserveA[tokenIn][tokenOut];
        uint256 reserveOut = reserveB[tokenIn][tokenOut];
        require(reserveIn > 0 && reserveOut > 0, "NO_POOL");

        // Transfer input tokens
        require(IERC20(tokenIn).transferFrom(msg.sender, address(this), amountIn), "TRANSFER_FAILED");

        // Calculate output
        uint256 amountOut = (amountIn * reserveOut) / (reserveIn + amountIn);
        require(amountOut >= amountOutMin, "INSUFFICIENT_OUTPUT");

        // Transfer output tokens
        require(IERC20(tokenOut).transfer(to, amountOut), "TRANSFER_FAILED");

        // Update reserves
        reserveA[tokenIn][tokenOut] += amountIn;
        reserveB[tokenIn][tokenOut] -= amountOut;

        amounts = new uint256[](2);
        amounts[0] = amountIn;
        amounts[1] = amountOut;
    }

    /// @dev Babylonian square root implementation
    function sqrt(uint256 y) internal pure returns (uint256 z) {
        if (y > 3) {
            z = y;
            uint256 x = y / 2 + 1;
            while (x < z) {
                z = x;
                x = (y / x + x) / 2;
            }
        } else if (y != 0) {
            z = 1;
        }
    }

    /// @dev Returns the smaller of two numbers
    function min(uint256 x, uint256 y) internal pure returns (uint256) {
        return x < y ? x : y;
    }
}
