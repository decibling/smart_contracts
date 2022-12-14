import {Buffer} from 'buffer/'
import web3 from 'web3';
import {ethers} from 'ethers';
function increaseHexByOne(hex, added) {
    let x = ethers.BigNumber.from(hex)
    let sum = x.add(added)
    let result = sum.toHexString()
    return result
}
export default {
    // AudioInfo storage audio = listNFT[uri];
    // Bidding storage bidding = audio.biddingList[index];
    // return (
    //     bidding.winner,
    //     bidding.price,
    //     bidding.status,
    //     bidding.startTime,
    //     bidding.endTime,
    //     bidding.currentSession
    // );

    injectContract(contract) {
        contract.getBidding = async function(uri, biddingIndex){
            let index = "252".padStart(64, '0')
            let data = "0x"+ Buffer.from(uri).toString('hex');
            //access to listNFT
            let newKey = web3.utils.sha3(data + index, { "encoding": "hex" });
            // point to location of biddingList index
            let biddingMapKey = increaseHexByOne(newKey, 5);
            let finalKey = web3.utils.sha3('0x' + biddingIndex.toString().padStart(64, "0") + biddingMapKey.replace(/0x/, ""), { "encoding": "hex" });
            let parseList = {
                'winner': "address",
                'price': "uint256",
                'status': "uint256",
                'startTime': "uint256",
                'endTime': "uint256",
                'currentSession': "uint256"
            }
            const provider = new ethers.providers.Web3Provider(window.ethereum);
            let finalResult = {};
            // console.log(finalKey);
            // console.log(await provider.getStorageAt("0xfdd485062b3e73549ec3e654ba565f6fab7dc670" ,increaseHexByOne(finalKey,3)));
            for(let i=0; i<Object.keys(parseList).length; i++){
                if(parseList[Object.keys(parseList)[i]] == "address"){
                    finalResult[Object.keys(parseList)[i]] = ethers.BigNumber.from(await provider.getStorageAt("0xfdd485062b3e73549ec3e654ba565f6fab7dc670", increaseHexByOne(finalKey, i))).toHexString();
                }
                else if(parseList[Object.keys(parseList)[i]] == "string" ){
                    finalResult[Object.keys(parseList)[i]] = web3.utils.toAscii(await provider.getStorageAt("0xfdd485062b3e73549ec3e654ba565f6fab7dc670", increaseHexByOne(finalKey, i)));
                }else{
                    finalResult[Object.keys(parseList)[i]] = ethers.BigNumber.from(await provider.getStorageAt("0xfdd485062b3e73549ec3e654ba565f6fab7dc670", increaseHexByOne(finalKey, i)));
                }
            }
            return finalResult;
        }
        contract.getBidSession = async function(uri, biddingIndex, bidIndex) {
            let index = "252".padStart(64, '0')
            let data = "0x"+ Buffer.from(uri).toString('hex');
            //access to listNFT
            let newKey = web3.utils.sha3(data + index, { "encoding": "hex" });
            // point to location of biddingList index
            let biddingMapKey = increaseHexByOne(newKey, 5);
            let keyOfBidding = web3.utils.sha3('0x' + biddingIndex.toString().padStart(64, "0") + biddingMapKey.replace(/0x/, ""), { "encoding": "hex" });
            let pointToMapping = increaseHexByOne(keyOfBidding, 6);
            let keyOfBid = web3.utils.sha3('0x' + bidIndex.toString().padStart(64, "0") + pointToMapping.replace(/0x/, ""), { "encoding": "hex" });
            let parseList = {
                'user': "address",
                'price': "uint256",
                'timestamp': "uint256"
            }
            const provider = new ethers.providers.Web3Provider(window.ethereum);
            let finalResult = {};
            for(let i=0; i<Object.keys(parseList).length; i++){
                if(parseList[Object.keys(parseList)[i]] == "address"){
                    finalResult[Object.keys(parseList)[i]] = ethers.BigNumber.from(await provider.getStorageAt("0xfdd485062b3e73549ec3e654ba565f6fab7dc670", increaseHexByOne(keyOfBid, i))).toHexString();
                }
                else if(parseList[Object.keys(parseList)[i]] == "string" ){
                    finalResult[Object.keys(parseList)[i]] = web3.utils.toAscii(await provider.getStorageAt("0xfdd485062b3e73549ec3e654ba565f6fab7dc670", increaseHexByOne(keyOfBid, i)));
                }else{
                    finalResult[Object.keys(parseList)[i]] = ethers.BigNumber.from(await provider.getStorageAt("0xfdd485062b3e73549ec3e654ba565f6fab7dc670", increaseHexByOne(keyOfBid, i)));
                }
            }
            return finalResult;

        }
        return contract;
    },

}