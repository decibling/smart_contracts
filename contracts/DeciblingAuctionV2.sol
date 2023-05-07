// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "./DeciblingNFT.sol";

contract DeciblingAuctionV2 is
    Initializable,
    ReentrancyGuardUpgradeable,
    OwnableUpgradeable,
    UUPSUpgradeable
{
    IERC20 public token;
    DeciblingNFTV2 public nftContract;

    // 10000 == 100%
    uint256 public firstSaleFee;
    uint256 public secondSaleFee;

    address public platformFeeRecipient;

    struct TopBid {
        address user;
        uint256 price;
    }

    struct Auction {
        address winner;
        uint256 startPrice;
        uint256 increment;
        uint256 startTime;
        uint256 endTime;
        bool resulted;
    }

    struct NftAuctionInfo {
        uint256 price;
        uint256 saleCount;
        bool isBidding;
    }

    mapping(uint256 => NftAuctionInfo) public nftAuctionInfos;
    mapping(uint256 => Auction) public auctions;
    mapping(uint256 => TopBid) public topBids;

    event UpdateNftAuctionInfo(NftAuctionInfo nftAuctionInfo);
    event UpdatePlatformFees(uint256 firstSaleFee, uint256 secondSaleFee);
    event UpdatePlatformFeeRecipient(address platformFeeRecipient);
    event CreateBid(
        uint256 itemId,
        uint256 startPrice,
        uint256 increment,
        uint256 startTime,
        uint256 endTime
    );
    event BidPlaced(uint256 itemId, address user, uint256 amount);
    event SettleBid(
        uint256 itemId,
        address oldowner,
        address newowner,
        uint256 totalPrice,
        uint256 platformValue,
        uint256 saleCount
    );
    event UpdateBidEndTime(uint256 itemId, uint256 endtime);

    modifier isOnSale(uint256 itemId) {
        NftAuctionInfo storage currentNFT = nftAuctionInfos[itemId];
        require(
            currentNFT.isBidding == true,
            "DeciblingAuction: This item is not on sale"
        );
        _;
    }

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    /**
     @notice Initialize for the DeciblingAuctionV2 contract
     @param _nftContractAddress address The DeciblingNFT contract address
     @param _tokenAddress address The ERC20 token contract address
     @param _platformFeeRecipient address payable The recipient for the platform fees
     */
    function initialize(
        address _nftContractAddress,
        address _tokenAddress,
        address _platformFeeRecipient
    ) public initializer {
        require(
            _nftContractAddress != address(0) &&
                _tokenAddress != address(0) &&
                _platformFeeRecipient != address(0),
            "DeciblingAuction: Constructor wallets cannot be zero"
        );
        nftContract = DeciblingNFTV2(_nftContractAddress);
        token = IERC20(_tokenAddress);
        platformFeeRecipient = _platformFeeRecipient;

        firstSaleFee = 1250;
        secondSaleFee = 1000;

        __Ownable_init();
        __UUPSUpgradeable_init();
        __ReentrancyGuard_init();
    }

    function _authorizeUpgrade(
        address newImplementation
    ) internal override onlyOwner {}

    /**
     @notice Method for creating a bid. Approve this contract to transfer owner's NFT first.
     @param itemId uint256 the id of the token
     @param startPrice uint256 the start price
     @param increment uint256 price increment
     @param startTime uint256 the start time
     @param endTime uint256 the end time
     */
    function createBidding(
        uint256 itemId,
        uint256 startPrice,
        uint256 increment,
        uint256 startTime,
        uint256 endTime
    ) external {
        address currentNftOwner = nftContract.ownerOf(itemId);
        require(
            currentNftOwner == msg.sender && currentNftOwner != address(0),
            "DeciblingAuction: You did not own this item"
        );
        // Add allowance check for the NFT
        require(
            nftContract.isApprovedForAll(currentNftOwner, address(this)) ||
                nftContract.getApproved(itemId) == address(this),
            "DeciblingAuction: Auction contract not approved to manage the NFT"
        );
        require(
            startTime < endTime,
            "DeciblingAuction: Start time must be before end time"
        );
        require(
            endTime > _getNow(),
            "DeciblingAuction: End time of biding must be in future"
        );
        require(increment > 0, "DeciblingAuction: Increment cannot be zero");
        require(
            endTime >= startTime + 300,
            "DeciblingAuction: end time must be after at least 5 mins"
        );

        NftAuctionInfo storage currentNFT = nftAuctionInfos[itemId];
        require(
            currentNFT.isBidding == false,
            "DeciblingAuction: This item is bidding"
        ); // Check is not bidding
        nftContract.lockNFT(itemId); // Lock item to avoid NFT owner transfer during auction

        auctions[itemId] = Auction({
            winner: address(0),
            startPrice: startPrice,
            increment: increment,
            startTime: startTime,
            endTime: endTime,
            resulted: false
        });

        currentNFT.isBidding = true;

        emit UpdateNftAuctionInfo(currentNFT);
        emit CreateBid(itemId, startPrice, increment, startTime, endTime);
    }

    /**
     @notice Method for placing a bid. Approve this contract to use bidder's ERC20 first.
     @param itemId uint256 the id of the token
     @param _amount uint256 the amount to bid
     */
    function bid(
        uint256 itemId,
        uint256 _amount
    ) public isOnSale(itemId) nonReentrant {
        address currentNftOwner = nftContract.ownerOf(itemId);
        require(
            currentNftOwner != msg.sender,
            "DeciblingAuction: Cannot bid on your own item"
        );
        require(
            auctions[itemId].startTime <= _getNow() &&
                _getNow() <= auctions[itemId].endTime,
            "12"
        );
        require(
            token.transferFrom(msg.sender, address(this), _amount),
            "DeciblingAuction: Transfer failed"
        );

        TopBid storage topBid = topBids[itemId];
        address topBidUser = topBid.user;
        uint256 lastPrice = topBid.price;
        if (topBidUser == address(0)) {
            if (_amount < lastPrice) revert("13");
            // assign top bidder and bid time
            topBids[itemId] = TopBid({user: msg.sender, price: _amount});
        } else {
            if (_amount < lastPrice + auctions[itemId].increment) revert("13");
            // assign top bidder and bid time
            topBids[itemId] = TopBid({user: msg.sender, price: _amount});
            require(token.transfer(topBidUser, lastPrice), "26"); // TODO check
        }

        emit BidPlaced(itemId, msg.sender, _amount);
    }

    /**
    @notice Method for settling a bid
    @param itemId uint256 the id of the token
    */
    function settleBid(uint256 itemId) external nonReentrant {
        address currentNftOwner = nftContract.ownerOf(itemId);
        require(currentNftOwner == msg.sender || owner() == msg.sender, "6");

        NftAuctionInfo storage currentNFT = nftAuctionInfos[itemId];
        require(currentNFT.isBidding == true, "8");

        Auction storage auction = auctions[itemId];
        require(auction.endTime < _getNow(), "12");
        require(!auction.resulted, "DeciblingAuction: this item is settled");

        TopBid storage topBid = topBids[itemId];
        require(
            topBid.user != address(0),
            "DeciblingAuction: invalid top bid user"
        );

        address topBidUser = topBid.user;
        uint256 topBidPrice = topBid.price;

        // Reset TopBid data
        topBids[itemId] = TopBid({user: address(0), price: 0});

        uint256 platformValue = _calculatePlatformFees(
            topBidPrice,
            currentNFT.saleCount
        );
        require(token.transfer(platformFeeRecipient, platformValue), "26");
        require(
            token.transfer(currentNftOwner, topBidPrice - platformValue),
            "DeciblingAuction: transfer failed"
        );

        nftContract.unlockNFT(itemId); // Unlock item to transfer to top bidder
        nftContract.transferFrom(currentNftOwner, topBidUser, itemId);

        address oldOwner = currentNftOwner;

        currentNFT.price = topBid.price;
        currentNFT.saleCount += 1;
        currentNFT.isBidding = false;

        auction.resulted = true;

        emit UpdateNftAuctionInfo(currentNFT);
        emit SettleBid(
            itemId,
            oldOwner,
            topBidUser,
            topBidPrice,
            platformValue,
            currentNFT.saleCount
        );
    }

    /**
    @notice Method for updating bid end time
    @param itemId uint256 the id of the token
    @param newEndTime uint256 the new end time
    */
    function updateBidEndTime(
        uint256 itemId,
        uint256 newEndTime
    ) external isOnSale(itemId) {
        address currentNftOwner = nftContract.ownerOf(itemId);
        require(
            currentNftOwner == msg.sender,
            "DeciblingAuction: Only admin can update bid end time"
        );

        Auction storage auction = auctions[itemId];
        require(
            auction.endTime > _getNow(),
            "DeciblingAuction: This bidding is ended"
        );
        require(
            newEndTime > _getNow(),
            "DeciblingAuction: End time of biding must be in future"
        );

        auction.endTime = newEndTime;

        emit UpdateBidEndTime(itemId, newEndTime);
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
        return (price * platformFees) / 10000;
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
     @param _platformFeeRecipient address the new platform fee recipient
     */
    function updatePlatformFeeRecipient(
        address _platformFeeRecipient
    ) external onlyOwner {
        require(
            _platformFeeRecipient != address(0),
            "DeciblingAuction: Invalid address"
        );
        platformFeeRecipient = _platformFeeRecipient;

        emit UpdatePlatformFeeRecipient(_platformFeeRecipient);
    }
}
