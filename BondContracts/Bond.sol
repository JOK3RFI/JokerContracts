// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC20/IERC20.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/interfaces/IERC20Metadata.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/interfaces/draft-IERC6093.sol";

import './ChainlinkOracle.sol';

interface ITreasuryContract {
    function owner() external view returns (address);

    function dimeToken() external view returns (address);

    function usdtToken() external view returns (address);

    function bond() external view returns (address);

    function getDimeBalance() external view returns (uint256);

    function getUsdtBalance() external view returns (uint256);

    function mintDime(uint256 amount) external;

    function DimeTransfer(uint256 amount, address _toSend) external;
}
abstract contract ERC20 is Context, IERC20, IERC20Metadata, IERC20Errors {
    mapping(address account => uint256) private _balances;

    mapping(address account => mapping(address spender => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the default value returned by this function, unless
     * it's overridden.
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual returns (uint8) {
        return 9;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - the caller must have a balance of at least `value`.
     */
    function transfer(address to, uint256 value) public virtual returns (bool) {
        address owner = _msgSender();
        _transfer(owner, to, value);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * NOTE: If `value` is the maximum `uint256`, the allowance is not updated on
     * `transferFrom`. This is semantically equivalent to an infinite approval.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 value) public virtual returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, value);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * NOTE: Does not update the allowance if the current allowance
     * is the maximum `uint256`.
     *
     * Requirements:
     *
     * - `from` and `to` cannot be the zero address.
     * - `from` must have a balance of at least `value`.
     * - the caller must have allowance for ``from``'s tokens of at least
     * `value`.
     */
    function transferFrom(address from, address to, uint256 value) public virtual returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, value);
        _transfer(from, to, value);
        return true;
    }

    /**
     * @dev Moves a `value` amount of tokens from `from` to `to`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * NOTE: This function is not virtual, {_update} should be overridden instead.
     */
    function _transfer(address from, address to, uint256 value) internal {
        if (from == address(0)) {
            revert ERC20InvalidSender(address(0));
        }
        if (to == address(0)) {
            revert ERC20InvalidReceiver(address(0));
        }
        _update(from, to, value);
    }

    /**
     * @dev Transfers a `value` amount of tokens from `from` to `to`, or alternatively mints (or burns) if `from`
     * (or `to`) is the zero address. All customizations to transfers, mints, and burns should be done by overriding
     * this function.
     *
     * Emits a {Transfer} event.
     */
    function _update(address from, address to, uint256 value) internal virtual {
        if (from == address(0)) {
            // Overflow check required: The rest of the code assumes that totalSupply never overflows
            _totalSupply += value;
        } else {
            uint256 fromBalance = _balances[from];
            if (fromBalance < value) {
                revert ERC20InsufficientBalance(from, fromBalance, value);
            }
            unchecked {
                // Overflow not possible: value <= fromBalance <= totalSupply.
                _balances[from] = fromBalance - value;
            }
        }

        if (to == address(0)) {
            unchecked {
                // Overflow not possible: value <= totalSupply or value <= fromBalance <= totalSupply.
                _totalSupply -= value;
            }
        } else {
            unchecked {
                // Overflow not possible: balance + value is at most totalSupply, which we know fits into a uint256.
                _balances[to] += value;
            }
        }

        emit Transfer(from, to, value);
    }

    /**
     * @dev Creates a `value` amount of tokens and assigns them to `account`, by transferring it from address(0).
     * Relies on the `_update` mechanism
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * NOTE: This function is not virtual, {_update} should be overridden instead.
     */
    function _mint(address account, uint256 value) internal {
        if (account == address(0)) {
            revert ERC20InvalidReceiver(address(0));
        }
        _update(address(0), account, value);
    }

    /**
     * @dev Destroys a `value` amount of tokens from `account`, lowering the total supply.
     * Relies on the `_update` mechanism.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * NOTE: This function is not virtual, {_update} should be overridden instead
     */
    function _burn(address account, uint256 value) internal {
        if (account == address(0)) {
            revert ERC20InvalidSender(address(0));
        }
        _update(account, address(0), value);
    }

    /**
     * @dev Sets `value` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     *
     * Overrides to this logic should be done to the variant with an additional `bool emitEvent` argument.
     */
    function _approve(address owner, address spender, uint256 value) internal {
        _approve(owner, spender, value, true);
    }

    /**
     * @dev Variant of {_approve} with an optional flag to enable or disable the {Approval} event.
     *
     * By default (when calling {_approve}) the flag is set to true. On the other hand, approval changes made by
     * `_spendAllowance` during the `transferFrom` operation set the flag to false. This saves gas by not emitting any
     * `Approval` event during `transferFrom` operations.
     *
     * Anyone who wishes to continue emitting `Approval` events on the`transferFrom` operation can force the flag to
     * true using the following override:
     * ```
     * function _approve(address owner, address spender, uint256 value, bool) internal virtual override {
     *     super._approve(owner, spender, value, true);
     * }
     * ```
     *
     * Requirements are the same as {_approve}.
     */
    function _approve(address owner, address spender, uint256 value, bool emitEvent) internal virtual {
        if (owner == address(0)) {
            revert ERC20InvalidApprover(address(0));
        }
        if (spender == address(0)) {
            revert ERC20InvalidSpender(address(0));
        }
        _allowances[owner][spender] = value;
        if (emitEvent) {
            emit Approval(owner, spender, value);
        }
    }

    /**
     * @dev Updates `owner` s allowance for `spender` based on spent `value`.
     *
     * Does not update the allowance value in case of infinite allowance.
     * Revert if not enough allowance is available.
     *
     * Does not emit an {Approval} event.
     */
    function _spendAllowance(address owner, address spender, uint256 value) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            if (currentAllowance < value) {
                revert ERC20InsufficientAllowance(spender, currentAllowance, value);
            }
            unchecked {
                _approve(owner, spender, currentAllowance - value, false);
            }
        }
    }
}
contract Bond is ERC20, Ownable {
    using SafeMath for uint256;
    IERC20 public JokerToken;
    IERC20 public UsdtToken;
    ITreasuryContract  public  Treasury;

    PriceConsumerV3 public dimeOracle;
    PriceConsumerV3 public jokerOracle;
    PriceConsumerV3 public usdtOracle;

    uint256 pricePrecision = 10 ** 9;
    address public revenueWallet;
    
    

    // Define a struct to store user information
    struct UserInfo {
        uint256 userRewards;
        uint256 depositTime;
        uint256 depositAmount;
        uint256 claimedAmount;
        uint256 claimeblePeriod;
        uint256 claimedTime;
    }

    // Mapping from user address to user information
    mapping(address => UserInfo) public users;
    uint256 public timeDuration;
    uint256 public term = 5;
    bool public lock = false;
    uint256 public lastEpoch;
    uint256 public epochHours;
    address public allowedAddress;


    // Constructor
    constructor(address initialOwner,PriceConsumerV3 _dimeOracle,PriceConsumerV3 _jokerOracle,PriceConsumerV3 _usdtOracle, address _revenueWallet,IERC20 _usdt,IERC20 _jokerToken) ERC20("DIME", "DIME") Ownable(initialOwner) {
        dimeOracle = _dimeOracle;
        jokerOracle = _jokerOracle;
        usdtOracle = _usdtOracle;
        revenueWallet = _revenueWallet;
        UsdtToken = _usdt;
        JokerToken = _jokerToken;
        


    }

    function getAllPrice() public  view returns (uint256,uint256,uint256) {
        int dimePrice = dimeOracle.getLatestPrice();
        // int jokerPrice = jokerOracle.getLatestPrice();//for now testing its to be commented
        int jokerPrice = 10 * (10 ** 8);
        int usdtPrice = usdtOracle.getLatestPrice();

        // Check if the price is non-negative before casting
        require(dimePrice >= 0, "Negative price not supported");

        // Convert int to uint256
        uint256 tokenPrice = uint256(dimePrice);

        return (tokenPrice,uint256(jokerPrice),uint256(usdtPrice));
    }

    modifier onlyAllowedAddress() {
            require(msg.sender == allowedAddress, "Only allowedAddress can call this function");
            _;
    }
    // Mint new tokens
    function mint(address to, uint256 amount) external onlyAllowedAddress {
        _mint(to, amount);
    }

    // // Burn tokens
    // function burn(uint256 amount) external {
    //     _burn(msg.sender, amount);
    // }

    // function totalSupply() public  view returns (uint256){
    //     return  totalSupply();
    // }

    function setallowedAddress(address _allowedAddress) external  onlyOwner {
      
       allowedAddress = _allowedAddress;
    }

    function setTreasuryAddress(address _treasury) external  onlyOwner {
      
       Treasury = ITreasuryContract(_treasury);
    }

    function setRevenueAddress(address _revenueWallet) external  onlyOwner {
      
      revenueWallet = _revenueWallet;
    }

    function setOracleAddress(PriceConsumerV3 _dimeOracle,PriceConsumerV3 _jokerOracle,PriceConsumerV3 _usdtOracle) external  onlyOwner {
       dimeOracle = _dimeOracle;
        jokerOracle = _jokerOracle;
        usdtOracle = _usdtOracle;
    }

     // Function to deposit DAI tokens and receive DIME tokens with a 20% discount
    function participateInBond(uint256 usdtAmount,uint256 jokerAmount) external {
        require(lock == false,"Deposit is Locked");
        require(usdtAmount > 0, "USDT amount must be greater than zero");
        require(jokerAmount > 0, "JOKER amount must be greater than zero");
        // Calculate the price of 1 USDT, 1JOKER, 1 DIME in USD
        (uint256 dimePrice, uint256 jokerPrice, uint256 usdtPrice) = getAllPrice();
        // Calculate equivalent USD values for USDT and JOKER
        uint256 usdtValue = usdtAmount * usdtPrice;
        uint256 jokerValue = jokerAmount * jokerPrice;

        // Calculate total USD value
        uint256 totalValueInUSD = usdtValue + jokerValue;

        require(usdtValue >= (totalValueInUSD*89).div(100),"USDT needs to be 90%");
        require(jokerValue >= (totalValueInUSD*9).div(100),"JOKER needs to be 10%");
        
        // Calculate the amount of DIME tokens to mint
        uint256 dimeToMint = totalValueInUSD / dimePrice;

        //calculate the treasury Value
        uint256 treasuryValue = (Treasury.getDimeBalance() * dimePrice).add(Treasury.getUsdtBalance() * usdtPrice); //need to add the function in treasury contract

        //treasuryValueOfDime= treasuryTotalAsset/totalSupplyOfDime
        uint256 treasuryTotalValue = (treasuryValue ).div(totalSupply());

        //discountRate=((marketPrice×PRECISION−treasuryValueOfDime)*100)/marketPrice×PRECISION
        uint256 discountRate = ((difference((dimePrice),treasuryTotalValue)).mul(100)).div(dimePrice);

        //Bond value = Bondvalue * discountRate/10000
        uint256 totalDIMEAllocated = (dimeToMint.mul(discountRate)).div(10000);       
       

        if(users[msg.sender].userRewards > 0){
            users[msg.sender].userRewards = users[msg.sender].userRewards + totalDIMEAllocated;
        }
        else{
            // Update the user's reward balance
            users[msg.sender].userRewards = totalDIMEAllocated ;
            users[msg.sender].depositTime = block.timestamp;
            users[msg.sender].claimeblePeriod = 5;
            
        }
        users[msg.sender].depositAmount = users[msg.sender].depositAmount + (totalValueInUSD.div(pricePrecision));
        uint256 revenueJoker = (jokerAmount*3)/100;
        uint256 remainJoker = jokerAmount - revenueJoker;
        JokerToken.transferFrom(msg.sender, address(revenueWallet), revenueJoker);
        //Burning the remaining token
        JokerToken.transferFrom(msg.sender, address(0x0000000000000000000000000000000000000000), remainJoker);
        uint256 usdtamount = usdtAmount;
        // Transfer USDT tokens from the user to this contract
        require(UsdtToken.transferFrom(msg.sender, address(Treasury), usdtamount), "USDT transfer failed");

        
    }

    // Assuming PRECISION is defined as: uint256 constant PRECISION = 1e18;

    function difference(uint256 a, uint256 b) public pure returns (uint256) {
        // Calculate the difference: a - b
        if (a > b) {
            return a - b;
        } else {
            // Handle  if a is less than b
            return (b - a);
        }
    }

     function claim() external {
        require(lock == false,"Claim is Locked");
        require((block.timestamp).sub(users[msg.sender].depositTime) > timeDuration,"Wait for the time duration");
        require(users[msg.sender].claimeblePeriod <= 5,"You are not allowed to claim");
        uint256 diffTime;
        if(users[msg.sender].claimedTime > 0){
            diffTime = (block.timestamp).sub(users[msg.sender].claimedTime);
            require((block.timestamp).sub(users[msg.sender].claimedTime) > timeDuration,"Wait for the time duration");
        }
        else{
            diffTime = (block.timestamp).sub(users[msg.sender].depositTime);
        }
        if(diffTime > timeDuration){
            uint256 timeCount = diffTime.div(timeDuration);
            if(timeCount > 5){
                timeCount = 5;
            }
            uint256 claimValue = (users[msg.sender].userRewards).div(users[msg.sender].claimeblePeriod);

            uint256 claimAmount = claimValue.mul(timeCount);
            if(timeCount == 5){
                users[msg.sender].userRewards = 0;
                users[msg.sender].claimeblePeriod = 0;
                users[msg.sender].claimedTime = 0;
                users[msg.sender].claimedAmount = 0;
            }
            else{
                users[msg.sender].userRewards = (users[msg.sender].userRewards).sub(claimAmount);
                users[msg.sender].claimeblePeriod = (users[msg.sender].claimeblePeriod).sub(timeCount);
                users[msg.sender].claimedTime = block.timestamp;
                users[msg.sender].claimedAmount = users[msg.sender].claimedAmount + claimAmount ;
            }      
            
            Treasury.DimeTransfer(claimAmount, msg.sender);
        }
    }

    function setEmergencyLock(bool _value) external  onlyOwner{
        lock = _value;
    }

    function rebase() public {
        require((lastEpoch+epochHours) <= block.timestamp,"Epoch is not reached");

        (uint256 dimePrice, uint256 jokerPrice, ) = getAllPrice();

        

        if(dimePrice > (jokerPrice.div(10))){
            //Rebase % = (((Oracle Rate - Price Target) / Price Target) * 100) / 10
            uint256 rebasePercentage = (((dimePrice.sub(jokerPrice.div(10))).div(jokerPrice.div(10))).mul(100)).div(10);
            uint256 amountToMint = (totalSupply().mul(rebasePercentage)).div(100);
            Treasury.mintDime(amountToMint);
        }
        lastEpoch = block.timestamp;

    }


    function setepochHours(uint256 _epochHours) public {
        epochHours = _epochHours;
    }

    function setClaimDuration(uint256 _timeDuration) public {
        timeDuration = _timeDuration;
    }

}
