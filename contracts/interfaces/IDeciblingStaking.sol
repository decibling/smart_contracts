// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

interface IDeciblingStaking {
    event AdminChanged(address previousAdmin, address newAdmin);
    event BeaconUpgraded(address indexed beacon);
    event Claim(string poolId, address user);
    event Initialized(uint8 version);
    event NewPool(string poolId);
    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );
    event Reinvest(string poolId, address user, uint256 profitAmount);
    event Stake(string poolId, address user, uint256 amount);
    event Unstake(string poolId, address user, uint256 amount);
    event UpdatePool(string poolId, uint8 r, uint8 rToOwner, bool isDefault);
    event UpdatePoolOwner(string poolId, address owner);
    event Upgraded(address indexed implementation);

    function accrueInterest(
        uint256 _principal,
        uint256 _rate,
        uint256 _age
    ) external pure returns (uint256);

    function claim(string memory id) external;

    function claimForPoolProfit(string memory id, address[] memory users)
        external;

    function initialize(address froyAddr) external;

    function merkleRoot() external view returns (bytes32);

    function newPool(bytes32[] memory proof, string memory id) external;

    function owner() external view returns (address);

    function payout(
        string memory _pid,
        address user,
        bool forPoolOwner
    ) external view returns (uint256 value);

    function pools(string memory)
        external
        view
        returns (
            address owner,
            uint256 hardCap,
            uint256 totalDeposit,
            uint8 rToOwner,
            uint8 r,
            bool isDefault
        );

    function proxiableUUID() external view returns (bytes32);

    function reinvest(string memory id) external returns (bool);

    function renounceOwnership() external;

    function setDefaultPool() external;

    function setMerkleRoot(bytes32 newMerkleRoot) external;

    function setPoolHardCap(string memory id, uint256 cap) external;

    function setReserveContract(address addr) external;

    function stake(string memory id, uint256 amount) external;

    function stakers(string memory, address)
        external
        view
        returns (
            uint256 totalDeposit,
            uint256 depositTime,
            uint256 lastPayout,
            uint256 lastPayoutToPoolOwner
        );

    function token() external view returns (address);

    function transferOwnership(address newOwner) external;

    function transferToken(uint256 _amount) external;

    function treasury() external view returns (address);

    function unstake(string memory id, uint256 amount) external;

    function updatePool(
        bytes32[] memory proof,
        string memory id,
        uint8 _r,
        uint8 _rToOwner
    ) external;

    function updatePoolOwner(
        bytes32[] memory proof,
        string memory id,
        address poolOwner
    ) external;

    function upgradeTo(address newImplementation) external;

    function upgradeToAndCall(address newImplementation, bytes memory data)
        external
        payable;

    function yearlyRateToRay(uint256 _rateWad) external pure returns (uint256);
}
