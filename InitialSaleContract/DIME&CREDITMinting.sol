// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./ChainlinkOracle.sol";

interface Itreasury {
     function withdraw(address recipient, uint256 amount) external;
}
interface IERC721Receiver {
    function onERC721Received(
        address operator,
        address from,
        uint tokenId,
        bytes calldata data
    ) external returns (bytes4);
}
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


}
contract TokenDeposit{
    address public owner;
    Itreasury public treasury;
    IERC20 public usdtToken;
    IERC20 public jokerToken;
    IERC20 public creditToken;
    bool private initialized;
    uint public nfttokenId;
    DataConsumerV3 public creditOracle;
    DataConsumerV3 public jokerOracle;
    DataConsumerV3 public usdtOracle;
    INonfungiblePositionManager public positionManager = INonfungiblePositionManager(0x1238536071E1c677A632429e3655c799b22cDA52);
    modifier notInitialized() {
        require(!initialized, "Already initialized");
        _;
    }
    function initialize(
        address _usdtToken,
        address _jokerToken,
        address _creditToken,
        Itreasury _treasury,
        uint _tokenid
    ) external notInitialized  {
        owner = msg.sender;
        usdtToken = IERC20(_usdtToken);
        jokerToken = IERC20(_jokerToken);
        creditToken = IERC20(_creditToken);
        treasury = _treasury;
        initialized = true;
        nfttokenId=_tokenid;
    }
    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function");
        _;
    }
    function getAllPrice() public  view returns (uint256,uint256,uint256) {
        int creditPrice = creditOracle.getChainlinkDataFeedLatestAnswer();
        // int jokerPrice = jokerOracle.getChainlinkDataFeedLatestAnswer();//for now testing its to be commented
        int jokerPrice = 10 * (10 ** 8);
        int usdtPrice = usdtOracle.getChainlinkDataFeedLatestAnswer();

        // Check if the price is non-negative before casting
        require(creditPrice >= 0, "Negative price not supported");

        // Convert int to uint256
        uint256 tokenPrice = uint256(creditPrice);

        return (tokenPrice,uint256(jokerPrice),uint256(usdtPrice));
    }
    function depositAndAddLiquidity(uint256 usdtAmount, uint256 jokerAmount) external {
        require(usdtAmount > 0 && jokerAmount > 0, "Amounts must be greater than zero");
        (uint256 creditPrice, uint256 jokerPrice, uint256 usdtPrice) = getAllPrice();
        // Ensure the correct deposit ratio 
              //     5 *10                          //50  * 1
        require(jokerAmount * jokerPrice <= usdtAmount * usdtPrice, "Deposit ratio must be 10 JOKER = 1 USDC");

       
        
        // Mint equal amount of CREDIT tokens
        
        uint256 usdtvalue=usdtAmount *usdtPrice;
        uint256 jokervalue=jokerAmount *jokerPrice;
        uint256 TotalvalueInusd=usdtvalue + jokervalue;
        //Deduction fee for reserver
        uint256 afterFeeDeduction=TotalvalueInusd-(TotalvalueInusd * 10)/100;  
        // usdtToken.approve(address(treasury), usdtvalue);
        // jokerToken.approve(address(treasury), jokervalue);
        
         // Transfer tokens from the user to this contract
        usdtToken.transferFrom(msg.sender, address(this), usdtAmount - ((usdtAmount * 5)/100));
        jokerToken.transferFrom(msg.sender, address(this), jokerAmount - ((jokerAmount * 5)/100));


        usdtToken.transferFrom(msg.sender,address(treasury),((usdtAmount * 5)/100));
        jokerToken.transferFrom(msg.sender,address(treasury), ((jokerAmount * 5)/100));

        uint256 creditAmount = afterFeeDeduction/creditPrice;
         // Ensure that the treasury contract is set before calling withdraw
        require(address(treasury) != address(0), "Treasury not set");
        treasury.withdraw(msg.sender,creditAmount);
         // Now, add liquidity to Uniswap V3 pool
        addLiquidityToUniswap(nfttokenId, jokerAmount- ((jokerAmount * 5)/100),usdtAmount -((usdtAmount * 5)/100));
        // // Transfer DIME tokens to the user from the treasury
        // creditToken.transfer(msg.sender, creditAmount);
    }

function addLiquidityToUniswap(
        uint tokenId,
        uint amount0ToAdd,
        uint amount1ToAdd
    ) private  returns (uint128 liquidity, uint amount0, uint amount1) {
        // dai.transferFrom(msg.sender, address(this), amount0ToAdd);
        // weth.transferFrom(msg.sender, address(this), amount1ToAdd);

        usdtToken.approve(address(positionManager), amount0ToAdd);
        jokerToken.approve(address(positionManager), amount1ToAdd);

        INonfungiblePositionManager.IncreaseLiquidityParams
            memory params = INonfungiblePositionManager.IncreaseLiquidityParams({
                tokenId: tokenId,
                amount0Desired: amount0ToAdd,
                amount1Desired: amount1ToAdd,
                amount0Min: 0,
                amount1Min: 0,
                deadline: block.timestamp
            });

        (liquidity, amount0, amount1) = positionManager.increaseLiquidity(
            params
        );
    }

function setOracleAddress(DataConsumerV3 _creditOracle,DataConsumerV3 _jokerOracle,DataConsumerV3 _usdtOracle) external  onlyOwner {
        creditOracle = _creditOracle;
        jokerOracle = _jokerOracle;
        usdtOracle = _usdtOracle;
    }

    function setUsdtToken(address _usdtToken) external onlyOwner {
        // require(!initialized, "Already initialized");
        usdtToken = IERC20(_usdtToken);
    }

    function setJokerToken(address _jokerToken) external onlyOwner {
        // require(!initialized, "Already initialized");
        jokerToken = IERC20(_jokerToken);
    }

    function setCreditToken(address _creditToken) external onlyOwner {
        // require(!initialized, "Already initialized");
        creditToken = IERC20(_creditToken);
    }

    function setTreasury(Itreasury _treasury) external onlyOwner {
        // require(!initialized, "Already initialized");
        treasury = _treasury;
    }
     function setTokenID(uint _tokenid) external onlyOwner {
        // require(!initialized, "Already initialized");
        nfttokenId = _tokenid;
    }
}
