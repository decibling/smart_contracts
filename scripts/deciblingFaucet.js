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
        ["0xaa8adb51329ba9640d86aa10b0f374d97a7b31d9"], {
            initializer: "initialize"
        }
    );
    await dbFaucet.deployed();
    console.log("DeciblingStaking deployed to:", dbFaucet.address);
}

main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error);
        process.exit(1);
    });