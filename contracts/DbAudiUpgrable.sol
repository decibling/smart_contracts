// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721URIStorageUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/utils/CountersUpgradeable.sol";


contract DbAudiUpgrable is ERC721Upgradeable, OwnableUpgradeable, ERC721URIStorageUpgradeable {
    using  CountersUpgradeable for CountersUpgradeable.Counter;
    CountersUpgradeable.Counter private _tokenIdCounter;
    uint256 public sharePercent;
    uint256 public biddingFee;
    function initialize() initializer public {
        __ERC721_init("Decibling", "DB");
        __ERC721URIStorage_init();
        __Ownable_init();
                sharePercent = 0;
        biddingFee = 3000000;

    }



    enum BidStatus {
        NOTREADY,
        START,
        BIDING,
        END
    }
    enum AudioStatus {
        NEW,
        BIDING,
        SELLING,
        OWNED
    }
    struct Bid {
        address user;
        uint256 price;
        uint256 timestamp;
    }
    struct Bidding {
        address winner;
        uint256 price; //\\
        BidStatus status;
        uint256 startTime;
        uint256 endTime;
        uint256 currentSession;
        mapping(uint256 => Bid) biddingSessions;
    }
    struct AudioInfo {
        address owner;
        string url;
        string name;
        uint256 price;
        AudioStatus status;
        mapping(uint256 => Bidding) biddingList;
        uint256 currentBidding;
    }
    mapping(string => AudioInfo) public listNFT;
    mapping(string => uint256) public tokenIdMapping;
    mapping(address => uint256[]) public listOwnToken;
    mapping(uint256 => uint256) public  indexOfToken;

    function _baseURI() internal pure override returns (string memory) {
        return "https://meta.decibling.com/nft/";

    }
    function _burn(uint256 tokenId)
        internal
        override(ERC721Upgradeable, ERC721URIStorageUpgradeable)
    {
        super._burn(tokenId);
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721Upgradeable, ERC721URIStorageUpgradeable)
        returns (string memory)
    {
        return super.tokenURI(tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) public override {
        listOwnToken[to].push(tokenId);
        listOwnToken[from][indexOfToken[tokenId]] = listOwnToken[from][
            listOwnToken[from].length - 1
        ];
        listOwnToken[from].pop();
        indexOfToken[tokenId] = listOwnToken[to].length - 1;
        return super.safeTransferFrom(from, to, tokenId, _data);
    }

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        listOwnToken[to].push(tokenId);
        listOwnToken[from][indexOfToken[tokenId]] = listOwnToken[from][
            listOwnToken[from].length - 1
        ];
        listOwnToken[from].pop();
        indexOfToken[tokenId] = listOwnToken[to].length - 1;
        super.transferFrom(from, to, tokenId);
    }

    /*
        createNFT
        uri : string of resource
        price : WEI
    */
    function createNFT(
        string memory uri,
        string memory name,
        uint256 price
    ) public returns (uint256) {
        AudioInfo storage currentNFT = listNFT[uri];
        require(keccak256(bytes(currentNFT.url)) != keccak256(bytes(uri)), "2");
        uint256 newItemId = _tokenIdCounter.current();
        _tokenIdCounter.increment();
        listNFT[uri].owner = msg.sender;
        listNFT[uri].url = uri;
        listNFT[uri].name = name;
        listNFT[uri].price = price;
        listNFT[uri].status = AudioStatus.NEW;
        listNFT[uri].currentBidding = 0;
        _safeMint(msg.sender, newItemId);
        _setTokenURI(newItemId, uri);
        tokenIdMapping[uri] = newItemId;
        listOwnToken[msg.sender].push(newItemId);
        indexOfToken[newItemId] = listOwnToken[msg.sender].length - 1;
        return newItemId;
    }
    // The following functions are overrides required by Solidity.
    function setSharePercent(uint256 share) public onlyOwner {
        require(share >= 0 && share <= 100, "1");
        sharePercent = share;
    }



    function setPriceNFT(string memory uri, uint256 price) public {
        AudioInfo storage currentNFT = listNFT[uri];
        require(currentNFT.owner == msg.sender, "3");
        currentNFT.price = price;
    }

    function transferNFT(string memory uri, address to) public {
        AudioInfo storage currentNFT = listNFT[uri];
        require(keccak256(bytes(currentNFT.url)) == keccak256(bytes(uri)), "4");
        require(currentNFT.owner == msg.sender, "5");
        safeTransferFrom(msg.sender, to, tokenIdMapping[uri]);
        currentNFT.owner = to;
    }

    function createBidding(
        string memory uri,
        uint256 startPrice,
        uint256 startTime,
        uint256 endTime
    ) public payable {
        require(startTime < endTime, "Start time must be before end time");
        AudioInfo storage currentNFT = listNFT[uri];
        require(keccak256(bytes(currentNFT.url)) == keccak256(bytes(uri)), "4");
        require(currentNFT.owner == msg.sender, "6");
        require(endTime > block.timestamp, "7");
        require(
            currentNFT.status == AudioStatus.NEW ||
                currentNFT.status == AudioStatus.OWNED,
            "8"
        );
        require(biddingFee <= msg.value, "9");

        currentNFT.currentBidding += 1;
        currentNFT.biddingList[currentNFT.currentBidding].winner = address(0);
        currentNFT.biddingList[currentNFT.currentBidding].price = startPrice;
        currentNFT.biddingList[currentNFT.currentBidding].status = startTime >
            block.timestamp
            ? BidStatus.START
            : BidStatus.NOTREADY;
        currentNFT.biddingList[currentNFT.currentBidding].startTime = startTime;
        currentNFT.biddingList[currentNFT.currentBidding].endTime = endTime;
        currentNFT.biddingList[currentNFT.currentBidding].currentSession = 0;
        currentNFT.status = AudioStatus.BIDING;
    }

    function bid(string memory uri) public payable {
        AudioInfo storage currentNFT = listNFT[uri];
        require(keccak256(bytes(currentNFT.url)) == keccak256(bytes(uri)), "4");
        require(currentNFT.status == AudioStatus.BIDING, "10");
        require(currentNFT.currentBidding != 0, "11");
        Bidding storage biddingOfNFT = currentNFT.biddingList[
            currentNFT.currentBidding
        ];
        require(
            biddingOfNFT.startTime <= block.timestamp &&
                block.timestamp <= biddingOfNFT.endTime,
            "12"
        );
        require(biddingOfNFT.price < msg.value, "13");
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

    function setbiddingFee(uint256 money) public onlyOwner {
        biddingFee = money;
    }

    function withDrawAll(uint256 money) public onlyOwner {
        payable(msg.sender).transfer(money);
    }

    function settleBiddingSession(string memory uri) public {
        AudioInfo storage currentNFT = listNFT[uri];
        require(keccak256(bytes(currentNFT.url)) == keccak256(bytes(uri)), "4");
        require(currentNFT.status == AudioStatus.BIDING, "14");
        require(currentNFT.currentBidding != 0, "11");
        Bidding storage biddingOfNFT = currentNFT.biddingList[
            currentNFT.currentBidding
        ];
        require(
            biddingOfNFT.startTime < block.timestamp &&
                block.timestamp > biddingOfNFT.endTime,
            "15"
        );
        require(
            biddingOfNFT.status == BidStatus.BIDING ||
                currentNFT.status == AudioStatus.BIDING,
            "16"
        );
        if (biddingOfNFT.winner != address(0)) {
            // no one bid
            // send money to owner
            uint256 transferPrice = biddingOfNFT.price;
            if (sharePercent > 0) {
                transferPrice = (transferPrice * (100 - sharePercent)) / 100;
            }
            payable(currentNFT.owner).transfer(transferPrice);
            //change owner = winner
            safeTransferFrom(
                currentNFT.owner,
                biddingOfNFT.winner,
                tokenIdMapping[uri]
            );
            currentNFT.owner = biddingOfNFT.winner;
        }

        biddingOfNFT.status = BidStatus.END;
        currentNFT.status = AudioStatus.OWNED;
    }
}
