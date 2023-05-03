require("dotenv").config();

require("@nomicfoundation/hardhat-toolbox");
require("@nomiclabs/hardhat-etherscan");
require("@nomiclabs/hardhat-truffle5");
require("@openzeppelin/hardhat-upgrades");
require("@nomiclabs/hardhat-web3");
require("hardhat-storage-layout");
require("hardhat-gas-reporter");
require("solidity-coverage");

// This is a sample Hardhat task. To learn how to create your own go to
// https://hardhat.org/guides/create-task.html
task("accounts", "Prints the list of accounts", async (taskArgs, hre) => {
  const accounts = await hre.ethers.getSigners();

  for (const account of accounts) {
    console.log(account.address);
  }
});

// You need to export an object to set up your config
// Go to https://hardhat.org/config/ to learn more

/**
 * @type import('hardhat/config').HardhatUserConfig
 */
module.exports = {
  solidity: "0.8.9",
  settings: {
    optimizer: {
      enabled: true,
      runs: 200,
    },
  },
  networks: {
    goerli: {
      url: process.env.GOERLI_URL,
      accounts: [process.env.ACCOUNT_KEY],
    },
    arb: {
      url: process.env.ARB_URL,
      accounts: [process.env.ACCOUNT_KEY],
    },
    mainnet: {
      url: process.env.MAIN_NET,
      accounts: [process.env.ACCOUNT_KEY],
    },

    localhost: {
      url: "http://127.0.0.1:8545",
      accounts: ["ac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80"]
    }

  },
  gasReporter: {
    enabled: (process.env.REPORT_GAS) ? true : false,
    coinmarketcap: "c9e4cd6a-851e-4aea-a372-43eede88dd18"
  },
  etherscan: {
    apiKey: {
      arbitrumGoerli : "mTDwIo0RdADc8P7ULK9fIXk0vPfHWXx3"
    }
  },
};
