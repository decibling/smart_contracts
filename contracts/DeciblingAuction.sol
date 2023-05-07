// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "./interfaces/IDeciblingNFT.sol";

contract DeciblingAuction is
    Initializable,
    ReentrancyGuardUpgradeable,
    OwnableUpgradeable,
    UUPSUpgradeable
{
    IERC20 public token;
    IDeciblingNFT public nftContract;

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

    mapping(uint256 => Auction) public auctions;
    mapping(uint256 => TopBid) public topBids;
    mapping(uint256 => bool) public secondarySale;

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
        uint256 platformValue
    );
    event UpdateBidEndTime(uint256 itemId, uint256 endtime);
    event CancelBid(uint256 itemId);

    modifier isOnSale(uint256 itemId) {
        require(auctions[itemId].endTime > 0, "This item is not on sale");
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
            "Constructor wallets cannot be zero"
        );
        nftContract = IDeciblingNFT(_nftContractAddress);
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
    function createBid(
        uint256 itemId,
        uint256 startPrice,
        uint256 increment,
        uint256 startTime,
        uint256 endTime
    ) external {
        require(
            nftContract.ownerOf(itemId) == msg.sender,
            "You did not own this item"
        );
        require(increment > 0, "Increment cannot be zero");
        require(auctions[itemId].endTime == 0, "This item is bidding");
        require(
            endTime >= startTime + 300,
            "end time must be after at least 5 mins"
        );
        require(
            endTime >= _getNow(),
            "End time of bidding must be in the future"
        );

        require(
            nftContract.isApprovedForAll(
                nftContract.ownerOf(itemId),
                address(this)
            ) || nftContract.getApproved(itemId) == address(this),
            "Auction contract not approved to manage the NFT"
        );
        nftContract.lockNFT(itemId); // Lock item to avoid NFT owner transfer during auction

        auctions[itemId] = Auction({
            winner: address(0),
            startPrice: startPrice,
            increment: increment,
            startTime: startTime,
            endTime: endTime,
            resulted: false
        });

        emit CreateBid(itemId, startPrice, increment, startTime, endTime);
    }

    /**
     @notice Method for placing a bid. Approve this contract to use bidder's ERC20 first.
     @param itemId uint256 the id of the token
     @param amount uint256 the amount to bid
     */
    function bid(
        uint256 itemId,
        uint256 amount
    ) public isOnSale(itemId) nonReentrant {
        require(
            nftContract.ownerOf(itemId) != msg.sender,
            "Cannot bid on your own item"
        );
        require(
            auctions[itemId].startTime <= _getNow() &&
                _getNow() <= auctions[itemId].endTime,
            "Cannot bid on this item this time"
        );

        require(
            token.transferFrom(msg.sender, address(this), amount),
            "Transfer failed"
        );

        address topBidUser = topBids[itemId].user;
        uint256 lastPrice = topBids[itemId].price;

        //refund to top bid user
        if (topBidUser != address(0)) {
            require(token.transfer(topBidUser, lastPrice), "Transfer failed");
            lastPrice += auctions[itemId].increment;
        }

        require(
            amount > lastPrice,
            "Bidding price must be larger than current"
        );
        topBids[itemId] = TopBid({user: msg.sender, price: amount});

        emit BidPlaced(itemId, msg.sender, amount);
    }

    /**
    @notice Method for settling a bid
    @param itemId uint256 the id of the token
    */
    function settleBid(
        uint256 itemId
    ) external nonReentrant isOnSale(itemId) {
        require(
            nftContract.ownerOf(itemId) == msg.sender || owner() == msg.sender,
            "You did not own this item or not an admin"
        );
        require(
            auctions[itemId].endTime < _getNow(),
            "Bidding is not ended yet"
        );
        require(!auctions[itemId].resulted, "This item is resulted");

        address topBidUser = topBids[itemId].user;
        require(
            topBidUser != address(0),
            "Please cancel this bid instead of settle"
        );
        uint256 topBidPrice = topBids[itemId].price;
        address currentNftOwner = nftContract.ownerOf(itemId);
        uint256 platformValue = _calculatePlatformFees(itemId, topBidPrice);
        require(
            token.transfer(platformFeeRecipient, platformValue),
            "Transfer failed to platform"
        );
        require(
            token.transfer(currentNftOwner, topBidPrice - platformValue),
            "Transfer failed to old owner"
        );
        nftContract.unlockNFT(itemId); // Unlock item to transfer to top bidder
        nftContract.transferFrom(currentNftOwner, topBidUser, itemId);

        // Reset TopBid data
        delete topBids[itemId];
        auctions[itemId].resulted = true;

        // Set secondary sale
        secondarySale[itemId] = true;

        emit SettleBid(
            itemId,
            currentNftOwner,
            topBidUser,
            topBidPrice,
            platformValue
        );

        // Remove auction
        delete auctions[itemId];
    }

    /**
    @notice Method for cancelling a bid
    @param itemId uint256 the id of the token
    */
    function cancelBid(
        uint256 itemId
    ) external nonReentrant isOnSale(itemId) {
                require(
            nftContract.ownerOf(itemId) == msg.sender || owner() == msg.sender,
            "You did not own this item or not an admin"
        );
        require(!auctions[itemId].resulted, "this item is settled");

        TopBid storage topBid = topBids[itemId];
        //refund to top bid user
        if (topBid.user != address(0)) {
            require(
                token.transfer(topBid.user, topBid.price),
                "Transfer failed"
            );
            //reset topbid data
            delete topBids[itemId];
        }

        nftContract.unlockNFT(itemId); // Unlock item
        delete auctions[itemId];

        emit CancelBid(itemId);
    }

    /**
    @notice Method for updating bid end time
    @param itemId uint256 the id of the token
    @param newEndTime uint256 the new end time
    */
    function updateBidEndTime(
        uint256 itemId,
        uint256 newEndTime
    ) external isOnSale(itemId) onlyOwner {
        Auction storage auction = auctions[itemId];
        require(auction.endTime > _getNow(), "This bidding is ended");
        require(
            newEndTime > _getNow(),
            "End time of bidding must be in future"
        );

        auction.endTime = newEndTime;

        emit UpdateBidEndTime(itemId, newEndTime);
    }

    /**
        @notice Method for calculating the platform fees
        @param itemId uint256 the item price
        @param price uint256 the sale count
    */
    function _calculatePlatformFees(
        uint256 itemId,
        uint256 price
    ) internal view returns (uint256) {
        uint256 platformFees = (
            !secondarySale[itemId] ? firstSaleFee : secondSaleFee
        );
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
        require(_platformFeeRecipient != address(0), "Invalid address");
        platformFeeRecipient = _platformFeeRecipient;

        emit UpdatePlatformFeeRecipient(_platformFeeRecipient);
    }
}
