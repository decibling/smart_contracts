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

    // Deploy DeciblingNFT contract
    // const DeciblingNFT = await ethers.getContractFactory("DeciblingNFT");
    // const deciblingNFT = await upgrades.deployProxy(DeciblingNFT, [], {
    //     initializer: "initialize"
    // });
    // await deciblingNFT.deployed();
    // console.log("DeciblingNFT deployed to:", deciblingNFT.address);

    // Deploy DeciblingNFT contract
    // const DeciblingReserve = await ethers.getContractFactory("DeciblingReserve");
    // const deciblingReserve = await upgrades.deployProxy(DeciblingReserve, [myToken.address], {
    //     initializer: "initialize"
    // });
    // await deciblingNFT.deployed();
    // console.log("DeciblingReserve deployed to:", deciblingReserve.address);

    // Deploy DeciblingAuction contract
    const DeciblingAuction = await ethers.getContractFactory("DeciblingAuction");
    const deciblingAuction = await upgrades.deployProxy(
        DeciblingAuction, ["0xAa8ADb51329BA9640D86Aa10b0F374d97A7B31d9", "0x33634B1Cd1B1c5783cA6Eab3E464464644ad7F73", "0x6D4b9E456F70504787158491f16c5b6eDC09B3CF"], {
            initializer: "initialize"
        });
    console.log("DeciblingAuction deployed to:", deciblingAuction.address);
}

main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error);
        process.exit(1);
    });