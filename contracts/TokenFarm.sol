// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract TokenFarm is Ownable  {
    IERC20 public froyToken;

    uint256 private defaultR = 2;
    uint256 private defaultF = 5;
    uint256 private defaultY = 365;
    uint256 private defaultSecondMultipler = 864000;
    string private defaultPoolId = "decibling_pool";

    /// @notice where to send platform fee funds to
    address payable public platformFeeRecipient;

    constructor() {
        froyToken = IERC20(0xd9145CCE52D386f254917e481eB44e9943F39138);
        platformFeeRecipient = payable(msg.sender);

        string memory id = defaultPoolId;
        pools[id].r = defaultR;
        pools[id].f = defaultF;
        pools[id].y = defaultY;
        pools[id].base = 1e18 * defaultR / (defaultSecondMultipler * defaultY);
        emit UpdatePoolConfigs(id, defaultR, defaultF, defaultY, pools[id].base);
    }

    struct StakeInfo {
        uint256 amount;
        uint256 stakeTime;
        uint256 unclaimAmount;
    }
    struct PoolInfo {
        uint256 r;
        uint256 f;
        uint256 y;
        uint256 base;
    }

    struct ClaimInfo {
        address to;
        string id;
    }

    mapping(string => mapping(address => StakeInfo)) public stakes;
    mapping(string => PoolInfo) public pools;
    event Stake(address _user, uint256 time, uint256 amount, string pool);
    event Unstake(address _user, uint256 time, string pool, uint256 unstakeAmount);
    event IssueToken(address _user, string pool, uint256 time, uint256 amount, uint256 platformValue);
    event UpdatePoolConfigs(string id, uint256 _r, uint256 _f, uint256 _y, uint256 base);
    event UpdatePlatformFeeRecipient(address payable platformFeeRecipient);
    event UpdateUnclaimAmount(address _user, uint256 time, string id, uint256 actualAmount);

    function getListStack(string memory pool)
        public
        view
        returns (
            uint256,
            uint256,
            uint256
        )
    {
        StakeInfo memory info = stakes[pool][msg.sender];
        return (info.amount, info.stakeTime, info.unclaimAmount);
    }

    function stake(string memory id, uint256 _amount) public payable  {
        froyToken.transferFrom(msg.sender, address(this), _amount);
        uint256 currentTime = _getNow();
        if (stakes[id][msg.sender].stakeTime != 0) {
            renewUnclaimAmount(msg.sender, currentTime, id);
        }
        stakes[id][msg.sender].stakeTime = currentTime;
        stakes[id][msg.sender].amount += _amount;
        emit Stake(msg.sender, currentTime, _amount, id);
    }

    function unstake(string memory pool, uint256 unstakeAmount) public {
        address user = msg.sender;
        require(stakes[pool][user].amount != 0, "1"); // amount must be smaller than current staked
        require(unstakeAmount <= stakes[pool][user].amount || unstakeAmount == 0, "18");
        uint256 currentTime = _getNow();
        renewUnclaimAmount(user, currentTime, pool);
        stakes[pool][user].amount = stakes[pool][user].amount - unstakeAmount;
        stakes[pool][user].stakeTime = currentTime;
        froyToken.transfer(user, unstakeAmount);
        emit Unstake(user, currentTime, pool, unstakeAmount);
    }

    function renewUnclaimAmount(
        address _user,
        uint256 currentTime,
        string memory id
    ) internal {
        uint256 stakedSeconds = currentTime - stakes[id][_user].stakeTime;
        uint256 base = 6341958396;
        if (pools[id].base >= 0) {
            base = pools[id].base;
        }
        stakes[id][_user].unclaimAmount += base * stakedSeconds * stakes[id][_user].amount / 1e18;
        emit UpdateUnclaimAmount(_user, currentTime, id, stakes[id][_user].unclaimAmount);
    }

    function issueToken(ClaimInfo[] calldata claims) public onlyOwner  {
        require(claims.length > 0, "23");
        uint256 currentTime = _getNow();
        for(uint i = 0; i < claims.length; i++) {
            address user = claims[i].to;
            string memory pool = claims[i].id;
            renewUnclaimAmount(user, currentTime, pool);
            if (stakes[pool][user].unclaimAmount <= 0) continue;
            uint256 rewardAmount = stakes[pool][user].unclaimAmount;
            uint256 platformValue = 0;
            if (pools[pool].f > 0) {
                platformValue = rewardAmount * pools[pool].f / 1e3;
                rewardAmount -= platformValue;
            }
            
            stakes[pool][user].unclaimAmount = 0;
            stakes[pool][user].stakeTime = currentTime;
            froyToken.transfer(user, rewardAmount);
            if (platformValue > 0) {
                froyToken.transfer(platformFeeRecipient, platformValue);
            }
            emit IssueToken(user, pool, currentTime, rewardAmount, platformValue);
        }
    }

    function updatePoolConfigs(string memory id, uint256 _r, uint256 _f, uint256 _y)
        public
        onlyOwner
    {
        pools[id].r = _r;
        pools[id].f = _f;
        pools[id].y = _y;
        pools[id].base = 1e18 * _r / (864000 * _y);
        emit UpdatePoolConfigs(id, _r, _f, _y, pools[id].base);
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
        external
        onlyOwner
    {
        require(_platformFeeRecipient != address(0), "21");

        platformFeeRecipient = _platformFeeRecipient;
        emit UpdatePlatformFeeRecipient(_platformFeeRecipient);
    }
}