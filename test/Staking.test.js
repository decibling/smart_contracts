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
  expect
} = require("chai");
const {
  ZERO_ADDRESS
} = require("@openzeppelin/test-helpers/src/constants");

const DeciblingStaking = artifacts.require("DeciblingStaking");
const Token = artifacts.require("FroggilyToken");

contract("DeciblingStaking", () => {
  let admin, user1, user2, artist;

  const ZERO_ADDRESS = '0x0000000000000000000000000000000000000000'

  const defaultPoolId = "decibling_pool";

  describe("Basic features on default pool", () => {
    beforeEach(async () => {
      accounts = await ethers.getSigners();
      admin = accounts[0];
      artist = accounts[1];
      user1 = accounts[2];
      user2 = accounts[3];
      
      const MyToken = await ethers.getContractFactory("FroggilyToken");
      myToken = await MyToken.deploy();
      this.token = await myToken.deployed();

      await this.token.transfer(user1.address, 1_000_000_000);
      await this.token.transfer(user2.address, 1_000_000_000);

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
        expect(await this.token.balanceOf(user1.address)).to.equal(1_000_000_000);

        //approve and stake
        expect(
          await this.token.connect(user1).approve(this.staking.address, 1_000)
        );
        expect(
          await this.staking.connect(user1).stake(defaultPoolId, 1_000)
        );

        //pool balance
        expect(await this.token.balanceOf(this.staking.address), 1_000);
        //user1 balance
        expect(await this.token.balanceOf(user1.address), 1_000_000_000 - 1_000);
      }),
      it("stake() with zero value", async () => {
        expect(await this.token.balanceOf(this.staking.address)).to.equal(0);
        expect(await this.token.balanceOf(user1.address)).to.equal(1_000_000_000);

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
        expect(await this.token.balanceOf(user1.address)).to.equal(1_000_000_000);

        //approve and stake
        expect(
          await this.token.connect(user1).approve(this.staking.address, 1_000)
        );
        expect(
          await this.staking.connect(user1).stake(defaultPoolId, 1_000)
        );

        //pool balance
        expect(await this.token.balanceOf(this.staking.address), 1_000);
        //user1 balance
        expect(await this.token.balanceOf(user1.address), 1_000_000_000 - 1_000);
      }),

      it("unstake()", async() => {
        // unstake
        expect(
          await this.staking.connect(user1).unstake(defaultPoolId, 1_000)
        );

        //pool balance
        expect(await this.token.balanceOf(this.staking.address), 1_000 - 1_000);
        //user1 balance
        expect(await this.token.balanceOf(user1.address), 1_000_000_000 - 1_000 + 1_000);
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
          this.staking.connect(user1).unstake(defaultPoolId, 2_000)
        ).to.be.revertedWith('DeciblingStaking: The amount must be smaller than your current staked');
      }),
      it("unstake() to invalid pool id", async () => {
        // unstake
        await expect(
          this.staking.connect(user1).unstake("invalid_pool", 1_000)
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
    })
  });
});