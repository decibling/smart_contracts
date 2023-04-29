// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/StringsUpgradeable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "hardhat/console.sol";
import "./DeciblingStaking.sol";

contract DeciblingTreasury is
    Initializable,
    OwnableUpgradeable,
    ReentrancyGuardUpgradeable,
    UUPSUpgradeable
{
    using AddressUpgradeable for address;
    using StringsUpgradeable for uint256;

    IERC20 public token;
    DeciblingStaking public staking;

    uint8 public payoutFee;

    event Payout(string poolId, address user, uint256 profitAmount);
    event UpdatePayoutFee(uint8 fee);

    modifier stakingContractOnly() {
        require(msg.sender == address(staking));
        _;
    }

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(
        address froyAddr
    ) public initializer {
        token = IERC20(froyAddr);
        payoutFee = 5;

        __Ownable_init();
        __UUPSUpgradeable_init();
    }

    function _authorizeUpgrade(
        address newImplementation
    ) internal override onlyOwner {}

    function requestPayout(
        string memory id,
        address user
    ) external nonReentrant stakingContractOnly returns (bool) {
        uint256 amount = staking.payout(id, user, false);
        require(amount > 0, "DeciblingTreasury: Payout must be > 0");
        uint256 feeAmount = (amount * payoutFee) / 100;
        uint256 payAmount = amount - feeAmount;
        require(
            token.transfer(user, payAmount),
            "DeciblingTreasury: Transfer failed"
        );

        emit Payout(id, msg.sender, payAmount);

        return true;
    }

    function requestPayoutForPoolOwner(
        string memory id,
        address[] calldata users
    ) external nonReentrant stakingContractOnly returns (bool) {
        uint256 totalPaidAmount;
        for (uint i = 0; i < users.length; i++) {
            uint256 amount = staking.payout(id, users[i], true);
            uint256 feeAmount = (amount * payoutFee) / 100;
            uint256 payAmount = amount - feeAmount;
            if (amount > 0) {
                require(
                    token.transfer(users[i], payAmount),
                    "DeciblingTreasury: Transfer failed"
                );
                totalPaidAmount += payAmount;
            }
        }

        emit Payout(id, msg.sender, totalPaidAmount);

        return true;
    }

    /**
     @notice Method for updating the platform fee
     @param _fee uint8 the new fee
     */
    function updatePlatformFees(uint8 _fee) external onlyOwner {
        payoutFee = _fee;

        emit UpdatePayoutFee(_fee);
    }

    function setStakingContract(address addr) external onlyOwner {
        staking = DeciblingStaking(addr);
    }

    /**
     * @dev Allow owner to transfer token from contract
     * @param _amount {uint256} amount of token to be transferred
     *
     * This is a generalized function which can be used to transfer any accidentally
     * sent (including team) out of the contract to owner
     */
    function transferToken(uint256 _amount) external onlyOwner {
        token.transfer(address(owner()), _amount);
    }

    function _getNow() internal view virtual returns (uint256) {
        return block.timestamp;
    }
}
