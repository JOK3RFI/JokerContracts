// SPDX-License-Identifier: MIT
pragma solidity >=0.6.12;
import "@openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol";
import  "@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol";
import  "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import  "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";
import  "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
//import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import  "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";

import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";

interface INonfungiblePositionManager {
    struct MintParams {
        address token0;
        address token1;
        uint24 fee;
        int24 tickLower;
        int24 tickUpper;
        uint amount0Desired;
        uint amount1Desired;
        uint amount0Min;
        uint amount1Min;
        address recipient;
        uint deadline;
    }

    function mint(
        MintParams calldata params
    )
        external
        payable
        returns (uint tokenId, uint128 liquidity, uint amount0, uint amount1);

    struct IncreaseLiquidityParams {
        uint tokenId;
        uint amount0Desired;
        uint amount1Desired;
        uint amount0Min;
        uint amount1Min;
        uint deadline;
    }

    function increaseLiquidity(
        IncreaseLiquidityParams calldata params
    ) external payable returns (uint128 liquidity, uint amount0, uint amount1);

    struct DecreaseLiquidityParams {
        uint tokenId;
        uint128 liquidity;
        uint amount0Min;
        uint amount1Min;
        uint deadline;
    }

    function decreaseLiquidity(
        DecreaseLiquidityParams calldata params
    ) external payable returns (uint amount0, uint amount1);

