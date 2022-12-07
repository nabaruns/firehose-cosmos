#!/bin/bash

# Run this from the root repo directory

echo "-----------------------"
echo "## Set config variables ##"
# NOTE: you will need to update these to deploy on different network
IMAGE_TAG="latest"
CONTAINER_NAME="persistenceCore"
BINARY="persistenceCore"
DENOM='uxprt'
CHAIN_ID='localnet'
RPC='http://localhost:26657/'
TXFLAG="--gas-prices 0.025$DENOM --gas auto --gas-adjustment 1.3 -y -b block --chain-id $CHAIN_ID --node $RPC"
BLOCK_GAS_LIMIT=${GAS_LIMIT:-100000000} # should mirror mainnet
PASSWORD=${PASSWORD:-1234567890}
echo "Done."

echo "-----------------------"
echo "## Add new test user user1 ##"
echo "-----------------------"
TEST_ADDR="persistence1m9lfg6fav7jev6mtzua0k589nhrytuwl6f96js"
MNEMONIC_2=${MNEMONIC_2:-"friend excite rough reopen cover wheel spoon convince island path clean monkey play snow number walnut pull lock shoot hurry dream divide concert discover"}

pushd tmp

echo "-----------------------"
echo "## Download cw20_base.wasm ##"
echo "-----------------------"
curl -LO https://github.com/CosmWasm/cw-plus/releases/download/v0.13.4/cw20_base.wasm
echo "Done."

echo "-----------------------"
echo "## Copy wasm binaries to docker container ##"
echo "-----------------------"
cp $HOME/IdeaProjects/work/BL-contracts/artifacts/bl_market.wasm .
cp $HOME/IdeaProjects/work/BL-contracts/artifacts/p_token.wasm .

echo "Done."

echo "-----------------------"
echo "## Recovering user1 ##"
echo "-----------------------"
echo "y" | $BINARY --home persistenceCore_home keys delete user1 --keyring-backend test
echo $MNEMONIC_2 | $BINARY --home persistenceCore_home keys add user1 --recover --keyring-backend test

echo "-----------------------"
echo "## Upload contracts and get code id ##"
echo "-----------------------"

### PTOKEN ###
PTOKEN_CODE=$($BINARY --home persistenceCore_home tx wasm store "p_token.wasm" --from user1 $TXFLAG --output json  --keyring-backend test | jq -r '.logs[0].events[-1].attributes[0].value')

### BL-MARKET ###
BL_MARKET_CODE=$($BINARY --home persistenceCore_home tx wasm store "bl_market.wasm" --from user1 $TXFLAG --output json  --keyring-backend test | jq -r '.logs[0].events[-1].attributes[0].value')

### CW20-BASE ###
CW20_CODE=$($BINARY --home persistenceCore_home tx wasm store "cw20_base.wasm" --from user1 $TXFLAG --output json --keyring-backend test | jq -r '.logs[0].events[-1].attributes[0].value')

echo "-----------------------"
echo "PTOKEN_CODE_ID=$PTOKEN_CODE"
echo "BL_MARKET_CONTRACT_CODE_ID=$BL_MARKET_CODE"
echo "CW20_CODE_CODE_ID=$CW20_CODE"
echo "-----------------------"

echo $($BINARY --home persistenceCore_home keys show -a validator --keyring-backend test) > validator.txt