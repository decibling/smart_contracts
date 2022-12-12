// hre.storageLayout.export();
// 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc

require("@nomiclabs/hardhat-web3");
const { ethers } = require('ethers');

function increaseHexByOne(hex, added) {
    let x = ethers.BigNumber.from(hex)
    let sum = x.add(added)
    let result = sum.toHexString()
    return result
}

async function main() {
    // Array(100).fill(1).forEach(async (e, i) => console.log(i, await web3.eth.getStorageAt("0xAB557fA0b2613f6230c7c96534ECae3df710B078", i)))


    // let index = "9".toString().padStart(64, '0')
    // let data = Buffer.from('QmWKgTCj6xAMi2QQ6vG5xWA9Xh5MF8v6GkuYuptKjGoZ9C').toString('hex');
    // data = ("0x" + data);
    // for (j = 0; j < 5; j++) {
    //     let newKey = web3.utils.sha3(data + index, { "encoding": "hex" });
    //     let a = await web3.eth.getStorageAt("0xf9ce0E872A36fEC962f454C63E19e69Dc2Dde4d4", increaseHexByOne(newKey, j));
    //     if (a != 0) {
    //         console.log('DATA FOUND-> ', j, a);
    //     } else {
    //         // break;
    //     }
    // }
    console.log(await web3.eth.getStorageAt("0x1d6B587c74E456D5390e10d49B9ecb28CD8a5830", "0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc"));
}
main();