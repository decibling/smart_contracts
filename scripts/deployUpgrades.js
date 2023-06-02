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
    const DeciblingStaking = await ethers.getContractFactory("DeciblingStaking");

    await upgrades.validateUpgrade("0xfD269C44f98f2af253f66897F24fBAD7926bcb18", DeciblingStaking)
    await upgrades.validateUpgrade("0x6D4b9E456F70504787158491f16c5b6eDC09B3CF", DeciblingReserve)
}

main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error);
        process.exit(1);
    });