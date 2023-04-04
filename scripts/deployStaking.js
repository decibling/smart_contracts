const { ethers, upgrades } = require("hardhat");

async function main() {
    const [deployer] = await ethers.getSigners();

    // Deploy MyToken contract
    // const MyToken = await ethers.getContractFactory("MyToken");
    // const myToken = await MyToken.deploy();
    // await myToken.deployed();
    // console.log("MyToken deployed to:", myToken.address); 0x5FbDB2315678afecb367f032d93F642f64180aa3

    // Deploy DeciblingStaking contract
    const DeciblingStaking = await ethers.getContractFactory("DeciblingStaking");
    const dbStaking = await upgrades.deployProxy(
        DeciblingStaking,
        [ "0x5FbDB2315678afecb367f032d93F642f64180aa3", deployer.address],
        { initializer: "initialize" }
    );
    await dbStaking.deployed();
    console.log("DeciblingStaking deployed to:", dbStaking.address);
}

main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error);
        process.exit(1);
    });
