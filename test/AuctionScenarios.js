const {
  expectRevert,
  expectEvent,
  BN,
  ether,
  constants,
  balance,
  send,
} = require("@openzeppelin/test-helpers");
const { time } = require("@nomicfoundation/hardhat-network-helpers");
const hre = require("hardhat");

const { expect } = require("chai");

const DeciblingAuction = artifacts.require("DeciblingAuction");
const Token = artifacts.require("FroggilyToken");

const weiToEther = (n) => {
  return web3.utils.fromWei(n.toString(), "ether");
};

const toPercent = (n) => {
  return n / 1e3;
};

contract("DeciblingAuction", (accounts) => {
  const [
    admin,
    artist,
    platformFeeAddress,
    minter,
    collector1,
    collector2,
    collector3,
  ] = accounts;

  const ZERO = new BN("0");
  const TOKEN_ONE_ID = new BN("1");
  const TOKEN_TWO_ID = new BN("2");
  const TWENTY_TOKENS = new BN("20000000000000000000");
  const ONE_TOKENS = new BN("1000000000000000000");
  const ONE_THOUSAND_TOKENS = new BN("1000000000000000000000");
  const ONE_MILLION_TOKENS = new BN("1000000000000000000000000");
  const ONE_BILLION_TOKENS = new BN("1000000000000000000000000000");

  const randomTokenURI = "rand";

  beforeEach(async () => {
    this.token = await Token.new({
      from: admin,
    });
    this.token.transfer(minter, ONE_BILLION_TOKENS, {
      from: admin,
    });
    this.token.transfer(collector1, ONE_BILLION_TOKENS, {
      from: admin,
    });
    this.token.transfer(collector2, ONE_BILLION_TOKENS, {
      from: admin,
    });
    this.token.transfer(collector3, ONE_BILLION_TOKENS, {
      from: admin,
    });
    this.auction = await DeciblingAuction.new(
      this.token.address,
      platformFeeAddress,
      {
        from: admin,
      }
    );
  });

  describe("Simple minting and auction", () => {
    it("Full sale workflow", async () => {
      console.log(`Admin address: ${admin}`);
      const balanceFirstSale = await this.auction.firstSaleFee({
        from: admin,
      });
      console.log(`Platform Fees: First sale ${toPercent(balanceFirstSale)}`);
      const platformA = await this.token.balanceOf(platformFeeAddress, {
        from: admin,
      });
      let bpa = await balanceOf("Platform A", platformFeeAddress, "initiated");
      let baa = await balanceOf("Artist A", artist, "initiated");
      let bc1 = await balanceOf("Collector 1", collector1, "initiated");
      let bc2 = await balanceOf("Collector 2", collector2, "initiated");

      console.log("Artist A creates a NFT", randomTokenURI);
      expect(
        await this.auction.createNFT(randomTokenURI, randomTokenURI, {
          from: artist,
        })
      );

      let nftOwner = await this.auction.ownerOf(TOKEN_ONE_ID, {
        from: admin,
      });
      console.log(`NFT owner address: ${nftOwner}`);

      let nftInfo = await this.auction.listNFT(randomTokenURI, {
        from: admin,
      });
      expect(nftInfo, {
        owner: artist,
        name: randomTokenURI,
        price: new BN("0"),
        saleCount: new BN("0"),
        status: new BN("0"),
      });

      let startTime = Date.now() / 1e3;
      let endTime = (Date.now() + 10 * 60000) / 1e3;

      console.log("Artist A creates a bid at", 1000);
      expect(
        await this.auction.createBidding(
          randomTokenURI,
          ONE_THOUSAND_TOKENS,
          ONE_TOKENS,
          startTime.toFixed(0),
          endTime.toFixed(0),
          {
            from: artist,
          }
        )
      );

      let auctionInfo = await this.auction.auctions(TOKEN_ONE_ID, {
        from: admin,
      });
      expect(auctionInfo, {
        winner: ZERO,
        increment: ONE_TOKENS,
        startPrice: ONE_THOUSAND_TOKENS,
        startTime: new BN(startTime.toFixed(0)),
        endTime: new BN(endTime.toFixed(0)),
        saleCount: new BN("0"),
        status: new BN("1"),
      });

      expect(
        await this.token.approve(this.auction.address, ONE_THOUSAND_TOKENS, {
          from: collector1,
        })
      );

      console.log("Collector 1 bids", 1000);
      expect(
        await this.auction.bid(randomTokenURI, ONE_THOUSAND_TOKENS, {
          from: collector1,
        })
      );

      expect(
        await this.token.approve(
          this.auction.address,
          ONE_THOUSAND_TOKENS.add(ONE_THOUSAND_TOKENS),
          {
            from: collector2,
          }
        )
      );

      console.log("Collector 2 bids", 2000);
      expect(
        await this.auction.bid(
          randomTokenURI,
          ONE_THOUSAND_TOKENS.add(ONE_THOUSAND_TOKENS),
          {
            from: collector2,
          }
        )
      );

      console.log("Increase time to", endTime + 100);
      await time.increaseTo(new BN(endTime + 100));

      console.log("Settle bidding for item", randomTokenURI);
      expect(
        await this.auction.settleBiddingSession(randomTokenURI, {
          from: artist,
        })
      );

      nftInfo = await this.auction.listNFT(randomTokenURI, {
        from: admin,
      });
      expect(nftInfo, {
        owner: collector2,
        price: ONE_THOUSAND_TOKENS.add(ONE_THOUSAND_TOKENS),
        saleCount: new BN("1"),
        status: new BN("3"),
      });

      auctionInfo = await this.auction.auctions(TOKEN_ONE_ID, {
        from: admin,
      });
      expect(auctionInfo, {
        winner: collector2,
        resulted: true,
      });

      expect(
        await balanceOf(
          "Platform A",
          platformFeeAddress,
          "after 1st sale",
          bpa
        ),
        new BN("250")
      );
      expect(
        await balanceOf("Artist A", artist, "after 1st sale", baa),
        new BN("1750")
      );
      expect(
        await balanceOf("Collector 1", collector1, "after 1st sale", bc1),
        ONE_BILLION_TOKENS
      );
      expect(
        await balanceOf("Collector 2", collector2, "after 1st sale", bc2),
        ONE_BILLION_TOKENS - new BN("2000")
      );

      // second sale
      const balanceSecondSale = await this.auction.secondSaleFee({
        from: admin,
      });
      console.log(`Platform Fees: Second sale ${toPercent(balanceSecondSale)}`);
      bpa = await balanceOf(
        "Platform A",
        platformFeeAddress,
        "before 2nd sale"
      );
      baa = await balanceOf("Artist A", artist, "before 2nd sale");
      bc1 = await balanceOf("Collector 1", collector1, "before 2nd sale");
      bc2 = await balanceOf("Collector 2", collector2, "before 2nd sale");
      const bc3 = await balanceOf("Collector 3", collector3, "before 2nd sale");

      nftOwner = await this.auction.ownerOf(TOKEN_ONE_ID, {
        from: admin,
      });
      console.log(`NFT owner address: ${nftOwner}`);

      nftInfo = await this.auction.listNFT(randomTokenURI, {
        from: admin,
      });
      expect(nftInfo, {
        owner: collector2,
        name: randomTokenURI,
        price: new BN("1000"),
        saleCount: new BN("1"),
        status: new BN("3"),
      });

      (startTime = endTime + 100), (endTime = startTime + 600);

      const startPrice = ONE_THOUSAND_TOKENS.mul(new BN("10"));
      console.log(
        "Collector 2 creates a bid at",
        weiToEther(startPrice),
        startTime,
        endTime
      );
      expect(
        await this.auction.createBidding(
          randomTokenURI,
          startPrice,
          ONE_TOKENS,
          startTime.toFixed(0),
          endTime.toFixed(0),
          {
            from: collector2,
          }
        )
      );

      auctionInfo = await this.auction.auctions(TOKEN_ONE_ID, {
        from: admin,
      });
      expect(auctionInfo, {
        winner: ZERO,
        increment: ONE_TOKENS,
        startPrice: startPrice,
        startTime: new BN(startTime.toFixed(0)),
        endTime: new BN(endTime.toFixed(0)),
        saleCount: new BN("1"),
        status: new BN("1"),
      });

      console.log("Collector 1 bids", weiToEther(startPrice));
      expect(
        await this.token.approve(this.auction.address, startPrice, {
          from: collector1,
        })
      );

      expect(
        await this.auction.bid(randomTokenURI, startPrice, {
          from: collector1,
        })
      );

      lastPrice = ONE_THOUSAND_TOKENS.mul(new BN("100"));
      console.log("Collector 3 bids", weiToEther(lastPrice));
      expect(
        await this.token.approve(this.auction.address, lastPrice, {
          from: collector3,
        })
      );

      expect(
        await this.auction.bid(randomTokenURI, lastPrice, {
          from: collector3,
        })
      );

      await time.increaseTo(new BN(endTime + 100));

      console.log("Settle bidding for item", randomTokenURI);
      const biddingSession2 = await this.auction.settleBiddingSession(
        randomTokenURI,
        {
          from: collector2,
        }
      );
      expect(biddingSession2).to.emit(this.token, "SettleBid");

      nftInfo = await this.auction.listNFT(randomTokenURI, {
        from: admin,
      });
      expect(nftInfo, {
        owner: collector3,
        price: lastPrice,
        saleCount: new BN("2"),
        status: new BN("3"),
      });

      auctionInfo = await this.auction.auctions(TOKEN_ONE_ID, {
        from: admin,
      });
      expect(auctionInfo, {
        winner: collector3,
        resulted: true,
      });

      await balanceOf("Platform A", platformFeeAddress, "before 2nd sale", bpa);
      await balanceOf("Artist A", artist, "after 2nd sale", baa);
      await balanceOf("Collector 1", collector1, "after 2nd sale", bc1);
      await balanceOf("Collector 2", collector2, "after 2nd sale", bc2);
      await balanceOf("Collector 3", collector3, "after 2nd sale", bc3);
    });
  });
});

const balanceOf = async (name, address, event, oldBalance = new BN("0")) => {
  const bal = await this.token.balanceOf(address, {
    from: address,
  });
  address = address.substring(0, 8);
  console.log(
    `${name} ${address} balance ${event}: ${new Intl.NumberFormat().format(
      weiToEther(bal)
    )} ${
      oldBalance > 0
        ? `- changed: ${new Intl.NumberFormat().format(
            weiToEther(bal.sub(oldBalance))
          )}`
        : ""
    }`
  );
  return bal;
};
