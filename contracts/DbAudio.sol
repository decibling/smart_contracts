// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract DbAudio is ERC721, Ownable, ERC721URIStorage {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;
    IERC20 public dbToken;

    uint256 MULTIPLER = 1e18;

    /// @notice global platform fee, assumed to always be to 1 decimal place i.e. 25 = 2.5%
    uint256 public platformFee = 125;

    /// @notice where to send platform fee funds to
    address payable public platformFeeRecipient;

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

    event UpdatePlatformFee(uint256 platformFee);
    event UpdatePlatformFeeRecipient(address payable platformFeeRecipient);
    event CreateNFT(string uri, uint256 index);
    event BidEvent(string uri, uint256 startPrice, uint256 startTime, uint256 endTime);
    event SettleBidding(string uri, address oldowner, address newowner, uint256 price);

    constructor() ERC721("Decibling", "DB") {
        dbToken = IERC20(0xd9145CCE52D386f254917e481eB44e9943F39138);
        platformFeeRecipient = payable(msg.sender);
    }

    function _burn(uint256)
        pure internal
        override(ERC721, ERC721URIStorage)
    {
        revert('Burn functionality is removed');
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721, ERC721URIStorage)
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
        name : internal id
    */
    function createNFT(
        string memory uri,
        string memory name
    ) public returns (uint256) {
        AudioInfo storage currentNFT = listNFT[uri];
        require(keccak256(bytes(currentNFT.url)) != keccak256(bytes(uri)), "2");
        _tokenIds.increment();
        listNFT[uri].owner = msg.sender;
        listNFT[uri].url = uri;
        listNFT[uri].name = name;
        listNFT[uri].status = AudioStatus.NEW;
        listNFT[uri].currentBidding = 0;
        uint256 newItemId = _tokenIds.current();
        _mint(msg.sender, newItemId);
        _setTokenURI(newItemId, uri);
        tokenIdMapping[uri] = newItemId;
        listOwnToken[msg.sender].push(newItemId);
        indexOfToken[newItemId] = listOwnToken[msg.sender].length - 1;
        emit CreateNFT(uri, newItemId);
        return newItemId;
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
        require(endTime > _getNow(), "7");
        require(
            currentNFT.status == AudioStatus.NEW ||
                currentNFT.status == AudioStatus.OWNED,
            "8"
        );

        currentNFT.currentBidding += 1;
        currentNFT.biddingList[currentNFT.currentBidding].winner = address(0);
        currentNFT.biddingList[currentNFT.currentBidding].price = startPrice;
        currentNFT.biddingList[currentNFT.currentBidding].status = startTime >
            _getNow()
            ? BidStatus.START
            : BidStatus.NOTREADY;
        currentNFT.biddingList[currentNFT.currentBidding].startTime = startTime;
        currentNFT.biddingList[currentNFT.currentBidding].endTime = endTime;
        currentNFT.biddingList[currentNFT.currentBidding].currentSession = 0;
        currentNFT.status = AudioStatus.BIDING;
        emit BidEvent(uri, startPrice, startTime, endTime);
    }

    function bid(string memory uri, uint256 _amount) public payable {
        dbToken.transferFrom(msg.sender, address(this), _amount);
        AudioInfo storage currentNFT = listNFT[uri];
        require(keccak256(bytes(currentNFT.url)) == keccak256(bytes(uri)), "4");
        require(currentNFT.status == AudioStatus.BIDING, "10");
        require(currentNFT.currentBidding != 0, "11");
        Bidding storage biddingOfNFT = currentNFT.biddingList[
            currentNFT.currentBidding
        ];
        require(
            biddingOfNFT.startTime <= _getNow() &&
                _getNow() <= biddingOfNFT.endTime,
            "12"
        );
        address lastWinner = biddingOfNFT.winner;
        uint256 lastPrice = biddingOfNFT.price;
        if (lastWinner == address(0)) {
            require(biddingOfNFT.price <= _amount, "13");
        } else {
            require(biddingOfNFT.price < _amount, "13");
        }
        biddingOfNFT.status = BidStatus.BIDING;
        Bid memory bidv = Bid(msg.sender, _amount, _getNow());
        biddingOfNFT.currentSession += 1;
        biddingOfNFT.biddingSessions[biddingOfNFT.currentSession] = bidv;
        // set winner and larger
        biddingOfNFT.winner = msg.sender;
        biddingOfNFT.price = _amount;
        if(lastWinner != address(0)){
            dbToken.transfer(lastWinner, lastPrice);
        }
    }

    function withDrawAll(uint256 money) public onlyOwner {
        payable(msg.sender).transfer(money);
    }

    function settleBiddingSession(string memory uri) public payable {
        AudioInfo storage currentNFT = listNFT[uri];
        require(keccak256(bytes(currentNFT.url)) == keccak256(bytes(uri)), "4");
        require(currentNFT.status == AudioStatus.BIDING, "14");
        require(currentNFT.currentBidding != 0, "11");
        require(platformFeeRecipient != address(0), "fee address");
        Bidding storage biddingOfNFT = currentNFT.biddingList[
            currentNFT.currentBidding
        ];
        require(
            biddingOfNFT.startTime < _getNow() &&
                _getNow() > biddingOfNFT.endTime,
            "15"
        );
        require(
            biddingOfNFT.status == BidStatus.BIDING ||
                currentNFT.status == AudioStatus.BIDING,
            "16"
        );
        uint256 totalPrice = biddingOfNFT.price;
        uint256 platformValue;
        address oldOwner = currentNFT.owner;
        if (biddingOfNFT.winner != address(0)) {
            // send money to owner
            if (platformFee > 0) {
                platformValue = totalPrice * platformFee / 1e3;
            }
            require(platformValue > 0, "pay value");
            safeTransferFrom(
                currentNFT.owner,
                biddingOfNFT.winner,
                tokenIdMapping[uri]
            );
            currentNFT.owner = biddingOfNFT.winner;
            dbToken.transfer(currentNFT.owner, totalPrice-platformValue);
            dbToken.transfer(platformFeeRecipient, platformValue);
            //change owner = winner
        }
        emit SettleBidding(uri, oldOwner, biddingOfNFT.winner, platformValue);
        biddingOfNFT.status = BidStatus.END;
        currentNFT.status = AudioStatus.OWNED;
    }

    function _getNow() internal view virtual returns (uint256) {
        return block.timestamp;
    }

        /**
     @notice Method for updating platform fee
     @dev Only admin
     @param _platformFee uint256 the platform fee to set
     */
    function updatePlatformFee(uint256 _platformFee) external onlyOwner {
        platformFee = _platformFee;
        emit UpdatePlatformFee(_platformFee);
    }

    /**
     @notice Method for updating platform fee address
     @dev Only admin
     @param _platformFeeRecipient payable address the address to sends the funds to
     */
    function updatePlatformFeeRecipient(address payable _platformFeeRecipient)
        external
        onlyOwner
    {
        require(_platformFeeRecipient != address(0), "zero address");

        platformFeeRecipient = _platformFeeRecipient;
        emit UpdatePlatformFeeRecipient(_platformFeeRecipient);
    }
}
