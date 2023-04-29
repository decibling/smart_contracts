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
  expect,
  assert
} = require("chai");
const {
  ZERO_ADDRESS
} = require("@openzeppelin/test-helpers/src/constants");
const {
  BigNumber,
  utils
} = require("ethers");
const {
  ethers
} = require("hardhat");

contract("DeciblingTreasury", () => {
  let admin, user1, user2, artist;

  const ZERO_ADDRESS = '0x0000000000000000000000000000000000000000';
  const ONE_BILLION = BigNumber.from("1000000000000000000000000000");
  const TEN_MILLION = BigNumber.from("10000000000000000000000000");
  const ONE_MILLION = BigNumber.from("1000000000000000000000000");

  const defaultPoolId = "decibling_pool";

  describe("Basic features on default pool", () => {
    beforeEach(async () => {
      accounts = await ethers.getSigners();
      admin = accounts[0];
      artist = accounts[1];
      user1 = accounts[2];
      user2 = accounts[3];

      const MyToken = await ethers.getContractFactory("FroggilyToken");
      const myToken = await MyToken.deploy();
      this.token = await myToken.deployed();

      await this.token.transfer(user1.address, ONE_BILLION);
      await this.token.transfer(user2.address, ONE_BILLION);

      const Staking = await ethers.getContractFactory("DeciblingStaking");
      this.staking = await upgrades.deployProxy(Staking, [this.token.address], {
        initializer: "initialize"
      });
      await this.staking.deployed();

      const Treasury = await ethers.getContractFactory("DeciblingTreasury");
      this.treasury = await upgrades.deployProxy(Treasury, [this.token.address], {
        initializer: "initialize"
      });
      await this.staking.deployed();

      await this.staking.setDefaultPool();

      //set contracts
      await this.treasury.setStakingContract(this.staking.address);
      await this.staking.setTreasuryContract(this.treasury.address);

      await this.token.transfer(this.treasury.address, ONE_BILLION); //send to treasury
    });
    it("requestPayout", async () => {
      expect(await this.token.balanceOf(this.staking.address)).to.equal(0);
      expect(await this.token.balanceOf(user1.address)).to.equal(ONE_BILLION);

      //approve and stake
      expect(
        await this.token.connect(user1).approve(this.staking.address, ONE_MILLION)
      );
      expect(
        await this.staking.connect(user1).stake(defaultPoolId, ONE_MILLION)
      );

      //pool balance
      expect(await this.token.balanceOf(this.staking.address)).to.equal(ONE_MILLION);
      //user1 balance
      expect(await this.token.balanceOf(user1.address)).to.equal(ONE_BILLION.sub(ONE_MILLION));

      // fast forward time to start of auction
      let depositTime = (await this.staking.stakers(defaultPoolId, user1.address)).depositTime;
      await ethers.provider.send("evm_setNextBlockTimestamp", [depositTime.toNumber() + (10 * 86400)]);
      await ethers.provider.send("evm_mine");

      let payout = await this.staking.connect(user1).payout(defaultPoolId, user1.address, false);
      let fee = await this.treasury.payoutFee();
      let payAmount = (payout * (100 - fee) / 100);
      let approx = 1000000000000000n;

      expect(await this.staking.connect(user1).claim(defaultPoolId));

      expect(await this.token.balanceOf(this.staking.address)).to.equal(ONE_MILLION);
      expect((await this.token.balanceOf(this.treasury.address))).to.closeTo((ONE_BILLION.sub(BigInt(payAmount))), approx);
      expect(await this.token.balanceOf(user1.address)).to.closeTo(ONE_BILLION.sub(ONE_MILLION).add(BigInt(payAmount)), approx);

      console.log(payout, fee, payAmount);
      console.log(await this.token.balanceOf(this.staking.address));
      console.log(await this.token.balanceOf(this.treasury.address));
      console.log(await this.token.balanceOf(user1.address));
    })
  });
});