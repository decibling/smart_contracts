const { ethers, upgrades } = require("hardhat");

async function main() {
    const [deployer] = await ethers.getSigners();

    // Deploy MyToken contract
    const MyToken = await ethers.getContractFactory("MyToken");
    const myToken = await MyToken.deploy();
    await myToken.deployed();
    console.log("MyToken deployed to:", myToken.address);

    // Deploy DeciblingNFT contract
    const DeciblingNFT = await ethers.getContractFactory("DeciblingNFT");
    const deciblingNFT = await upgrades.deployProxy(DeciblingNFT, [], { initializer: "initialize" });
    await deciblingNFT.deployed();
    console.log("DeciblingNFT deployed to:", deciblingNFT.address);

    // Deploy DeciblingAuctionV2 contract
    const DeciblingAuctionV2 = await ethers.getContractFactory("DeciblingAuctionV2");
    const deciblingAuctionV2 = await upgrades.deployProxy(
        DeciblingAuctionV2,
        [deciblingNFT.address, myToken.address, deployer.address],
        { initializer: "initialize" }
    );
    await deciblingAuctionV2.deployed();
    console.log("DeciblingAuctionV2 deployed to:", deciblingAuctionV2.address);
}

main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error);
        process.exit(1);
    });