      function positions(
    uint256 tokenId
  ) external view returns (uint96 nonce, address operator, address token0, address token1, uint24 fee, int24 tickLower, int24 tickUpper, uint128 liquidity, uint256 feeGrowthInside0LastX128, uint256 feeGrowthInside1LastX128, uint128 tokensOwed0, uint128 tokensOwed1);
    function balanceOf(address owner) external  view returns (uint256);
    function safeTransferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external ;
    function transfer(address recipient, uint256 amount) external ;
}
contract MasterChef is ContextUpgradeable,OwnableUpgradeable, ERC721Holder{
    using SafeMathUpgradeable for uint256;
    using AddressUpgradeable for address;
    // Info of each user.
    struct UserInfo {
        uint256 amount;     // How many LP tokens the user has provided.
        uint256 rewardDebt; // Reward debt. See explanation below.
        uint256 tokenId;  //What is the tokenID of the staked NFT
        //
        // We do some fancy math here. Basically, any point in time, the amount of BLACKs
        // entitled to a user but is pending to be distributed is:
        //
        //   pending reward = (user.amount * pool.accBlackPerShare) - user.rewardDebt
        //
        // Whenever a user deposits or withdraws LP tokens to a pool. Here's what happens:
        //   1. The pool's `accBlackPerShare` (and `lastRewardBlock`) gets updated.
        //   2. User receives the pending reward sent to his/her address.
        //   3. User's `amount` gets updated.
        //   4. User's `rewardDebt` gets updated.
    }

    // Info of each pool.
    struct PoolInfo {
        IERC20Upgradeable lpToken;           // Address of LP token contract.
        uint256 allocPoint;       // How many allocation points assigned to this pool. BLACKs to distribute per block.
        uint256 lastRewardBlock;  // Last block number that BLACKs distribution occurs.
        uint256 accBlackPerShare; // Accumulated BLACKs per share, times 1e18. See below.
    }

    // The BLACK TOKEN!
    IERC20Upgradeable public black;
   
    // Dev address.
    address public communitywallet;
    // BLACK tokens created per block.
    uint256 public blackPerBlock;
    // Bonus muliplier for early black makers.
    uint256 public BONUS_MULTIPLIER;

    //It is the LP common Creator NFT address
    INonfungiblePositionManager public positionManager = INonfungiblePositionManager(0x1238536071E1c677A632429e3655c799b22cDA52);
    //this token address are the paired Address of the LP token
    address public PairTokenAddress1;
    address public PairTokenAddress2;

    uint256 public totalLiquiidtySupply;


    // Info of each pool.
    PoolInfo public poolInfo;
    // Info of each user that stakes LP tokens.
    mapping  (address => UserInfo) public userInfo;
    // Total allocation points. Must be the sum of all allocation points in all pools.
    uint256 public totalAllocPoint = 0;
    // The block number when BLACK mining starts.
    uint256 public startBlock;
    //Todo maxlimit may be change
    uint256 public  maxStakeAmount;
    //Todo lockperiod may be change 
    // Once holder stakes maxStakeAmount, then he will not be able to stake any more coins for this time period
    uint256 public constant stakingLockPeriod = 2 weeks;
    //Todo withdrawLockupPeriod may be change 
    // Once holder stakes coins, he can unstake only after below time period
    uint256 public constant withdrawLockPeriod = 1 days;
    //Contract deployment time
    uint256 public startTime;
    //Date on which stakers start getting rewards 
    uint256 public rewardStartDate;
    //Todo maxrewardlimit fixed
    uint256 public minRewardBalanceToClaim;
    uint256  public  decimalMultiplier;  
    // latest Staking time +  withdrawLockPeriod,  to find when can I unstake
    mapping(address => uint256) public holderUnstakeRemainingTime;
    
    // once staking amount reaches maxStakeAmount, then it stores (current block time + stakingLockPeriod)
    mapping (address => uint256) private holderNextStakingAllowedTime;
    
    // Holds the running staking balance for each holder for staking lock, here balance of a user can reach to 
    // a maximum of maxStakeAmount
    mapping(address => uint256) private holdersRunningStakeBalance;

    bool private  feesAppliableStaking;
    
    event Deposit(address indexed user, uint256 amount);
    event Withdraw(address indexed user, uint256 amount);
    event EmergencyWithdraw(address indexed user,  uint256 amount);
    
    function initialize()  public initializer{
        OwnableUpgradeable.__Ownable_init(msg.sender);
        startBlock = block.number;
        startTime = block.timestamp;
        //TODO change rewardStartdate
        rewardStartDate = block.timestamp + 2 minutes;
        poolInfo.allocPoint=1000;
        poolInfo.lastRewardBlock= startBlock;
        poolInfo.accBlackPerShare= 0;
        totalAllocPoint = 1000;    
        decimalMultiplier = 1e18;
        minRewardBalanceToClaim = 100 * 1e9;
        maxStakeAmount = 1000000 * decimalMultiplier;   
        BONUS_MULTIPLIER = 1;       
    }

    function updateMultiplier(uint256 multiplierNumber) public onlyOwner {
        BONUS_MULTIPLIER = multiplierNumber;
    }
   
    // Return reward multiplier over the given _from to _to block.
    function getMultiplier(uint256 _from, uint256 _to) private view  returns (uint256) {
        //TODO change 1 days to double rewards period
        uint256 holderUnstakeTime = holderUnstakeRemainingTime[msg.sender];
        uint256 userStakingTime = withdrawLockPeriod + startTime + 1 days;
        if(holderUnstakeTime >= userStakingTime){
            return _to.sub(_from).mul(BONUS_MULTIPLIER);
        }
        else{
            return _to.sub(_from).mul(BONUS_MULTIPLIER * 2);
        }
            
   }

    // View function to see pending BLACKs on frontend.
    function pendingBlack(address _user) external view returns (uint256) {
        if(rewardStartDate <= block.timestamp ){
            PoolInfo storage pool = poolInfo;
            UserInfo storage user = userInfo[_user];
            uint256 accBlackPerShare = pool.accBlackPerShare;
            // uint256 totalStakedTokens = pool.lpToken.balanceOf(address(this));
            uint256 totalStakedTokens = totalLiquiidtySupply ;
            if (block.number > pool.lastRewardBlock && totalStakedTokens != 0) {
                uint256 multiplier = getMultiplier(pool.lastRewardBlock, block.number);
                uint256 blackReward = multiplier.mul(blackPerBlock).mul(pool.allocPoint).div(totalAllocPoint);
                accBlackPerShare = accBlackPerShare.add(blackReward.mul(decimalMultiplier).div(totalStakedTokens));
            }
            return user.amount.mul(accBlackPerShare).div(decimalMultiplier).sub(user.rewardDebt);
        }
        else
            return 0;
        
    }

    // Update reward variables of the given pool to be up-to-date.
    function updatePool() public {
        PoolInfo storage pool = poolInfo;
        if (block.number <= pool.lastRewardBlock) {
            return;
        }
        // uint256 lpSupply = pool.lpToken.balanceOf(address(this));
        uint256 lpSupply = totalLiquiidtySupply;
        if (lpSupply == 0) {
            pool.lastRewardBlock = block.number;
            return;
        }
        uint256 multiplier = getMultiplier(pool.lastRewardBlock, block.number);
        uint256 blackReward = multiplier.mul(blackPerBlock).mul(pool.allocPoint).div(totalAllocPoint);
        pool.accBlackPerShare = pool.accBlackPerShare.add(blackReward.mul(decimalMultiplier).div(lpSupply));
        pool.lastRewardBlock = block.number;
    }

    // Deposit LP tokens to MasterChef for BLACK allocation
    function deposit() public {
        require(!lock(msg.sender),"Sender is in locking state !");
        (uint256 tokenId,uint256 liquidityAmount) = getWalletIDFromContract(address(positionManager),msg.sender);
        uint256 _amount = liquidityAmount;
        require(_amount > 0, "Deposit amount cannot be less than zero !");
	    checkStakeLimit(_amount);
        PoolInfo storage pool = poolInfo;
        UserInfo storage user = userInfo[msg.sender];
        user.tokenId = tokenId;
        updatePool();
		uint256 stakedAmount = _amount; 
        // if(feesAppliableStaking)
        //   stakedAmount = _amount * 90 / 100;
        user.amount = user.amount.add(stakedAmount);
        holderUnstakeRemainingTime[msg.sender]= block.timestamp + withdrawLockPeriod;
        positionManager.transferFrom(msg.sender, address(this), tokenId );
        // bool flag = pool.lpToken.transferFrom(address(msg.sender), address(this), _amount);
        // require(flag, "Deposit unsuccessful, hence aborting the transaction !");
        user.rewardDebt = user.amount.mul(pool.accBlackPerShare).div(decimalMultiplier);
        totalLiquiidtySupply = totalLiquiidtySupply + liquidityAmount;
        emit Deposit(msg.sender, stakedAmount);
    }

    // Withdraw LP tokens from MasterChef.
    function withdraw() public {
        require(rewardStartDate <= block.timestamp,"Rewards allocation period yet to start !" );
        require (holderUnstakeRemainingTime[msg.sender] <= block.timestamp, "Holder is in locked state !");
        PoolInfo storage pool = poolInfo;
        UserInfo storage user = userInfo[msg.sender];
        uint256 _amount = user.amount;
        require(_amount > 0, "withdraw amount cannot be less than zero !");
        require(user.amount >= _amount, "Insufficient balance !");
        updatePool();
        uint256  currentUserBalance=user.amount;
        uint256 CurrentRewardBalance= user.rewardDebt;
        user.amount = user.amount.sub(_amount);
        user.rewardDebt = user.amount.mul(pool.accBlackPerShare).div(decimalMultiplier);
        uint256 pending = currentUserBalance.mul(pool.accBlackPerShare).div(decimalMultiplier).sub(CurrentRewardBalance);
        if(pending > 0) {
            bool flag = black.transferFrom(communitywallet,msg.sender, pending);
            require(flag, "Withdraw unsuccessful, during reward transfer, hence aborting the transaction !");
        }
        positionManager.transferFrom(address(this),msg.sender, user.tokenId );
        totalLiquiidtySupply = totalLiquiidtySupply - _amount;
        user.tokenId = 0;
        // bool flag =  pool.lpToken.transfer(msg.sender, _amount);
        // require(flag, "Withdraw unsuccessful, during staking amount transfer, hence aborting the transaction !");
        emit Withdraw(msg.sender, _amount);
    }


    // Withdraw without caring about rewards. EMERGENCY ONLY.
    function emergencyWithdraw() public {
        PoolInfo storage pool = poolInfo;
        UserInfo storage user = userInfo[msg.sender];
		uint256 currentBalance = user.amount;
		require(currentBalance > 0,"Insufficient balance !");
		user.amount = 0;
        user.rewardDebt = 0;
        positionManager.transferFrom(address(this),msg.sender, user.tokenId );
        totalLiquiidtySupply = totalLiquiidtySupply -  user.amount;
        user.tokenId = 0;
        // bool flag = pool.lpToken.transfer(address(msg.sender), currentBalance);
		// require(flag, "Transfer unsuccessful !");
        emit EmergencyWithdraw(msg.sender, user.amount);
        
    }

   //---------------------locking-------------------------//
    //checks the account is locked(true) or unlocked(false)
    function lock(address account) public view returns(bool){
        return holderNextStakingAllowedTime[account] > block.timestamp;
    }
	
	 // if sender is in frozen state,then this function returns epoch value remaining for the address for it to get unfrozen.
    function secondsLeft(address account) public view returns(uint256){
        if(lock(account)){
            return  ( holderNextStakingAllowedTime[account] - block.timestamp );
        }
         else
            return 0;
    }
 
    function checkStakeLimit(uint256 _stakeAmount) internal{	  
        require(_stakeAmount <= maxStakeAmount,"Cannot stake  more than permissible limit");
        uint256 balance =  holdersRunningStakeBalance[msg.sender]  + _stakeAmount;
        if(balance == maxStakeAmount) {
            holdersRunningStakeBalance[msg.sender] = 0;        
		    holderNextStakingAllowedTime[msg.sender] = block.timestamp + stakingLockPeriod;        
        }
        else{
            require(balance < maxStakeAmount,"cannot stake more than permissible limit");
            holdersRunningStakeBalance[msg.sender] = balance;       
        }
    }
    
    //----------------------endlocking-----//
   //------------------claim reward----------------------------//
   
   function claimReward() external {
        require(rewardStartDate <= block.timestamp,"Rewards not yet Started !" );
        PoolInfo storage pool = poolInfo;
        UserInfo storage user = userInfo[msg.sender];
        updatePool();
        uint256 CurrentRewardBalance= user.rewardDebt;
        user.rewardDebt = user.amount.mul(pool.accBlackPerShare).div(decimalMultiplier);
        uint256 pending = user.amount.mul(pool.accBlackPerShare).div(decimalMultiplier).sub(CurrentRewardBalance);
        require(pending >= minRewardBalanceToClaim,"reward Limit for claiming not reached"); 
        bool flag = black.transferFrom(communitywallet,msg.sender, pending);
        require(flag, "Claim reward unsuccessful, hence aborting the transaction !");
        emit Withdraw(msg.sender,pending);
   }
   
   
   //----------------reward end------------------------------------------------//

  //----------setter---------------------------------------------//

    function setBlackPerBlock(uint256 _blackPerBlock) public onlyOwner {
        blackPerBlock = _blackPerBlock;
    }
    
     function setTotalAllocationPoint(uint256 _totalAllocPoint) public onlyOwner {
        totalAllocPoint = _totalAllocPoint;
    }
    
     function setAllocationPoint(uint256 _allocPoint) public onlyOwner {
        poolInfo.allocPoint = _allocPoint;
    }
    
    function setRewardStartDate(uint256 _rewardStartdate) public onlyOwner {
       rewardStartDate = _rewardStartdate;
    }
    
    function setRewardAmount(uint256 _minRewardBalanceToClaim) public onlyOwner {
       minRewardBalanceToClaim = _minRewardBalanceToClaim;
    }
    
    function unLockWeeklyLock(address account) public onlyOwner{
        holderNextStakingAllowedTime[account] = block.timestamp;
    }
    
    function unLockStakeHolder(address account) public onlyOwner{
        holderUnstakeRemainingTime[account] = block.timestamp;
    }
    // type of toke that will be accepted for staking
    function setStakingTokenAddress(address  _token) public onlyOwner{       
        poolInfo.lpToken=IERC20Upgradeable(_token);
    }
	// this is token is the reward token
    function setBlackAddress(address  _black) public onlyOwner{
        black = IERC20Upgradeable( _black);
    }

    function setCommunityWallet(address  _communitywallet) public onlyOwner{
        communitywallet = _communitywallet;    
    }
    function setFeesAppliableStaking(bool  _feesAppliableStaking) public onlyOwner{
        feesAppliableStaking = _feesAppliableStaking;
        if(_feesAppliableStaking){
             decimalMultiplier = 1e9; 
             minRewardBalanceToClaim = 100 * decimalMultiplier ;
             maxStakeAmount = 1000000 * decimalMultiplier;
        }
                   
    }
    
    function getHoldersRunningStakeBalance() public view returns(uint256){
        require(!address(msg.sender).isContract() && msg.sender == tx.origin, "Sorry we do not accept contract!");
        uint256 stakeBalance = holdersRunningStakeBalance[msg.sender];
        return stakeBalance;
    } 

    function gettotalTokens(address wallet) public view returns (uint256){
        return positionManager.balanceOf(wallet);
    }

    function getWalletIDFromContract(address _contract, address wallet) public  view returns (uint256,uint256) {
        uint256 bal = gettotalTokens(wallet);
        uint256 ids;
        uint256 liquiidtyAmount;
        for (uint256 i = 0; i < bal; i++) {
            uint256 tokenId = IERC721Enumerable(_contract).tokenOfOwnerByIndex(wallet, i);
            (,, address token0, address token1, , , , uint128 liquidity, , , ,) = positionManager.positions(tokenId);
            if((token0 == PairTokenAddress1) && (token1 == PairTokenAddress2)){
                ids = tokenId;
                liquiidtyAmount = liquidity;
                break;
            }
        }
        return (ids,liquiidtyAmount);
    }

    function setTokenAddress(address _token1,address _token2) external onlyOwner{
        PairTokenAddress1 = _token1;
        PairTokenAddress2 = _token2;
    }
    
}