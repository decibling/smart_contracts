// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts-upgradeable/utils/cryptography/MerkleProofUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

contract DeciblingPoolConfig is
    Initializable,
    OwnableUpgradeable,
    UUPSUpgradeable
{
    address public feeAddress;
    uint256 public fee;
    bytes32 public merkleRoot;
    address public stakingContract;

    struct PoolInfo {
        address owner;
        uint256 rToOwner;
        uint256 r;
        uint256 base;
        uint256 baseToOwner;
        uint256 unclaimToOwner;
    }

    mapping(string => PoolInfo) public pools;

    event NewPool(string id);
    event UpdatePool(
        string id,
        uint256 r,
        uint256 rToOwner,
        uint256 base,
        uint256 baseToOwner
    );
    event UpdatePoolOwner(string id, address owner);

    event UpdateFeeAddress(address feeAddress);
    event UpdateFee(uint256 fee);

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(address _stakingContract) public initializer {
        require(
            _stakingContract != address(0),
            "DeciblingPoolConfig: invalid pool config address"
        );

        stakingContract = _stakingContract;

        __Ownable_init();
        __UUPSUpgradeable_init();
    }

    function _authorizeUpgrade(
        address newImplementation
    ) internal override onlyOwner {}

    modifier onlyStakingContract() {
        require(
            msg.sender == stakingContract,
            "DeciblingPoolConfig: only staking contract address call"
        );
        _;
    }

    modifier validPool(string memory id) {
        bytes memory idTest = bytes(id);
        require(
            idTest.length != 0,
            "DeciblingPoolConfig: pool length must be > 0"
        );
        _;
    }

    modifier onlyPoolOwner(string memory id) {
        require(
            pools[id].owner == msg.sender || owner() == msg.sender,
            "DeciblingPoolConfig: not pool owner or admin"
        );
        _;
    }

    modifier validAddress(address addr) {
        require(addr != address(0), "DeciblingPoolConfig: not a valid address");
        _;
    }

    function updateCaller(address newCaller) external onlyOwner {
        stakingContract = newCaller;
    }

    /**
     * @dev Sets the Merkle root for minting authorization.
     * @param newMerkleRoot The new Merkle root to be set
     */
    function setMerkleRoot(bytes32 newMerkleRoot) external onlyOwner {
        merkleRoot = newMerkleRoot;
    }

    function newPool(string memory id) external validPool(id) {
        require(
            pools[id].owner == address(0),
            "DeciblingPoolConfig: pool id exists"
        );

        _newPool(id);
    }

    function _newPool(string memory _id) internal virtual {
        pools[_id].owner = msg.sender;

        emit NewPool(_id);
    }

    function updatePool(
        string memory id,
        uint256 _r,
        uint256 _rToOwner
    ) external validPool(id) onlyPoolOwner(id) {
        require(
            _r >= 3 && _r <= 8,
            "DeciblingPoolConfig: invalid return value"
        );
        require(
            _rToOwner <= 5,
            "DeciblingPoolConfig: invalid return to owner value"
        );
        require(
            _rToOwner + _r == 8,
            "DeciblingPoolConfig: total return must be equal 8"
        );

        _updatePool(id, _r, _rToOwner);
    }

    function _updatePool(
        string memory _id,
        uint256 _r,
        uint256 _rToOwner
    ) internal virtual {
        pools[_id].r = _r;
        pools[_id].rToOwner = _rToOwner;
        pools[_id].base = (1e18 * _r) / (86400 * 100 * 365);
        pools[_id].baseToOwner = (1e18 * _rToOwner) / (86400 * 100 * 365);

        emit UpdatePool(
            _id,
            _r,
            _rToOwner,
            pools[_id].base,
            pools[_id].baseToOwner
        );
    }

    function updateUnclaimToOwnerAmount(
        uint256 amount,
        string memory id
    ) external onlyStakingContract validPool(id) {
        pools[id].unclaimToOwner = amount;
    }

    function updatePoolOwner(
        string memory id,
        address poolOwner
    ) external validPool(id) onlyPoolOwner(id) {
        require(
            poolOwner != address(0),
            "DeciblingPoolConfig: not a valid address"
        );

        pools[id].owner = poolOwner;

        emit UpdatePoolOwner(id, poolOwner);
    }

    /**
     @notice Method for updating platform fee address
     @dev Only owner
     @param _feeAddress payable address the address to sends the funds to
     */
    function updatePlatformFeeRecipient(
        address _feeAddress
    ) external onlyOwner validAddress(_feeAddress) {
        feeAddress = _feeAddress;
        emit UpdateFeeAddress(_feeAddress);
    }

    function updatePlatformFee(uint256 _fee) external onlyOwner {
        fee = _fee;
        emit UpdateFee(_fee);
    }
}
