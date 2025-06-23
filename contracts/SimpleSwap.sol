// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address to, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
}

/**
 * @dev Implementation of the {IERC20} interface.
 */
contract ERC20 is IERC20 {
    string public name;
    string public symbol;
    uint8 public immutable decimals = 18;
    uint256 public override totalSupply;

    mapping(address => uint256) public override balanceOf;
    mapping(address => mapping(address => uint256)) public override allowance;

    constructor(string memory name_, string memory symbol_) {
        name = name_;
        symbol = symbol_;
    }

    function transfer(address to, uint256 amount) public override returns (bool) {
        require(balanceOf[msg.sender] >= amount, "ERC20: transfer amount exceeds balance");
        balanceOf[msg.sender] -= amount;
        balanceOf[to] += amount;
        emit Transfer(msg.sender, to, amount);
        return true;
    }

    function approve(address spender, uint256 amount) public override returns (bool) {
        allowance[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    function transferFrom(address from, address to, uint256 amount) public override returns (bool) {
        require(balanceOf[from] >= amount, "ERC20: transfer amount exceeds balance");
        require(allowance[from][msg.sender] >= amount, "ERC20: insufficient allowance");

        allowance[from][msg.sender] -= amount;
        balanceOf[from] -= amount;
        balanceOf[to] += amount;

        emit Transfer(from, to, amount);
        return true;
    }

    function _mint(address to, uint256 amount) internal {
        totalSupply += amount;
        balanceOf[to] += amount;
        emit Transfer(address(0), to, amount);
    }

    function _burn(address from, uint256 amount) internal {
        require(balanceOf[from] >= amount, "ERC20: burn amount exceeds balance");
        balanceOf[from] -= amount;
        totalSupply -= amount;
        emit Transfer(from, address(0), amount);
    }

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

/**
 * @title SimpleSwap
 * @notice A decentralized exchange contract with liquidity provision and token swapping.
 */
contract SimpleSwap is ERC20 {
    mapping(address => mapping(address => uint256)) public reserveA;
    mapping(address => mapping(address => uint256)) public reserveB;

    uint256 public constant MINIMUM_LIQUIDITY = 1000;

    constructor() ERC20("Simple LP Token", "SLP") {}

    /// @notice Adds liquidity to the pool
    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidityTokens) {
        require(block.timestamp <= deadline, "Transaction expired");
        require(tokenA != tokenB, "Identical tokens");

        uint reserveA_ = reserveA[tokenA][tokenB];
        uint reserveB_ = reserveB[tokenA][tokenB];

        if (reserveA_ == 0 && reserveB_ == 0) {
            amountA = amountADesired;
            amountB = amountBDesired;
            liquidityTokens = sqrt(amountA * amountB);
            require(liquidityTokens >= MINIMUM_LIQUIDITY, "Insufficient initial liquidity");
        } else {
            uint totalLiq = totalSupply;

            uint amountBOptimal = (amountADesired * reserveB_) / reserveA_;
            if (amountBOptimal <= amountBDesired) {
                require(amountBOptimal >= amountBMin, "Insufficient B amount");
                amountA = amountADesired;
                amountB = amountBOptimal;
            } else {
                uint amountAOptimal = (amountBDesired * reserveA_) / reserveB_;
                require(amountAOptimal >= amountAMin, "Insufficient A amount");
                amountA = amountAOptimal;
                amountB = amountBDesired;
            }

            uint liq1 = (amountA * totalLiq) / reserveA_;
            uint liq2 = (amountB * totalLiq) / reserveB_;
            liquidityTokens = min(liq1, liq2);
        }

        require(IERC20(tokenA).transferFrom(msg.sender, address(this), amountA), "Transfer A failed");
        require(IERC20(tokenB).transferFrom(msg.sender, address(this), amountB), "Transfer B failed");

        reserveA[tokenA][tokenB] += amountA;
        reserveB[tokenA][tokenB] += amountB;

        _mint(to, liquidityTokens);
    }

    /// @notice Removes liquidity and burns LP tokens
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidityAmount,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB) {
        require(block.timestamp <= deadline, "Transaction expired");
        require(tokenA != tokenB, "Identical tokens");
        require(balanceOf[msg.sender] >= liquidityAmount, "Not enough LP tokens");

        uint totalLiq = totalSupply;

        amountA = (liquidityAmount * reserveA[tokenA][tokenB]) / totalLiq;
        amountB = (liquidityAmount * reserveB[tokenA][tokenB]) / totalLiq;

        require(amountA >= amountAMin, "Amount A too low");
        require(amountB >= amountBMin, "Amount B too low");

        _burn(msg.sender, liquidityAmount);

        reserveA[tokenA][tokenB] -= amountA;
        reserveB[tokenA][tokenB] -= amountB;

        require(IERC20(tokenA).transfer(to, amountA), "Transfer A failed");
        require(IERC20(tokenB).transfer(to, amountB), "Transfer B failed");
    }

    /// @notice Swaps exact amount of tokens for tokens from a pool
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts) {
        require(path.length == 2, "Only direct swaps supported");
        require(block.timestamp <= deadline, "Transaction expired");

        address tokenIn = path[0];
        address tokenOut = path[1];

        require(reserveA[tokenIn][tokenOut] > 0 && reserveB[tokenIn][tokenOut] > 0, "Pool doesn't exist");

        IERC20(tokenIn).transferFrom(msg.sender, address(this), amountIn);

        uint reserveIn = reserveA[tokenIn][tokenOut];
        uint reserveOut = reserveB[tokenIn][tokenOut];

        uint amountOut = (amountIn * reserveOut) / (reserveIn + amountIn);
        require(amountOut >= amountOutMin, "Insufficient output amount");

        IERC20(tokenOut).transfer(to, amountOut);

        reserveA[tokenIn][tokenOut] += amountIn;
        reserveB[tokenIn][tokenOut] -= amountOut;

        amounts = new uint[](2);
        amounts[0] = amountIn;
        amounts[1] = amountOut;
    }

    function sqrt(uint y) internal pure returns (uint z) {
        if (y > 3) {
            z = y;
            uint x = y / 2 + 1;
            while (x < z) {
                z = x;
                x = (y / x + x) / 2;
            }
        } else if (y != 0) {
            z = 1;
        }
    }

    function min(uint x, uint y) internal pure returns (uint) {
        return x < y ? x : y;
    }
}