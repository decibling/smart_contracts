import { ethers } from "ethers";
import DbAudio from "../../artifacts/contracts/DbAudio.sol/DbAudio.json";
import DeciblingToken from "../../artifacts/contracts/DB.sol/DeciblingToken.json";
import TokenFarm from "../../artifacts/contracts/TokenFarm.sol/TokenFarm.json";
export default {
  async connectWallet() {
    const [account] = await window.ethereum.request({
      method: "eth_requestAccounts",
    });
    const provider = new ethers.providers.Web3Provider(window.ethereum);
    const mbalance = await provider.getBalance(account);
    return [account, ethers.utils.formatEther(mbalance)];
  },
  getTokenContract() {
    const provider = new ethers.providers.Web3Provider(window.ethereum);
    const signer = provider.getSigner();
    const contract = new ethers.Contract(
      "0x0317e82cBDA8188b8d67d817b81De0E781aBa0E9",
      DeciblingToken.abi,
      signer
    );
    return [contract, signer];
  },
  getTokenFarmContract() {
    const provider = new ethers.providers.Web3Provider(window.ethereum);
    const signer = provider.getSigner();
    const contract = new ethers.Contract(
      "0x9ff3Cc7d2C869E64F7868daEa2C7C7fE452320Dd",
      TokenFarm.abi,
      signer
    );
    return [contract, signer];
    w;
  },
  getContract() {
    const provider = new ethers.providers.Web3Provider(window.ethereum);
    const signer = provider.getSigner();
    const contract = new ethers.Contract(
      "0xaA773D0Ebf777F8311c813C0763A1e3e4Fd077c2",
      DbAudio.abi,
      signer
    );
    return [contract, signer];
  },
  async uploadIpfs(file) {
    let ipfsClient = window.IpfsHttpClient.create("https://datgital.top");
    return await ipfsClient.add(file);
  },
  initEvent() {
    if (window.ethereum) {
      window.ethereum.on("accountsChanged", function () {
        // account have been changed
        window.location.reload();
      });
      window.ethereum.on("disconnect", function () {
        // account have been changed
        window.location.reload();
      });
      window.ethereum.on("chainChanged", function () {
        // account have been changed
        window.location.reload();
      });
    }
  },
  checkAvailable() {
    return !!window.ethereum;
  },
};
