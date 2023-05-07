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
  time
} = require("@nomicfoundation/hardhat-network-helpers");

const {
  expect, assert
} = require("chai");
const {
  ZERO_ADDRESS
} = require("@openzeppelin/test-helpers/src/constants");
const { BigNumber, utils } = require("ethers");
const { ethers } = require("hardhat");

const DeciblingStaking = artifacts.require("DeciblingStaking");
const Token = artifacts.require("FroggilyToken");

contract("DeciblingStaking", () => {
  let admin, user1, user2, artist;

  const ZERO_ADDRESS = '0x0000000000000000000000000000000000000000';
  const ONE_BILLION = BigNumber.from("1000000000000000000000000000");
  const TEN_MILLION = BigNumber.from("10000000000000000000000000");
  const ONE_MILLION = BigNumber.from("1000000000000000000000000");
  const ONE_THOUSAND = BigNumber.from("1000000000000000000000");

  const defaultPoolId = "decibling_pool";

  describe("Basic features on default pool", () => {
    beforeEach(async () => {
      accounts = await ethers.getSigners();
      admin = accounts[0];
      artist = accounts[1];
      user1 = accounts[2];
      user2 = accounts[3];
      
      const MyToken = await ethers.getContractFactory("FroggilyToken");
      let myToken = await MyToken.deploy();
      this.token = await myToken.deployed();

      await this.token.transfer(user1.address, ONE_BILLION);
      await this.token.transfer(user2.address, ONE_BILLION);

      const Staking = await ethers.getContractFactory("DeciblingStaking");
      this.staking = await upgrades.deployProxy(Staking, [this.token.address], {
        initializer: "initialize"
      });
      await this.staking.deployed();

      await this.staking.setDefaultPool();
    });
    it("newPool() from admin", async () => {
        const poolId = "test_pool_admin";
        await this.staking.connect(admin).newPool([], poolId);
        const poolInfo = await this.staking.pools(poolId);
        expect(poolInfo.owner).to.equal(admin.address);
      }),
      it("newPool() from artist", async () => {
        const poolId = "test_pool_artist";
        await this.staking.connect(artist).newPool([], poolId);
        const poolInfo = await this.staking.pools(poolId);
        expect(poolInfo.owner).to.equal(artist.address);
      });
    it("updatePool() from admin", async () => {
        const poolId = "test_pool_admin";
        await this.staking.connect(admin).newPool([], poolId);
        await this.staking.connect(admin).updatePool([], poolId, 4, 4);
        const poolInfo = await this.staking.pools(poolId);
        expect(poolInfo.r).to.equal(new BN("4"));
        expect(poolInfo.rToOwner).to.equal(new BN("4"));
        expect(poolInfo.owner).to.equal(admin.address);
      }),
      it("updatePool() from artist", async () => {
        const poolId = "test_pool_artist";
        await this.staking.connect(artist).newPool([], poolId);
        await this.staking.connect(artist).updatePool([], poolId, 4, 4);
        const poolInfo = await this.staking.pools(poolId);
        expect(poolInfo.r).to.equal(new BN("4"));
        expect(poolInfo.rToOwner).to.equal(new BN("4"));
        expect(poolInfo.owner).to.equal(artist.address);
      }),
      it("updatePool() error not owner", async () => {
        const poolId = "test_pool_user";
        await this.staking.connect(user1).newPool([], poolId);
        await expectRevert.unspecified(
          this.staking.connect(user2).updatePool([], poolId, 4, 4));
      }),
      it("updatePool() artist if admin", async () => {
        const poolId = "test_pool_user";
        await this.staking.connect(artist).newPool([], poolId);
        await this.staking.connect(admin).updatePool([], poolId, 4, 4);
        poolInfo = await this.staking.pools(poolId);
        expect(poolInfo.r).to.equal(new BN("4"));
        expect(poolInfo.rToOwner).to.equal(new BN("4"));
        expect(poolInfo.owner).to.equal(artist.address);
      });
    it("stake()", async () => {
        expect(await this.token.balanceOf(this.staking.address)).to.equal(0);
        expect(await this.token.balanceOf(user1.address)).to.equal(ONE_BILLION);

        //approve and stake
        expect(
          await this.token.connect(user1).approve(this.staking.address, ONE_THOUSAND)
        );
        expect(
          await this.staking.connect(user1).stake(defaultPoolId, ONE_THOUSAND)
        );

        //pool balance
        expect(await this.token.balanceOf(this.staking.address)).to.equal(ONE_THOUSAND);
        //user1 balance
        expect(await this.token.balanceOf(user1.address)).to.equal(ONE_BILLION.sub(ONE_THOUSAND));
      }),
      it("stake() with zero value", async () => {
        expect(await this.token.balanceOf(this.staking.address)).to.equal(0);
        expect(await this.token.balanceOf(user1.address)).to.equal(ONE_BILLION);

        //approve and stake
        expect(
          await this.token.connect(user1).approve(this.staking.address, 0)
        );
        await expect(
          this.staking.connect(user1).stake(defaultPoolId, 0)
        ).to.be.revertedWith('DeciblingStaking: amount must be > 0');
      });
    describe("unstake cases", async () => {
      beforeEach(async() => {
        expect(await this.token.balanceOf(this.staking.address)).to.equal(0);
        expect(await this.token.balanceOf(user1.address)).to.equal(ONE_BILLION);

        //approve and stake
        expect(
          await this.token.connect(user1).approve(this.staking.address, ONE_THOUSAND)
        );
        expect(
          await this.staking.connect(user1).stake(defaultPoolId, ONE_THOUSAND)
        );

        //pool balance
        expect(await this.token.balanceOf(this.staking.address), ONE_THOUSAND);
        //user1 balance
        expect(await this.token.balanceOf(user1.address), ONE_BILLION.sub(ONE_THOUSAND));
      }),

      it("unstake()", async() => {
        // unstake
        expect(
          await this.staking.connect(user1).unstake(defaultPoolId, ONE_THOUSAND)
        );

        //pool balance
        expect(await this.token.balanceOf(this.staking.address), 0);
        //user1 balance
        expect(await this.token.balanceOf(user1.address), ONE_BILLION);
      }),

      it("unstake() with zero value", async () => {
        // unstake
        await expect(
          this.staking.connect(user1).unstake(defaultPoolId, 0)
        ).to.be.revertedWith('DeciblingStaking: amount must be > 0');
      }),

      it("unstake() with value larger than staked amount", async () => {
        // unstake
        await expect(
          this.staking.connect(user1).unstake(defaultPoolId, ONE_THOUSAND.add(ONE_THOUSAND))
        ).to.be.revertedWith('DeciblingStaking: The amount must be smaller than your current staked');
      }),
      it("unstake() to invalid pool id", async () => {
        // unstake
        await expect(
          this.staking.connect(user1).unstake("invalid_pool", ONE_THOUSAND)
        ).to.be.revertedWith('DeciblingStaking: this pool is not exist');
      })

      }),
    describe("updatePoolOwner cases", async () => {
      beforeEach(async() => {
        const poolId = "test_pool_owner";
        await this.staking.connect(user1).newPool([], poolId);
        expect(await this.staking.pools(poolId).owner, user1.address);
      }),
      it("updatePoolOwner()", async() => {
        const poolId = "test_pool_owner";
        await this.staking.connect(user1).updatePoolOwner([], poolId, user2.address);
        expect(await this.staking.pools(poolId).owner, user2.address);
      }),

      it("updatePoolOwner() from admin", async() => {
        const poolId = "test_pool_owner";
        await this.staking.connect(admin).updatePoolOwner([], poolId, user2.address);
        expect(await this.staking.pools(poolId).owner, user2.address);
      }),
      it("updatePoolOwner() with invalid id", async() => {
        await expect(
          this.staking.connect(admin).updatePoolOwner([], "invalid_id", user2.address)
          ).to.be.revertedWith("DeciblingStaking: this pool is not exist");
      }),
      it("updatePoolOwner() with invalid address", async() => {
        const poolId = "test_pool_owner";
        await expect(
          this.staking.connect(user1).updatePoolOwner([], poolId, ZERO_ADDRESS)
        ).to.be.revertedWith("DeciblingStaking: not a valid address");
      })
    }),
    describe("hardCap cases", async() => {
      beforeEach(async() => {
        await this.staking.connect(admin).setDefaultPool();
        expect(await this.staking.pools("decibling_pool").owner, admin.address);
      }),
      it("default pool hardcap", async() => {
        const poolId = "decibling_pool";
        assert.equal((await this.staking.pools(poolId)).hardCap, 10_000_000 * 1e18);
      })
    }),
    describe("payout cases", async() => {
      beforeEach(async() => {
      }),
      it("defaultPool payout 1 stake", async() => {
        const poolId = "decibling_pool";

        await this.staking.connect(admin).setDefaultPool();
        expect(await this.staking.pools(poolId).owner, admin.address);

        await this.token.connect(user1).approve(this.staking.address, 5_000_000);
        await this.staking.connect(user1).stake(poolId, 5_000_000);

        let depositTime = (await this.staking.stakers(poolId, user1.address)).depositTime;

        // fast forward time to start of auction
        await ethers.provider.send("evm_setNextBlockTimestamp", [depositTime.add(depositTime, BigNumber.from(5 * 86400)).toNumber()]);
        await ethers.provider.send("evm_mine");

        console.log(await this.staking.connect(user1).payout(poolId, user1.address, false));
      }),
      it("newPool payout 1 stake", async() => {
        const poolId = "new_pool";

        await this.staking.connect(artist).newPool([], poolId);
        expect(await this.staking.pools(poolId).owner, artist.address);
        await this.staking.connect(artist).updatePool([], poolId, 5, 3);
        poolInfo = await this.staking.pools(poolId);
        expect(poolInfo.r).to.equal(new BN("5"));
        expect(poolInfo.rToOwner).to.equal(new BN("3"));

        await this.token.connect(user1).approve(this.staking.address, TEN_MILLION);
        await this.staking.connect(user1).stake(poolId, TEN_MILLION);

        let depositTime = (await this.staking.stakers(poolId, user1.address)).depositTime;

        // fast forward time to start of auction
        await ethers.provider.send("evm_setNextBlockTimestamp", [depositTime.toNumber() + (365 * 86400)]);
        await ethers.provider.send("evm_mine");

        // console.log(await this.staking.connect(artist).payout(poolId));
        console.log(await this.staking.connect(user1).payout(poolId, user1.address, false));
      }),
      it("newPool payout 2 stakes", async() => {
        const poolId = "new_pool";

        await this.staking.connect(artist).newPool([], poolId);
        expect(await this.staking.pools(poolId).owner, artist.address);
        await this.staking.connect(artist).updatePool([], poolId, 5, 3);
        poolInfo = await this.staking.pools(poolId);
        expect(poolInfo.r).to.equal(new BN("5"));
        expect(poolInfo.rToOwner).to.equal(new BN("3"));

        await this.token.connect(user1).approve(this.staking.address, ONE_MILLION);
        await this.staking.connect(user1).stake(poolId, ONE_MILLION);

        let depositTime = (await this.staking.stakers(poolId, user1.address)).depositTime;

        // fast forward time
        await ethers.provider.send("evm_setNextBlockTimestamp", [depositTime.toNumber() + (10 * 86400)]);
        await ethers.provider.send("evm_mine");

        let payout = await this.staking.connect(user1).payout(poolId, user1.address, false);
        let age = (poolInfo.r / 100) * (10 / 365);
        let rate = Math.pow(Math.exp(1), age);
        let profit = (ONE_MILLION * rate) - ONE_MILLION;
        expect((payout / 1e18).toFixed(5)).to.equal((profit/1e18).toFixed(5));

        await this.token.connect(user1).approve(this.staking.address, ONE_MILLION);
        await this.staking.connect(user1).stake(poolId, ONE_MILLION);

        depositTime = (await this.staking.stakers(poolId, user1.address)).depositTime;

        // fast forward time
        await ethers.provider.send("evm_setNextBlockTimestamp", [depositTime.toNumber() + (10 * 86400)]);
        await ethers.provider.send("evm_mine");

        // console.log(await this.staking.connect(artist).payout(poolId));
        payout = await this.staking.connect(user1).payout(poolId, user1.address, false);
        age = (poolInfo.r / 100) * (10 / 365);
        rate = Math.pow(Math.exp(1), age);
        totalNewDeposit = ONE_MILLION.add(ONE_MILLION).add(BigInt(profit));
        let profit2 = (totalNewDeposit * rate) - totalNewDeposit;
        expect((payout / 1e18).toFixed(5)).to.equal((profit2/1e18).toFixed(5));
      })
    })
  });
});