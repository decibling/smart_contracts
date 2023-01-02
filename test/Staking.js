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

const { expect } = require("chai");

const DeciblingStaking = artifacts.require("DeciblingStakingMock");
const Token = artifacts.require("FroggilyToken");

contract("DeciblingStaking", (accounts) => {
  const [admin, platformFeeAddress, user1, user2, artist] = accounts;

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

  beforeEach(async () => {
    this.token = await Token.new({
      from: admin,
    });

    this.token.transfer(user1, ONE_BILLION_TOKENS, {
      from: admin,
    });
    this.token.transfer(user2, ONE_BILLION_TOKENS, {
      from: admin,
    });

    this.staking = await DeciblingStaking.new(
      this.token.address,
      platformFeeAddress,
      {
        from: admin,
      }
    );
  });

  describe("Basic features on default pool", () => {
    it("newPool() from admin", async () => {
      const poolId = "test_pool_admin";
      await this.staking.newPool(poolId, 3, 5, {
        from: admin,
      });
      const poolInfo = await this.staking.pools(poolId);
      expect(poolInfo.r).to.equal(new BN("3"));
      expect(poolInfo.r_to_owner).to.equal(new BN("5"));
      expect(poolInfo.owner).to.equal(admin);
    }),
      it("newPool() from artist", async () => {
        const poolId = "test_pool_artist";
        await this.staking.newPool(poolId, 3, 5, {
          from: artist,
        });
        const poolInfo = await this.staking.pools(poolId);
        expect(poolInfo.r).to.equal(new BN("3"));
        expect(poolInfo.r_to_owner).to.equal(new BN("5"));
        expect(poolInfo.owner).to.equal(artist);
      }),
      it("updatePool() from admin", async () => {
        const poolId = "test_pool_admin";
        await this.staking.newPool(poolId, 3, 5, {
          from: admin,
        });
        let poolInfo = await this.staking.pools(poolId);
        expect(poolInfo.r).to.equal(new BN("3"));
        expect(poolInfo.r_to_owner).to.equal(new BN("5"));
        expect(poolInfo.owner).to.equal(admin);
        await this.staking.updatePool(poolId, 4, 4, {
          from: admin,
        });
        poolInfo = await this.staking.pools(poolId);
        expect(poolInfo.r).to.equal(new BN("4"));
        expect(poolInfo.r_to_owner).to.equal(new BN("4"));
        expect(poolInfo.owner).to.equal(admin);
      }),
      it("updatePool() from artist", async () => {
        const poolId = "test_pool_artist";
        await this.staking.newPool(poolId, 4, 4, {
          from: artist,
        });
        let poolInfo = await this.staking.pools(poolId);
        expect(poolInfo.r).to.equal(new BN("4"));
        expect(poolInfo.r_to_owner).to.equal(new BN("4"));
        expect(poolInfo.owner).to.equal(artist);
        await this.staking.updatePool(poolId, 3, 5, {
          from: artist,
        });
        poolInfo = await this.staking.pools(poolId);
        expect(poolInfo.r).to.equal(new BN("3"));
        expect(poolInfo.r_to_owner).to.equal(new BN("5"));
        expect(poolInfo.owner).to.equal(artist);
      }),
      it("updatePool() error not owner", async () => {
        const poolId = "test_pool_user";
        await this.staking.newPool(poolId, 3, 5, {
          from: user1,
        });
        await expectRevert(
          this.staking.updatePool(poolId, 4, 4, {
            from: user2,
          }),
          "not pool owner"
        );
      }),
      it("updatePool() artist if admin", async () => {
        const poolId = "test_pool_user";
        await this.staking.newPool(poolId, 3, 5, {
          from: artist,
        });
        await this.staking.updatePool(poolId, 4, 4, {
          from: admin,
        });
        poolInfo = await this.staking.pools(poolId);
        expect(poolInfo.r).to.equal(new BN("4"));
        expect(poolInfo.r_to_owner).to.equal(new BN("4"));
        expect(poolInfo.owner).to.equal(artist);
      }),
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
      }),
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
      });
    it("issueToken() normal", async () => {
      let bpd = await balanceOf(
        "Pool Default",
        this.staking.address,
        "initiated"
      );
      let bpa = await balanceOf("Platform A", platformFeeAddress, "initiated");
      let bu1 = await balanceOf("User 1", user1, "initiated");

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

      bpd = await balanceOf(
        "Pool Default",
        this.staking.address,
        "after stake",
        bpd
      );
      bu1 = await balanceOf("User 1", user1, "after stake", bu1);
      bpa = await balanceOf(
        "Platform A",
        platformFeeAddress,
        "after stake",
        bpa
      );

      currentTime = await time.latest();
      shiftTime = currentTime + 86400;
      console.log("Increase time", currentTime, shiftTime);
      await time.increaseTo(new BN(shiftTime));

      console.log("Issue token", user1, defaultPoolId);
      expect(
        await this.staking.issueToken([[user1, defaultPoolId]], {
          from: admin,
        })
      );

      const poolInfo = await this.staking.pools(defaultPoolId);
      const base = weiToEther(poolInfo.base);
      const shifted = (await time.latest()) - currentTime;
      const stakedAmount = 1000;
      console.log(`Pool info: r ${weiToEther(poolInfo.r)} base ${base}`);

      const stakeInfo = await this.staking.stakes(defaultPoolId, user1);
      console.log("Amount:", weiToEther(stakeInfo.amount));
      console.log("Stake time:", stakeInfo.stakeTime.toNumber());
      console.log("Unclaim amount:", weiToEther(stakeInfo.unclaimAmount));

      console.log("Time shifted:", shifted);
      console.log("Expected rewards ~", base * shifted * stakedAmount * 0.95);
      console.log("Expected fee ~", base * shifted * stakedAmount * 0.05);

      await balanceOf("Pool Default", this.staking.address, "", bpd);
      await balanceOf("User 1", user1, "", bu1);
      await balanceOf("Platform A", platformFeeAddress, "", bpa);
    }),
      it("issueToken() with unstake", async () => {
        await this.token.transfer(this.staking.address, ONE_BILLION_TOKENS, {
          from: admin,
        });

        const bpd = await balanceOf(
          "Pool Default",
          this.staking.address,
          "initiated"
        );
        const bpa = await balanceOf(
          "Platform A",
          platformFeeAddress,
          "initiated"
        );
        const bu1 = await balanceOf("User 1", user1, "initiated");

        console.log("User 1 does the stake", weiToEther(ONE_THOUSAND_TOKENS));
        await stake(defaultPoolId, user1, ONE_THOUSAND_TOKENS);

        const bpdA = await balanceOf(
          "Pool Default",
          this.staking.address,
          "after stake",
          bpd
        );
        expect(bpdA).equal(bpd.add(ONE_THOUSAND_TOKENS));
        const bu1A = await balanceOf("User 1", user1, "after stake", bu1);
        expect(bu1A).equal(bu1.sub(ONE_THOUSAND_TOKENS));

        currentTime = await time.latest();
        shiftTime = currentTime + 86400;
        console.log("Increase time", currentTime, shiftTime);
        await time.increaseTo(new BN(shiftTime));

        // unstake
        console.log("User 1 does the unstake", weiToEther(ONE_THOUSAND_TOKENS));
        await this.staking.unstake(defaultPoolId, ONE_THOUSAND_TOKENS, {
          from: user1,
        });

        const bpdB = await balanceOf(
          "Pool Default",
          this.staking.address,
          "after stake",
          bpdA
        );
        expect(bpdB).equal(bpdA.sub(ONE_THOUSAND_TOKENS));
        const bu1B = await balanceOf("User 1", user1, "after stake", bu1A);
        expect(bu1B).equal(bu1A.add(ONE_THOUSAND_TOKENS));

        console.log("Issue token", user1, defaultPoolId);
        await this.staking.issueToken([[user1, defaultPoolId]], {
          from: admin,
        });

        const poolInfo = await this.staking.pools(defaultPoolId);
        const base = poolInfo.base;
        const shifted = (await time.latest()) - currentTime;
        const stakedAmount = ONE_THOUSAND_TOKENS;
        console.log(`Pool info: r ${weiToEther(poolInfo.r)} base ${base}`);

        const stakeInfo = await this.staking.stakes(defaultPoolId, user1);
        console.log("Amount:", weiToEther(stakeInfo.amount));
        console.log("Stake time:", stakeInfo.stakeTime.toNumber());
        console.log("Unclaim amount:", weiToEther(stakeInfo.unclaimAmount));

        console.log("Time shifted:", shifted);
        const totalStaked = (base * shifted * stakedAmount) / 1e18;
        const toUser = totalStaked * 0.95;
        console.log("Expected rewards ~", weiToEther(toUser));
        const toPlatform = totalStaked * 0.05;
        console.log("Expected fee ~", weiToEther(toPlatform));

        const bpaC = await balanceOf(
          "Platform A",
          platformFeeAddress,
          "after claims",
          bpa
        );
        expect(bpaC / 1e18).closeTo(5, 0.05);
        const bu1C = await balanceOf("User 1", user1, "after claims", bu1B);
        expect((bu1C - bu1B) / 1e18).closeTo(95, 0.05);
        const bpdC = await balanceOf(
          "Pool Default",
          this.staking.address,
          "after claims",
          bpdB
        );
        expect((bpdC - bpdB) / 1e18).closeTo(-100, 0.05);
      }),
      it("renewUnclaimAmount() with stake", async () => {
        let bpd = await balanceOf(
          "Pool Default",
          this.staking.address,
          "initiated"
        );
        let bpa = await balanceOf(
          "Platform A",
          platformFeeAddress,
          "initiated"
        );
        let bu1 = await balanceOf("User 1", user1, "initiated");

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

        bpd = await balanceOf(
          "Pool Default",
          this.staking.address,
          "after stake",
          bpd
        );
        bu1 = await balanceOf("User 1", user1, "after stake", bu1);
        bpa = await balanceOf(
          "Platform A",
          platformFeeAddress,
          "after stake",
          bpa
        );

        currentTime = await time.latest();
        shiftTime = currentTime + 86400;
        console.log("Increase time", currentTime, shiftTime);
        await time.increaseTo(new BN(shiftTime));

        // stake
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

        const poolInfo = await this.staking.pools(defaultPoolId);
        const base = weiToEther(poolInfo.base);
        console.log(`Pool info: r ${weiToEther(poolInfo.r)} base ${base}`);

        const stakeInfo = await this.staking.stakes(defaultPoolId, user1);
        console.log("Amount:", weiToEther(stakeInfo.amount));
        console.log("Stake time:", stakeInfo.stakeTime.toNumber());
        console.log("Unclaim amount:", weiToEther(stakeInfo.unclaimAmount));
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
