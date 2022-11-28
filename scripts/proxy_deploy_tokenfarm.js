const hre = require("hardhat");
const { ethers, upgrades } = require("hardhat");

async function main() {
    var tokenAddress = "";
    var tokenFarmAddress = "";
    var proxyAdmin = "";
    var proxyAddress = "";
    if (tokenAddress.length == 0) {
        // console.log("[+]Deploying token Froggily ...");
        // const db = await hre.ethers.getContractFactory("DeciblingToken");
        // const dbTx = await db.deploy();
        // console.log("[+]Deployed Froggily : " + dbTx.address);
        if (tokenFarmAddress.length == 0) {
            console.log("[+]Deploying TokenFarm ...");
            const tokenFarm = await hre.ethers.getContractFactory("TokenFarm");
            const tokenFarmTx = await tokenFarm.deploy();
            console.log("DEPPLOYED : " + tokenFarmTx.address);
        }
    }
}

main().catch((error) => {
    console.error(error);
    process.exitCode = 1;
});
