const {
    ethers,
    upgrades
} = require("hardhat");

async function main() {
    const [deployer] = await ethers.getSigners();

    // Deploy MyToken contract
    // const MyToken = await ethers.getContractFactory("FroggilyToken");
    // const myToken = await MyToken.deploy();
    // await myToken.deployed();
    // console.log("FroggilyToken deployed to:", myToken.address);

    // Deploy DeciblingStaking contract
    const DeciblingStaking = await ethers.getContractFactory("DeciblingStaking");
    // const dbStaking = await upgrades.forceImport(
    //     "0xAb2B61C03A5c6c6b9CC4810F80b29ae14D75256F",
    //     DeciblingStaking,
    // );
    // const dbStaking = await upgrades.validateUpgrade(
    //     "0xAb2B61C03A5c6c6b9CC4810F80b29ae14D75256F",
    //     DeciblingStaking,
    // );
    const dbStaking = await upgrades.upgradeProxy(
        "0xAb2B61C03A5c6c6b9CC4810F80b29ae14D75256F",
        DeciblingStaking,
    );
    // await dbStaking.deployed();
    // console.log("DeciblingStaking deployed to:", dbStaking.address);

    // Deploy DeciblingReserve contract
    // const DeciblingReserve = await ethers.getContractFactory("DeciblingReserve");
    // const dbReserve = await upgrades.deployProxy(
    //     DeciblingReserve,
    //     [myToken.address], {
    //         initializer: "initialize"
    //     }
    // );
    // await dbReserve.deployed();
    // console.log("DeciblingReserve deployed to:", dbReserve.address);

    // console.log("Settings");
    // let dbStaking = DeciblingStaking.attach("0xAb2B61C03A5c6c6b9CC4810F80b29ae14D75256F");
    // let dbReserve = DeciblingReserve.attach("0x77E23179173Ab05a17f7DD546d5bbEd9044560d0");
    // await dbStaking.setReserveContract(dbReserve.address);
    // await dbReserve.setStakingContract(dbStaking.address);
}

main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error);
        process.exit(1);
    });