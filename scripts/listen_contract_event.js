var Web3 = require("web3");
const InputDataDecoder = require('ethereum-input-data-decoder');
const abi = require("../artifacts/contracts/DbAudio.sol/DbAudio.json");
let options = {
    fromBlock: 0,
    address: ['0x7a1848F92cd4945298192De154C24405EAB71aDD'],    //Only get events from specific addresses
    topics: []                              //What topics to subscribe to
};
var ether_port = 'wss://arb-goerli.g.alchemy.com/v2/mTDwIo0RdADc8P7ULK9fIXk0vPfHWXx3'
var web3       = new Web3(new Web3.providers.WebsocketProvider(ether_port));

let subscription = web3.eth.subscribe('logs', options,(err,event) => {
    // if (!err)
    // console.log(event)
});
const decoder = new InputDataDecoder([abi]);

subscription.on('data', event => {
    console.log(event);
    console.log(decoder.decodeData(event['data']));
})

// (function wait () {
//     setTimeout(wait, 1000);
//  })();
 