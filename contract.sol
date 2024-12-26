// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// Interface for interacting with ERC-20 tokens
interface IERC20 {
    function transfer(address recipient, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
}

contract SimpleSwap {

    // Declare the token A and token B (ERC-20)
    IERC20 public tokenA;
    IERC20 public tokenB;

    // Price ratio of Token A to Token B (example: 1 Token A = 2 Token B)
    uint256 public swapRate;  // e.g., 2 = 1 Token A = 2 Token B

    // Liquidity pool (amount of tokens A and B available for swaps)
    uint256 public liquidityA;
    uint256 public liquidityB;

    // Owner of the contract who can add liquidity
    address public owner;

    // Events
    event TokensSwapped(address indexed user, uint256 amountIn, uint256 amountOut);
    event LiquidityAdded(address indexed user, uint256 amountA, uint256 amountB);

    modifier onlyOwner() {
        require(msg.sender == owner, "Only the owner can perform this action.");
        _;
    }

    // Constructor to initialize the contract with the two tokens and the initial swap rate
    constructor(address _tokenA, address _tokenB, uint256 _swapRate) {
        tokenA = IERC20(_tokenA);
        tokenB = IERC20(_tokenB);
        swapRate = _swapRate;  // Set the swap rate (e.g., 1 A = 2 B)
        owner = msg.sender;  // The owner is the one who deploys the contract
    }

    // Function 1: Swap Token A for Token B
    function swapTokens(uint256 amountIn) external {
        require(amountIn > 0, "Amount must be greater than 0.");
        
        // Calculate the amount of Token B to send back based on the swap rate
        uint256 amountOut = amountIn * swapRate;

        // Ensure there is enough liquidity in the pool
        require(liquidityA >= amountIn, "Not enough Token A liquidity.");
        require(liquidityB >= amountOut, "Not enough Token B liquidity.");

        // Transfer Token A from the user to the contract
        bool successA = tokenA.transferFrom(msg.sender, address(this), amountIn);
        require(successA, "Token A transfer failed.");

        // Transfer Token B from the contract to the user
        bool successB = tokenB.transfer(msg.sender, amountOut);
        require(successB, "Token B transfer failed.");

        // Update the liquidity pool
        liquidityA -= amountIn;
        liquidityB -= amountOut;

        // Emit event for the swap
        emit TokensSwapped(msg.sender, amountIn, amountOut);
    }

    // Function 2: Add liquidity to the pool
    function addLiquidity(uint256 amountA, uint256 amountB) external onlyOwner {
        require(amountA > 0 && amountB > 0, "Amounts must be greater than 0.");

        // Transfer the tokens from the owner to the contract
        bool successA = tokenA.transferFrom(msg.sender, address(this), amountA);
        require(successA, "Token A transfer failed.");

        bool successB = tokenB.transferFrom(msg.sender, address(this), amountB);
        require(successB, "Token B transfer failed.");

        // Increase the liquidity pool
        liquidityA += amountA;
        liquidityB += amountB;

        // Emit event for adding liquidity
        emit LiquidityAdded(msg.sender, amountA, amountB);
    }

    // Function to check liquidity status
    function getLiquidity() external view returns (uint256, uint256) {
        return (liquidityA, liquidityB);
    }

    // Function to change the swap rate (only by owner)
    function setSwapRate(uint256 newRate) external onlyOwner {
        swapRate = newRate;
    }
}
