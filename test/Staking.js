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
  let admin, platformFeeAddress, user1, user2, artist;

  const ZERO = new BN("0");
  const TOKEN_ONE_ID = new BN("1");
  const TOKEN_TWO_ID = new BN("2");
  const TWENTY_TOKENS = new BN("20000000000000000000");
  const ONE_TOKENS = new BN("1000000000000000000");
  const ONE_THOUSAND_TOKENS = new BN("1000000000000000000000");
  const ONE_MILLION_TOKENS = new BN("1000000000000000000000000");
  const ONE_BILLION_TOKENS = new BN("1000000000000000000000000000");

  const defaultPoolId = "decibling_pool";
  const randomTokenURI = "rand";

  describe("Basic features on default pool", () => {
    beforeEach(async () => {
      accounts = await ethers.getSigners();
      admin = accounts[0];
      artist = accounts[1];
      user1 = accounts[2];
      user2 = accounts[3];

      this.token = await Token.new();

      this.token.transfer(user1, ONE_BILLION_TOKENS, {
        from: admin,
      });
      this.token.transfer(user2, ONE_BILLION_TOKENS, {
        from: admin,
      });

      Staking = await ethers.getContractFactory("DeciblingStaking");
      this.staking = await upgrades.deployProxy(Staking, [this.token.address], {
        initializer: "initialize"
      });
      await this.staking.deployed();
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
        const bpd = await balanceOf(
          "Pool Default",
          this.staking.address,
          "initiated"
        );
        const bu1 = await balanceOf("User 1", user1, "initiated");

        console.log("User 1 does the stake", weiToEther(ONE_THOUSAND_TOKENS));
        expect(
          await this.token.approve(this.staking.address, ONE_THOUSAND_TOKENS, {
            from: user1,
          })
        );
        expect(
          await this.staking.stake(defaultPoolId, ONE_THOUSAND_TOKENS, {
            from: user1,
          })
        );

        expect(
          await balanceOf(
            "Pool Default",
            this.staking.address,
            "after a stake",
            bpd
          )
        ).to.equal(ONE_THOUSAND_TOKENS);
        expect(await balanceOf("User 1", user1, "after a stake", bu1)).to.equal(
          bu1.sub(ONE_THOUSAND_TOKENS)
        );
      }),
      it("stake() with zero value", async () => {
        console.log("User 1 does the stake", weiToEther(ONE_THOUSAND_TOKENS));
        expect(
          await this.token.approve(this.staking.address, ZERO, {
            from: user1,
          })
        );
        await expectRevert(
          this.staking.stake(defaultPoolId, ZERO, {
            from: user1,
          }),
          "amount must be larger than zero"
        );
      });
    it("unstake()", async () => {
        const bpd = await balanceOf(
          "Pool Default",
          this.staking.address,
          "initiated"
        );
        const bu1 = await balanceOf("User 1", user1, "initiated");

        // stake first
        console.log("User 1 does the stake", weiToEther(ONE_THOUSAND_TOKENS));
        await this.token.approve(this.staking.address, ONE_THOUSAND_TOKENS, {
          from: user1,
        });
        await this.staking.stake(defaultPoolId, ONE_THOUSAND_TOKENS, {
          from: user1,
        });

        // unstake
        expect(
          await balanceOf(
            "Pool Default",
            this.staking.address,
            "after a stake",
            bpd
          )
        ).to.equal(ONE_THOUSAND_TOKENS);
        expect(await balanceOf("User 1", user1, "after a stake", bu1)).to.equal(
          bu1.sub(ONE_THOUSAND_TOKENS)
        );

        console.log("User 1 does the unstake", weiToEther(ONE_THOUSAND_TOKENS));
        expect(
          await this.staking.unstake(defaultPoolId, ONE_THOUSAND_TOKENS, {
            from: user1,
          })
        );

        expect(
          await balanceOf(
            "Pool Default",
            this.staking.address,
            "after an unstake",
            bpd
          )
        ).to.equal(ZERO);
        expect(await balanceOf("User 1", user1, "after an unstake")).to.equal(
          bu1
        );
      }),
      it("unstake() with zero value", async () => {
        const bpd = await balanceOf(
          "Pool Default",
          this.staking.address,
          "initiated"
        );
        const bu1 = await balanceOf("User 1", user1, "initiated");

        // stake first
        console.log("User 1 does the stake", weiToEther(ONE_THOUSAND_TOKENS));
        await this.token.approve(this.staking.address, ONE_THOUSAND_TOKENS, {
          from: user1,
        });
        await this.staking.stake(defaultPoolId, ONE_THOUSAND_TOKENS, {
          from: user1,
        });

        // unstake
        expect(
          await balanceOf(
            "Pool Default",
            this.staking.address,
            "after a stake",
            bpd
          )
        ).to.equal(ONE_THOUSAND_TOKENS);
        expect(await balanceOf("User 1", user1, "after a stake", bu1)).to.equal(
          bu1.sub(ONE_THOUSAND_TOKENS)
        );

        console.log("User 1 does the unstake", weiToEther(ZERO));
        await expectRevert(
          this.staking.unstake(defaultPoolId, ZERO, {
            from: user1,
          }),
          "amount must be larger than zero"
        );
      }),
      it("unstake() with value larger than staked amount", async () => {
        const bpd = await balanceOf(
          "Pool Default",
          this.staking.address,
          "initiated"
        );
        const bu1 = await balanceOf("User 1", user1, "initiated");

        // stake first
        console.log("User 1 does the stake", weiToEther(TWENTY_TOKENS));
        await this.token.approve(this.staking.address, TWENTY_TOKENS, {
          from: user1,
        });
        await this.staking.stake(defaultPoolId, TWENTY_TOKENS, {
          from: user1,
        });

        //unstake
        expect(
          await balanceOf(
            "Pool Default",
            this.staking.address,
            "after a stake",
            bpd
          )
        ).to.equal(TWENTY_TOKENS);
        expect(await balanceOf("User 1", user1, "after a stake", bu1)).to.equal(
          bu1.sub(TWENTY_TOKENS)
        );

        console.log("User 1 does the unstake", weiToEther(ONE_THOUSAND_TOKENS));
        await expectRevert(
          this.staking.unstake(defaultPoolId, ONE_THOUSAND_TOKENS, {
            from: user1,
          }),
          "23"
        );
      }),
      it("unstake() to invalid pool id", async () => {
        const bpd = await balanceOf(
          "Pool Default",
          this.staking.address,
          "initiated"
        );
        const bu1 = await balanceOf("User 1", user1, "initiated");

        // stake first
        console.log("User 1 does the stake", weiToEther(ONE_THOUSAND_TOKENS));
        await this.token.approve(this.staking.address, ONE_THOUSAND_TOKENS, {
          from: user1,
        });
        await this.staking.stake(defaultPoolId, ONE_THOUSAND_TOKENS, {
          from: user1,
        });

        // unstake
        expect(
          await balanceOf(
            "Pool Default",
            this.staking.address,
            "after a stake",
            bpd
          )
        ).to.equal(ONE_THOUSAND_TOKENS);
        expect(await balanceOf("User 1", user1, "after a stake", bu1)).to.equal(
          bu1.sub(ONE_THOUSAND_TOKENS)
        );

        console.log("User 1 does the unstake", weiToEther(ZERO));
        await expectRevert(
          this.staking.unstake(defaultPoolId + "invalid", ZERO, {
            from: user1,
          }),
          "not an active pool"
        );
      });
    it("updatePoolOwner()", async () => {
        const poolId = "test_pool_user";
        await this.staking.newPool(poolId, 3, 5, {
          from: user1,
        });
        await this.staking.updatePoolOwner(poolId, user2, {
          from: user1,
        });
      }),
      it("updatePoolOwner() from admin", async () => {
        const poolId = "test_pool_user";
        await this.staking.newPool(poolId, 3, 5, {
          from: user1,
        });
        await this.staking.updatePoolOwner(poolId, user2, {
          from: admin,
        });
      }),
      it("updatePoolOwner() with invalid id", async () => {
        const poolId = "test_pool_user";
        await this.staking.newPool(poolId, 3, 5, {
          from: user1,
        });
        await expectRevert(this.staking.updatePoolOwner("", user2, {
          from: user1,
        }), 'invalid pool id');
      }),
      it("updatePoolOwner() with invalid address", async () => {
        const poolId = "test_pool_user";
        await this.staking.newPool(poolId, 3, 5, {
          from: user1,
        });
        await expectRevert(this.staking.updatePoolOwner(poolId, ZERO_ADDRESS, {
          from: user1,
        }), '21');
      }),
      it("updatePoolOwner() invalid owner", async () => {
        const poolId = "test_pool_user";
        await this.staking.newPool(poolId, 3, 5, {
          from: user1,
        });
        await expectRevert(this.staking.updatePoolOwner(poolId, user1, {
          from: user2,
        }), "not pool owner or admin");
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

const weiToEther = (n) => {
  return web3.utils.fromWei(n.toString(), "ether");
};

const toPercent = (n) => {
  return n / 1e3;
};

const stake = async (poolId, user, value) => {
  await this.token.approve(this.staking.address, value, {
    from: user,
  });
  await this.staking.stake(poolId, value, {
    from: user,
  });
};