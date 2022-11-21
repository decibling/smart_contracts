import { ethers } from "ethers";
import DbAudio from "../../artifacts/contracts/DbAudio.sol/DbAudio.json";
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
      "0x8de83e46aF3B8b62e787fa4d8f7C4889A619e91a",
      TokenFarm.abi,
      signer
    );
    return [contract, signer];
  },
  getContract() {
    const provider = new ethers.providers.Web3Provider(window.ethereum);
    const signer = provider.getSigner();
    let contract = new ethers.Contract(
      "0x8BCA4b50Df16B7FBeC8755e37910476fd8BC92Ac",
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
