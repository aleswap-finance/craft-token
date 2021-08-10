pragma solidity 0.6.12;


import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/ReentrancyGuardUpgradeable.sol";


import "./CraftToken.sol";

contract CraftSwapV1 is Initializable, OwnableUpgradeable, ReentrancyGuardUpgradeable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    struct MerchantInfo {
        bool enabled;     
        uint256 fee; 
        uint256 remainBUSD;
    }    

    uint256 private constant FEE_DENOMINATOR = 10**10;
    uint256 private constant MINIMUM_SWAP = 10**18;

    CraftToken public craft;
    
    // Fee Token
    IERC20 public ale;
    
    // Base Token
    IERC20 public busd;
    
    // Dev address.
    address public devaddr;

    address public redeemAdder;

    uint256 public depositFee;
    uint256 public withdrawFee;

    mapping (address => MerchantInfo) public merchants;

    uint256 public devFee;
    

    event DepositBUSD(address indexed user, uint256 amount);
    event WithdrawBUSD(address indexed user, uint256 amount);

    function initialize(        
        CraftToken _craft,
        IERC20 _ale,
        IERC20 _busd,
        address _devaddr
    ) public initializer {
        __Ownable_init_unchained();
        __ReentrancyGuard_init_unchained();

        craft = _craft;
        ale = _ale;
        busd = _busd;
        devaddr = _devaddr;

        depositFee = 0;
        withdrawFee = 0;
    }

    // Deposit BUSD 
    function depositBUSD(uint256 _amount) public {
        uint256 fee;

        require(_amount >= MINIMUM_SWAP, "deposit at least 1 busd");    

        busd.safeTransferFrom(msg.sender, address(this), _amount);
        fee = _amount.mul(depositFee).div(FEE_DENOMINATOR);

        if (fee > 0) {
            ale.safeTransferFrom(msg.sender, address(this), fee);
        }

        craft.mint(msg.sender, _amount);
        
        emit DepositBUSD(msg.sender, _amount);
    }

    function _withdrawBUSD(uint256 _amount,uint256 _withdrawFee) internal {
        uint256 fee;

        require(_amount >= MINIMUM_SWAP, "withdraw at least 1 busd");

        craft.burnFrom(msg.sender, _amount);
        fee = _amount.mul(_withdrawFee).div(FEE_DENOMINATOR);

        if (fee > 0) {
            ale.safeTransferFrom(msg.sender, address(this), fee);
        }  

        busd.safeTransfer(msg.sender, _amount);
          
        emit WithdrawBUSD(msg.sender, _amount);
    }    

    // withdraw BUSD 
    function withdrawBUSD(uint256 _amount) public {
        _withdrawBUSD(_amount, withdrawFee);
    }

    // Merchant redeem Craft Token
    function redeemBUSD(uint256 _amount) public {
        MerchantInfo storage merchant = merchants[msg.sender];

        require(merchant.enabled, "this merchant not enabled");  

        _withdrawBUSD(_amount,merchant.fee);
    }    

    function setDepositFee(uint256 _depositFee) public onlyOwner {
        depositFee = _depositFee;
    }

    function setMerchantRedeemFee(address _merchant, uint256 _redeemFee, bool _enabled) public onlyOwner {
        MerchantInfo storage merchant = merchants[_merchant];

        merchant.enabled = _enabled;
        merchant.fee = _redeemFee;
    }

    function setWithdrawFee(uint256 _withdrawFee) public onlyOwner {
        withdrawFee = _withdrawFee;
    }

    function withdrawAllFee(address withdrawTo) public onlyOwner {
        ale.safeTransfer(withdrawTo, ale.balanceOf(address(this)));
    }

    function setDev(address _dev) public onlyOwner {
        devaddr = _dev;
    }   
    function setRedeemAdder(address _redeemAdder) public onlyOwner {
        redeemAdder = _redeemAdder;
    }    
}
