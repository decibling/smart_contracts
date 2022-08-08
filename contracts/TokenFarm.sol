// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

contract TokenFarm is Ownable {
    // stakeTokens - DONE!
    // unStakeTokens - DONE
    // issueTokens - DONE!
    // addAllowedTokens - DONE!
    // getValue - DONE!
    IERC20 public dbToken;

    constructor(address _dbTokenAddress) public {
        dbToken = IERC20(_dbTokenAddress);
    }

    struct StakeInfo {
        uint256 amount;
        uint256 stakeTime;
        uint256 unClaimAmount;
    }
    mapping(string => mapping(address => StakeInfo)) public listStake;
    mapping(string => mapping(address => uint256)) public userStakeIndex;
    mapping(string => address[]) public userStake;

    mapping(string => uint256) public rewardPercent;
    mapping(string => uint256) public perSeconds;
    event Stake(address _user, uint256 amount, string pool);
    event Unstake(address _user, string pool);
    event ClaimReward(address _user, string pool);

    function stake(uint256 _amount, string memory pool) public payable {
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
        if (
            (currentTime - listStake[pool][_user].stakeTime) /
                perSeconds[pool] !=
            0
        ) {
            // unclaim amount = staking time / perseconds[pool] * percentGainned / 100 ;
            listStake[pool][_user].unClaimAmount +=
                (((currentTime - listStake[pool][_user].stakeTime) /
                    perSeconds[pool]) *
                    rewardPercent[pool] *
                    listStake[pool][_user].amount) /
                10000;
        }
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

    function unstake(string memory pool) public {
        require(userStakeIndex[pool][msg.sender] != 0, "2"); // user is not exists
        require(listStake[pool][msg.sender].amount != 0, "1"); // amount must be smaller than current staked
        dbToken.transfer(msg.sender, listStake[pool][msg.sender].amount);
        listStake[pool][msg.sender].amount = 0;
        listStake[pool][msg.sender].stakeTime = 0;
        listStake[pool][msg.sender].unClaimAmount = 0;
        removeUser(msg.sender, pool);
        emit Unstake(msg.sender, pool);
    }

    function claimToken(string memory pool) public onlyOwner {
        address _user = msg.sender;
        uint256 currentTime = block.timestamp;
        if (listStake[pool][_user].stakeTime == 0) {
            // no longer stake
            if (listStake[pool][_user].unClaimAmount != 0) {
                dbToken.transfer(_user, listStake[pool][_user].unClaimAmount);
                listStake[pool][_user].unClaimAmount = 0;
                listStake[pool][_user].amount = 0;
                removeUser(_user, pool);
            }
        } else {
            // staking
            renewUnClaimAmount(_user, currentTime, pool);
            listStake[pool][_user].stakeTime = currentTime;
            dbToken.transfer(_user, listStake[pool][_user].unClaimAmount);
            listStake[pool][_user].unClaimAmount = 0;
        }
        emit ClaimReward(_user, pool);
    }

    function setRewardPercent(uint256 percent, string memory pool)
        public
        onlyOwner
    {
        rewardPercent[pool] = percent;
    }

    function setPerSecondsReward(uint256 sec, string memory pool)
        public
        onlyOwner
    {
        perSeconds[pool] = sec;
    }
}
