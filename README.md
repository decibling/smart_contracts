# Advanced Sample Hardhat Project

This project demonstrates an advanced Hardhat use case, integrating other tools commonly used alongside Hardhat in the ecosystem.

The project comes with a sample contract, a test for that contract, a sample script that deploys that contract, and an example of a task implementation, which simply lists the available accounts. It also comes with a variety of other tools, preconfigured to work with the project code.

Try running some of the following tasks:

```shell
npx hardhat accounts
npx hardhat compile
npx hardhat clean
npx hardhat test
npx hardhat node
npx hardhat help
REPORT_GAS=true npx hardhat test
npx hardhat coverage
npx hardhat run scripts/deploy.js
node scripts/deploy.js
npx eslint '**/*.js'
npx eslint '**/*.js' --fix
npx prettier '**/*.{json,sol,md}' --check
npx prettier '**/*.{json,sol,md}' --write
npx solhint 'contracts/**/*.sol'
npx solhint 'contracts/**/*.sol' --fix
```

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

# Latest test results (3 Jan, 2023)
·-------------------------------------------------|----------------------------|-------------|-----------------------------·
|               Solc version: 0.8.9               ·  Optimizer enabled: false  ·  Runs: 200  ·  Block limit: 30000000 gas  │
··················································|····························|·············|······························
|  Methods                                        ·               17 gwei/gas                ·       1218.01 usd/eth       │
·························|························|··············|·············|·············|···············|··············
|  Contract              ·  Method                ·  Min         ·  Max        ·  Avg        ·  # calls      ·  usd (avg)  │
·························|························|··············|·············|·············|···············|··············
|  DeciblingAuction      ·  bid                   ·       88164  ·     144572  ·     116368  ·            4  ·       2.41  │
·························|························|··············|·············|·············|···············|··············
|  DeciblingAuction      ·  createBidding         ·       73093  ·     148281  ·     110687  ·            2  ·       2.29  │
·························|························|··············|·············|·············|···············|··············
|  DeciblingAuction      ·  createNFT             ·           -  ·          -  ·     169975  ·            1  ·       3.52  │
·························|························|··············|·············|·············|···············|··············
|  DeciblingAuction      ·  settleBiddingSession  ·      165477  ·     233998  ·     199738  ·            2  ·       4.14  │
·························|························|··············|·············|·············|···············|··············
|  DeciblingStakingMock  ·  issueToken            ·      111538  ·     113538  ·     112538  ·            2  ·       2.33  │
·························|························|··············|·············|·············|···············|··············
|  DeciblingStakingMock  ·  newPool               ·      143002  ·     143026  ·     143014  ·            6  ·       2.96  │
·························|························|··············|·············|·············|···············|··············
|  DeciblingStakingMock  ·  stake                 ·       94733  ·     111833  ·     107075  ·            6  ·       2.22  │
·························|························|··············|·············|·············|···············|··············
|  DeciblingStakingMock  ·  unstake               ·       88929  ·      93729  ·      91329  ·            2  ·       1.89  │
·························|························|··············|·············|·············|···············|··············
|  DeciblingStakingMock  ·  updatePool            ·       53926  ·      56107  ·      54657  ·            3  ·       1.13  │
·························|························|··············|·············|·············|···············|··············
|  FroggilyToken         ·  approve               ·       26945  ·      46941  ·      45114  ·           11  ·       0.93  │
·························|························|··············|·············|·············|···············|··············
|  FroggilyToken         ·  transfer              ·       47289  ·      52197  ·      51552  ·           39  ·       1.07  │
·························|························|··············|·············|·············|···············|··············
|  Deployments                                    ·                                          ·  % of limit   ·             │
··················································|··············|·············|·············|···············|··············
|  DeciblingAuction                               ·           -  ·          -  ·    4989863  ·       16.6 %  ·     103.32  │
··················································|··············|·············|·············|···············|··············
|  DeciblingStakingMock                           ·     2996307  ·    2996319  ·    2996318  ·         10 %  ·      62.04  │
··················································|··············|·············|·············|···············|··············
|  FroggilyToken                                  ·           -  ·          -  ·    1402874  ·        4.7 %  ·      29.05  │
·-------------------------------------------------|--------------|-------------|-------------|---------------|-------------·