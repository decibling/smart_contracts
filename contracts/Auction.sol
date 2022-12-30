// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract DbAudio is ERC721, Ownable, ReentrancyGuard {
    using SafeMath for uint256;
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;
    IERC20 private token;

    /// @notice global platform fees, assumed to always be to 1 decimal place i.e. 25 = 2.5%
    uint256 private firstSaleFee = 125;
    uint256 private secondSaleFee = 100;

    /// @notice where to send platform fee funds to
    address payable private platformFeeRecipient;

    enum AudioStatus {
        NEW,
        BIDDING,
        OWNED
    }

    struct TopBid {
        address user;
        uint256 price;
        uint256 timestamp;
    }

    struct Auction {
        address winner;
        uint256 startPrice;
        uint256 increment;
        uint256 startTime;
        uint256 endTime;
        bool resulted;
    }

    struct AudioInfo {
        address owner;
        string name;
        uint256 price;
        uint256 saleCount;
        AudioStatus status;
    }

    mapping(string => AudioInfo) public listNFT;
    mapping(string => uint256) public tokenIdMapping;
    mapping(uint256 => Auction) public auctions;
    mapping(uint256 => TopBid) public topBids;

    event UpdatePlatformFees(uint256 firstSaleFee, uint256 secondSaleFee);
    event UpdatePlatformFeeRecipient(address payable platformFeeRecipient);
    event CreateNFT(string uri, uint256 index);
    event CreateBid(string uri, uint256 startPrice, uint256 increment, uint256 startTime, uint256 endTime);
    event BidPlaced(string uri, address user, uint256 amount);
    event SettleBid(string uri, address oldowner, address newowner, uint256 totalPrice, uint256 platformValue, uint256 saleCount);

    constructor() ERC721("Decibling", "DB") {
        token = IERC20(0xd9145CCE52D386f254917e481eB44e9943F39138);
        platformFeeRecipient = payable(msg.sender);
    }

    /*
        createNFT
        uri : string of resource
        name : internal id
    */
    function createNFT(
        string calldata uri,
        string calldata name
    ) external {
        require(tokenIdMapping[uri] == 0, "2");
        _tokenIds.increment();
        uint256 newItemId = _tokenIds.current();
        _safeMint(_msgSender(), newItemId);
        tokenIdMapping[uri] = newItemId;

        listNFT[uri] = AudioInfo({
            owner: _msgSender(),
            name: name,
            status: AudioStatus.NEW,
            price: 0,
            saleCount: 0
        });

        emit CreateNFT(uri, newItemId);
    }

    /**
     @notice Method for create a bid
     @param uri string the platform token uri
     @param startPrice uint256 the start price
     @param increment uint256 price increment
     @param startTime uint256 the start time
     @param endTime uint256 the end time
     */
    function createBidding(
        string calldata uri,
        uint256 startPrice,
        uint256 increment,
        uint256 startTime,
        uint256 endTime
    ) external {
        AudioInfo storage currentNFT = listNFT[uri];
        uint256 itemId = tokenIdMapping[uri];

        require(startTime < endTime, "18");
        require(tokenIdMapping[uri] > 0, "2");
        require(listNFT[uri].owner == _msgSender(), "6");
        require(endTime > _getNow(), "7");
        require(currentNFT.status == AudioStatus.NEW || currentNFT.status == AudioStatus.OWNED, "8");
        require(increment > 0, "22");
        require(endTime >= startTime + 300, "24"); //end time must be after at least 5 mins

        auctions[itemId] = Auction({
            winner: address(0),
            startPrice: startPrice,
            increment: increment,
            startTime: startTime,
            endTime: endTime,
            resulted: false
        });

        currentNFT.status = AudioStatus.BIDDING;

        emit CreateBid(uri, startPrice, increment, startTime, endTime);
    }

    /**
     @notice Method for place a bid
     @param uri string the platform token uri
     @param _amount uint256 the amount to bid
     */
    function bid(string memory uri, uint256 _amount) public payable nonReentrant {
        AudioInfo storage currentNFT = listNFT[uri];
        uint256 itemId = tokenIdMapping[uri];

        require(tokenIdMapping[uri] > 0, "2");
        require(currentNFT.status == AudioStatus.BIDDING, "8");
        
        Auction storage auction = auctions[itemId];
        require(auction.startTime <= _getNow() && _getNow() <= auction.endTime, "12");
        require(token.transferFrom(msg.sender, address(this), _amount), "26");

        TopBid storage topBid = topBids[itemId];
        address topBidUser = topBid.user;
        uint256 lastPrice = topBid.price;
        if (topBidUser == address(0)) {
            if (_amount < lastPrice) revert ("13");
        } else {
            if (_amount < lastPrice + auction.increment) revert ("13");
            require(token.transfer(topBidUser, lastPrice), "26");
        }

        // assign top bidder and bid time
        topBid.user = _msgSender();
        topBid.price = _amount;
        topBid.timestamp = _getNow();

        emit BidPlaced(uri, _msgSender(), _amount);
    }

    /**
     @notice Method for settle a bid, or cancel if no winner
     @param uri string the platform token uri
     */
    function settleBiddingSession(string memory uri) public payable nonReentrant {
        AudioInfo storage currentNFT = listNFT[uri];
        uint256 itemId = tokenIdMapping[uri];
        
        require(currentNFT.owner == _msgSender() || owner() == _msgSender(), "6");
        require(tokenIdMapping[uri] > 0, "2");
        require(currentNFT.status == AudioStatus.BIDDING, "8");
        require(platformFeeRecipient != address(0), "19");

        Auction storage auction = auctions[itemId];
        // Ensure auction not already resulted
        require(!auction.resulted, "27");
        require(auction.startTime < _getNow() && _getNow() > auction.endTime, "15");

        // Get info on who the highest bidder is
        TopBid storage topBid = topBids[itemId];
        address winner = topBid.user;

        // Result the auction
        auction.resulted = true;

        // Clean up the highest bid
        delete topBids[itemId];

        uint256 totalPrice = topBid.price;
        uint256 platformValue;
        address oldOwner = currentNFT.owner;
        if (winner != address(0)) {
            if (currentNFT.saleCount == 0 && firstSaleFee > 0) {
                platformValue = totalPrice.mul(firstSaleFee).div(1e3);
            } else {
                platformValue = totalPrice.mul(secondSaleFee).div(1e3);
            }
            if (platformValue > 0) revert ("20");
            //to seller - old owner
            require(token.transfer(oldOwner, totalPrice-platformValue), "26");
            //to platform
            require(token.transfer(platformFeeRecipient, platformValue), "26");
            //to new owner
            safeTransferFrom(oldOwner, winner, tokenIdMapping[uri]);
            currentNFT.owner = winner;
            currentNFT.price = totalPrice;
            currentNFT.status = AudioStatus.OWNED;
            currentNFT.saleCount = currentNFT.saleCount.add(1);

            auction.winner = winner;

            emit SettleBid(uri, oldOwner, auction.winner, totalPrice, platformValue, currentNFT.saleCount);
        } else {
            currentNFT.status = AudioStatus.NEW;
        }

    }

    function _getNow() internal view virtual returns (uint256) {
        return block.timestamp;
    }

    /**
     @notice Method for updating platform fees
     @dev Only admin
     @param _firstSaleFee uint256 the platform first sale fee to set
     @param _secondSaleFee uint256 the platform second sale fee to set
     */
    function updatePlatformFees(uint256 _firstSaleFee, uint256 _secondSaleFee) external onlyOwner {
        firstSaleFee = _firstSaleFee;
        secondSaleFee = _secondSaleFee;
        emit UpdatePlatformFees(_firstSaleFee, _secondSaleFee);
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
        require(_platformFeeRecipient != address(0), "21");

        platformFeeRecipient = _platformFeeRecipient;
        emit UpdatePlatformFeeRecipient(_platformFeeRecipient);
    }
}
