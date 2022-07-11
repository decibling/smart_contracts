// We require the Hardhat Runtime Environment explicitly here. This is optional
// but useful for running the script in a standalone fashion through `node <script>`.
//
// When running the script with `npx hardhat run <script>` you'll find the Hardhat
// Runtime Environment's members available in the global scope.
const hre = require("hardhat");
const { ethers } = require("hardhat");

async function main() {
  // Hardhat always runs the compile task when running scripts with its command
  // line interface.
  //
  // If this script is run directly using `node` you may want to call compile
  // manually to make sure everything is compiled
  // await hre.run('compile');

  // We get the contract to deploy
  // const DeciblingToken = await hre.ethers.getContractFactory("DeciblingToken");
  // const dbaudio = await DeciblingToken.deploy();

  // await dbaudio.deployed();

  // console.log("DeciblingToken deployed to:", dbaudio.address);
  const accounts = await hre.ethers.getSigners();

}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
// owner transfer to 0x4E27Bc09a0C840C54FBbF30E605f522b30373116
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
