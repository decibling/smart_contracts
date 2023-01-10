const express = require('express')
const app = express()
require("dotenv").config();
const DeciblingToken = require('../artifacts/contracts/DB.sol/DeciblingToken.json');
var Web3 = require("web3");
var ethers = require("ethers");
const port = 3000
var addressList = {}
var ether_port = 'wss://arb-goerli.g.alchemy.com/v2/mTDwIo0RdADc8P7ULK9fIXk0vPfHWXx3'
var web3       = new Web3(new Web3.providers.WebsocketProvider(ether_port));
let wallet = new ethers.Wallet(process.env.ACCOUNT_KEY, web3)

async function sendMoney(receiverAddress){
    let tx = {
        to: receiverAddress,
        // Convert currency unit from ether to wei
        value: ethers.utils.parseEther(0.0001)
    }
    console.log(wallet.sendTransaction(tx));
    const contract = new ethers.Contract(
        "0xAa8ADb51329BA9640D86Aa10b0F374d97A7B31d9",
        DeciblingToken.abi,
        web3
      );
    console.log(contract.transfer(receiverAddress, ethers.utils.parseEther(10000))); 
    
}
app.get('/gain/:address', async (req, res) => {
   let address = req.params.address;
   if(address){
        if((addressList[address.toLowerCase] && (addressList[address.toLowerCase] - new Date().getTime() > 5000) || !addressList[address.toLowerCase])){
            // sned 
            addressList[address.toLowerCase] = new Date().getTime();
            res.send(sendMoney(address));            
            return;
        }else{
            res.send('wait');            
            return;
        }
    }
   res.send('failed');
})

app.listen(port, () => {
  console.log(`Faucet is running on :${port}`)
})