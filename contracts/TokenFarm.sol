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
        rewardPercent = 100;
        perSeconds = 60;
    }

    struct StakeInfo {
        uint256 amount;
        uint256 stakeTime;
        uint256 unClaimAmount;
    }
    mapping(address => StakeInfo) public listStake;
    mapping(address => uint256) public userStakeIndex;
    address[] public userStake;

    uint256 public rewardPercent;
    uint256 public perSeconds;
    event Stake(address _user, uint256 amount);
    event Unstake(address _user);
    event ClaimReward(address _user);

    function stake(uint256 _amount) public payable {
        dbToken.transferFrom(msg.sender, address(this), _amount);
        uint256 currentTime = block.timestamp;
        if (listStake[msg.sender].stakeTime != 0) {
            renewUnClaimAmount(msg.sender, currentTime);
        } else {
            // never stake before -> add to list user stakke
            if (userStakeIndex[msg.sender] == 0) {
                uint256 currentLength = userStake.length;
                userStake.push(msg.sender);
                userStakeIndex[msg.sender] = currentLength + 1;
            }
        }
        listStake[msg.sender].stakeTime = currentTime;
        listStake[msg.sender].amount += _amount;
        emit Stake(msg.sender, _amount);
    }

    function renewUnClaimAmount(address _user, uint256 currentTime) internal {
        if ((currentTime - listStake[_user].stakeTime) / perSeconds != 0) {
            // unclaim amount = staking time / perseconds * percentGainned / 100 ;
            listStake[_user].unClaimAmount +=
                (((currentTime - listStake[_user].stakeTime) / perSeconds) *
                    rewardPercent *
                    listStake[_user].amount) /
                10000;
        }
    }

    function removeUser(address _user) internal {
        if (userStakeIndex[_user] != 0) {
            userStake[userStakeIndex[_user] - 1] = userStake[
                userStake.length - 1
            ];
            userStake.pop();
            userStakeIndex[_user] = 0;
        }
    }

    function unstake() public {
        require(userStakeIndex[msg.sender] != 0, "2"); // user is not exists
        require(listStake[msg.sender].amount != 0, "1"); // amount must be smaller than current staked
        dbToken.transfer(msg.sender, listStake[msg.sender].amount);
        listStake[msg.sender].amount = 0;
        listStake[msg.sender].stakeTime = 0;
        listStake[msg.sender].unClaimAmount = 0;
        removeUser(msg.sender);
        emit Unstake(msg.sender);
    }

    function claimToken() public onlyOwner {
        address _user = msg.sender;
        uint256 currentTime = block.timestamp;
        if (listStake[_user].stakeTime == 0) {
            // no longer stake
            if (listStake[_user].unClaimAmount != 0) {
                dbToken.transfer(_user, listStake[_user].unClaimAmount);
                listStake[_user].unClaimAmount = 0;
                listStake[_user].amount = 0;
                removeUser(_user);
            }
        } else {
            // staking
            renewUnClaimAmount(_user, currentTime);
            listStake[_user].stakeTime = currentTime;
            dbToken.transfer(_user, listStake[_user].unClaimAmount);
            listStake[_user].unClaimAmount = 0;
        }
        emit ClaimReward(_user);
    }

    function setRewardPercent(uint256 percent) public onlyOwner {
        rewardPercent = percent;
    }

    function setPerSecondsReward(uint256 sec) public onlyOwner {
        perSeconds = sec;
    }
}
