// Sources flattened with hardhat v2.9.2 https://hardhat.org

// File @openzeppelin/contracts/utils/Context.sol@v4.5.0

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}


// File @openzeppelin/contracts/access/Ownable.sol@v4.5.0

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

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
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
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
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}


// File @openzeppelin/contracts/token/ERC20/IERC20.sol@v4.5.0

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}


// File @chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol@v0.4.0

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface AggregatorV3Interface {
  function decimals() external view returns (uint8);

  function description() external view returns (string memory);

  function version() external view returns (uint256);

  // getRoundData and latestRoundData should both raise "No data present"
  // if they do not have data to report, instead of returning unset values
  // which could be misinterpreted as actual reported values.
  function getRoundData(uint80 _roundId)
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

  function latestRoundData()
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );
}


// File contracts/TokenFarm.sol

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;



contract TokenFarm is Ownable {
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
    uint256 public defaultRewardPer = 2;
    uint256 public defaultPerSec = 5;
    mapping(string => uint256) public rewardPercent;
    mapping(string => uint256) public perSeconds;
    event Stake(address _user, uint256 amount, string pool);
    event Unstake(address _user, string pool);
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
                    10000;
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
                    10000;
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

    function issueToken(string memory pool, address user) public onlyOwner {
        uint256 currentTime = block.timestamp;
        if (listStake[pool][user].stakeTime == 0) {
            // no longer stake
            if (listStake[pool][user].unClaimAmount != 0) {
                dbToken.transfer(user, listStake[pool][user].unClaimAmount);
                listStake[pool][user].unClaimAmount = 0;
                listStake[pool][user].amount = 0;
                removeUser(user, pool);
            }
        } else {
            // staking
            renewUnClaimAmount(user, currentTime, pool);
            listStake[pool][user].stakeTime = currentTime;
            dbToken.transfer(user, listStake[pool][user].unClaimAmount);
            listStake[pool][user].unClaimAmount = 0;
        }
        emit ClaimReward(user, pool);
    }

    function setSplitConfig(uint256 percent, uint256 sec, string memory pool)
        public
        onlyOwner
    {
        // need require config percent and sec for google measure
        rewardPercent[pool] = percent;
        perSeconds[pool] = sec;
    }

    function setSplitConfigDefault(uint256 percent, uint256 sec) public onlyOwner {
        // need require config percent and sec for google measure
        defaultRewardPer = percent;
        defaultPerSec = sec;
    }

}
