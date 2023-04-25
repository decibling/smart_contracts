// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721URIStorageUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/CountersUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/cryptography/MerkleProofUpgradeable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/Base64.sol";

/**
 * @title DeciblingNFT
 * @dev An upgradeable NFT contract for minting audio-related NFTs, leveraging OpenZeppelin's upgradeable contracts library.
 */
contract DeciblingNFT is
    Initializable,
    ERC721Upgradeable,
    ERC721URIStorageUpgradeable,
    OwnableUpgradeable,
    UUPSUpgradeable
{
    using AddressUpgradeable for address;
    using StringsUpgradeable for uint256;
    using CountersUpgradeable for CountersUpgradeable.Counter;

    CountersUpgradeable.Counter private _tokenIdCounter;

    // The Merkle root of a Merkle tree, used to verify the whitelist for minting permissions
    bytes32 public _merkleRoot;

    // On-chain NFTInfo
    struct NFTInfo {
        string name;
    }

    // Mapping tokenId => AudioInfo
    mapping(uint256 => NFTInfo) public nftInfos;

    // Lock mechanism
    mapping(uint256 => bool) public lockedNFTs;
    address public auctionContractAddress;

    // Mapping to store used URI hashes
    mapping(bytes32 => bool) private usedURIHashes;

    /// @notice Emitted when an NFT is created
    event Minted(uint256 tokenId);

    /// @notice Emitted when an NFT is locked
    event Locked(uint256 tokenId);

    /// @notice Emitted when an NFT is unlocked
    event Unlocked(uint256 tokenId);

    /**
     * @dev Initializes the contract.
     */
    function initialize() public initializer {
        __ERC721_init("Decibling", "dB");
        __ERC721URIStorage_init();
        __Ownable_init();
        __UUPSUpgradeable_init();
    }

    /**
     * @dev Locks the specified NFT to prevent transfers during an ongoing auction.
     * This function can only be called by the auction contract.
     * @param tokenId The unique identifier of the NFT to be locked.
     */
    function lockNFT(uint256 tokenId) external {
        require(
            auctionContractAddress == msg.sender,
            "Only auction contract can lock"
        );
        lockedNFTs[tokenId] = true;
        emit Locked(tokenId);
    }

    /**
     * @dev Unlocks the specified NFT after the auction has ended or setted,
     * allowing transfers to occur again.
     * This function can only be called by the auction contract.
     * @param tokenId The unique identifier of the NFT to be unlocked.
     */
    function unlockNFT(uint256 tokenId) external {
        require(
            auctionContractAddress == msg.sender,
            "Only auction contract can unlock"
        );
        lockedNFTs[tokenId] = false;
        emit Unlocked(tokenId);
    }

    // Override the _beforeTokenTransfer function from the base ERC721 contract
    // to add custom logic for transferring tokens in batches.
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId,
        uint256 batchSize
    ) internal virtual override {
        // Check if the token is locked due to an ongoing auction
        require(
            !lockedNFTs[tokenId],
            "Not allowed to transfer during auction."
        );

        // Call the parent implementation of _beforeTokenTransfer
        super._beforeTokenTransfer(from, to, tokenId, batchSize);
    }

    /**
     * @dev Sets the Merkle root for minting authorization.
     * @param newMerkleRoot The new Merkle root to be set
     */
    function setMerkleRoot(bytes32 newMerkleRoot) external onlyOwner {
        _merkleRoot = newMerkleRoot;
    }

    /**
     * @dev Set the auction contract address.
     * @notice This function can only be called by the contract owner.
     * @param newAuctionContractAddress The new address for the auction contract.
     */
    function setAuctionContractAddress(
        address newAuctionContractAddress
    ) external onlyOwner {
        // Ensure the new address is not the zero address
        require(
            newAuctionContractAddress != address(0),
            "New address cannot be zero address."
        );

        // Update the auction contract address
        auctionContractAddress = newAuctionContractAddress;
    }

    /**
     * @dev Mints a new NFT with the given parameters.
     * @param proof Merkle proof that the caller is authorized to mint
     * @param hashData Hash (SHA256) of the raw NFT file
     * @param name Name of the NFT's metadata
     */
    function mint(bytes32[] calldata proof, string memory hashData, string memory name) external {
        // Validate merkle proof || skip if Merkle Root = 0
        if (_merkleRoot != bytes32(0)) {
            // bytes32 merkleLeaf = keccak256(bytes.concat(keccak256(abi.encode(_msgSender()))));
            bytes32 merkleLeaf = keccak256(abi.encodePacked(_msgSender()));
            require(
                MerkleProofUpgradeable.verify(proof, _merkleRoot, merkleLeaf),
                "Invalid proof"
            );
        }

        // Hash the URI and check if it's unique
        bytes32 uriHash = keccak256(abi.encodePacked(hashData));
        require(!usedURIHashes[uriHash], "URI already exists");

        _tokenIdCounter.increment();
        uint256 tokenId = _tokenIdCounter.current();
        _safeMint(msg.sender, tokenId);
        _setTokenURI(tokenId, hashData);

        // Set storage
        nftInfos[tokenId].name = name;

        // Mark URI hash as used
        usedURIHashes[uriHash] = true;

        emit Minted(tokenId);
    }

    /**
     * @dev Authorizes a new implementation for the upgrade.
     * @param newImplementation Address of the new implementation to authorize
     */
    function _authorizeUpgrade(
        address newImplementation
    ) internal override onlyOwner {}

    // The following functions are overrides required by Solidity.

    /**
     * @dev Burns the specified token.
     * @param tokenId ID of the token to burn
     */
    function _burn(
        uint256 tokenId
    ) internal override(ERC721Upgradeable, ERC721URIStorageUpgradeable) {
        super._burn(tokenId);
    }

    /**
     * @dev Retrieves the token URI for the specified token.
     * @param tokenId ID of the token to get the URI for
     * @return string URI of the token
     */
    function tokenURI(
        uint256 tokenId
    )
        public
        view
        override(ERC721Upgradeable, ERC721URIStorageUpgradeable)
        returns (string memory)
    {
        string memory rawURI = super.tokenURI(tokenId);
        string memory tokenIDstring = tokenId.toString();
        string memory defaultBaseURL = "https://meta.decibling.com/";
        bytes memory dataURI = abi.encodePacked(
            "{",
            '"hash_sha256":"',rawURI,'",',
            '"name":"',nftInfos[tokenId].name,'",',
            '"image":"',string.concat(defaultBaseURL, "image/", tokenIDstring),'",',
            '"external_link":"',string.concat(defaultBaseURL, tokenIDstring),'"',
            "}"
        );
        return
            string(
                abi.encodePacked(
                    "data:application/json;base64,",
                    Base64.encode(dataURI)
                )
            );
    }
}
