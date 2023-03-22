// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./DeciblingNFT.sol";

contract DeciblingAuctionV2 is ReentrancyGuard, Ownable {
    using SafeMath for uint256;

    IERC20 private token;
    DeciblingNFT private nftContract;

    uint256 public firstSaleFee = 125;
    uint256 public secondSaleFee = 100;

    address payable private platformFeeRecipient;

    enum AudioStatus {
        NOTMINTED,
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

    struct AudioAuctionInfo {
        uint256 price;
        uint256 saleCount;
        AudioStatus status;
    }

    mapping(string => AudioAuctionInfo) public listNFT;
    // mapping(string => uint256) public tokenIdMapping;
    mapping(uint256 => Auction) public auctions;
    mapping(uint256 => TopBid) public topBids;

    event UpdatePlatformFees(uint256 firstSaleFee, uint256 secondSaleFee);
    event UpdatePlatformFeeRecipient(address payable platformFeeRecipient);
    event CreateBid(
        string uri,
        uint256 startPrice,
        uint256 increment,
        uint256 startTime,
        uint256 endTime
    );
    event BidPlaced(string uri, address user, uint256 amount);
    event SettleBid(
        string uri,
        address oldowner,
        address newowner,
        uint256 totalPrice,
        uint256 platformValue,
        uint256 saleCount
    );
    event UpdateBidEndTime(string uri, uint256 endtime);

    // Modifier to check if the caller is the nft contract
    modifier onlyNftContract() {
        require(
            msg.sender == address(nftContract),
            "Caller is not nft contract"
        );
        _;
    }

    /**
     @notice Constructor for the DeciblingAuctionV2 contract
     @param _nftContractAddress address The DeciblingNFT contract address
     @param _tokenAddress address The ERC20 token contract address
     @param _platformFeeRecipient address payable The recipient for the platform fees
     */
    constructor(
        address _nftContractAddress,
        address _tokenAddress,
        address payable _platformFeeRecipient
    ) {
        require(
            _nftContractAddress != address(0) &&
                _tokenAddress != address(0) &&
                _platformFeeRecipient != address(0),
            "34"
        );
        nftContract = DeciblingNFT(_nftContractAddress);
        token = IERC20(_tokenAddress);
        platformFeeRecipient = _platformFeeRecipient;
    }

    /**
     * @dev Add information of an audio auction to the listNFT mapping.
     * @param uri The URI of the audio to be added.
     * Requirements:
     * - Only the NFT contract can call this function.
     */
    function addAudioAuctionInfo(string calldata uri) external onlyNftContract {
        listNFT[uri] = AudioAuctionInfo({
            price: 0,
            saleCount: 0,
            status: AudioStatus.MINTED
        });
    }

    /**
     @notice Method for creating a bid
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
        uint256 itemId = nftContract.getTokenIdByUri(uri);
        address currentNftOwner = nftContract.getAudioInfoOwner(uri);
        require(itemId > 0, "26");
        AudioAuctionInfo storage currentNFT = listNFT[uri];
        require(currentNftOwner == msg.sender, "6");
        require(startTime < endTime, "18");
        require(endTime > _getNow(), "7");
        require(currentNFT.status == AudioStatus.MINTED, "8"); // TODO Check if needed
        require(increment > 0, "22");
        require(endTime >= startTime + 300, "24"); // end time must be after at least 5 mins

        nftContract.approve(owner(), itemId);

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
     @notice Method for placing a bid
     @param uri string the platform token uri
     @param _amount uint256 the amount to bid
     */
    function bid(
        string memory uri,
        uint256 _amount
    ) public payable nonReentrant {
        uint256 itemId = nftContract.getTokenIdByUri(uri);
        address currentNftOwner = nftContract.getAudioInfoOwner(uri);
        require(itemId > 0, "26");
        AudioAuctionInfo storage currentNFT = listNFT[uri];
        require(currentNftOwner != msg.sender, "25");
        require(currentNFT.status == AudioStatus.BIDDING, "8");

        Auction storage auction = auctions[itemId];
        require(
            auction.startTime <= _getNow() && _getNow() <= auction.endTime,
            "12"
        );
        require(token.transferFrom(msg.sender, address(this), _amount), "26");

        TopBid storage topBid = topBids[itemId];
        address topBidUser = topBid.user;
        uint256 lastPrice = topBid.price;
        if (topBidUser == address(0)) {
            if (_amount < lastPrice) revert("13");
        } else {
            if (_amount < lastPrice + auction.increment) revert("13");
            require(token.transfer(topBidUser, lastPrice), "26");
        }

        // assign top bidder and bid time // TODO: Possible reentrancy vulnerabilities. Avoid state changes after transfer.
        topBids[itemId] = TopBid({
            user: msg.sender,
            price: _amount,
            timestamp: _getNow()
        });
        emit BidPlaced(uri, msg.sender, _amount);
    }

    /**
    @notice Method for settling a bid
    @param uri string the platform token uri
    */
    function settleBid(string calldata uri) external nonReentrant {
        uint256 itemId = nftContract.getTokenIdByUri(uri);
        address currentNftOwner = nftContract.getAudioInfoOwner(uri);

        require(itemId > 0, "26");

        AudioAuctionInfo storage currentNFT = listNFT[uri];
        require(currentNFT.status == AudioStatus.BIDDING, "8");

        Auction storage auction = auctions[itemId];
        require(auction.endTime < _getNow(), "12");
        require(!auction.resulted, "19");

        TopBid storage topBid = topBids[itemId];
        require(topBid.user != address(0), "20");

        uint256 platformValue = _calculatePlatformFees(
            topBid.price,
            currentNFT.saleCount
        );

        require(token.transfer(platformFeeRecipient, platformValue), "26");
        require(
            token.transfer(currentNftOwner, topBid.price.sub(platformValue)),
            "26"
        );

        nftContract.transferFrom(currentNftOwner, topBid.user, itemId);

        address oldOwner = currentNftOwner;
        nftContract.updateAudioInfoOwner(uri, topBid.user);
        // currentNFT.owner = topBid.user;
        currentNFT.price = topBid.price;
        currentNFT.saleCount += 1;
        currentNFT.status = AudioStatus.MINTED;

        auction.resulted = true;

        emit SettleBid(
            uri,
            oldOwner,
            topBid.user,
            topBid.price,
            platformValue,
            currentNFT.saleCount
        );
    }

    /**
    @notice Method for updating bid end time
    @param uri string the platform token uri
    @param newEndTime uint256 the new end time
    */
    function updateBidEndTime(
        string calldata uri,
        uint256 newEndTime
    ) external {
        uint256 itemId = nftContract.getTokenIdByUri(uri);
        address currentNftOwner = nftContract.getAudioInfoOwner(uri);

        require(itemId > 0, "26");
        // AudioAuctionInfo storage currentNFT = listNFT[uri];
        require(currentNftOwner == msg.sender, "6");

        Auction storage auction = auctions[itemId];
        require(auction.endTime > _getNow(), "7");
        require(newEndTime > _getNow(), "7");

        auction.endTime = newEndTime;

        emit UpdateBidEndTime(uri, newEndTime);
    }

    /**
        @notice Method for calculating the platform fees
        @param price uint256 the item price
        @param saleCount uint256 the sale count
    */
    function _calculatePlatformFees(
        uint256 price,
        uint256 saleCount
    ) internal view returns (uint256) {
        uint256 platformFees = saleCount == 0 ? firstSaleFee : secondSaleFee;
        return price.mul(platformFees).div(1000);
    }

    /**
     @notice Method for getting the current time
     */
    function _getNow() internal view returns (uint256) {
        return block.timestamp;
    }

    /**
     @notice Method for updating the platform fees
     @param _firstSaleFee uint256 the new first sale fee
     @param _secondSaleFee uint256 the new second sale fee
     */
    function updatePlatformFees(
        uint256 _firstSaleFee,
        uint256 _secondSaleFee
    ) external onlyOwner {
        firstSaleFee = _firstSaleFee;
        secondSaleFee = _secondSaleFee;

        emit UpdatePlatformFees(_firstSaleFee, _secondSaleFee);
    }

    /**
     @notice Method for updating the platform fee recipient
     @param _platformFeeRecipient address payable the new platform fee recipient
     */
    function updatePlatformFeeRecipient(
        address payable _platformFeeRecipient
    ) external onlyOwner {
        require(_platformFeeRecipient != address(0), "Invalid address");
        platformFeeRecipient = _platformFeeRecipient;

        emit UpdatePlatformFeeRecipient(_platformFeeRecipient);
    }
}
