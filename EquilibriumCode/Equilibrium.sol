
// SPDX-License-Identifier: MIT
//BOSON Labs.
pragma solidity >=0.6.0;
// Import ERC20 interfaces for DimeToken, BlackToken, and DaiToken
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@uniswap/v3-periphery/contracts/interfaces/ISwapRouter.sol";

abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return payable(msg.sender);
    }
    

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}
/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
contract Ownable is Context {
    address public _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function initialize () public virtual {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}
contract Initializable  {

  /**
   * @dev Indicates that the contract has been initialized.
   */
  bool private initialized;

  /**
   * @dev Indicates that the contract is in the process of being initialized.
   */
  bool private initializing;

  /**
   * @dev Modifier to use in the initializer function of a contract.
   */
  modifier initializer() {
    require(initializing || isConstructor() || !initialized, "Contract instance has already been initialized");

    bool isTopLevelCall = !initializing;
    if (isTopLevelCall) {
      initializing = true;
      initialized = true;
    }

    _;

    if (isTopLevelCall) {
      initializing = false;
    }
  }

  /// @dev Returns true if and only if the function is running in the constructor
  function isConstructor() private view returns (bool) {
    // extcodesize checks the size of the code stored in an address, and
    // address returns the current address. Since the code is still not
    // deployed when running a constructor, any checks on its code size will
    // yield zero, making it an effective way to detect if a contract is
    // under construction or not.
    address self = address(this);
    uint256 cs;
    assembly { cs := extcodesize(self) }
    return cs == 0;
  }

  // Reserved storage space to allow for layout changes in the future.
  uint256[50] private ______gap;
}
/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts with custom message when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

// pragma solidity >=0.6.2;

interface IUniswapV3Router01 {
    function factory() external pure returns (address);
    function WETH9() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity);
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETH(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountToken, uint amountETH);
    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETHWithPermit(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountToken, uint amountETH);
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);
    function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);

    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
}

