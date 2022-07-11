const { expect } = require("chai");
const { ethers } = require("hardhat");
const TokenFarm = require("../artifacts/contracts/TokenFarm.sol/TokenFarm.json");

const contractAddress = "0x34BCcb3498a42cE3ba362EeD5f56798910Af554f";
describe("DbAudio", function () {
  it("stake some money", async function () {
    const [owner] = await ethers.getSigners();
    const contract = ethers.contract(
      contractAddress,
      TokenFarm.abi,
      owner
    )
      console.log(contract);
  });
});
