// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/StringsUpgradeable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract DeciblingFaucet is
    Initializable,
    OwnableUpgradeable,
    ReentrancyGuardUpgradeable,
    UUPSUpgradeable
{
    using AddressUpgradeable for address;
    using StringsUpgradeable for uint256;

    uint256 private constant AMOUNT = 10_000 * 10 ** 18;

    IERC20 public token;

    mapping(address => uint256) public faucets;

    event Faucet(address user);

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(
        address froyAddr
    ) public initializer {
        token = IERC20(froyAddr);

        __Ownable_init();
        __UUPSUpgradeable_init();
        __ReentrancyGuard_init();
    }

    function _authorizeUpgrade(
        address newImplementation
    ) internal override onlyOwner {}

    function request() external nonReentrant {
        require(
            faucets[msg.sender] + 3600 <= _getNow(),
            "DeciblingFaucet: Only 1 request per hour per user"
        );
        require(
            token.transfer(msg.sender, AMOUNT),
            "DeciblingFaucet: Transfer failed"
        );

        faucets[msg.sender] = _getNow();

        emit Faucet(msg.sender);
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
