const hre = require("hardhat");
const { ethers, upgrades } = require("hardhat");

async function main() {
    var tokenAddress = "";
    var tokenFarmAddress = "";
    var proxyAdmin = "";
    var proxyAddress = "";
    if (tokenAddress.length == 0) {
        console.log("[+]Deploying Bidding contract ...");
        const db = await hre.ethers.getContractFactory("DbAudio");
        const dbTx = await upgrades.deployProxy(db, []);
        // const dbTx = await db.deploy();
        // await dbTx.deployed();
        console.log("[+]Deployed Bidding contract : " + dbTx.address);
        // if (proxyAdmin.length == 0) {
        //     console.log("[+]Deploying ProxAdmin ...");
        //     const proxAdmin = await hre.ethers.getContractFactory("ProxyAdmin");
        //     const proxAdminTx = (await proxAdmin.deploy());
        //     if (proxyAddress.length == 0) {
        //         console.log("[+]Deploying TransparentUpgradeableProxy...");
        //         const dbProxy = await hre.ethers.getContractFactory("TransparentUpgradeableProxy");
        //         const dbProxyTx = await dbProxy.deploy(dbTx.address, proxAdminTx.address, "0x");
        //         console.log("DEPLOYED PROXY IMPLEMENTATION: " + dbProxyTx.address);
        //     }
        // }
    }
}

main().catch((error) => {
    console.error(error);
    process.exitCode = 1;
});
