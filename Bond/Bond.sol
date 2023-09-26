// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import '../../NewFraxProtocol/contracts/Frax/Frax.sol';

interface ITreasuryContract {
    function owner() external view returns (address);

    function dimeToken() external view returns (address);

    function blackToken() external view returns (address);

    function daiToken() external view returns (address);

    function bond() external view returns (address);

    function getDimeBalance(address user) external view returns (uint256);

    function getBlackBalance(address user) external view returns (uint256);

    function getDaiBalance(address user) external view returns (uint256);

    function mintDime(uint256 amount) external;

    function burnDime(uint256 amount) external;

    function BlackTransfer(uint256 amount, address _toSend) external;
}

contract BondContract {
    using SafeMath for uint256;
    address public owner;
    IERC20 public daiToken;
    IERC20 public dimeToken;
   
    FRAXStablecoin public  JUSD;
    ITreasuryContract  public  Treasury;
  

    uint256 public constant PRICE_PRECISION = 1e6; // Precision for price calculation
    uint8 public  chainlink_dai_usd_decimals ; // Number of decimals in Chainlink price feed

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
    uint256 public Max_threshold = 999999;
    // JUSD = FRAXStablecoin(0xeeaeCf2Adb6Ae4fDf9c0988c6349cE36a8f21423);
    

    constructor(
        address _daiTokenAddress,
        address _dimeTokenAddress,    
        uint256 _timeDuration,
        uint256 _epochHours
    ) {
        owner = msg.sender;
        daiToken = IERC20(_daiTokenAddress);
        dimeToken = IERC20(_dimeTokenAddress);
        JUSD = FRAXStablecoin(0xeeaeCf2Adb6Ae4fDf9c0988c6349cE36a8f21423);        
        timeDuration = _timeDuration;
        epochHours = _epochHours;

    }


    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function");
        _;
    }
    function setTreasuryAddress(address _treasury) external  onlyOwner {
      
       Treasury = ITreasuryContract(_treasury);
    }

   

    // Function to deposit DAI tokens and receive DIME tokens with a 20% discount
    function depositDAI(uint256 amount) external {
        require(lock == false,"Deposit is Locked");
        require(amount > 0, "Amount must be greater than zero");
        // Calculate the price of X DAI in  1 USD
        uint256 daiToUSDPrice = JUSD.eth_usd_price(); // Implement your DAI price function

        // Calculate the price of 1 ELEM in USD
        uint256 blackToUSDPrice = JUSD.black_price(); // Implement your DIME price function

        // Convert the amount from DAI to USD
        uint256 amountInUSD = amount.mul(daiToUSDPrice).div(1e6);

        // Convert the amount from USD to BLACK
        uint256 amountInBLACK = amountInUSD.mul(1e6).div(blackToUSDPrice);
        uint256 blackAmountd_9  = amountInBLACK.div(1e9);

        // Calculate the discounted amount of BLACK with a 20% discount
        uint256 discountedAmountInDIME = blackAmountd_9.mul(20).div(100);

        uint256 totalDIMEAllocated = blackAmountd_9 + discountedAmountInDIME;

       
       

        if(users[msg.sender].userRewards > 0){
            users[msg.sender].userRewards = users[msg.sender].userRewards + totalDIMEAllocated;
        }
        else{
            // Update the user's reward balance
            users[msg.sender].userRewards = totalDIMEAllocated ;
            users[msg.sender].depositTime = block.timestamp;
            users[msg.sender].claimeblePeriod = 5;
            
        }
        users[msg.sender].depositAmount = users[msg.sender].depositAmount + amount;
        
        // Transfer DAI tokens from the user to this contract
        require(daiToken.transferFrom(msg.sender, address(Treasury), amount), "DAI transfer failed");
        
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
            
        
            
            Treasury.BlackTransfer(claimAmount, msg.sender);
        }
    }


    function setEmergencyLock(bool _value) external  onlyOwner{
        lock = _value;
    }

    function rebase() public {
        require((lastEpoch+epochHours) <= block.timestamp,"Epoch is not reached");
        uint256 blackPrice = JUSD.black_price();
        uint256 blackPriceEquilibrium = blackPrice/10000;
        uint256 dimePrice = JUSD.fxs_price();
        uint256 dimeSupply = dimeToken.totalSupply();

        
        if(blackPriceEquilibrium > dimePrice){
            uint256 diff_in_price = blackPriceEquilibrium - dimePrice;
            // uint256 diff = Max_threshold - blackPrice;
            //New Supply(mint) = (Old Price * Old Supply) / New Price
            uint256 amountToMint = (dimePrice.mul(dimeSupply)).div((dimePrice.sub(diff_in_price)));
            Treasury.mintDime(amountToMint);
        }
        else if(blackPriceEquilibrium < dimePrice){
            uint256 diff_in_price = dimePrice - blackPriceEquilibrium;
            //Tokens to Burn= Current Supply×(Current Price−Target Price)/Target Price
            uint256 amountToBurn = (((dimePrice.add(diff_in_price)).sub(dimePrice)).mul(dimeSupply)).div(dimePrice.add(diff_in_price));
            Treasury.burnDime(amountToBurn);
        }
        else{
            //nothing to do
        }


        lastEpoch = block.timestamp;

    }

    function setMaxThreshold(uint256 _maxthreshold) public {
        Max_threshold = _maxthreshold;
    }

    function setepochHours(uint256 _lastEpoch) public {
        lastEpoch = _lastEpoch;
    }

    function setClaimDuration(uint256 _timeDuration) public {
        timeDuration = _timeDuration;
    }



  

    
}


   