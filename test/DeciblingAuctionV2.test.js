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
        let endTime = Math.floor(Date.now() / 1000) + 36000000;

        beforeEach(async () => {
            const proof = [];
            const uri = "https://example.com/testaudio";
            await deciblingNFT.connect(owner).mint(proof, uri);
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
        let endTime = startTime + 36000000;
        let bidAmount = BigNumber.from("1200000000000000000");

        beforeEach(async () => {
            const proof = [];
            const uri = "https://example.com/testaudio";
            await deciblingNFT.connect(owner).mint(proof, uri);
            await deciblingNFT.connect(owner).approve(deciblingAuctionV2.address, itemId);
            await token.connect(bidder1).mint();
            await deciblingAuctionV2.connect(owner).createBidding(itemId, startPrice, increment, startTime, endTime);
        });

        it("should place a bid successfully", async () => {
            // fast forward time to start of auction
            await ethers.provider.send("evm_setNextBlockTimestamp", [startTime + 2800820]);
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
        let startTime = Math.floor(Date.now() / 1000) + 300;
        let endTime = startTime + 36000000;
        let bidAmount = BigNumber.from("1200000000000000000");

        beforeEach(async () => {
            const proof = [];
            const uri = "https://example.com/testaudio";
            await deciblingNFT.connect(owner).mint(proof, uri);
            await deciblingNFT.connect(owner).approve(deciblingAuctionV2.address, itemId);
            await token.connect(bidder1).mint();
            await deciblingAuctionV2.connect(owner).createBidding(itemId, startPrice, increment, startTime, endTime);
            // fast forward time to start of auction
            await ethers.provider.send("evm_setNextBlockTimestamp", [startTime + 3600000]);
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
    describe("bidWonReceive", function () {
        let itemId = 0;
        let startPrice = BigNumber.from("1000000000000000000");
        let increment = BigNumber.from("100000000000000000");
        let startTime = Math.floor(Date.now() / 1000) + 300;
        let endTime = Math.floor(Date.now() / 1000) + 3600000000;
        let bidAmount = BigNumber.from("1200000000000000000");

        beforeEach(async () => {
            const proof = [];
            const uri = "https://example.com/testaudio";
            await deciblingNFT.connect(owner).mint(proof, uri);
            await deciblingNFT.connect(owner).approve(deciblingAuctionV2.address, itemId);
            await token.connect(bidder1).mint();
            await deciblingAuctionV2.connect(owner).createBidding(itemId, startPrice, increment, startTime, endTime);
            // fast forward time to start of auction
            await ethers.provider.send("evm_setNextBlockTimestamp", [startTime + 45996009]);
            await ethers.provider.send("evm_mine");
            await token.connect(bidder1).approve(deciblingAuctionV2.address, bidAmount);
            await deciblingAuctionV2.connect(bidder1).bid(itemId, bidAmount);
        });

        it("should nft's owner receive winner's bid amount successfully", async () => {
            const ownerBalanceBefore = await token.balanceOf(owner.address);

            // fast forward time to end of auction
            await ethers.provider.send("evm_setNextBlockTimestamp", [endTime + 1]);
            await ethers.provider.send("evm_mine");

            await deciblingAuctionV2.connect(owner).settleBid(itemId);


            const ownerBalanceAfter = await token.balanceOf(owner.address);
            const firstSaleFee = bidAmount.mul(await deciblingAuctionV2.firstSaleFee()).div(10000);
            const expectedOwnerBalance = ownerBalanceBefore.add(bidAmount).sub(firstSaleFee);
            expect(ownerBalanceAfter).to.equal(expectedOwnerBalance);
        });
    });

    describe("firstFeeReceive", function () {
        let itemId = 0;
        let startPrice = BigNumber.from("1000000000000000000");
        let increment = BigNumber.from("100000000000000000");
        let bidAmount = BigNumber.from("1200000000000000000");
        let startTime = Math.floor(Date.now() / 1000) + 300;
        let endTime = Math.floor(Date.now() / 1000) + 36000000000;

        beforeEach(async () => {
            const proof = [];
            const uri = "https://example.com/testaudio";
            await deciblingNFT.connect(owner).mint(proof, uri);
            await deciblingNFT.connect(owner).approve(deciblingAuctionV2.address, itemId);
            await token.connect(bidder1).mint();
            await deciblingAuctionV2.connect(owner).createBidding(itemId, startPrice, increment, startTime, endTime);
            // fast forward time to start of auction
            await ethers.provider.send("evm_setNextBlockTimestamp", [Math.floor(Date.now() / 1000) + 4585403997]);
            await ethers.provider.send("evm_mine");
            await token.connect(bidder1).approve(deciblingAuctionV2.address, bidAmount);
            await deciblingAuctionV2.connect(bidder1).bid(itemId, bidAmount);
        });

        it("should platform fee recipient receive first time fee successfully", async () => {
            const feeRecipientBalanceBefore = await token.balanceOf(platformFeeRecipient.address);

            // fast forward time to end of auction
            await ethers.provider.send("evm_setNextBlockTimestamp", [endTime + 1]);
            await ethers.provider.send("evm_mine");

            await deciblingAuctionV2.connect(owner).settleBid(itemId);

            const feeRecipientBalanceAfter = await token.balanceOf(platformFeeRecipient.address);
            const firstSaleFee = bidAmount.mul(await deciblingAuctionV2.firstSaleFee()).div(10000);
            const expectedFeeRecipientBalance = feeRecipientBalanceBefore.add(firstSaleFee);
            expect(feeRecipientBalanceAfter).to.equal(expectedFeeRecipientBalance);
        });
    });

    describe("secondFeeReceive", function () {
        let itemId = 0;
        let startPrice = BigNumber.from("1000000000000000000");
        let increment = BigNumber.from("100000000000000000");
        let bidAmount = BigNumber.from("1200000000000000000");
        let secondBidAmount = BigNumber.from("2400000000000000000");
        let startTime = Math.floor(Date.now() / 1000) + 300;
        let endTime = Math.floor(Date.now() / 1000) + 36000000000000;

        beforeEach(async () => {
            const proof = []
            const uri = "https://example.com/testaudio";
            await deciblingNFT.connect(owner).mint(proof, uri);
            await deciblingNFT.connect(owner).approve(deciblingAuctionV2.address, itemId);
            await token.connect(bidder1).mint();
            const nftownerbalance = await token.balanceOf(owner.address);
            await deciblingAuctionV2.connect(owner).createBidding(itemId, startPrice, increment, startTime, endTime);
            // fast forward time to start of auction
            await ethers.provider.send("evm_setNextBlockTimestamp", [Math.floor(Date.now() / 1000) + 45999404000]);
            await ethers.provider.send("evm_mine");
            await token.connect(bidder1).approve(deciblingAuctionV2.address, bidAmount);

            await deciblingAuctionV2.connect(bidder1).bid(itemId, bidAmount);

            // fast forward time to end of auction
            await ethers.provider.send("evm_setNextBlockTimestamp", [endTime + 1]);
            await ethers.provider.send("evm_mine");

            await deciblingAuctionV2.connect(owner).settleBid(itemId);

        });


        it("should platform fee recipient receive second time fee successfully", async () => {
            let feeRecipientBalanceBefore = await token.balanceOf(platformFeeRecipient.address);
            let firstSaleFee = bidAmount.mul(await deciblingAuctionV2.firstSaleFee()).div(10000);
            expect(feeRecipientBalanceBefore).to.equal(firstSaleFee);

            startTime = Math.floor(Date.now() / 1000) + 300;
            endTime = Math.floor(Date.now() / 1000) + 360000000000000;

            await deciblingNFT.connect(bidder1).approve(deciblingAuctionV2.address, itemId);
            await deciblingAuctionV2.connect(bidder1).createBidding(itemId, startPrice, increment, startTime, endTime);

            // fast forward time to start of auction
            await ethers.provider.send("evm_setNextBlockTimestamp", [Math.floor(Date.now() / 1000) + 36999999999502]);
            await ethers.provider.send("evm_mine");

            await token.connect(owner).mint();
            // Place a bid on the second item
            await token.connect(owner).approve(deciblingAuctionV2.address, secondBidAmount);
            await deciblingAuctionV2.connect(owner).bid(itemId, secondBidAmount);

            // fast forward time to end of auction
            await ethers.provider.send("evm_setNextBlockTimestamp", [Math.floor(Date.now() / 1000) + 560000000000000]);
            await ethers.provider.send("evm_mine");

            await deciblingAuctionV2.connect(bidder1).settleBid(itemId);

            feeRecipientBalanceBefore = await token.balanceOf(platformFeeRecipient.address);
            secondSaleFee = secondBidAmount.mul(await deciblingAuctionV2.secondSaleFee()).div(10000);
            expectedFeeRecipientBalance = firstSaleFee.add(secondSaleFee);
            expect(feeRecipientBalanceBefore).to.equal(expectedFeeRecipientBalance);
        });
    });
})