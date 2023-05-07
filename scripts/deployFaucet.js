const {
    ethers,
    upgrades
} = require("hardhat");

async function main() {
    const [deployer] = await ethers.getSigners();

    // Deploy DeciblingStaking contract
    const DeciblingFaucet = await ethers.getContractFactory("DeciblingFaucet");
    const dbFaucet = await upgrades.deployProxy(
        DeciblingFaucet,
        ["0x33634B1Cd1B1c5783cA6Eab3E464464644ad7F73"], {
            initializer: "initialize"
        }
    );
    await dbFaucet.deployed();
    console.log("DeciblingFaucet deployed to:", dbFaucet.address);
}

main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error);
        process.exit(1);
    });