const {
    ethers,
    upgrades
} = require("hardhat");

async function main() {
    const [deployer] = await ethers.getSigners();

    const DeciblingStaking = await ethers.getContractFactory("DeciblingStaking");
    // const dbStaking = await upgrades.deployProxy(
    //     DeciblingStaking,
    //     ["0x33634B1Cd1B1c5783cA6Eab3E464464644ad7F73"], {
    //         initializer: "initialize"
    //     }
    // );
    // await dbStaking.deployed();
    // console.log("DeciblingStaking deployed to:", dbStaking.address);

    // // Deploy DeciblingReserve contract
    const DeciblingReserve = await ethers.getContractFactory("DeciblingReserve");
    // const dbReserve = await upgrades.deployProxy(
    //     DeciblingReserve,
    //     ["0x33634B1Cd1B1c5783cA6Eab3E464464644ad7F73"], {
    //         initializer: "initialize"
    //     }
    // );
    // await dbReserve.deployed();
    // console.log("DeciblingReserve deployed to:", dbReserve.address);

    // console.log("Settings");
    let dbStaking = DeciblingStaking.attach("0xE2678C127C4b68DC46Bd52b7991613885c5b212A");
    let dbReserve = DeciblingReserve.attach("0x2cc52A8d5544eD2A5cd66CC0Cb0E2504FC2C55F7");
    await dbStaking.setReserveContract(dbReserve.address);
    await dbReserve.setStakingContract(dbStaking.address);
    await dbStaking.setDefaultPool();
}

main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error);
        process.exit(1);
    });