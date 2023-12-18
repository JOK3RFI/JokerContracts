// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract EcoReserveTreasury {
    address public owner;
    IERC20 public creditToken;
    address public MinterAddress;

    // Flag to track if the contract has been initialized
    bool public initialized;

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function");
        _;
    }
    modifier onlyMinterContract() {
        require(msg.sender == MinterAddress, "Only owner can call this function");
        _;
    }

    modifier notInitialized() {
        require(!initialized, "Contract already initialized");
        _;
    }

    function initialize(address _creditToken,address _MinterAddress) external notInitialized {
        owner = msg.sender;
        creditToken = IERC20(_creditToken);
        MinterAddress =_MinterAddress;
        initialized = true;
    }

    function setCreditToken(address _creditToken) external onlyOwner {
        // require(!initialized, "Contract already initialized");
        creditToken = IERC20(_creditToken);
    }
    function setMinterAddress(address _MinterAddress) external onlyOwner {
        // require(!initialized, "Contract already initialized");
        MinterAddress = _MinterAddress;
    }

    // function deposit(uint256 amount) external onlyOwner {
    //     require(initialized, "Contract not initialized");
    //     // Transfer CREDIT tokens to the treasury
    //     creditToken.transferFrom(msg.sender, address(this), amount);
    // }

    function withdraw(address recipient, uint256 amount) external onlyMinterContract {
        // require(initialized, "Contract not initialized");
        // Transfer CREDIT tokens from the treasury to the recipient
        creditToken.transfer(recipient, amount);
    }

    function getTreasuryBalance() external view returns (uint256) {
        // require(initialized, "Contract not initialized");
        // Get the balance of CREDIT tokens held in the treasury
        return creditToken.balanceOf(address(this));
    }
}
