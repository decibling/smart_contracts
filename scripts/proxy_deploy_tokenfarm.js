const hre = require("hardhat");
const { ethers } = require("hardhat");

async function main() {
    var tokenAddress = "";
    var tokenFarmAddress = "";
    var proxyAdmin = "";
    var proxyAddress = "";
    if (tokenAddress.length == 0) {
        console.log("[+]Deploying token Froggily ...");
        const db = await hre.ethers.getContractFactory("DeciblingToken");
        const dbTx = await db.deploy();
        console.log("[+]Deployed Froggily : " + dbTx.address);
        if (tokenFarmAddress.length == 0) {
            console.log("[+]Deploying TokenFarm ...");
            const tokenFarm = await hre.ethers.getContractFactory("TokenFarm");
            const tokenFarmTx = await tokenFarm.deploy(dbTx.address);
            console.log("[+]Deployed TokenFarm : " + tokenFarmTx.address);
            if (proxyAdmin.length == 0) {
                console.log("[+]Deploying ProxAdmin ...");
                const proxAdmin = await hre.ethers.getContractFactory("ProxyAdmin");
                const proxAdminTx = (await proxAdmin.deploy());
                console.log("[+]Deployed ProxAdmin : " + proxAdminTx.address);
                if (proxyAddress.length == 0) {
                    console.log("[+]Deploying TransparentUpgradeableProxy...");
                    const dbProxy = await hre.ethers.getContractFactory("TransparentUpgradeableProxy");
                    const dbProxyTx = await dbProxy.deploy(tokenFarmTx.address, proxAdminTx.address, "0x");
                    console.log("DEPLOYED PROXY IMPLEMENTATION: " + dbProxyTx.address);

                }
            }
        }
    }
}

main().catch((error) => {
    console.error(error);
    process.exitCode = 1;
});
