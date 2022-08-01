#!/usr/bin/env bash

set -o errexit
set -o pipefail

CLEANUP=${CLEANUP:-"0"}
NETWORK=${NETWORK:-"testnet"}
OS_PLATFORM=$(uname -s)
OS_ARCH=$(uname -m)
PERSISTENCE_PLATFORM=${PERSISTENCE_PLATFORM:-"darwin-amd64"}
persistenceCore_PATH="persistenceCore"
PERSISTENCE_COMMON_BLOCKSTREAM_ADDR=${PERSISTENCE_COMMON_BLOCKSTREAM_ADDR:-"localhost:9000"}

case $NETWORK in
  mainnet)
    echo "Using MAINNET"
    PERSISTENCE_VERSION=${PERSISTENCE_VERSION:-"v3.0.1"}
    PERSISTENCE_GENESIS="https://raw.githubusercontent.com/persistenceOne/networks/master/core-1/final_genesis.json"
    PERSISTENCE_GENESIS_HEIGHT=${PERSISTENCE_GENESIS_HEIGHT:-"1"}
  ;;
  testnet)
    echo "Using TESTNET"
    PERSISTENCE_VERSION=${PERSISTENCE_VERSION:-"v3.0.1"}
    PERSISTENCE_GENESIS="https://raw.githubusercontent.com/persistenceOne/networks/master/test-core-1/final_genesis.json"
    PERSISTENCE_GENESIS_HEIGHT=${PERSISTENCE_GENESIS_HEIGHT:-"7232900"}
  ;;
  localnet)
    echo "Using LOCALNET"
    CHAIN_ID=${CHAIN_ID:-"localnet"}
    PERSISTENCE_VERSION=${PERSISTENCE_VERSION:-"v3.0.1"}
    PERSISTENCE_GENESIS=""
    PERSISTENCE_GENESIS_HEIGHT=${PERSISTENCE_GENESIS_HEIGHT:-"1"}
    MNEMONIC_1=${MNEMONIC_1:-"guard cream sadness conduct invite crumble clock pudding hole grit liar hotel maid produce squeeze return argue turtle know drive eight casino maze host"}
    MNEMONIC_2=${MNEMONIC_2:-"friend excite rough reopen cover wheel spoon convince island path clean monkey play snow number walnut pull lock shoot hurry dream divide concert discover"}
    MNEMONIC_3=${MNEMONIC_3:-"fuel obscure melt april direct second usual hair leave hobby beef bacon solid drum used law mercy worry fat super must ritual bring faculty"}
    GENESIS_COINS=${GENESIS_COINS:-"1000000000000000stake"}
    GENESIS_COINS_U=${GENESIS_COINS_UXPRT:-"1000000000000000uxprt"}
  ;;
  *)
    echo "Invalid network: $NETWORK"; exit 1;
  ;;
esac

case $OS_PLATFORM-$OS_ARCH in
  Darwin-x86_64) PERSISTENCE_PLATFORM="darwin_amd64" ;;
  Linux-x86_64)  PERSISTENCE_PLATFORM="linux_amd64"  ;;
esac

if [[ -z $(which "wget" || true) ]]; then
  echo "ERROR: wget is not installed"
  exit 1
fi

if [[ $CLEANUP -eq "1" ]]; then
  echo "Deleting all local data"
  rm -rf ./tmp/ > /dev/null
fi

echo "Setting up working directory"
mkdir -p tmp
pushd tmp

echo "Your platform is $OS_PLATFORM/$OS_ARCH"

if [[ -z $(which persistenceCore || true) ]]; then
  echo "Please make sure you have installed local persistenceCore $PERSISTENCE_VERSION binary"
  exit 1
fi

if [ ! -d "persistenceCore_home" ]; then
  echo "Configuring home directory"
  case $NETWORK in
    localnet)
      $persistenceCore_PATH --home=persistenceCore_home init $(hostname) --chain-id $CHAIN_ID 2> /dev/null ;;
    *)
      $persistenceCore_PATH --home=persistenceCore_home init $(hostname) 2> /dev/null
      rm -f \
        persistenceCore_home/config/genesis.json \
        persistenceCore_home/config/addrbook.json
    ;;
  esac
fi

