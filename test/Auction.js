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

const DeciblingAuction = artifacts.require("DeciblingAuctionV2");
const Token = artifacts.require("FroggilyToken");
const { time } = require("@nomicfoundation/hardhat-network-helpers");

contract("DeciblingAuctionV2", (accounts) => {
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
    this.token.transfer(bidder, ONE_BILLION_TOKENS, {
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
        let now = await time.latest()
        let startTime = now;
        let endTime = now + 10 * 60000;
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
        let now = await time.latest()
        let startTime = now;
        let endTime = now + 10 * 60000;
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
      it("Bid lower than last bid value", async () => {
        await this.auction.createNFT(randomTokenURI, randomTokenURI, {
          from: owner,
        })
        let now = await time.latest()
        let startTime = now;
        let endTime = now + 10 * 60000;
        await this.auction.createBidding(
          randomTokenURI,
          ONE_THOUSAND_TOKENS,
          ONE_TOKENS,
          startTime.toFixed(0),
          endTime.toFixed(0), {
            from: owner,
          }
        )
        await this.token.approve(this.auction.address, ONE_THOUSAND_TOKENS, {
          from: artist,
        })
        await this.auction.bid(randomTokenURI, TWENTY_TOKENS, {
          from: artist,
        })
        await expectRevert(this.auction.bid(randomTokenURI, ONE_TOKENS, {
          from: artist,
        }), '13');
      }),
      it("Create bid on an invalid item", async () => {
        await this.auction.createNFT(randomTokenURI, randomTokenURI, {
          from: artist,
        })
        let now = await time.latest()
        let startTime = now;
        let endTime = now + 10 * 60000;
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
    it("Create bid with invalid owner", async () => {
      await this.auction.createNFT(randomTokenURI, randomTokenURI, {
        from: owner,
      })
      let now = await time.latest()
      let startTime = now;
      let endTime = now + 10 * 60000;
      await expectRevert(
        this.auction.createBidding(
          randomTokenURI,
          ONE_THOUSAND_TOKENS,
          ONE_TOKENS,
          startTime.toFixed(0),
          endTime.toFixed(0), {
            from: artist,
          }
        ), "6");
    }),
    it("Create bid with end time before start time", async () => {
      await this.auction.createNFT(randomTokenURI, randomTokenURI, {
        from: owner,
      })
      let now = await time.latest()
      let startTime = now;
      let endTime = now - 10 * 60000;
      await expectRevert(
        this.auction.createBidding(
          randomTokenURI,
          ONE_THOUSAND_TOKENS,
          ONE_TOKENS,
          startTime.toFixed(0),
          endTime.toFixed(0), {
            from: owner,
          }
        ), "18");
    }),
    it("Create bid on an on sale item", async () => {
      await this.auction.createNFT(randomTokenURI, randomTokenURI, {
        from: owner,
      })
      let now = await time.latest()
      let startTime = now;
      let endTime = now + 10 * 60000;
      await this.auction.createBidding(
        randomTokenURI,
        ONE_THOUSAND_TOKENS,
        ONE_TOKENS,
        startTime.toFixed(0),
        endTime.toFixed(0), {
          from: owner,
        }
      )
      await expectRevert(
        this.auction.createBidding(
          randomTokenURI,
          ONE_THOUSAND_TOKENS,
          ONE_TOKENS,
          startTime.toFixed(0),
          endTime.toFixed(0), {
            from: owner,
          }
        ), "8");
    }),
    it("Create NFT on an invalid item", async () => {
      await expectRevert(this.auction.createNFT("", "dsadsa", {
        from: artist,
      }), "27")
    }),
    it("Update end time of an ongoing bid", async () => {
      await this.auction.createNFT(randomTokenURI, randomTokenURI, {
        from: owner,
      })
      let now = await time.latest()
      let startTime = now;
      let endTime = now + 10 * 60000;
      let endTimeUpdated = now + 15 * 60000;
      await this.auction.createBidding(
        randomTokenURI,
        ONE_THOUSAND_TOKENS,
        ONE_TOKENS,
        startTime.toFixed(0),
        endTime.toFixed(0), {
          from: owner,
        }
      )
      expect(
        await this.auction.updateBidEndtime(randomTokenURI, endTimeUpdated.toFixed(0))
      );
    }),
    it("Update end time before start time of an ongoing bid", async () => {
      await this.auction.createNFT(randomTokenURI, randomTokenURI, {
        from: owner,
      })
      let now = await time.latest()
      let startTime = now;
      let endTime = now + 10 * 60000;
      let endTimeUpdated = now - 10 * 60000;
      await this.auction.createBidding(
        randomTokenURI,
        ONE_THOUSAND_TOKENS,
        ONE_TOKENS,
        startTime.toFixed(0),
        endTime.toFixed(0), {
          from: owner,
        }
      )
      await expectRevert(
        this.auction.updateBidEndtime(randomTokenURI, endTimeUpdated.toFixed(0)), "18"
      );
    }),
    it("Settle an ongoing bid before end time", async () => {
      await this.auction.createNFT(randomTokenURI, randomTokenURI, {
        from: owner,
      })
      let now = await time.latest()
      let startTime = now;
      let endTime = now + 10 * 60000;
      await this.auction.createBidding(
        randomTokenURI,
        ONE_THOUSAND_TOKENS,
        ONE_TOKENS,
        startTime.toFixed(0),
        endTime.toFixed(0), {
          from: owner,
        }
      )
      await expectRevert(
        this.auction.settleBiddingSession(randomTokenURI, {
          from: owner,
        }), "15")
    }),
    it("Admin settle bid", async () => {
      await this.auction.createNFT(randomTokenURI, randomTokenURI, {
        from: owner,
      })
      let now = await time.latest()
      let startTime = now;
      let endTime = now + 10 * 60000;
      await this.auction.createBidding(
        randomTokenURI,
        ONE_THOUSAND_TOKENS,
        ONE_TOKENS,
        startTime.toFixed(0),
        endTime.toFixed(0), {
          from: owner,
        }
      )
      await this.token.approve(this.auction.address, ONE_THOUSAND_TOKENS, {
        from: bidder,
      })
      await this.auction.bid(randomTokenURI, ONE_THOUSAND_TOKENS, {
        from: bidder,
      })

      await time.increaseTo(new BN(endTime + 100));
      expect(
        await this.auction.settleBiddingSession(randomTokenURI, {
          from: admin,
        })
      )
    }),
    it("Bidder settle bid", async () => {
      await this.auction.createNFT(randomTokenURI, randomTokenURI, {
        from: owner,
      })
      let now = await time.latest()
      let startTime = now;
      let endTime = now + 10 * 60000;
      await this.auction.createBidding(
        randomTokenURI,
        ONE_THOUSAND_TOKENS,
        ONE_TOKENS,
        startTime.toFixed(0),
        endTime.toFixed(0), {
          from: owner,
        }
      )
      await this.token.approve(this.auction.address, ONE_THOUSAND_TOKENS, {
        from: bidder,
      })
      await this.auction.bid(randomTokenURI, ONE_THOUSAND_TOKENS, {
        from: bidder,
      })

      await time.increaseTo(new BN(endTime + 100));
      await expectRevert(
        this.auction.settleBiddingSession(randomTokenURI, {
          from: bidder,
        }), "6"
      )
    })
  })

  describe("Contract deployment", () => {
    it("Reverts when platform fee recipient is zero", async () => {
      await this.auction.createNFT(randomTokenURI, randomTokenURI, {
        from: artist,
      })
      let now = await time.latest()
      let startTime = now;
      let endTime1 = now + 100 * 60000;
      let endTime2 = now + 10 * 60000;
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