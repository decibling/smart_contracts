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


    for (i = 9; i <= 9; i++) {
        let index = i.toString().padStart(64, '0')
        let data = Buffer.from('QmX2bKvrPjGq5PvAqwEcQ5CYYa7WQNBzTnFvN15eNZbxrj').toString('hex');
        data = ("0x" + data);
        console.log(data);
        // console.log(data);
        var newKey = web3.utils.sha3(data + index, { "encoding": "hex" });
        for (j = 0; j < 6; j++) {
            let a;
            if (j == 2) {
                // mapping(string => int) listInt;
                let data2 = Buffer.from('aaa').toString('hex');
                data2 = ("0x" + data2);
                // let mykey = web3.utils.sha3(newKey + data2 + j.toString().padStart(64, "0"), { "encoding": "hex" });
                // let mykey = increaseHexByOne(newKey, data2);
                // let mykey = web3.utils.sha3(newKey + data2 + j.toString().padStart(64, "0"), { "encoding": "hex" });
                // let mykey = web3.utils.sha3(newKey + data2, { "encoding": "hex" });
                // let mykey = web3.utils.sha3(data2 + newKey, { "encoding": "hex" });
                // let mykey = web3.utils.sha3(increaseHexByOne(newKey, data2), { "encoding": "hex" });
                // let mykey = increaseHexByOne(newKey, web3.utils.sha3(data2 + j.toString().padStart(64, "0"), { "encoding": "hex" }))
                // let mykey = web3.utils.sha3(data + index + data2 + j.toString().padStart(64, "0"), { "encoding": "hex" });
                let mykey = web3.utils.sha3(data2 + increaseHexByOne(newKey, j).replace(/0x/, ''), { "encoding": "hex" });
                a = await web3.eth.getStorageAt("0x5081a39b8A5f0E35a8D959395a630b68B74Dd30f", mykey);
                console.log('DATA FOUND-> ', i, j, 'aaa', a);
                data2 = Buffer.from('bbb').toString('hex');
                data2 = ("0x" + data2);
                mykey = web3.utils.sha3(data2 + increaseHexByOne(newKey, j).replace(/0x/, ''), { "encoding": "hex" });
                a = await web3.eth.getStorageAt("0x5081a39b8A5f0E35a8D959395a630b68B74Dd30f", mykey);
                data2 = Buffer.from('ccc').toString('hex');
                data2 = ("0x" + data2);
                mykey = web3.utils.sha3(data2 + increaseHexByOne(newKey, j).replace(/0x/, ''), { "encoding": "hex" });
                console.log('DATA FOUND-> ', i, j, 'bbb', a);
                a = await web3.eth.getStorageAt("0x5081a39b8A5f0E35a8D959395a630b68B74Dd30f", mykey);
                console.log('DATA FOUND-> ', i, j, 'ccc', a);

                continue;

            } else if (j == 3) {
                // mapping(string => X) listArray1;
                let data2 = Buffer.from('aaa').toString('hex');
                data2 = ("0x" + data2);
                let mykey = web3.utils.sha3(data2 + increaseHexByOne(newKey, j).replace(/0x/, ''), { "encoding": "hex" });
                a = await web3.eth.getStorageAt("0x5081a39b8A5f0E35a8D959395a630b68B74Dd30f", mykey);
                console.log('DATA FOUND-> ', i, j, 'value1', a);
                a = await web3.eth.getStorageAt("0x5081a39b8A5f0E35a8D959395a630b68B74Dd30f", increaseHexByOne(mykey, 1));
                console.log('DATA FOUND-> ', i, j, 'value2', a);

                a = await web3.eth.getStorageAt("0x5081a39b8A5f0E35a8D959395a630b68B74Dd30f", increaseHexByOne(mykey, 2));
                console.log('DATA FOUND-> ', i, j, 'value3', a);

                continue;

            } else if (j == 4) {
                // mapping(string => X[]) listArray2; 
                let data2 = Buffer.from('aaa').toString('hex');
                data2 = ("0x" + data2);
                let mykey = web3.utils.sha3(data2 + increaseHexByOne(newKey, j).replace(/0x/, ''), { "encoding": "hex" });
                a = await web3.eth.getStorageAt("0x5081a39b8A5f0E35a8D959395a630b68B74Dd30f", mykey);
                console.log('DATA FOUND-> ', i, j, 'length arr', a);
                let parKey = web3.utils.sha3(mykey, { "encoding": "hex" });
                a = await web3.eth.getStorageAt("0x5081a39b8A5f0E35a8D959395a630b68B74Dd30f", parKey);
                console.log('DATA FOUND-> ', i, j, 'value 1', a);
                a = await web3.eth.getStorageAt("0x5081a39b8A5f0E35a8D959395a630b68B74Dd30f", increaseHexByOne(parKey, 1));
                console.log('DATA FOUND-> ', i, j, 'value 2', a);
                a = await web3.eth.getStorageAt("0x5081a39b8A5f0E35a8D959395a630b68B74Dd30f", increaseHexByOne(parKey, 2));
                console.log('DATA FOUND-> ', i, j, 'value 3', a);

            } else {
                a = await web3.eth.getStorageAt("0x5081a39b8A5f0E35a8D959395a630b68B74Dd30f", increaseHexByOne(newKey, j));
            }
            if (a != 0) {
                console.log('DATA FOUND-> ', i, j, a);
            } else {
                // break;
            }

        }
    }
    // console.log(index, data, newKey);
}
main();