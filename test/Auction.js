const {
  expectRevert,
  expectEvent,
  BN,
  ether,
  constants,
  balance,
  send,
} = require("@openzeppelin/test-helpers");

const {
  expect
} = require("chai");

const DeciblingAuction = artifacts.require("DeciblingAuction");
const Token = artifacts.require("FroggilyToken");

contract("DeciblingAuction", (accounts) => {
  const [
    admin,
    smartContract,
    platformFeeAddress,
    minter,
    owner,
    artist,
    bidder,
    bidder2,
    provider,
  ] = accounts;

  const ZERO = new BN("0");
  const TOKEN_ONE_ID = new BN("1");
  const TOKEN_TWO_ID = new BN("2");
  const TWENTY_TOKENS = new BN("20000000000000000000");
  const ONE_THOUSAND_TOKENS = new BN("1000000000000000000000");
  const ONE_TOKENS = new BN("1000000000000000000");
  const ONE_BILLION_TOKENS = new BN("1000000000000000000000000000");


  const randomTokenURI = "rand";

  beforeEach(async () => {
    this.token = await Token.new();
    this.auction = await DeciblingAuction.new(
      this.token.address,
      platformFeeAddress, {
        from: admin,
      }
    );
    this.token.transfer(artist, ONE_BILLION_TOKENS, {
      from: admin,
    });
  });

  describe("Contract deployment successfully", () => {
    it("Deploy the contract", async () => {
      expect(DeciblingAuction.new(this.token.address, {
        from: admin
      }));
    });
  });

  describe("Bidding", () => {
    it("Item owner cannot place a bid when on sale", async () => {
        await this.auction.createNFT(randomTokenURI, randomTokenURI, {
          from: artist,
        })
        let startTime = Date.now() / 1e3;
        let endTime = (Date.now() + 10 * 60000) / 1e3;
        expect(
          await this.auction.createBidding(
            randomTokenURI,
            ONE_THOUSAND_TOKENS,
            ONE_TOKENS,
            startTime.toFixed(0),
            endTime.toFixed(0), {
              from: artist,
            }
          )
        );
        expect(
          await this.token.approve(this.auction.address, ONE_THOUSAND_TOKENS, {
            from: artist,
          })
        );
        await expectRevert(this.auction.bid(randomTokenURI, ONE_THOUSAND_TOKENS, {
          from: artist,
        }), '25');
      }),
      it("Bid on invalid item id", async () => {
        await this.auction.createNFT(randomTokenURI, randomTokenURI, {
          from: artist,
        })
        let startTime = Date.now() / 1e3;
        let endTime = (Date.now() + 10 * 60000) / 1e3;
        expect(
          await this.auction.createBidding(
            randomTokenURI,
            ONE_THOUSAND_TOKENS,
            ONE_TOKENS,
            startTime.toFixed(0),
            endTime.toFixed(0), {
              from: artist,
            }
          )
        );
        expect(
          await this.token.approve(this.auction.address, ONE_THOUSAND_TOKENS, {
            from: artist,
          })
        );
        await expectRevert(this.auction.bid(randomTokenURI + 'invalid', ONE_THOUSAND_TOKENS, {
          from: artist,
        }), '26');
      }),
      it("Create bid on an invalid item", async () => {
        await this.auction.createNFT(randomTokenURI, randomTokenURI, {
          from: artist,
        })
        let startTime = Date.now() / 1e3;
        let endTime = (Date.now() + 10 * 60000) / 1e3;
        await expectRevert(
          this.auction.createBidding(
            randomTokenURI + 'invalid',
            ONE_THOUSAND_TOKENS,
            ONE_TOKENS,
            startTime.toFixed(0),
            endTime.toFixed(0), {
              from: artist,
            }
          ), "26");
      })
    it("Create NFT on an invalid item", async () => {
      await expectRevert(this.auction.createNFT("", "dsadsa", {
        from: artist,
      }), "27")
    }),
    it("Update end time of an ongoing bid", async () => {
      await expectRevert(this.auction.createNFT("", "dsadsa", {
        from: artist,
      }), "27")
    })
  })

  describe("Contract deployment", () => {
    it("Reverts when platform fee recipient is zero", async () => {
      await this.auction.createNFT(randomTokenURI, randomTokenURI, {
        from: artist,
      })
      let startTime = Date.now() / 1e3;
      let endTime1 = (Date.now() + 100 * 60000) / 1e3;
      let endTime2 = (Date.now() + 10 * 60000) / 1e3;
      await this.auction.createBidding(
        randomTokenURI,
        ONE_THOUSAND_TOKENS,
        ONE_TOKENS,
        startTime.toFixed(0),
        endTime1.toFixed(0), 
        { from: artist })
      let auctionInfo = await this.auction.auctions("1", {
          from: admin,
        });
      expect(auctionInfo.endTime).to.equal(new BN(endTime1.toFixed(0)));
      await this.auction.updateBidEndtime(
          randomTokenURI,
          endTime2.toFixed(0), 
          { from: admin })
      auctionInfo = await this.auction.auctions("1", {
        from: admin,
      });
      expect(auctionInfo.endTime).to.equal(new BN(endTime2.toFixed(0)));
    });
  });
});