contract Equilibrium is Ownable, Initializable {

    using SafeMath for uint256;
    uint256 public DimePrice;
    uint256 public JusdPrice;
    uint256 public BlackPrice;

    uint256 public DimeCirSupply;
    uint256 public JusdCirSupply;
    uint256 public BlackCirSupply;

    uint256 public DimeMarketCap;
    uint256 public JusdMarketCap;
    uint256 public BlackMarketCap;

    uint256 public lastTimeEquilibiriumAchieved;

    IUniswapV3Router01 public  uniswapV3Router;


    function initialize() public override initializer {
        Ownable.initialize();
    }

    function CheckEquilibirium() public {
        if(JusdMarketCap.add(DimeMarketCap) <= BlackMarketCap){
            lastTimeEquilibiriumAchieved = block.timestamp;
            if(BlackMarketCap < (20 * JusdMarketCap)){
                if(BlackMarketCap > (10 * DimeMarketCap) ){
                    //DYNAMIC PRINCIPLE 2
                }
                else if(JusdMarketCap > (2 * DimeMarketCap)){
                    //DYNAMIC PRINCIPLE 5
                }
                else if(DimeMarketCap > (2 * JusdMarketCap)){
                    //DYNAMIC PRINCIPLE 6
                }
                else{
                    //DYNAMIC PRINCIPLE 7
                    return;
                }
            }
            else{
                if(BlackMarketCap < (10 * DimeMarketCap)){
                    //Dynamic principle 3
                }
                else{
                    //Dynamic principle 4
                }
            }
        }else{
            //If the protocol doesn’t reach equilibrium for 365 days condition
            if(block.timestamp.sub(lastTimeEquilibiriumAchieved) >= 31556926){
                //Dynamic principle 8
            }
            else if(JusdMarketCap == DimeMarketCap){
               //Dynamic principle 9
            }
            else if(JusdMarketCap > DimeMarketCap){
                //Dynamic principle 1.0
            }else{
                //Dynamic principle 1.1
            }
        }
    }


    //for testing purpose setter functions
    function setValues(uint256 dimePrice,uint256 jusdPrice,uint256 blackPrice,uint256 dimeCirSupply,uint256 jusdCirSupply,uint256 blackCirSupply) public {
        DimePrice = dimePrice;
        JusdPrice = jusdPrice;
        BlackPrice = blackPrice;
        DimeCirSupply = dimeCirSupply;
        JusdCirSupply = jusdCirSupply;
        BlackCirSupply = blackCirSupply;
        DimeMarketCap = DimePrice * DimeCirSupply;
        JusdMarketCap = JusdPrice * JusdCirSupply;
        BlackMarketCap = BlackPrice * BlackCirSupply;
    }


    function swapTokens(address path1,address path2,uint256 tokenAmount) public {
        ISwapRouter _uniswapV3Router = ISwapRouter(0x8357227D4eDc78991Db6FDB9bD6ADE250536dE1d);
          // The pool fee of 0.05%
        uint24  poolFee = 500;
        // uniswapV3Router = _uniswapV3Router;

    //     address[] memory path = new address[](2);
    //     path[0] = path1;
    //     path[1] = path2;
    //     IERC20  firstToken =  IERC20(path1);
    //    firstToken.approve(address(uniswapV3Router), tokenAmount);
    //     uniswapV3Router.swapExactTokensForTokens(
    //         tokenAmount,
    //         0, // accept any amount of BNB
    //         path,
    //         address(this),
    //         block.timestamp
    //     );

    IERC20(path1).transferFrom(msg.sender, address(this), tokenAmount);

        // Approve router to spend DAI
    IERC20(path1).approve(address(_uniswapV3Router), tokenAmount);

    // Set up parameters for swap
    // ISwapRouter.ExactInputSingleParams memory params = ISwapRouter.ExactInputSingleParams({
    //     tokenIn: path1,
    //     tokenOut: path2,
    //     fee: poolFee,
    //     recipient: msg.sender,
    //     deadline: block.timestamp,
    //     amountIn: tokenAmount,
    //     amountOutMinimum: 0,
    //     sqrtPriceLimitX96: 0
    // });

    // // Execute swap and return output amount
    // uint256 amountOut = _uniswapV3Router.exactInputSingle(params);
    }

     function swapTokens1(address path1,address path2,uint256 tokenAmount) public {
        ISwapRouter _uniswapV3Router = ISwapRouter(0x8357227D4eDc78991Db6FDB9bD6ADE250536dE1d);
          // The pool fee of 0.05%
        uint24  poolFee = 500;
        // uniswapV3Router = _uniswapV3Router;

    //     address[] memory path = new address[](2);
    //     path[0] = path1;
    //     path[1] = path2;
    //     IERC20  firstToken =  IERC20(path1);
    //    firstToken.approve(address(uniswapV3Router), tokenAmount);
    //     uniswapV3Router.swapExactTokensForTokens(
    //         tokenAmount,
    //         0, // accept any amount of BNB
    //         path,
    //         address(this),
    //         block.timestamp
    //     );

    // IERC20(path1).transferFrom(msg.sender, address(this), tokenAmount);

    //     // Approve router to spend DAI
    // IERC20(path1).approve(address(_uniswapV3Router), tokenAmount);

    // Set up parameters for swap
    ISwapRouter.ExactInputSingleParams memory params = ISwapRouter.ExactInputSingleParams({
        tokenIn: path1,
        tokenOut: path2,
        fee: poolFee,
        recipient: msg.sender,
        deadline: block.timestamp,
        amountIn: tokenAmount,
        amountOutMinimum: 0,
        sqrtPriceLimitX96: 0
    });

    // Execute swap and return output amount
    uint256 amountOut = _uniswapV3Router.exactInputSingle(params);
    }

    function readSwap(address path1,address path2,uint256 tokenAmount)public  view returns(string memory params){
        ISwapRouter _uniswapV3Router = ISwapRouter(0x8357227D4eDc78991Db6FDB9bD6ADE250536dE1d);
          // The pool fee of 0.05%
        uint24  poolFee = 500;
        ISwapRouter.ExactInputSingleParams memory params = ISwapRouter.ExactInputSingleParams({
        tokenIn: path1,
        tokenOut: path2,
        fee: poolFee,
        recipient: msg.sender,
        deadline: block.timestamp,
        amountIn: tokenAmount,
        amountOutMinimum: 0,
        sqrtPriceLimitX96: 0
    });
    }

    
    
}
