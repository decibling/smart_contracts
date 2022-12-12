const { ethers } = require("hardhat");
const DeciblingToken = require("../artifacts/contracts/DB.sol/DeciblingToken.json");

async function main() {
    // let contract = new ethers.Contract(
    //     "0xAa8ADb51329BA9640D86Aa10b0F374d97A7B31d9",
    //     DeciblingToken.abi,toke
    //     ethers.provider
    // );
    // console.log(contract);
    let abi = [
        "function stake(uint256 _amount, string memory pool)",
        "event BidEvent(string uri, uint256 startPrice, uint256 startTime, uint256 endTime)",
        "event SettleBidding(string uri, address oldowner, address newowner, uint256 price)"
    ];
    
    let iface = new ethers.utils.Interface(abi)
    
    
    let data = "0xe7e4e1f7000000000000000000000000000000000000000000000006aaf7c8516d0c00000000000000000000000000000000000000000000000000000000000000000040000000000000000000000000000000000000000000000000000000000000002364617431313233393779717765666975676277657238377932337269757765726638370000000000000000000000000000000000000000000000000000000000";
    console.log(iface.decodeFunctionData("stake", data));
}
main(); `1`