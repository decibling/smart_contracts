import { ethers } from "ethers";
import DbAudio from "../../artifacts/contracts/DbAudioUpgrable.sol/DbAudioUpgrable.json";
import DeciblingToken from "../../artifacts/contracts/DB.sol/DeciblingToken.json";
import TokenFarm from "../../artifacts/contracts/TokenFarm.sol/TokenFarm.json";
import extension from "./extension";
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
      "0xAa8ADb51329BA9640D86Aa10b0F374d97A7B31d9",
      DeciblingToken.abi,
      signer
    );
    return [contract, signer];
  },
  getTokenFarmContract() {
    const provider = new ethers.providers.Web3Provider(window.ethereum);
    const signer = provider.getSigner();
    const contract = new ethers.Contract(
      "0x9e4f9f6dfaeb9DDA9a2abCd651FC6470c467A327",
      TokenFarm.abi,
      signer
    );
    return [contract, signer];
  },
  getContract() {
    const provider = new ethers.providers.Web3Provider(window.ethereum);
    const signer = provider.getSigner();
    let contract = new ethers.Contract(
      "0x1d6B587c74E456D5390e10d49B9ecb28CD8a5830",
      DbAudio.abi,
      signer
    );
    contract = extension.injectContract(contract);

    return [contract, signer];
  },
  async uploadIpfs(file) {
    let ipfsClient = window.IpfsHttpClient.create("https://ipfs.decibling.com");
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
