const {
    ethers,
    upgrades
} = require("hardhat");

async function main() {
    const [deployer] = await ethers.getSigners();

    // Deploy MyToken contract
    const MyToken = "0x33634B1Cd1B1c5783cA6Eab3E464464644ad7F73";
    const DeciblingNFT = await ethers.getContractFactory("DeciblingNFT");
    const DeciblingReserve = await ethers.getContractFactory("DeciblingReserve");
    const DeciblingAuction = await ethers.getContractFactory("DeciblingAuction");

    await upgrades.validateUpgrade("0x2a3d9fAf012A9A60583eCea22F09b98839359441", DeciblingAuction)
}

main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error);
        process.exit(1);
    });