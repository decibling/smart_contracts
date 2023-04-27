// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/utils/cryptography/MerkleProofUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract DeciblingStaking is
    Initializable,
    OwnableUpgradeable,
    UUPSUpgradeable
{
    uint256 private DEFAULT_HARD_CAP = 10_000_000 * 1e18;

    IERC20 public token;
    bytes32 public merkleRoot;

    struct StakeInfo {
        uint256 totalDeposit;
        uint256 depositTime;
    }
    struct PoolInfo {
        address owner;
        uint256 hardCap;
        uint256 totalDeposit;
        uint8 rToOwner;
        uint8 r;
        bool isDefault;
    }

    mapping(string => mapping(address => StakeInfo)) public stakers;
    mapping(string => PoolInfo) public pools;

    event NewPool(string poolId);
    event UpdatePool(string poolId, uint8 r, uint8 rToOwner, bool isDefault);
    event UpdatePoolOwner(string poolId, address owner);
    event Stake(string poolId, address user, uint256 amount);
    event Unstake(string poolId, address user, uint256 amount);
    event Claim(string poolId, address user, uint256 profitAmount);

    modifier validPool(string memory id) {
        bytes memory idTest = bytes(id);
        require(
            idTest.length != 0,
            "DeciblingStaking: pool length must be > 0"
        );
        _;
    }

    modifier existPool(string memory id) {
        require(
            pools[id].owner != address(0),
            "DeciblingStaking: this pool is not exist"
        );
        _;
    }

    modifier validAmount(uint256 amount) {
        require(amount > 0, "DeciblingStaking: amount must be > 0");
        _;
    }

    modifier onlyPoolOwnerOrAdmin(string memory id) {
        require(
            pools[id].owner == msg.sender || owner() == msg.sender,
            "DeciblingPoolConfig: not pool owner or admin"
        );
        _;
    }

    modifier validProof(bytes32[] calldata proof) {
        // Validate merkle proof || skip if Merkle Root = 0
        if (merkleRoot != bytes32(0)) {
            bytes32 merkleLeaf = keccak256(abi.encodePacked(_msgSender()));
            require(
                MerkleProofUpgradeable.verify(proof, merkleRoot, merkleLeaf),
                "Invalid proof"
            );
        }
        _;
    }

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(address froyAddr) public initializer {
        token = IERC20(froyAddr);

        __Ownable_init();
        __UUPSUpgradeable_init();
    }

    function _authorizeUpgrade(
        address newImplementation
    ) internal override onlyOwner {}

    /**
     * @dev Sets the Merkle root for minting authorization.
     * @param newMerkleRoot The new Merkle root to be set
     */
    function setMerkleRoot(bytes32 newMerkleRoot) external onlyOwner {
        merkleRoot = newMerkleRoot;
    }

    function newPool(
        bytes32[] calldata proof,
        string memory id
    ) external validPool(id) validProof(proof) {
        require(
            pools[id].owner == address(0),
            "DeciblingPoolConfig: pool id exists"
        );

        _newPool(id);
    }

    function setDefaultPool() external onlyOwner {
        string memory pid = "decibling_pool";
        _newPool(pid);
        _updatePool(pid, 2, 0, true);
    }

    function setPoolHardCap(
        string memory id,
        uint256 cap
    ) external onlyOwner validPool(id) existPool(id) validAmount(cap) {
        pools[id].hardCap = cap;
    }

    function _newPool(string memory _id) internal virtual {
        pools[_id].owner = msg.sender;

        emit NewPool(_id);
    }

    function updatePool(
        bytes32[] calldata proof,
        string memory id,
        uint8 _r,
        uint8 _rToOwner
    )
        external
        validPool(id)
        onlyPoolOwnerOrAdmin(id)
        existPool(id)
        validProof(proof)
    {
        require(
            _r >= 3 && _r <= 8,
            "DeciblingPoolConfig: invalid return value"
        );
        require(
            _rToOwner >= 0 && _rToOwner <= 5,
            "DeciblingPoolConfig: invalid return to owner value"
        );
        require(
            _rToOwner + _r == 8,
            "DeciblingPoolConfig: total return must be equal 8"
        );

        _updatePool(id, _r, _rToOwner, false);
    }

    function _updatePool(
        string memory _id,
        uint8 _r,
        uint8 _rToOwner,
        bool _isDefault
    ) internal virtual {
        pools[_id].r = _r;
        pools[_id].rToOwner = _rToOwner;
        pools[_id].isDefault = _isDefault;
        pools[_id].hardCap = DEFAULT_HARD_CAP;

        emit UpdatePool(_id, _r, _rToOwner, _isDefault);
    }

    function updatePoolOwner(
        bytes32[] calldata proof,
        string memory id,
        address poolOwner
    )
        external
        validPool(id)
        onlyPoolOwnerOrAdmin(id)
        existPool(id)
        validProof(proof)
    {
        require(
            poolOwner != address(0),
            "DeciblingStaking: not a valid address"
        );

        _updatePoolOwner(id, poolOwner);
    }

    function _updatePoolOwner(
        string memory id,
        address poolOwner
    ) internal virtual {
        pools[id].owner = poolOwner;

        emit UpdatePoolOwner(id, poolOwner);
    }

    function stake(
        string memory id,
        uint256 amount
    ) external validPool(id) validAmount(amount) existPool(id) {
        require(
            pools[id].totalDeposit + amount <= pools[id].hardCap,
            "DeciblingStaking: Hard cap reached, cannot stake more on this pool"
        );
        require(
            token.transferFrom(msg.sender, address(this), amount),
            "DeciblingStaking: Transfer failed"
        );

        _stake(id, amount);
    }

    function _stake(string memory id, uint256 amount) internal virtual {
        stakers[id][msg.sender].depositTime = _getNow();
        stakers[id][msg.sender].totalDeposit += amount;
        pools[id].totalDeposit += amount;

        emit Stake(id, msg.sender, amount);
    }

    function unstake(
        string memory id,
        uint256 amount
    ) external validPool(id) validAmount(amount) existPool(id) {
        require(
            stakers[id][msg.sender].totalDeposit != 0,
            "DeciblingStaking: Your current stake amount of this pool is 0"
        );
        require(
            amount <= stakers[id][msg.sender].totalDeposit,
            "DeciblingStaking: The amount must be smaller than your current staked"
        );
        require(
            token.transfer(msg.sender, amount),
            "DeciblingStaking: Transfer failed"
        );

        _unstake(id, amount);
    }

    function _unstake(string memory id, uint256 amount) internal virtual {
        stakers[id][msg.sender].totalDeposit -= amount;
        stakers[id][msg.sender].depositTime = _getNow();
        pools[id].totalDeposit -= amount;

        emit Unstake(id, msg.sender, amount);
    }

    function claim(string memory id) external validPool(id) existPool(id) {
        emit Claim(id, msg.sender, 0);
    }

    function _getNow() internal view virtual returns (uint256) {
        return block.timestamp;
    }
}
