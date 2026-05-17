# FundMe

[![Foundry Version](https://img.shields.io/badge/foundry-v0.2.0-blue.svg)](https://book.getfoundry.sh/)
[![Solidity Version](https://img.shields.io/badge/solidity-^0.8.18-lightgrey.svg)](https://soliditylang.org/)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

**A baseline project for learning secure smart contract crowdfunding.** Build on a solid foundation of community-approved code.

This project is part of my journey learning Foundry fundamentals on Cyfrin Updraft. It showcases:
* Custom oracle price feed integrations via Chainlink AggregatorV3.
* Dynamic conversion of ETH amounts to their USD values using a utility library.
* Unit and integration testing patterns using the forge-std package.

**New to Foundry?** Read the official Foundry Book to understand compilation, testing, and script execution.

> [!IMPORTANT]
> FundMe relies on real-time price feeds. When deploying or forking, ensure that the aggregator address is correctly configured for your target network. Using incorrect or unverified price feeds can compromise the security and execution of the contract. Learn more at the Chainlink Price Feed Addresses Book.

## Overview

### Target Networks

The project is structured to deploy on local, testnet, and mainnet networks dynamically using environment-dependent helper scripts:

| Chain ID   | Network                 | Description                                                                                                                                                                   |
| :--------- | :---------------------- | :---------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **1**      | Ethereum Mainnet        | Production deployments using the official Chainlink ETH/USD Feed.                                                                                                             |
| **11155111**| Sepolia Testnet         | Test network mimicking production oracle behaviors with official Chainlink Sepolia feeds.                                                                                     |
| **Local**  | Local Anvil Chain       | Local development network. The deploy scripts dynamically spawn a MockV3Aggregator to simulate prices locally without external RPC calls.                                     |

### Installation

#### Submodule Dependencies

This repository utilizes git submodules for external libraries:

```bash
make install
```

Configure your directory remappings in remappings.txt or within your foundry.toml file:

```text
@chainlink/contracts/=lib/chainlink-evm/contracts/
```

### Usage

This repository contains a Makefile designed to simplify standard task execution. You can use simple make commands instead of invoking long forge commands manually.

Compile and build your smart contracts:

```bash
make build
```

Execute the local unit and integration tests:

```bash
make test
```

Start your local test blockchain (Anvil) with steps tracing and custom block time configured:

```bash
make anvil
```

#### Local Deployment & Interactions (Anvil)

Deploy the contract locally to Anvil using the deployment script (uses the default Anvil key and local RPC URL defined in the Makefile):

```bash
make deploy
```

Fund the contract using your interaction scripts:

```bash
make fund
```

Withdraw funds from the contract using the owner wallet:

```bash
make withdraw
```

#### Testnet Deployment & Interactions (Sepolia)

Deploy the contract to Sepolia, dynamically loading environment variables and verifying on Etherscan:

```bash
make deploy-sepolia
```

Fund the contract on Sepolia using the private key configured in your .env file:

```bash
make fund-sepolia
```

Withdraw funds from the contract on Sepolia using the owner wallet:

```bash
make withdraw-sepolia
```

## Learn More

The following topics will help guide you through the Cyfrin Updraft curriculum:

* Access Control: Understand modifiers like onlyOwner and how custom errors save deployment gas.
* Testing: Explore advanced testing features including prank, hoax, deal, expectRevert, and gas left counters.
* Mocks: Learn how deploying mock contracts on local networks enables offline development.

## Security

Smart contracts are a nascent technology and carry a high level of technical risk. Using this baseline code serves as a learning sandbox and is not a substitute for a comprehensive smart contract security audit.

FundMe is made available under the MIT License, which disclaims all warranties in relation to the project.

## License

This project is released under the MIT License.
