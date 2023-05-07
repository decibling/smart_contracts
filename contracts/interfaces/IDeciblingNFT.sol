// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

interface IDeciblingNFT {
    event AdminChanged(address previousAdmin, address newAdmin);
    event Approval(
        address indexed owner,
        address indexed approved,
        uint256 indexed tokenId
    );
    event ApprovalForAll(
        address indexed owner,
        address indexed operator,
        bool approved
    );
    event BeaconUpgraded(address indexed beacon);
    event Initialized(uint8 version);
    event Locked(uint256 tokenId);
    event Minted(uint256 tokenId);
    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );
    event Transfer(
        address indexed from,
        address indexed to,
        uint256 indexed tokenId
    );
    event Unlocked(uint256 tokenId);
    event Upgraded(address indexed implementation);

    function _merkleRoot() external view returns (bytes32);

    function approve(address to, uint256 tokenId) external;

    function auctionContractAddress() external view returns (address);

    function balanceOf(address owner) external view returns (uint256);

    function getApproved(uint256 tokenId) external view returns (address);

    function initialize() external;

    function isApprovedForAll(address owner, address operator)
        external
        view
        returns (bool);

    function lockNFT(uint256 tokenId) external;

    function lockedNFTs(uint256) external view returns (bool);

    function mint(
        bytes32[] memory proof,
        string memory hashData,
        string memory name
    ) external;

    function name() external view returns (string memory);

    function nftInfos(uint256) external view returns (string memory name);

    function owner() external view returns (address);

    function ownerOf(uint256 tokenId) external view returns (address);

    function proxiableUUID() external view returns (bytes32);

    function renounceOwnership() external;

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) external;

    function setApprovalForAll(address operator, bool approved) external;

    function setAuctionContractAddress(address newAuctionContractAddress)
        external;

    function setMerkleRoot(bytes32 newMerkleRoot) external;

    function supportsInterface(bytes4 interfaceId) external view returns (bool);

    function symbol() external view returns (string memory);

    function tokenURI(uint256 tokenId) external view returns (string memory);

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    function transferOwnership(address newOwner) external;

    function unlockNFT(uint256 tokenId) external;

    function upgradeTo(address newImplementation) external;

    function upgradeToAndCall(address newImplementation, bytes memory data)
        external
        payable;
}
