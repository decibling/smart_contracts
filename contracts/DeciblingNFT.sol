// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./DeciblingAuctionV2.sol";

contract DeciblingNFT is ERC721, Ownable {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;

    // Address of the auction contract
    DeciblingAuctionV2 public auctionContract;

    struct AudioInfo {
        address owner;
        string name;
    }

    mapping(string => AudioInfo) public listNFT;
    mapping(string => uint256) public tokenIdMapping;

    event CreateNFT(string uri, uint256 index);

    // Modifier to check if the caller is the auction contract
    modifier onlyAuction() {
        require(
            msg.sender == address(auctionContract),
            "Caller is not auction contract"
        );
        _;
    }

    constructor() ERC721("Decibling", "dB") {}

    /**
     * @dev Creates a new NFT with the given URI and name.
     * @param uri The URI of the NFT.
     * @param name The name of the NFT.
     */
    function createNFT(string calldata uri, string calldata name) external {
        require(
            address(auctionContract) != address(0),
            "Auction contract not setted"
        );
        bytes memory idTest = bytes(uri);
        require(idTest.length != 0, "27");
        bytes memory nameTest = bytes(name);
        require(nameTest.length != 0, "28");
        require(tokenIdMapping[uri] == 0, "2");
        _tokenIds.increment();
        uint256 newItemId = _tokenIds.current();
        _safeMint(msg.sender, newItemId);
        tokenIdMapping[uri] = newItemId;

        // Added checking URI duplication
        require(listNFT[uri].owner == address(0), "Duplicate uri");
        listNFT[uri] = AudioInfo({owner: msg.sender, name: name});

        auctionContract.addAudioAuctionInfo(uri);

        emit CreateNFT(uri, newItemId);
    }

    /**
     * @dev Returns the token ID associated with the given URI.
     * @param uri The URI of the NFT.
     * @return The token ID associated with the given URI.
     */
    function getTokenIdByUri(string memory uri) public view returns (uint256) {
        return tokenIdMapping[uri];
    }

    /**
     * @dev Returns the owner of the audio info associated with the given URI.
     * @param uri The URI of the NFT.
     * @return The address of the audio info owner.
     */
    function getAudioInfoOwner(
        string memory uri
    ) public view returns (address) {
        AudioInfo storage audioInfo = listNFT[uri];
        return audioInfo.owner;
    }

    /**
     * @dev Sets the auction contract address.
     * @param _auctionContract The new auction address.
     */
    function setAuctionContractAddress(
        address _auctionContract
    ) public onlyOwner {
        require(_auctionContract != address(0), "Invalid auction address");
        auctionContract = DeciblingAuctionV2(_auctionContract);
    }

    /**
     * @dev Updates the owner of the audio info associated with the given URI.
     * @param uri The URI of the NFT.
     * @param newOwner The new owner address.
     */
    function updateAudioInfoOwner(
        string calldata uri,
        address newOwner
    ) public onlyAuction {
        require(newOwner != address(0), "Invalid owner");
        AudioInfo storage audioInfo = listNFT[uri];
        audioInfo.owner = newOwner;
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal {
        super._beforeTokenTransfer(from, to, tokenId, 1);
        // TODO what happen if transfer nft? does AudioInfo.owner change too?
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) public override {
        super.safeTransferFrom(from, to, tokenId, data);
    }

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public override {
        super.transferFrom(from, to, tokenId);
    }
}
