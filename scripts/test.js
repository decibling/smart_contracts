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


    for (i = 9; i < 15; i++) {
        let index = i.toString().padStart(64, '0')
        let data = Buffer.from('QmWKgTCj6xAMi2QQ6vG5xWA9Xh5MF8v6GkuYuptKjGoZ9C').toString('hex');
        data = ("0x" + data);
        for (j = 0; j < 5; j++) {
            let newKey = web3.utils.sha3(data + index, { "encoding": "hex" });
            let a = await web3.eth.getStorageAt("0x8BCA4b50Df16B7FBeC8755e37910476fd8BC92Ac", increaseHexByOne(newKey, j));
            if (a != 0) {
                console.log('DATA FOUND-> ', i, j, a);
            } else {
                // break;
            }
        }
    }
    await
        hre.storageLayout.export();

}
main();