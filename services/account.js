require("dotenv").config();

const express = require("express");
const app = express();
const DeciblingToken = require("../artifacts/contracts/DB.sol/DeciblingToken.json");
var Web3 = require("web3");
var ethers = require("ethers");
const port = 3000;
var addressList = {};
var ether_port =
  "wss://arb-goerli.g.alchemy.com/v2/mTDwIo0RdADc8P7ULK9fIXk0vPfHWXx3";
const FLOY_ADDRESS = "0xAa8ADb51329BA9640D86Aa10b0F374d97A7B31d9";
const FLOY_AMOUNT = 10000;
const ETHER_AMOUNT = 0.0001;
const WAIT_TIME = 5;// second
var myprovider = new ethers.providers.WebSocketProvider(process.env.ARB_URL);
var wallet = new ethers.Wallet("0x" + process.env.ACCOUNT_KEY, myprovider);
const signer = wallet.provider.getSigner(wallet.address);

async function sendMoney(receiverAddress) {
  try {
    let tx = {
      to: receiverAddress,
      // Convert currency unit from ether to wei
      value: ethers.utils.parseEther(ETHER_AMOUNT.toString()),
    };
    console.log(`[+]Start sending ETHERS => [${receiverAddress}]`);
    let e = await wallet.sendTransaction(tx, myprovider.getSigner());

    console.log(
      `[+] Send ETHERS successfully : [${receiverAddress}] at [${e.hash ?? ""}]`
    );

    const contract = new ethers.Contract(
      FLOY_ADDRESS,
      DeciblingToken.abi,
      wallet
    );
    console.log(`[+]Start transfer FLOY => [${receiverAddress}]`);
    let e2 = await contract.transfer(
      receiverAddress,
      ethers.utils.parseEther(FLOY_AMOUNT.toString())
    );
    console.log(
      `[+] Send FLOY successfully : [${receiverAddress}] at [${e2.hash ?? ""}]`
    );

    return "done";
  } catch {
    return "fail";
  }
}
app.get("/gain/:address", async (req, res) => {
    console.log(new Date().getTime());
  let address = req.params.address;
  if (address) {
    if (
      (addressList[address.toLowerCase] &&
        new Date().getTime() - addressList[address.toLowerCase] > (WAIT_TIME * 1000)) ||
      !addressList[address.toLowerCase]
    ) {
      // sned
      addressList[address.toLowerCase] = new Date().getTime();
      setTimeout(function(){
        sendMoney(address);
      },0);
      res.send('done');
      return;
    } else {
      res.send("wait");
      return;
    }
  }
  res.send("failed");
});

app.listen(port, () => {
  console.log(`Faucet is running on :${port}`);
});
