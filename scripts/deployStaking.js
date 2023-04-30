const {
    ethers,
    upgrades
} = require("hardhat");

async function main() {
    const [deployer] = await ethers.getSigners();

    // Deploy MyToken contract
    const MyToken = await ethers.getContractFactory("FroggilyToken");
    const myToken = await MyToken.deploy();
    await myToken.deployed();
    console.log("FroggilyToken deployed to:", myToken.address);

    // Deploy DeciblingStaking contract
    const DeciblingStaking = await ethers.getContractFactory("DeciblingStaking");
    const dbStaking = await upgrades.deployProxy(
        DeciblingStaking,
        [myToken.address], {
            initializer: "initialize"
        }
    );
    await dbStaking.deployed();
    console.log("DeciblingStaking deployed to:", dbStaking.address);

    // Deploy DeciblingReserve contract
    const DeciblingReserve = await ethers.getContractFactory("DeciblingReserve");
    const dbReserve = await upgrades.deployProxy(
        DeciblingReserve,
        [myToken.address], {
            initializer: "initialize"
        }
    );
    await dbReserve.deployed();
    console.log("DeciblingReserve deployed to:", dbReserve.address);

    console.log("Settings");
    dbStaking.setReserveContract(dbReserve.address);
    dbReserve.setStakingContract(dbStaking.address);
}

main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error);
        process.exit(1);
    });