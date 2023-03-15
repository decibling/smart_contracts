// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

//remove ReentrancyGuard
//ERC721 > ERC721Upgradeable
//ERC20 > ERC721Upgradeable
//Ownable > OwnableUpgradeable
//Counters > CountersUpgradeable

contract DeciblingAuction is ERC721, Ownable, ReentrancyGuard {
    using SafeMath for uint256;
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;
    IERC20 private token;

    /// @notice global platform fees, assumed to always be to 1 decimal place i.e. 25 = 2.5%
    uint256 public firstSaleFee = 125;
    uint256 public secondSaleFee = 100;

    /// @notice where to send platform fee funds to
    address payable private platformFeeRecipient;

    enum AudioStatus {
        MINTED,
        BIDDING
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
    event UpdateBidEndTime(string uri, uint256 endtime);

    constructor(address _tokenAddress, address payable _platformFeeRecipient) ERC721("Decibling", "dB") {
        require(_tokenAddress != address(0) && _platformFeeRecipient != address(0), "34");
        token = IERC20(_tokenAddress);
        platformFeeRecipient = _platformFeeRecipient;
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
        bytes memory idTest = bytes(uri); // Uses memory
        require(idTest.length != 0, "27");
        bytes memory nameTest = bytes(name); // Uses memory
        require(nameTest.length != 0, "28");
        require(tokenIdMapping[uri] == 0, "2");
        _tokenIds.increment();
        uint256 newItemId = _tokenIds.current();
        _safeMint(msg.sender, newItemId);
        tokenIdMapping[uri] = newItemId;

        listNFT[uri] = AudioInfo({
            owner: msg.sender,
            name: name,
            status: AudioStatus.MINTED,
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
        require(tokenIdMapping[uri] > 0, "26");
        require(currentNFT.owner == msg.sender, "6");
        require(endTime > _getNow(), "7");
        require(currentNFT.status == AudioStatus.MINTED, "8");
        require(increment > 0, "22");
        require(endTime >= startTime + 300, "24"); //end time must be after at least 5 mins

        approve(owner(), itemId);

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

        require(currentNFT.owner != msg.sender, "25");
        require(tokenIdMapping[uri] > 0, "26");
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
        topBid.user = msg.sender;
        topBid.price = _amount;
        topBid.timestamp = _getNow();

        emit BidPlaced(uri, msg.sender, _amount);
    }

    /**
     @notice Method for settle a bid, or cancel if no winner
     @param uri string the platform token uri
     */
    function settleBiddingSession(string memory uri) public payable nonReentrant {
        AudioInfo storage currentNFT = listNFT[uri];
        uint256 itemId = tokenIdMapping[uri];
        
        require(currentNFT.owner == msg.sender || owner() == msg.sender, "6");
        require(tokenIdMapping[uri] > 0, "26");
        require(currentNFT.status == AudioStatus.BIDDING, "8");
        require(platformFeeRecipient != address(0), "19");

        Auction storage auction = auctions[itemId];
        // Ensure auction not already resulted
        require(!auction.resulted, "27");
        require(auction.startTime < _getNow() && _getNow() > auction.endTime, "15");

        // Get info on who the highest bidder is
        TopBid storage topBid = topBids[itemId];
        address winner = topBid.user;
        require(winner != address(0), "29");
        uint256 totalPrice = topBid.price;

        // Result the auction
        auction.resulted = true;

        // Clean up the highest bid
        delete topBids[itemId];

        uint256 platformValue;
        address oldOwner = currentNFT.owner;

        if (currentNFT.saleCount == 0 && firstSaleFee > 0) {
            platformValue = totalPrice.mul(firstSaleFee).div(1e3);
        } else {
            platformValue = totalPrice.mul(secondSaleFee).div(1e3);
        }
        if (platformValue == 0) revert ("20");
        //to seller - old owner
        require(token.transfer(oldOwner, totalPrice-platformValue), "26");
        //to platform
        require(token.transfer(platformFeeRecipient, platformValue), "26");
        //to new owner
        safeTransferFrom(oldOwner, winner, tokenIdMapping[uri]);
        currentNFT.owner = winner;
        currentNFT.price = totalPrice;
        currentNFT.saleCount = currentNFT.saleCount.add(1);
        currentNFT.status = AudioStatus.MINTED;
        auction.winner = winner;

        emit SettleBid(uri, oldOwner, auction.winner, totalPrice, platformValue, currentNFT.saleCount);
    }

    /**
     @notice Update the current end time for an auction
     @dev Only admin
     @dev Auction must exist
     @param uri Token ID of the NFT being auctioned
     @param endtime New end time (unix epoch in seconds)
     */
    function updateBidEndtime(
        string memory uri,
        uint256 endtime
    ) external onlyOwner {
        AudioInfo storage currentNFT = listNFT[uri];
        uint256 itemId = tokenIdMapping[uri];
        
        require(currentNFT.owner == msg.sender || owner() == msg.sender, "6");
        require(tokenIdMapping[uri] > 0, "26");
        require(currentNFT.status == AudioStatus.BIDDING, "8");

        Auction storage auction = auctions[itemId];
        // Ensure auction not already resulted
        require(!auction.resulted, "27");
        // Check the auction has not ended
        require(_getNow() < auction.endTime, "30");

        require(auction.endTime > 0, "31");
        require(
            auction.startTime < endtime,
            "18"
        );
        require(
            endtime > _getNow() + 300,
            "33"
        );

        auction.endTime = endtime;
        emit UpdateBidEndTime(uri, endtime);
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
