// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol";
interface IDeciblingPoolConfig{
    struct PoolInfo {
        address owner;
        uint256 rToOwner;
        uint256 r;
        uint256 base;
        uint256 baseToOwner;
    }

    function froyToken() view external returns(address);
    function pools(string memory) external view returns(
        address,
        uint256,
        uint256,
        uint256,
        uint256,
        uint256
    );
    function platformFeeRecipient() view external returns(address);
    function platformFee() view external returns(uint256);
    function _merkleRoot() view external returns(bytes32);
    function updateUnclaimAmount(uint256) external;
}
contract DeciblingStaking is Initializable, OwnableUpgradeable  {
    using SafeMathUpgradeable for uint256;   
    /// @notice where to send platform fee funds to
    constructor() {
    }
    address private configAdr;
    mapping(string => mapping(address => StakeInfo)) public stakes;
    function initialize(address _configAdr) public initializer {  
        configAdr = _configAdr;      
    }

    struct StakeInfo {
        uint256 amount;
        uint256 stakeTime;
        uint256 unclaimAmount;
        uint256 unclaimAmountToOwner;
    }

    struct ClaimInfo {
        address to;
        string id;
    }
    struct PoolInfo {
        address owner;
        uint256 rToOwner;
        uint256 r;
        uint256 base;
        uint256 baseToOwner;
        uint256 unclaimAmount;
    }
    event UpdateUnclaimAmount(address _user, string id, uint256 actualAmount);
    event Stake(address _user, uint256 amount, string pool);
    event Unstake(address _user, string pool, uint256 unstakeAmount);
    event IssueToken(address _user, string pool, uint256 amount, uint256 amountToOwner, uint256 platformValue);
    function stake(
        string memory id, 
        uint256 _amount
    ) public {
        bytes memory idTest = bytes(id); // Uses memory
        require(idTest.length != 0, "invalid pool id");
        require(_amount > 0, "amount must be larger than zero");
        (address owner,,,,,) = IDeciblingPoolConfig(configAdr).pools(id);
        require(owner != address(0), "not an active pool");
        uint256 currentTime = _getNow();
        require(IERC20Upgradeable(IDeciblingPoolConfig(configAdr).froyToken()).transferFrom(msg.sender, address(this), _amount));
        if (stakes[id][msg.sender].stakeTime != 0) {
            renewUnclaimAmount(msg.sender, currentTime, id);
        }
        stakes[id][msg.sender].stakeTime = currentTime;
        stakes[id][msg.sender].amount += _amount;
        emit Stake(msg.sender, _amount, id);
    }

    function unstake(string memory id, uint256 unstakeAmount) external {
        bytes memory idTest = bytes(id); // Uses memory
        require(idTest.length != 0, "invalid pool id");
        address user = msg.sender;
        IDeciblingPoolConfig config =IDeciblingPoolConfig(configAdr);
        (address owner,,,,,) = config.pools(id);
        require(owner != address(0), "not an active pool");
        require(unstakeAmount > 0, "amount must be larger than zero");
        require(stakes[id][user].amount != 0, "1"); // amount must be smaller than current staked
        require(unstakeAmount <= stakes[id][user].amount || unstakeAmount == 0, "23");
        uint256 currentTime = _getNow();
        renewUnclaimAmount(user, currentTime, id);
        stakes[id][user].amount = stakes[id][user].amount - unstakeAmount;
        stakes[id][user].stakeTime = currentTime;
        require(IERC20Upgradeable(config.froyToken()).transfer(user, unstakeAmount), "");
        emit Unstake(user, id, unstakeAmount);
    }

    function renewUnclaimAmount(
        address _user,
        uint256 currentTime,
        string memory id
    ) internal {
        bytes memory idTest = bytes(id); // Uses memory
        require(idTest.length != 0, "invalid pool id");
        uint256 stakedSeconds = currentTime - stakes[id][_user].stakeTime;
        uint256 base = 6341958396;
        uint256 baseToOwner = 0;
         (address owner,,,uint256 pbase,uint256 pbaseToOwner,) = IDeciblingPoolConfig(configAdr).pools(id);
        if (pbase >= 0) {
            base = pbase;
        }
        if (pbaseToOwner >= 0) {
            baseToOwner = pbaseToOwner;
        }
        stakes[id][_user].unclaimAmount += base * stakedSeconds * stakes[id][_user].amount / 1e18;
        stakes[id][_user].unclaimAmountToOwner += baseToOwner * stakedSeconds * stakes[id][_user].amount / 1e18;
        emit UpdateUnclaimAmount(_user, id, stakes[id][_user].unclaimAmount);
    }
    event ClaimByOwner(address owner, address caller, string pool_id, uint256 amount, uint256 received_amount);
    function claimPool(string memory poolId) external{
        IDeciblingPoolConfig config = IDeciblingPoolConfig(configAdr);
        uint256 platformFee = config.platformFee();
         (address pOwner,,,,,uint256 pUnclaimToOwner) = config.pools(poolId);
        require(pOwner == msg.sender || owner() == msg.sender, "");
        require(pUnclaimToOwner != 0, "");
        uint256 rewardAmountToOwner = pUnclaimToOwner;
        uint256 oriClaim = pUnclaimToOwner;
        uint256 platformValueFromOwner = 0;
        platformValueFromOwner = rewardAmountToOwner * platformFee / 100;
        rewardAmountToOwner -= platformValueFromOwner;
        config.updateUnclaimAmount(0);
        emit ClaimByOwner(pOwner, msg.sender, poolId,  oriClaim, rewardAmountToOwner);
    }
    function issueToken(string memory pool) public {
        uint256 currentTime = _getNow();
        IDeciblingPoolConfig config = IDeciblingPoolConfig(configAdr);
        (address pOwner,,,,,) = config.pools(pool);
        address user = pOwner;
        require(pOwner == msg.sender || owner() == msg.sender, "not pool owner or admin");
        bytes memory idTest = bytes(pool); // Uses memory
        require (idTest.length == 0);
        renewUnclaimAmount(user, currentTime, pool);
        uint256 rewardAmount = stakes[pool][user].unclaimAmount;
        uint256 rewardAmountToOwner = stakes[pool][user].unclaimAmountToOwner;
        uint256 platformValue = 0;
        uint256 platformFee = config.platformFee();
        if (platformFee > 0) {
            platformValue = rewardAmount * platformFee / 100;
            rewardAmount -= platformValue;
        }
        IERC20Upgradeable froyToken = IERC20Upgradeable(config.froyToken());
        stakes[pool][user].unclaimAmount = 0;
        stakes[pool][user].stakeTime = currentTime;
        if (rewardAmount > 0) {
            require(froyToken.transfer(user, rewardAmount));
        }
        if (platformValue > 0) {
            require(froyToken.transfer(config.platformFeeRecipient(), platformValue));
        }

        emit IssueToken(user, pool, rewardAmount, rewardAmountToOwner, platformValue);
    }

    function _getNow() internal view virtual returns (uint256) {
        return block.timestamp;
    }
}