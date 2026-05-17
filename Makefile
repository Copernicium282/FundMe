-include .env

.PHONY: all test clean deploy fund help install snapshot format anvil deploy-sepolia fund-sepolia withdraw-sepolia

DEFAULT_ANVIL_KEY := 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80
ANVIL_RPC_URL := http://localhost:8545

all: clean install build

# Clean compile artifacts
clean:
	forge clean

# Install libraries safely without automatic git commits
install:
	forge install cyfrin/foundry-devops --no-commit && \
	forge install smartcontractkit/chainlink-evm@contracts-v1.5.1-beta.0 --no-commit && \
	forge install foundry-rs/forge-std --no-commit

# Build contracts
build:
	forge build

# Run tests
test:
	forge test

# Generate gas snapshots
snapshot:
	forge snapshot

# Format Solidity files
format:
	forge fmt

# Spin up local Anvil chain with step tracing
anvil:
	anvil -m 'test test test test test test test test test test test junk' --steps-tracing --block-time 1

# Deploy locally (Anvil)
deploy:
	@forge script script/DeployFundMe.s.sol:DeployFundMe --rpc-url $(ANVIL_RPC_URL) --private-key $(DEFAULT_ANVIL_KEY) --broadcast

# Deploy to Sepolia (Reads values from .env automatically)
deploy-sepolia:
	@forge script script/DeployFundMe.s.sol:DeployFundMe --rpc-url $(SEPOLIA_RPC_URL) --private-key $(PRIVATE_KEY) --broadcast --verify --etherscan-api-key $(ETHERSCAN_API_KEY) -vvvv

# Interactions for Anvil (Local)
fund:
	@forge script script/interactions.s.sol:FundFundMe --rpc-url $(ANVIL_RPC_URL) --private-key $(DEFAULT_ANVIL_KEY) --broadcast

withdraw:
	@forge script script/interactions.s.sol:WithdrawFundMe --rpc-url $(ANVIL_RPC_URL) --private-key $(DEFAULT_ANVIL_KEY) --broadcast

# Interactions for Sepolia (Reads .env automatically)
fund-sepolia:
	@forge script script/interactions.s.sol:FundFundMe --rpc-url $(SEPOLIA_RPC_URL) --private-key $(PRIVATE_KEY) --broadcast

withdraw-sepolia:
	@forge script script/interactions.s.sol:WithdrawFundMe --rpc-url $(SEPOLIA_RPC_URL) --private-key $(PRIVATE_KEY) --broadcast