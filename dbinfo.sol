// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract DbAudio is ERC721, Ownable, ERC721URIStorage {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;
    uint public sharePercent;
    constructor() ERC721("DbAudio", "DBAU") {
        sharePercent = 0;
    }
    enum BidStatus { NOTREADY, START, BIDING, END}
    enum AudioStatus {NEW, BIDING, SELLING, OWNED}
    struct Bid{
        address user;
        uint256 price;
        uint256 timestamp;
    }
    struct Bidding{
        address winner;
        uint256 price; // 
        BidStatus status;
        uint256 startTime;
        uint256 endTime;
        mapping(uint256 => Bid) biddingSessions;
        uint256 currentSession;
    }
    struct AudioInfo{
        address owner;
        string url;
        uint256 price;
        AudioStatus status;
        mapping(uint256 => Bidding) biddingList;
        uint256 currentBidding;
    }
    mapping(string => AudioInfo) public listNFT;
    
    mapping(string => uint256) public tokenIdMapping;
    function safeMint(address to, uint256 tokenId, string memory uri)
        public
        onlyOwner
    {
        _safeMint(to, tokenId);
        _setTokenURI(tokenId, uri);
    }

    // The following functions are overrides required by Solidity.
    function setSharePercent(uint share) public onlyOwner{
        require(share >= 0 && share <= 100, "Share percent format is not correct");
        sharePercent = share;
    }
    function _burn(uint256 tokenId) internal override(ERC721, ERC721URIStorage) {
        super._burn(tokenId);
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721, ERC721URIStorage)
        returns (string memory)
    {
        return super.tokenURI(tokenId);
    }
/*
        createNFT
        uri : string of resource
        price : WEI
    */
    function createNFT(string memory uri, uint256 price) public returns(uint256){
        AudioInfo storage currentNFT = listNFT[uri];
        require(keccak256(bytes(currentNFT.url)) != keccak256(bytes(uri)), "This NFT is existed");
        _tokenIds.increment();
        listNFT[uri].owner = msg.sender;
        listNFT[uri].url = uri;
        listNFT[uri].price = price;
        listNFT[uri].status = AudioStatus.NEW;
        listNFT[uri].currentBidding = 0;
        uint256 newItemId = _tokenIds.current();
        _mint(msg.sender, newItemId);
        _setTokenURI(newItemId, uri);
        tokenIdMapping[uri] = newItemId;
        return newItemId;
    }
    function setPriceNFT(string memory uri, uint256 price) public{
        AudioInfo storage currentNFT = listNFT[uri];
        require(currentNFT.owner == msg.sender, "You must be own this NFT for setPriceNFT"); 
        currentNFT.price = price;
    }
    function transferNFT(string memory uri, address to) public {
        AudioInfo storage currentNFT = listNFT[uri];
        require(keccak256(bytes(currentNFT.url)) == keccak256(bytes(uri)), "This NFT is not exists");
        require(currentNFT.owner == msg.sender, "You must be own this NFT for transferNFT"); 
        safeTransferFrom(msg.sender, to, tokenIdMapping[uri]);
        currentNFT.owner = to;
    }
    function createBidding(string memory uri, uint256 startPrice, uint256 startTime, uint256 endTime) public {
        require(startTime < endTime, "Start time must be before end time");
        AudioInfo storage currentNFT = listNFT[uri];
        require(keccak256(bytes(currentNFT.url)) == keccak256(bytes(uri)), "This NFT is not exists");
        require(currentNFT.owner == msg.sender, "You must be own this NFT for createBidding");
        require(endTime > block.timestamp, "End time of biding must be in future");
        require(currentNFT.status == AudioStatus.NEW || currentNFT.status == AudioStatus.OWNED, "Audio is not ready status");
        currentNFT.currentBidding += 1;
        currentNFT.biddingList[currentNFT.currentBidding].winner = address(0);
        currentNFT.biddingList[currentNFT.currentBidding].price= startPrice;
        currentNFT.biddingList[currentNFT.currentBidding].status= startTime > block.timestamp? BidStatus.START:BidStatus.NOTREADY;
        currentNFT.biddingList[currentNFT.currentBidding].startTime = startTime;
        currentNFT.biddingList[currentNFT.currentBidding].endTime = endTime;
        currentNFT.biddingList[currentNFT.currentBidding].currentSession= 0;
        currentNFT.status = AudioStatus.BIDING;
    }
    function bid(string memory uri) public payable {
        AudioInfo storage currentNFT = listNFT[uri];
        require(keccak256(bytes(currentNFT.url)) == keccak256(bytes(uri)), "This NFT is not exists");
        require(currentNFT.status == AudioStatus.BIDING, "This NFT is not available for biding due to : STATUS_INCORRECT");
        require(currentNFT.currentBidding != 0, "NFT is not available for biding due to : BIDING_NOT_FOUND");
        Bidding storage biddingOfNFT = currentNFT.biddingList[currentNFT.currentBidding];
        require(biddingOfNFT.startTime <= block.timestamp && block.timestamp <= biddingOfNFT.endTime, "Bidding is over");
        require(biddingOfNFT.price < msg.value, "Bidding price must be larger than current");
        biddingOfNFT.status = BidStatus.BIDING;
        Bid memory bidv = Bid(msg.sender, msg.value, block.timestamp);
        biddingOfNFT.currentSession += 1;
        biddingOfNFT.biddingSessions[biddingOfNFT.currentSession] = bidv;
        // set winner and larger
        address lastWinner = biddingOfNFT.winner;
        uint256 lastPrice = biddingOfNFT.price;
        biddingOfNFT.winner = msg.sender;
        biddingOfNFT.price = msg.value;
        // refund for last bider
        payable(lastWinner).transfer(lastPrice);
    }
    function settleBiddingSession(string memory uri) public {
        AudioInfo storage currentNFT = listNFT[uri];
        require(keccak256(bytes(currentNFT.url)) == keccak256(bytes(uri)), "This NFT is not exists");
        require(currentNFT.status == AudioStatus.BIDING, "This NFT is not available for settle");
        require(currentNFT.currentBidding != 0, "NFT is not available for biding due to : BIDING_NOT_FOUND");
        Bidding storage biddingOfNFT = currentNFT.biddingList[currentNFT.currentBidding];
        require(biddingOfNFT.startTime < block.timestamp && block.timestamp > biddingOfNFT.endTime, "Bidding is not over yet");
        require(biddingOfNFT.status == BidStatus.BIDING, "Bidding is not available for settle");
        if(biddingOfNFT.winner != address(0)){
            // no one bid
                    // send money to owner
            uint256 transferPrice = biddingOfNFT.price;
            if(sharePercent > 0){
                transferPrice = transferPrice * (100 - sharePercent) / 100;
            }
            payable(currentNFT.owner).transfer(transferPrice);
            //change owner = winner
            safeTransferFrom(currentNFT.owner, biddingOfNFT.winner, tokenIdMapping[uri]);
            currentNFT.owner = biddingOfNFT.winner;
        }

        biddingOfNFT.status = BidStatus.END;
        currentNFT.status = AudioStatus.OWNED;
    } 
}
