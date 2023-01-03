// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract DeciblingStaking is Ownable  {
    using SafeMath for uint256;
    IERC20 public froyToken;
    
    uint256 public platformFee = 5;
    /// @notice where to send platform fee funds to
    address payable public platformFeeRecipient;

    constructor(address _tokenAddress, address payable _platformFeeRecipient) {
        require(_tokenAddress != address(0) && _platformFeeRecipient != address(0), "Constructor wallets cannot be zero");
        froyToken = IERC20(_tokenAddress);
        platformFeeRecipient = _platformFeeRecipient;

        _newPool("decibling_pool", 2, 0);
    }

    struct StakeInfo {
        uint256 amount;
        uint256 stakeTime;
        uint256 unclaimAmount;
        uint256 unclaimAmountToOwner;
    }
    struct PoolInfo {
        address owner;
        uint256 rToOwner;
        uint256 r;
        uint256 base;
        uint256 baseToOwner;
    }

    struct ClaimInfo {
        address to;
        string id;
    }

    mapping(string => mapping(address => StakeInfo)) public stakes;
    mapping(string => PoolInfo) public pools;
    
    event Stake(address _user, uint256 time, uint256 amount, string pool);
    event Unstake(address _user, uint256 time, string pool, uint256 unstakeAmount);
    event IssueToken(address _user, string pool, uint256 time, uint256 amount, uint256 amountToOwner, uint256 platformValue, uint256 platformValueToOwner);
    event NewPool(string id);
    event UpdatePool(string id, uint256 r, uint256 r_to_owner, uint256 base, uint256 base_to_owner);
    event UpdatePoolOwner(string id, address payable owner);
    event UpdatePlatformFeeRecipient(address payable platformFeeRecipient);
    event UpdatePlatformFee(uint256 platformFee);
    event UpdateUnclaimAmount(address _user, uint256 time, string id, uint256 actualAmount);

    function newPool(string memory _id, uint256 _r, uint256 _r_to_owner) external {
        require(pools[_id].owner == address(0), "pool exists");
        require(_r >= 3 && _r <= 8, "invalid return value");
        require(_r_to_owner <= 5, "invalid return to owner value");
        require(_r_to_owner + _r <= 8, "total return must be less than or equal 8");
        _newPool(_id, _r, _r_to_owner);
    }

    function _newPool(string memory _id, uint256 _r, uint256 _r_to_owner) internal {
        bytes memory idTest = bytes(_id); // Uses memory
        require(idTest.length != 0, "invalid pool id");
        pools[_id].owner = msg.sender;
        _updatePool(_id, _r, _r_to_owner);
        emit NewPool(_id);
    }

    function updatePool(string memory id, uint256 _r, uint256 _r_to_owner)
        external
    {
        require(pools[id].owner == msg.sender || owner() == msg.sender, "not pool owner or admin");
        require(_r >= 3 && _r <= 8, "invalid return value");
        require(_r_to_owner <= 5, "invalid return to owner value");
        require(_r_to_owner + _r == 8, "total return must be equal 8");
        
        _updatePool(id, _r, _r_to_owner);
    }

    function updatePoolOwner(string memory _id, address payable _owner)
        external
    {
        bytes memory idTest = bytes(_id); // Uses memory
        require(idTest.length != 0, "invalid pool id");
        require(pools[_id].owner == msg.sender || owner() == msg.sender, "not pool owner or admin");
        require(_owner != address(0), "21");
        pools[_id].owner = _owner;

        emit UpdatePoolOwner(_id, _owner);
    }
    
    function _updatePool(string memory id, uint256 _r, uint256 _r_to_owner)
        internal
    {
        bytes memory idTest = bytes(id); // Uses memory
        require(idTest.length != 0, "invalid pool id");
        pools[id].r = _r;
        pools[id].rToOwner = _r_to_owner;
        pools[id].base = 1e18 * _r / (86400 * 100 * 365);
        pools[id].baseToOwner = 1e18 * _r_to_owner / (86400 * 100 * 365);
        emit UpdatePool(id, _r, _r_to_owner, pools[id].base, pools[id].baseToOwner);
    }

    function stake(string memory id, uint256 _amount) external {
        bytes memory idTest = bytes(id); // Uses memory
        require(idTest.length != 0, "invalid pool id");
        require(_amount > 0, "amount must be larger than zero");
        require(pools[id].owner != address(0), "not an active pool");
        uint256 currentTime = _getNow();
        require(froyToken.transferFrom(msg.sender, address(this), _amount));
        if (stakes[id][msg.sender].stakeTime != 0) {
            renewUnclaimAmount(msg.sender, currentTime, id);
        }
        stakes[id][msg.sender].stakeTime = currentTime;
        stakes[id][msg.sender].amount += _amount;
        emit Stake(msg.sender, currentTime, _amount, id);
    }

    function unstake(string memory id, uint256 unstakeAmount) external {
        bytes memory idTest = bytes(id); // Uses memory
        require(idTest.length != 0, "invalid pool id");
        address user = msg.sender;
        require(pools[id].owner != address(0), "not an active pool");
        require(unstakeAmount > 0, "amount must be larger than zero");
        require(stakes[id][user].amount != 0, "1"); // amount must be smaller than current staked
        require(unstakeAmount <= stakes[id][user].amount || unstakeAmount == 0, "18");
        uint256 currentTime = _getNow();
        renewUnclaimAmount(user, currentTime, id);
        stakes[id][user].amount = stakes[id][user].amount - unstakeAmount;
        stakes[id][user].stakeTime = currentTime;
        require(froyToken.transfer(user, unstakeAmount));
        emit Unstake(user, currentTime, id, unstakeAmount);
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
        if (pools[id].base >= 0) {
            base = pools[id].base;
        }
        if (pools[id].baseToOwner >= 0) {
            baseToOwner = pools[id].baseToOwner;
        }
        stakes[id][_user].unclaimAmount += base * stakedSeconds * stakes[id][_user].amount / 1e18;
        stakes[id][_user].unclaimAmountToOwner += baseToOwner * stakedSeconds * stakes[id][_user].amount / 1e18;
        emit UpdateUnclaimAmount(_user, currentTime, id, stakes[id][_user].unclaimAmount);
    }

    function issueToken(ClaimInfo[] calldata claims) external {
        require(claims.length > 0, "23");
        uint256 currentTime = _getNow();
        for(uint i = 0; i < claims.length; i++) {
            address user = claims[i].to;
            string memory id = claims[i].id;
            require(pools[id].owner == msg.sender || owner() == msg.sender, "not pool owner or admin");
            bytes memory idTest = bytes(id); // Uses memory
            if (idTest.length == 0) continue;
            renewUnclaimAmount(user, currentTime, id);
            uint256 rewardAmount = stakes[id][user].unclaimAmount;
            uint256 rewardAmountToOwner = stakes[id][user].unclaimAmountToOwner;
            uint256 platformValue = 0;
            uint256 platformValueFromOwner = 0;
            if (platformFee > 0) {
                platformValue = rewardAmount * platformFee / 100;
                rewardAmount -= platformValue;
                platformValueFromOwner = rewardAmountToOwner * platformFee / 100;
                rewardAmountToOwner -= platformValueFromOwner;
            }
            
            stakes[id][user].unclaimAmount = 0;
            stakes[id][user].unclaimAmountToOwner = 0;
            stakes[id][user].stakeTime = currentTime;
            if (rewardAmount > 0) {
                require(froyToken.transfer(user, rewardAmount));
            }
            if (rewardAmountToOwner > 0) {
                require(froyToken.transfer(pools[id].owner, rewardAmountToOwner));
            }
            if (platformValue > 0) {
                require(froyToken.transfer(platformFeeRecipient, platformValue+platformValueFromOwner));
            }

            emit IssueToken(user, id, currentTime, rewardAmount, rewardAmountToOwner, platformValue, platformValueFromOwner);
        }
    }

    function _getNow() internal view virtual returns (uint256) {
        return block.timestamp;
    }

    /**
     @notice Method for updating platform fee address
     @dev Only admin
     @param _platformFeeRecipient payable address the address to sends the funds to
     */
    function updatePlatformFeeRecipient(address payable _platformFeeRecipient)
        external onlyOwner
    {
        require(_platformFeeRecipient != address(0), "21");

        platformFeeRecipient = _platformFeeRecipient;
        emit UpdatePlatformFeeRecipient(_platformFeeRecipient);
    }

    function updatePlatformFee(uint256 _platformFee)
        external onlyOwner
    {
        platformFee = _platformFee;
        emit UpdatePlatformFee(_platformFee);
    }
}