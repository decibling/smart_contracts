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

contract("DeciblingReserve", () => {
  let user1, user2;

  const ZERO_ADDRESS = '0x0000000000000000000000000000000000000000';
  const ONE_BILLION = BigNumber.from("1000000000000000000000000000");
  const TEN_MILLION = BigNumber.from("10000000000000000000000000");
  const ONE_MILLION = BigNumber.from("1000000000000000000000000");

  describe("Basic features on default pool", () => {
    beforeEach(async () => {
      accounts = await ethers.getSigners();
      user1 = accounts[2];
      user2 = accounts[3];

      const MyToken = await ethers.getContractFactory("FroggilyToken");
      const myToken = await MyToken.deploy();
      this.token = await myToken.deployed();

      const Faucet = await ethers.getContractFactory("DeciblingFaucet");
      this.faucet = await upgrades.deployProxy(Faucet, [this.token.address], {
        initializer: "initialize"
      });
      await this.faucet.deployed();

      await this.token.transfer(this.faucet.address, ONE_BILLION); //send to faucet
    });
    it("request default", async () => {
        expect(
          await this.faucet.connect(user1).request()
        );

        console.log(await this.token.balanceOf(this.faucet.address));
        console.log(await this.token.balanceOf(user1.address));

        await expectRevert.unspecified(
          this.faucet.connect(user1).request()
        );

        const startTime = await this.faucet.faucets(user1.address);

        await ethers.provider.send("evm_setNextBlockTimestamp", [startTime.add(3600).toNumber()]);
        await ethers.provider.send("evm_mine");

        expect(
          await this.faucet.connect(user1).request()
        );

        console.log(await this.token.balanceOf(this.faucet.address));
        console.log(await this.token.balanceOf(user1.address));
      })
  });
});