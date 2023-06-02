# Etherscan verification

To try out Etherscan verification, you first need to deploy a contract to an Ethereum network that's supported by Etherscan, such as Ropsten.

In this project, copy the .env.example file to a file named .env, and then edit it to fill in the details. Enter your Etherscan API key, your Ropsten node URL (eg from Alchemy), and the private key of the account which will send the deployment transaction. With a valid .env file in place, first deploy your contract:

```shell
hardhat run --network ropsten scripts/deploy.js
```

Then, copy the deployment address and paste it in to replace `DEPLOYED_CONTRACT_ADDRESS` in this command:

```shell
npx hardhat verify --network ropsten DEPLOYED_CONTRACT_ADDRESS "Hello, Hardhat!"
```
```
npx hardhat verify --network sepolia 0x33634B1Cd1B1c5783cA6Eab3E464464644ad7F73 --contract contracts/Token.sol:FroggilyToken
npx hardhat verify --network sepolia 0xAa8ADb51329BA9640D86Aa10b0F374d97A7B31d9 --contract contracts/DeciblingNFT.sol:DeciblingNFT
npx hardhat verify --network sepolia 0x2cc52A8d5544eD2A5cd66CC0Cb0E2504FC2C55F7 --contract contracts/DeciblingReserve.sol:DeciblingReserve
npx hardhat verify --network sepolia 0x6F53C1836e3988f5DC0645C2c58b399A7497486f --contract contracts/DeciblingAuction.sol:DeciblingAuction
npx hardhat verify --network sepolia 0xE2678C127C4b68DC46Bd52b7991613885c5b212A --contract contracts/DeciblingStaking.sol:DeciblingStaking
npx hardhat verify --network sepolia 0x20959E89F3d04a6033aa5081056e20A1321352aA --contract contracts/DeciblingFaucet.sol:DeciblingFaucet
```

# Latest test results (May 1, 2023)
## Auction
```
·---------------------------|----------------------------|-------------|-----------------------------·
|    Solc version: 0.8.9    ·  Optimizer enabled: false  ·  Runs: 200  ·  Block limit: 30000000 gas  │
····························|····························|·············|······························
|  Methods                  ·               35 gwei/gas                ·       1889.69 usd/eth       │
·················|··········|··············|·············|·············|···············|··············
|  Contract      ·  Method  ·  Min         ·  Max        ·  Avg        ·  # calls      ·  usd (avg)  │
·················|··········|··············|·············|·············|···············|··············
|  DeciblingNFT  ·  mint    ·           -  ·          -  ·     168690  ·            6  ·      11.16  │
·················|··········|··············|·············|·············|···············|··············
|  Deployments              ·                                          ·  % of limit   ·             │
····························|··············|·············|·············|···············|··············
|  DeciblingAuctionV2       ·           -  ·          -  ·    4227364  ·       14.1 %  ·     279.59  │
····························|··············|·············|·············|···············|··············
|  DeciblingNFT             ·           -  ·          -  ·    4904162  ·       16.3 %  ·     324.36  │
····························|··············|·············|·············|···············|··············
|  MyToken                  ·           -  ·          -  ·    1328038  ·        4.4 %  ·      87.84  │
·---------------------------|--------------|-------------|-------------|---------------|-------------·
```

## Staking
```
·-------------------------------------------|----------------------------|-------------|-----------------------------·
|            Solc version: 0.8.9            ·  Optimizer enabled: false  ·  Runs: 200  ·  Block limit: 30000000 gas  │
············································|····························|·············|······························
|  Methods                                  ·               33 gwei/gas                ·       1891.43 usd/eth       │
·····················|······················|··············|·············|·············|···············|··············
|  Contract          ·  Method              ·  Min         ·  Max        ·  Avg        ·  # calls      ·  usd (avg)  │
·····················|······················|··············|·············|·············|···············|··············
|  DeciblingReserve  ·  setStakingContract  ·       34162  ·      34174  ·      34170  ·            3  ·       2.13  │
·····················|······················|··············|·············|·············|···············|··············
|  DeciblingStaking  ·  claim               ·      134562  ·     136155  ·     135178  ·            4  ·       8.44  │
·····················|······················|··············|·············|·············|···············|··············
|  DeciblingStaking  ·  claimForPoolProfit  ·      168068  ·     238408  ·     203238  ·            2  ·      12.69  │
·····················|······················|··············|·············|·············|···············|··············
|  DeciblingStaking  ·  newPool             ·           -  ·          -  ·      55665  ·            2  ·       3.47  │
·····················|······················|··············|·············|·············|···············|··············
|  DeciblingStaking  ·  setDefaultPool      ·           -  ·          -  ·     103400  ·            3  ·       6.45  │
·····················|······················|··············|·············|·············|···············|··············
|  DeciblingStaking  ·  setReserveContract  ·       51312  ·      51324  ·      51320  ·            3  ·       3.20  │
·····················|······················|··············|·············|·············|···············|··············
|  DeciblingStaking  ·  stake               ·      232439  ·     266653  ·     257496  ·            4  ·      16.07  │
·····················|······················|··············|·············|·············|···············|··············
|  DeciblingStaking  ·  updatePool          ·           -  ·          -  ·      84746  ·            2  ·       5.29  │
·····················|······················|··············|·············|·············|···············|··············
|  FroggilyToken     ·  approve             ·       46894  ·      46918  ·      46906  ·            4  ·       2.93  │
·····················|······················|··············|·············|·············|···············|··············
|  FroggilyToken     ·  transfer            ·       52229  ·      52241  ·      52236  ·            9  ·       3.26  │
·····················|······················|··············|·············|·············|···············|··············
|  Deployments                              ·                                          ·  % of limit   ·             │
············································|··············|·············|·············|···············|··············
|  DeciblingReserve                         ·           -  ·          -  ·    2651385  ·        8.8 %  ·     165.49  │
············································|··············|·············|·············|···············|··············
|  DeciblingStaking                         ·           -  ·          -  ·    5202366  ·       17.3 %  ·     324.72  │
············································|··············|·············|·············|···············|··············
|  FroggilyToken                            ·           -  ·          -  ·    1180904  ·        3.9 %  ·      73.71  │
·-------------------------------------------|--------------|-------------|-------------|---------------|-------------·
```
