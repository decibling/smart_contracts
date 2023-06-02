// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

interface IDeciblingReserve {
    event AdminChanged(address previousAdmin, address newAdmin);
    event BeaconUpgraded(address indexed beacon);
    event Initialized(uint8 version);
    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );
    event Payout(string poolId, address user, uint256 profitAmount);
    event UpdatePayoutFee(uint8 fee);
    event Upgraded(address indexed implementation);

    function initialize(address froyAddr) external;

    function owner() external view returns (address);

    function payoutFee() external view returns (uint8);

    function proxiableUUID() external view returns (bytes32);

    function renounceOwnership() external;

    function requestPayout(
        string memory id,
        address user,
        uint256 amount
    ) external returns (bool);

    function setStakingContract(address addr) external;

    function staking() external view returns (address);

    function token() external view returns (address);

    function transferOwnership(address newOwner) external;

    function transferToken(uint256 _amount) external;

    function updatePlatformFees(uint8 _fee) external;

    function upgradeTo(address newImplementation) external;

    function upgradeToAndCall(address newImplementation, bytes memory data)
        external
        payable;
}
