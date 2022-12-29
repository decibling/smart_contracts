// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract DbAudio is ERC721, Ownable, ERC721URIStorage {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;
    IERC20 private froyContract;

    /// @notice global platform fees, assumed to always be to 1 decimal place i.e. 25 = 2.5%
    uint256 private firstSaleFee = 125;
    uint256 private secondSaleFee = 100;

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
        uint256 price;
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
        uint256 saleCount;
    }

    mapping(string => AudioInfo) public listNFT;
    mapping(string => uint256) public tokenIdMapping;
    mapping(address => uint256[]) public listOwnToken;
    mapping(uint256 => uint256) public  indexOfToken;

    event UpdatePlatformFees(uint256 firstSaleFee, uint256 secondSaleFee);
    event UpdatePlatformFeeRecipient(address payable platformFeeRecipient);
    event CreateNFT(string uri, uint256 index);
    event BidEvent(string uri, uint256 startPrice, uint256 startTime, uint256 endTime);
    event SettleBidding(string uri, address oldowner, address newowner, uint256 totalPrice, uint256 platformValue, uint256 saleCount);

    constructor() ERC721("Decibling", "DB") {
        froyContract = IERC20(0xAa8ADb51329BA9640D86Aa10b0F374d97A7B31d9);
        platformFeeRecipient = payable(msg.sender);
    }

    function _burn(uint256)
        internal pure 
        override(ERC721, ERC721URIStorage)
    {
        revert("17");
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
        listNFT[uri].saleCount = 0;
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
        require(startTime < endTime, "18");
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
        froyContract.transferFrom(msg.sender, address(this), _amount);
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
            froyContract.transfer(lastWinner, lastPrice);
        }
    }

    function settleBiddingSession(string memory uri) public payable {
        AudioInfo storage currentNFT = listNFT[uri];
        require(keccak256(bytes(currentNFT.url)) == keccak256(bytes(uri)), "4");
        require(currentNFT.status == AudioStatus.BIDING, "14");
        require(currentNFT.currentBidding != 0, "11");
        require(platformFeeRecipient != address(0), "19");
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
            if (currentNFT.saleCount == 0 && firstSaleFee > 0) {
                platformValue = totalPrice * firstSaleFee / 1e3;
            } else {
                platformValue = totalPrice * secondSaleFee / 1e3;
            }

            require(platformValue > 0, "20");
            safeTransferFrom(
                currentNFT.owner,
                biddingOfNFT.winner,
                tokenIdMapping[uri]
            );
            currentNFT.owner = biddingOfNFT.winner;
            currentNFT.price = totalPrice;
            //to seller
            froyContract.transfer(currentNFT.owner, totalPrice-platformValue);
            //to platform
            froyContract.transfer(platformFeeRecipient, platformValue);
        }
        biddingOfNFT.status = BidStatus.END;
        currentNFT.status = AudioStatus.OWNED;
        currentNFT.saleCount += 1;

        emit SettleBidding(uri, oldOwner, biddingOfNFT.winner, totalPrice, platformValue, currentNFT.saleCount);
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
