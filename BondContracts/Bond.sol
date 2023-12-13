// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


import '../../NewFraxProtocol/contracts/Frax/Pools/FraxPoolV3.sol';

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
    FraxPoolV3 public  JUSDPool;
    IERC20 public blackToken;
    ITreasuryContract  public  Treasury;
    AggregatorV3Interface public priceFeedDAIUSD; // Chainlink price feed for BLACK/USD

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
    

    constructor(
        address _daiTokenAddress,
        address _dimeTokenAddress,
        address _priceFeedDAIUSD,
        address _JUSDPool,        
        uint256 _timeDuration,
        uint256 _epochHours,
        address _blackToken
    ) {
        owner = msg.sender;
        daiToken = IERC20(_daiTokenAddress);
        dimeToken = IERC20(_dimeTokenAddress);
        priceFeedDAIUSD = AggregatorV3Interface(_priceFeedDAIUSD);
        JUSDPool = FraxPoolV3(_JUSDPool);
        chainlink_dai_usd_decimals = priceFeedDAIUSD.decimals();        
        timeDuration = _timeDuration;
        epochHours = _epochHours;
        blackToken = IERC20(_blackToken);
    }


    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function");
        _;
    }
    function setTreasuryAddress(address _treasury) external  onlyOwner {
      
       Treasury = ITreasuryContract(_treasury);
    }

    // Function to get the price of the BLACK token in USD
    function getDAIPrice() public view returns (uint256) {
        (uint80 roundID, int price, , uint256 updatedAt, uint80 answeredInRound) = priceFeedDAIUSD.latestRoundData();
        require(price >= 0 && updatedAt != 0 && answeredInRound >= roundID, "Invalid chainlink price");

        return uint256(price).mul(PRICE_PRECISION).div(10**uint256(chainlink_dai_usd_decimals));
    }

    // Function to deposit DAI tokens and receive DIME tokens with a 20% discount
    function depositDAI(uint256 amount) external {
        require(lock == false,"Deposit is Locked");
        require(amount > 0, "Amount must be greater than zero");
        // Calculate the price of 1 DAI in USD
        uint256 daiToUSDPrice = getDAIPrice(); // Implement your DAI price function

        // Calculate the price of 1 ELEM in USD
        uint256 dimeToUSDPrice = JUSDPool.getFXSPrice(); // Implement your DIME price function

        // Convert the amount from DAI to USD
        uint256 amountInUSD = amount.mul(daiToUSDPrice).div(1e18);

        // Convert the amount from USD to DIME
        uint256 amountInDIME = amountInUSD.mul(1e18).div(dimeToUSDPrice);

        // Calculate the discounted amount of DIME with a 20% discount
        uint256 discountedAmountInDIME = amountInDIME.mul(20).div(100);

        uint256 totalDIMEAllocated = amountInDIME + discountedAmountInDIME;

       
       

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
        blackToken.transferFrom(msg.sender, address(Treasury), amount);
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
                users[msg.sender].claimedAmount = users[msg.sender].claimedAmount + claimAmount.div(1e9) ;
            }
            
        
            
            Treasury.BlackTransfer(claimAmount.div(1e9), msg.sender);
        }
    }


    function setEmergencyLock(bool _value) external  onlyOwner{
        lock = _value;
    }

    function rebase() public {
        require((lastEpoch+epochHours) <= block.timestamp,"Epoch is not reached");
        uint256 blackPrice = JUSDPool.getBLACKPrice();
        uint256 dimekPrice = JUSDPool.getFXSPrice();
        uint256 dimeSupply = dimeToken.totalSupply();
        // uint256 Max_threshold = 999999;
        if(blackPrice < Max_threshold){
            uint256 diff = Max_threshold - blackPrice;
            //New Supply(mint) = (Old Price * Old Supply) / New Price
            uint256 amountToMint = (dimekPrice.mul(dimeSupply)).div((dimekPrice.sub(diff)));
            Treasury.mintDime(amountToMint);
        }
        else if(blackPrice > Max_threshold){
            uint256 diff = blackPrice - Max_threshold;
            //Tokens to Burn= Current Supply×(Current Price−Target Price)/Target Price
            uint256 amountToBurn = (((dimekPrice.add(diff)).sub(dimekPrice)).mul(dimeSupply)).div(dimekPrice.add(diff));
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


   