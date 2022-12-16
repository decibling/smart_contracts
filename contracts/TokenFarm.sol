// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

contract TokenFarm is Ownable  {
    // stakeTokens - DONE!
    // unStakeTokens - DONE
    // issueTokens - DONE!
    // addAllowedTokens - DONE!
    // getValue - DONE!
    IERC20 public dbToken;

    constructor() {
        dbToken = IERC20(0xAa8ADb51329BA9640D86Aa10b0F374d97A7B31d9);
    }

    struct StakeInfo {
        uint256 amount;
        uint256 stakeTime;
        uint256 unClaimAmount;
    }
    mapping(string => mapping(address => StakeInfo)) public listStake;
    mapping(string => mapping(address => uint256)) public userStakeIndex;
    mapping(string => address[]) public userStake;
    uint256 public defaultRewardPer = 1e6;
    uint256 public defaultPerSec = 60;
    mapping(string => uint256) public rewardPercent;
    mapping(string => uint256) public perSeconds;
    event Stake(address _user, uint256 amount, string pool);
    event Unstake(address _user, string pool, uint256 unstakeAmount);
    event ClaimReward(address _user, string pool);

    function getListStack(string memory pool)
        public
        view
        returns (
            uint256,
            uint256,
            uint256
        )
    {
        StakeInfo memory info = listStake[pool][msg.sender];
        return (info.amount, info.stakeTime, info.unClaimAmount);
    }

    function stake(uint256 _amount, string memory pool) public payable  {
        dbToken.transferFrom(msg.sender, address(this), _amount);
        uint256 currentTime = block.timestamp;
        if (listStake[pool][msg.sender].stakeTime != 0) {
            renewUnClaimAmount(msg.sender, currentTime, pool);
        } else {
            // never stake before -> add to list user stakke
            if (userStakeIndex[pool][msg.sender] == 0) {
                uint256 currentLength = userStake[pool].length;
                userStake[pool].push(msg.sender);
                userStakeIndex[pool][msg.sender] = currentLength + 1;
            }
        }
        listStake[pool][msg.sender].stakeTime = currentTime;
        listStake[pool][msg.sender].amount += _amount;
        emit Stake(msg.sender, _amount, pool);
    }
    function renewUnClaimAmount(
        address _user,
        uint256 currentTime,
        string memory pool
    ) internal {
        if (rewardPercent[pool] == 0 || perSeconds[pool] == 0) {
            if (
                (currentTime - listStake[pool][_user].stakeTime) /
                    defaultPerSec !=
                0
            ) {
                // use default pool
                listStake[pool][_user].unClaimAmount +=
                    (((currentTime - listStake[pool][_user].stakeTime) /
                        defaultPerSec) *
                        defaultRewardPer *
                        listStake[pool][_user].amount) /
                    1e8;
            }
        } else {
            if (
                (currentTime - listStake[pool][_user].stakeTime) /
                    perSeconds[pool] !=
                0
            ) {
                listStake[pool][_user].unClaimAmount +=
                    (((currentTime - listStake[pool][_user].stakeTime) /
                        perSeconds[pool]) *
                        rewardPercent[pool] *
                        listStake[pool][_user].amount) /
                    1e8;
            }
        }
        // unclaim amount = staking time / perseconds[pool] * percentGainned / 100 ;
    }

    function removeUser(address _user, string memory pool) internal {
        if (userStakeIndex[pool][_user] != 0) {
            userStake[pool][userStakeIndex[pool][_user] - 1] = userStake[pool][
                userStake[pool].length - 1
            ];
            userStake[pool].pop();
            userStakeIndex[pool][_user] = 0;
        }
    }

    function unstake(string memory pool, address user, uint256 unstakeAmount) public {
        require(msg.sender == user || msg.sender == owner(), "17");
        require(userStakeIndex[pool][user] != 0, "2"); // user is not exists
        require(listStake[pool][user].amount != 0, "1"); // amount must be smaller than current staked
        require(unstakeAmount <= listStake[pool][user].amount || unstakeAmount == 0, "18");
        uint256 currentTime = block.timestamp;
        if(unstakeAmount == 0 || unstakeAmount == listStake[pool][user].amount){
            renewUnClaimAmount(user, currentTime, pool);
            uint256 returnAmount = listStake[pool][user].amount;
            listStake[pool][user].amount = 0;
            listStake[pool][user].stakeTime = 0;
            dbToken.transfer(user, returnAmount);
            removeUser(user, pool);
            emit Unstake(user, pool, listStake[pool][user].amount);
        }else{
            renewUnClaimAmount(user, currentTime, pool);
            listStake[pool][user].amount = listStake[pool][user].amount - unstakeAmount;
            listStake[pool][user].stakeTime = currentTime;
            dbToken.transfer(user, unstakeAmount);
            emit Unstake(user, pool, unstakeAmount);
        }
    }

    function issueToken(string memory pool, address user) public onlyOwner  {
        uint256 currentTime = block.timestamp;
        if (listStake[pool][user].stakeTime == 0) {
            // no longer stake
            if (listStake[pool][user].unClaimAmount != 0) {
                uint256 rewardAmount = listStake[pool][user].unClaimAmount;
                listStake[pool][user].unClaimAmount = 0;
                listStake[pool][user].amount = 0;
                dbToken.transfer(user, rewardAmount);
                removeUser(user, pool);
            }
        } else {
            // staking
            renewUnClaimAmount(user, currentTime, pool);
            uint256 rewardAmount = listStake[pool][user].unClaimAmount;
            listStake[pool][user].unClaimAmount = 0;
            listStake[pool][user].stakeTime = currentTime;
            dbToken.transfer(user, rewardAmount);
        }
        emit ClaimReward(user, pool);
    }

    function setSplitConfig(uint256 percent, uint256 sec, string memory pool)
        public
        onlyOwner
    {
        // need require config percent and sec for good measure
        rewardPercent[pool] = percent;
        perSeconds[pool] = sec;
    }

    function setSplitConfigDefault(uint256 percent, uint256 sec) public onlyOwner {
        // need require config percent and sec for good measure
        defaultRewardPer = percent;
        defaultPerSec = sec;
    }

}
