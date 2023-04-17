// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts-upgradeable/utils/cryptography/MerkleProofUpgradeable.sol";


contract DeciblingPoolConfig is Ownable{
    address public froyToken;
    address public platformFeeRecipient;
    uint256 public platformFee;
    bytes32 public _merkleRoot;
    address public caller;
    constructor() {
    }
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
    event UpdatePool(string id, uint256 r, uint256 r_to_owner, uint256 base, uint256 base_to_owner);
    event UpdatePoolOwner(string id, address owner);
    event UpdatePlatformFeeRecipient(address platformFeeRecipient);
    event UpdatePlatformFee(uint256 platformFee);
    modifier onlyCaller{
        require(msg.sender == caller, "");
        _;
    }

    
    function newPool(string memory _id, uint256 _r, uint256 _r_to_owner) external {
        require(pools[_id].owner == address(0), "pool exists");
        require(_r >= 3 && _r <= 8, "invalid return value");
        require(_r_to_owner <= 5, "invalid return to owner value");
        require(_r_to_owner + _r <= 8, "total return must be less than or equal 8");
        _newPool(_id, _r, _r_to_owner);
    }
    function updateCaller(address newCaller)  external onlyOwner {
        caller = newCaller;
    }
    function updateUnclaimAmount(uint256 unclaim, string memory poolId) external onlyCaller{
        pools[poolId].unclaimToOwner = unclaim;
    }
    function getPoolsInfo(string memory id) public view returns(PoolInfo memory){
        return pools[id];
    }
    function _newPool(string memory _id, uint256 _r, uint256 _r_to_owner) internal virtual{
        bytes memory idTest = bytes(_id); // Uses memory
        require(idTest.length != 0, "invalid pool id");
        pools[_id].owner = msg.sender;
        _updatePool(_id, _r, _r_to_owner);
        emit NewPool(_id);
    }

    function updatePool(string memory id, uint256 _r, uint256 _r_to_owner)
        external
    {
        require(pools[id].owner == msg.sender || owner() == msg.sender, "not pool owner or admin");
        require(_r >= 3 && _r <= 8, "invalid return value");
        require(_r_to_owner <= 5, "invalid return to owner value");
        require(_r_to_owner + _r == 8, "total return must be equal 8");
        
        _updatePool(id, _r, _r_to_owner);
    }

    function updatePoolOwner(string memory _id, address _owner)
        external
    {
        bytes memory idTest = bytes(_id); // Uses memory
        require(idTest.length != 0, "invalid pool id");
        require(pools[_id].owner == msg.sender || owner() == msg.sender, "not pool owner or admin");
        require(_owner != address(0), "21");
        pools[_id].owner = _owner;

        emit UpdatePoolOwner(_id, _owner);
    }
    
    function _updatePool(string memory id, uint256 _r, uint256 _r_to_owner)
        internal virtual
    {
        bytes memory idTest = bytes(id); // Uses memory
        require(idTest.length != 0, "invalid pool id");
        pools[id].r = _r;
        pools[id].rToOwner = _r_to_owner;
        pools[id].base = 1e18 * _r / (86400 * 100 * 365);
        pools[id].baseToOwner = 1e18 * _r_to_owner / (86400 * 100 * 365);
        emit UpdatePool(id, _r, _r_to_owner, pools[id].base, pools[id].baseToOwner);
    }

    /**
     @notice Method for updating platform fee address
     @dev Only admin
     @param _platformFeeRecipient payable address the address to sends the funds to
     */
    function updatePlatformFeeRecipient(address _platformFeeRecipient)
        external onlyOwner
    {
        require(_platformFeeRecipient != address(0), "21");

        platformFeeRecipient = _platformFeeRecipient;
        emit UpdatePlatformFeeRecipient(_platformFeeRecipient);
    }

    function updatePlatformFee(uint256 _platformFee)
        external onlyOwner
    {
        platformFee = _platformFee;
        emit UpdatePlatformFee(_platformFee);
    }
    /**
     * @dev Sets the Merkle root for minting authorization.
     * @param newMerkleRoot The new Merkle root to be set
     */
    function setMerkleRoot(bytes32 newMerkleRoot) external onlyOwner {
        _merkleRoot = newMerkleRoot;
    }
    // function verifyStakablePools(
    //             string memory id, 
    //     bytes32[] calldata proof

    // ) public returns (bool)  {
    //     if (_merkleRoot != bytes32(0)) {
    //         bytes32 merkleLeaf = keccak256(abi.encodePacked(id));
    //         require(
    //             MerkleProofUpgradeable.verify(proof, _merkleRoot, merkleLeaf),
    //             "Invalid proof"
    //         );
    //     }
    //     return true;
    // }
}