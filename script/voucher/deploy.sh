#!/bin/bash

# Function to display usage instructions
usage() {
    echo "Usage: $0 [chain] [private_key] [deployment]"
    echo "Chains supported: avax-fuji, avax-mainnet, bnb-mainnet, bnb-testnet"
    echo "Deployments supported: Deploy, Deploy.Account, Upgrade.Voucher"
    exit 1
}

# Check if the correct number of arguments are provided
if [ "$#" -ne 3 ]; then
    usage
fi

# Assigning input parameters
CHAIN=$1
PRIVATE_KEY=$2
DEPLOYMENT=$3

# Validate deployment parameter
if [[ "$DEPLOYMENT" != "Deploy" && "$DEPLOYMENT" != "Deploy.Account" && "$DEPLOYMENT" != "Upgrade.Voucher" ]]; then
    echo "Error: Unsupported deployment '$DEPLOYMENT'"
    usage
fi

# Validate deployment parameter
case $DEPLOYMENT in
    Deploy)
        CONTRACT_NAME="VoucherFactory"
        CONTRACT_SOURCE="src/VoucherFactory.sol"
        ;;
    Deploy.Account)
        CONTRACT_NAME="VoucherAccount"
        CONTRACT_SOURCE="src/VoucherAccount.sol"
        ;;
    Upgrade.Voucher)
        CONTRACT_NAME="VoucherFactory"
        CONTRACT_SOURCE="src/VoucherFactory.sol"
        ;;
    *)
        echo "Error: Unsupported deployment '$DEPLOYMENT'"
        usage
        ;;
esac


# Set the RPC URL and Verifier URL based on the input chain
case $CHAIN in
    avax-fuji)
        RPC_URL="https://avalanche-fuji-c-chain-rpc.publicnode.com"
        VERIFIER_URL="https://api.routescan.io/v2/network/mainnet/evm/43113/etherscan"
        CHAIN_ID=43113
        ;;
    avax-mainnet)
        RPC_URL="https://api.avax.network/ext/bc/C/rpc"
        VERIFIER_URL="https://api.snowtrace.io/api"
        CHAIN_ID=43114
        ;;
    bnb-mainnet)
        RPC_URL="https://bsc-dataseed.binance.org/"
        VERIFIER_URL="https://api.bscscan.com/api"
        CHAIN_ID=56
        ;;
    bnb-testnet)
        RPC_URL="https://data-seed-prebsc-1-s1.binance.org:8545/"
        VERIFIER_URL="https://api-testnet.bscscan.com/api"
        CHAIN_ID=97
        ;;
    *)
        echo "Error: Unsupported chain '$CHAIN'"
        usage
        ;;
esac

# Deploy the contract using the provided parameters and capture the contract address
DEPLOY_OUTPUT=$(forge clean && forge build && forge script script/${DEPLOYMENT}.s.sol \
    --rpc-url $RPC_URL \
    --verifier-url $VERIFIER_URL \
    --etherscan-api-key "1VYRT81XHNBY8BC2X88N9ZF4XRBXUJDYKQ" \
    --ffi \
    --private-key $PRIVATE_KEY \
    --broadcast)

# Print deployment output for debugging
echo "$DEPLOY_OUTPUT"

# Extract the contract address from the deploy output
# CONTRACT_ADDRESS=$(echo "$DEPLOY_OUTPUT" | grep -oP 'Contract Address: \K0x[a-fA-F0-9]{40}')
CONTRACT_ADDRESS=$(echo "$DEPLOY_OUTPUT" | awk '/Contract Address:/ {print $3}')

# Print contract address for debugging
echo "Contract Address: $CONTRACT_ADDRESS"

# Verify the contract using the captured contract address
forge verify-contract $CONTRACT_ADDRESS \
    --watch \
    --chain $CHAIN_ID \
    $CONTRACT_SOURCE:$CONTRACT_NAME \
    --etherscan-api-key "1VYRT81XHNBY8BC2X88N9ZF4XRBXUJDYKQ" \
    --num-of-optimizations 200 \
    --compiler-version 0.8.23
