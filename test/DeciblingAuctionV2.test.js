const { expect } = require("chai");
const { ethers } = require("hardhat");
const { BigNumber } = ethers;

describe("DeciblingAuctionV2", function () {
    let DeciblingNFT, deciblingNFT, DeciblingAuctionV2, deciblingAuctionV2, token, accounts, owner, bidder1, bidder2, platformFeeRecipient;

    beforeEach(async () => {
        accounts = await ethers.getSigners();
        owner = accounts[0];
        bidder1 = accounts[1];
        bidder2 = accounts[2];
        platformFeeRecipient = accounts[3];

        // Deploy DeciblingNFT contract
        DeciblingNFT = await ethers.getContractFactory("DeciblingNFT");
        deciblingNFT = await DeciblingNFT.deploy();
        await deciblingNFT.deployed();

        // Deploy ERC20 token
        const Token = await ethers.getContractFactory("MyToken");
        token = await Token.deploy();
        await token.deployed();

        // Deploy DeciblingAuctionV2 contract
        DeciblingAuctionV2 = await ethers.getContractFactory("DeciblingAuctionV2");
        deciblingAuctionV2 = await upgrades.deployProxy(DeciblingAuctionV2, [deciblingNFT.address, token.address, platformFeeRecipient.address]);
        await deciblingAuctionV2.deployed();
    });

    describe("initialize", function () {
        it("should have correct initial values", async () => {
            expect(await deciblingAuctionV2.owner()).to.equal(owner.address);
            expect(await deciblingAuctionV2.firstSaleFee()).to.equal(1250);
            expect(await deciblingAuctionV2.secondSaleFee()).to.equal(1000);
        });
    });

    describe("createBidding", function () {
        let itemId = 0;
        let startPrice = BigNumber.from("1000000000000000000");
        let increment = BigNumber.from("100000000000000000");
        let startTime = Math.floor(Date.now() / 1000) + 300;
        let endTime = startTime + 3600;

        beforeEach(async () => {
            const name = "Test Audio";
            const uri = "https://example.com/testaudio";
            await deciblingNFT.connect(owner).mint(name, uri);
        });

        it("should create a new bid", async () => {
            await deciblingNFT.connect(owner).approve(deciblingAuctionV2.address, itemId);
            await deciblingAuctionV2.connect(owner).createBidding(itemId, startPrice, increment, startTime, endTime);
            const auction = await deciblingAuctionV2.auctions(itemId);

            expect(auction.startPrice).to.equal(startPrice);
            expect(auction.increment).to.equal(increment);
            expect(auction.startTime).to.equal(startTime);
            expect(auction.endTime).to.equal(endTime);
            expect(auction.resulted).to.equal(false);
        });
    });

    describe("bid", function () {
        let itemId = 0;
        let startPrice = BigNumber.from("1000000000000000000");
        let increment = BigNumber.from("100000000000000000");
        let startTime = Math.floor(Date.now() / 1000) + 300;
        let endTime = startTime + 3600;
        let bidAmount = BigNumber.from("1200000000000000000");

        beforeEach(async () => {
            const name = "Test Audio";
            const uri = "https://example.com/testaudio";
            await deciblingNFT.connect(owner).mint(name, uri);
            await deciblingNFT.connect(owner).approve(deciblingAuctionV2.address, itemId);
            await token.connect(owner).transfer(bidder1.address, bidAmount);
            await deciblingAuctionV2.connect(owner).createBidding(itemId, startPrice, increment, startTime, endTime);
        });

        it("should place a bid successfully", async () => {
            // fast forward time to start of auction
            await ethers.provider.send("evm_setNextBlockTimestamp", [startTime + 1]);
            await ethers.provider.send("evm_mine");

            await token.connect(bidder1).approve(deciblingAuctionV2.address, bidAmount);
            await deciblingAuctionV2.connect(bidder1).bid(itemId, bidAmount);

            const topBid = await deciblingAuctionV2.topBids(itemId);
            expect(topBid.user).to.equal(bidder1.address);
            expect(topBid.price).to.equal(bidAmount);
        });
    });

    describe("settleBid", function () {
        let itemId = 0;
        let startPrice = BigNumber.from("1000000000000000000");
        let increment = BigNumber.from("100000000000000000");
        let startTime = Math.floor(Date.now() / 1000) + 500;
        let endTime = startTime + 3600;
        let bidAmount = BigNumber.from("1200000000000000000");

        beforeEach(async () => {
            const name = "Test Audio";
            const uri = "https://example.com/testaudio";
            await deciblingNFT.connect(owner).mint(name, uri);
            await deciblingNFT.connect(owner).approve(deciblingAuctionV2.address, itemId);
            await token.connect(owner).transfer(bidder1.address, bidAmount);
            await deciblingAuctionV2.connect(owner).createBidding(itemId, startPrice, increment, startTime, endTime);
            // fast forward time to start of auction
            await ethers.provider.send("evm_setNextBlockTimestamp", [startTime + 1]);
            await ethers.provider.send("evm_mine");
            await token.connect(bidder1).approve(deciblingAuctionV2.address, bidAmount);
            await deciblingAuctionV2.connect(bidder1).bid(itemId, bidAmount);
        });

        it("should settle bid successfully", async () => {
            // fast forward time to end of auction
            await ethers.provider.send("evm_setNextBlockTimestamp", [endTime + 1]);
            await ethers.provider.send("evm_mine");

            await deciblingAuctionV2.connect(owner).settleBid(itemId);

            const auction = await deciblingAuctionV2.auctions(itemId);
            expect(auction.resulted).to.equal(true);

            const newOwner = await deciblingNFT.ownerOf(itemId);
            expect(newOwner).to.equal(bidder1.address);
        });
    });
})