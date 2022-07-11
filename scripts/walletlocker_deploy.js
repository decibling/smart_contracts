// We require the Hardhat Runtime Environment explicitly here. This is optional
// but useful for running the script in a standalone fashion through `node <script>`.
//
// When running the script with `npx hardhat run <script>` you'll find the Hardhat
// Runtime Environment's members available in the global scope.
const hre = require("hardhat");

async function main() {
  // Hardhat always runs the compile task when running scripts with its command
  // line interface.
  //
  // If this script is run directly using `node` you may want to call compile
  // manually to make sure everything is compiled
  // await hre.run('compile');

  // We get the contract to deploy
  //   const DbAudio = await hre.ethers.getContractFactory("DeciblingToken");
  //   const dbaudio = await DbAudio.deploy();

  //   await dbaudio.deployed();
  //   console.log("DbAudio deployed to:", dbaudio.address);

  const WalletLocker = await hre.ethers.getContractFactory("WalletLocker");
  const tf = await WalletLocker.deploy(
    "0x0317e82cBDA8188b8d67d817b81De0E781aBa0E9"
  );

  await tf.deployed();
  console.log("WalletLocker deployed to:", tf.address);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
