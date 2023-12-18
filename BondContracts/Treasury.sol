// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// Import ERC20 interfaces for DimeToken, and UsdtToken
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

import './ChainlinkOracle.sol';
import './BondNew.sol';

contract TreasuryContract  {

    DataConsumerV3 public price;
    address public owner;

    Bond public dimeToken; // Address of the DimeToken contract
    IERC20 public usdtToken;   // Address of the DaiToken contract

    constructor(address _dimeToken,  address _usdtToken) {
        owner = msg.sender;
        dimeToken = Bond(_dimeToken);
        usdtToken = IERC20(_usdtToken);
        
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function");
        _;
    }

    modifier onlyBond() {
        require(msg.sender == address(dimeToken), "Only Bond Contract can call this function");
        _;
    }

    function getDimeBalance() public view returns (uint256) {
        return dimeToken.balanceOf(address(this));
    }

    function getUsdtBalance() public view returns (uint256) {
        return usdtToken.balanceOf(address(this));
    }

    function mintDime(uint256 amount) external  onlyBond {
        // Mint DimeToken and send it to the this contract
        dimeToken.mint(address(this), amount);
    }

    

    function DimeTransfer(uint256 amount,address _toSend) external  onlyBond 
    {
        // Mint DimeToken and send it to the this contract
        dimeToken.transfer(_toSend, amount);
    }
    
    function setBondAddress(Bond _dimeToken) external  onlyOwner {      
        dimeToken = _dimeToken;
    }
    

    //emergency withdraw

     function withdrawUSDT(address withdrawAddress,uint256 amount) external  onlyOwner {      
        usdtToken.transfer(withdrawAddress, amount);
    }

    
    
}
