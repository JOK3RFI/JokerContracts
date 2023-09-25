// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// Import ERC20 interfaces for DimeToken, BlackToken, and DaiToken
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";



interface IFxs {
  function DEFAULT_ADMIN_ROLE() external view returns(bytes32);
  function FRAXStablecoinAdd() external view returns(address);
  function FXS_DAO_min() external view returns(uint256);
  function allowance(address owner, address spender) external view returns(uint256);
  function approve(address spender, uint256 amount) external returns(bool);
  function balanceOf(address account) external view returns(uint256);
  function burn(uint256 amount) external;
  function burnFrom(address account, uint256 amount) external;
  function checkpoints(address, uint32) external view returns(uint32 fromBlock, uint96 votes);
  function decimals() external view returns(uint8);
  function decreaseAllowance(address spender, uint256 subtractedValue) external returns(bool);
  function genesis_supply() external view returns(uint256);
  function getCurrentVotes(address account) external view returns(uint96);
  function getPriorVotes(address account, uint256 blockNumber) external view returns(uint96);
  function getRoleAdmin(bytes32 role) external view returns(bytes32);
  function getRoleMember(bytes32 role, uint256 index) external view returns(address);
  function getRoleMemberCount(bytes32 role) external view returns(uint256);
  function grantRole(bytes32 role, address account) external;
  function hasRole(bytes32 role, address account) external view returns(bool);
  function increaseAllowance(address spender, uint256 addedValue) external returns(bool);
  function mint(address to, uint256 amount) external;
  function name() external view returns(string memory);
  function numCheckpoints(address) external view returns(uint32);
  function oracle_address() external view returns(address);
  function owner_address() external view returns(address);
  function pool_burn_from(address b_address, uint256 b_amount) external;
  function pool_mint(address m_address, uint256 m_amount) external;
  function renounceRole(bytes32 role, address account) external;
  function revokeRole(bytes32 role, address account) external;
  function setFRAXAddress(address frax_contract_address) external;
  function setFXSMinDAO(uint256 min_FXS) external;
  function setOracle(address new_oracle) external;
  function setOwner(address _owner_address) external;
  function setTimelock(address new_timelock) external;
  function symbol() external view returns(string memory);
  function timelock_address() external view returns(address);
  function toggleVotes() external;
  function totalSupply() external view returns(uint256);
  function trackingVotes() external view returns(bool);
  function transfer(address recipient, uint256 amount) external returns(bool);
  function transferFrom(address sender, address recipient, uint256 amount) external returns(bool);
}



contract TreasuryContract {
    address public owner;

    IFxs public dimeToken; // Address of the DimeToken contract
    IERC20 public blackToken; // Address of the BlackToken contract
    IERC20 public daiToken;   // Address of the DaiToken contract
    address public  bond; // Address of the Bond contract

    constructor(address _dimeToken, address _blackToken, address _daiToken) {
        owner = msg.sender;
        dimeToken = IFxs(_dimeToken);
        blackToken = IERC20(_blackToken);
        daiToken = IERC20(_daiToken);
        
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function");
        _;
    }

    modifier onlyBond() {
        require(msg.sender == bond, "Only Bond Contract can call this function");
        _;
    }

    function getDimeBalance(address user) public view returns (uint256) {
        return dimeToken.balanceOf(user);
    }

    function getBlackBalance(address user) public view returns (uint256) {
        return blackToken.balanceOf(user);
    }

    function getDaiBalance(address user) public view returns (uint256) {
        return daiToken.balanceOf(user);
    }

    function mintDime(uint256 amount) external  onlyBond {
        // Mint DimeToken and send it to the this contract
        dimeToken.mint(address(this), amount);
    }

    function burnDime(uint256 amount) external  onlyBond {
        // Mint DimeToken and send it to the this contract
        dimeToken.pool_burn_from(address(this), amount);
    }

    function BlackTransfer(uint256 amount,address _toSend) external  onlyBond {
        // Mint DimeToken and send it to the this contract
        blackToken.transfer(_toSend, amount);
    }
    
    function setBondAddress(address _bondAddress) external  onlyOwner {
      
        bond = _bondAddress;
    }

    //emergency withdrawl
    function withdrawBlack(address _owner,uint256 amount) external onlyOwner{
        blackToken.transfer(_owner, amount);
    }
    
}