case $NETWORK in
  mainnet) # Using addrbook will ensure fast block sync time
    if [ ! -f "persistenceCore_home/config/genesis.json" ]; then
      echo "Downloading genesis file"
      wget --quiet -O persistenceCore_home/config/genesis.json $PERSISTENCE_GENESIS
    fi
    echo "Configuring p2p seeds"
    sed -i -e 's/seeds = ""/seeds = "876946a947850952383347724206d067d7032b22@3.137.86.151:26656,ecc00c5a7abd057ea5ca4a94c48d1d937bbab34a@34.118.19.56:26656,ac7e6aab726e842b92c06b8ebbf5a3616872ee80@128.1.133.107:26656,b9dab7a1a5ffd16d43b19e40a8020db84e8dfffd@3.14.116.246:44456,60385a36ea72a2985bd8450c95b8df8be2adebb8@54.95.235.242:26656,a92ff1da2020e5cbc9b05527e9e39c34a84e8a27@34.72.57.218:26656,e15524629aee25fea01f62d26c4e062bfda94b70@35.247.171.7:26656,7c106099b8d07085431a97387e5a5db2d1ecd71d@18.223.209.36:26656,b19a3cf4d9938b41539729d027bf2e3c1a4e1fbb@85.214.130.157:26656,7cc92a9e3dcad37e5e7b3adf7814c37070fa9787@161.97.187.189:26656,7b9839cd3e994c44cbd747d1ddc51ee695f60e58@157.90.134.48:26656,cfb529bd0325fc884296518655f1f315bc42dd0c@185.144.83.165:26656,01102f3c84e6602e30e1e39498e242cbb60a0b73@178.62.103.7:26656"/g' persistenceCore_home/config/config.toml
  ;;
  testnet) # There's no address book for the testnet, use seeds instead
    if [ ! -f "persistenceCore_home/config/genesis.json" ]; then
      echo "Downloading genesis file"
      wget --quiet -O persistenceCore_home/config/genesis.json $PERSISTENCE_GENESIS
    fi
    echo "Configuring p2p seeds"
    sed -i -e 's/seeds = ""/seeds = "a530147d623ef4cbb9d61d06c5e8ddd04180d972@13.208.223.192:26656,ca6da5de41d2a0c317f1d885efe74e9a580cd593@10.128.0.2:26656,10e69554d68b3c737a7c6bb55938f38e6b547ea7@220.76.21.184:43006,642cba81f229c50457008410ab5a7a3e6b7b39fe@85.214.61.70:26656,e6f73a89cce68ca961517cf861dbf294a03ad340@18.179.50.45:26656,d4738dfdeede1047076de9ddcc3bef269bdfb898@35.223.239.9:26656,d1fe16cbd078a56465ad2f02bfbf3c8a22253790@13.125.252.209:26656,723218672704e92a65100ddc28cd5719ada07686@3.25.196.255:26656,e46e42065d8fb108b8f2add2539b16b01f0544f4@13.244.233.149:26656"/g' persistenceCore_home/config/config.toml
    sed -i -e 's/enable = false/enable = true/g' persistenceCore_home/config/config.toml
    sed -i -e 's/rpc_servers = ""/rpc_servers = "https:\/\/rpc.testnet.persistence.one:443,https:\/\/rpc.testnet.persistence.one:443"/g' persistenceCore_home/config/config.toml
    sed -i -e 's/trust_height = 0/trust_height = 7221716/g' persistenceCore_home/config/config.toml
    sed -i -e 's/trust_hash = ""/trust_hash = "1F836BCEA5AF44B985CA4CFD39CC2514FC5F3A799F68EF1622589D2931ED03E3"/g' persistenceCore_home/config/config.toml
    sed -i -e 's/trust_period = "168h0m0s"/trust_period = "112h0m0s"/g' persistenceCore_home/config/config.toml
  ;;
  localnet) # Setup localnet
    echo "Adding genesis accounts..."
    echo "y" | $persistenceCore_PATH --home persistenceCore_home keys delete validator --keyring-backend test
    echo "y" | $persistenceCore_PATH --home persistenceCore_home keys delete user1 --keyring-backend test
    echo "y" | $persistenceCore_PATH --home persistenceCore_home keys delete user2 --keyring-backend test
    echo $MNEMONIC_1 | $persistenceCore_PATH --home persistenceCore_home keys add validator --recover --keyring-backend test
    echo $MNEMONIC_2 | $persistenceCore_PATH --home persistenceCore_home keys add user1 --recover --keyring-backend test
    echo $MNEMONIC_3 | $persistenceCore_PATH --home persistenceCore_home keys add user2 --recover --keyring-backend test
    $persistenceCore_PATH --home persistenceCore_home add-genesis-account $($persistenceCore_PATH --home persistenceCore_home keys show validator --keyring-backend test -a) $GENESIS_COINS
    $persistenceCore_PATH --home persistenceCore_home add-genesis-account $($persistenceCore_PATH --home persistenceCore_home keys show user1 --keyring-backend test -a) $GENESIS_COINS_UXPRT
    $persistenceCore_PATH --home persistenceCore_home add-genesis-account $($persistenceCore_PATH --home persistenceCore_home keys show user2 --keyring-backend test -a) $GENESIS_COINS_UXPRT

    echo "Creating and collecting gentx..."
    $persistenceCore_PATH --home persistenceCore_home gentx validator 1000000000stake --chain-id $CHAIN_ID --keyring-backend test
    $persistenceCore_PATH --home persistenceCore_home collect-gentxs
  ;;
esac

cat << END >> persistenceCore_home/config/config.toml

#######################################################
###       Extractor Configuration Options     ###
#######################################################
[extractor]
enabled = true
output_file = "stdout"
END

if [ ! -f "firehose.yml" ]; then
  cat << END >> firehose.yml
start:
  args:
    - ingestor
    - merger
    - firehose
  flags:
    common-first-streamable-block: $PERSISTENCE_GENESIS_HEIGHT
    common-blockstream-addr: $PERSISTENCE_COMMON_BLOCKSTREAM_ADDR
    ingestor-mode: node
    ingestor-node-path: $(which persistenceCore)
    ingestor-node-args: start --x-crisis-skip-assert-invariants --home=persistenceCore_home
    ingestor-node-logs-filter: "module=(p2p|pex|consensus|x/bank)"
    firehose-real-time-tolerance: 99999h
    relayer-max-source-latency: 99999h
    verbose: 1
END
fi
