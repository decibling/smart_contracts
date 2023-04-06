// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721URIStorageUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/CountersUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/cryptography/MerkleProofUpgradeable.sol";

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
    bytes32 public _merkleRoot;

    // Mapping to store used URI hashes
    mapping(bytes32 => bool) private usedURIHashes;

    /// @notice Emitted when an NFT is created
    event Minted(uint256 tokenId);

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
     * @dev Sets the Merkle root for minting authorization.
     * @param newMerkleRoot The new Merkle root to be set
     */
    function setMerkleRoot(bytes32 newMerkleRoot) external onlyOwner {
        _merkleRoot = newMerkleRoot;
    }

    /**
     * @dev Mints a new NFT with the given parameters.
     * @param proof Merkle proof that the caller is authorized to mint
     * @param uri URI of the NFT's metadata
     */
    function mint(bytes32[] calldata proof, string memory uri) external {
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
        bytes32 uriHash = keccak256(abi.encodePacked(uri));
        require(!usedURIHashes[uriHash], "URI already exists");

        uint256 tokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();
        _safeMint(msg.sender, tokenId);
        _setTokenURI(tokenId, uri);

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
        return super.tokenURI(tokenId);
    }
}
