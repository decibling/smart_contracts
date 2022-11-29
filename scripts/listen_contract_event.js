var Web3 = require("web3");
var ethers = require("ethers");

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
let abi = [
    "event CreateNFT(string uri, uint256 index)",
    "event BidEvent(string uri, uint256 startPrice, uint256 startTime, uint256 endTime)",
    "event SettleBidding(string uri, address oldowner, address newowner, uint256 price)"
];

let iface = new ethers.utils.Interface(abi)


subscription.on('data', event => {
    console.log(event);
    if(event.topics && event.data != '0x')
    console.log(iface.parseLog(event));
})