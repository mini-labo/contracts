#!/bin/sh

rpc_url=$RINKEBY_RPC_URL
private_key=$TEST_DEPLOY_PK
etherscan_api_key=$ETHERSCAN_API_KEY
compiler_version="v0.8.10+commit.fc410830"
chain_id="4" # rinkeby by default

# Auction House vars
WETH_ADDRESS=0xc778417e063141139fce010982780140aa0cd5ab # rinkeby by default TODO: conditional based on chainid
AUCTION_RESERVE_PRICE=1
AUCTION_MIN_BID_INCREMENT_PERCENTAGE=2
AUCTION_DURATION=86400
AUCTION_TIME_BUFFER=300
AUCTION_TIME_BUFFER=1

echo "=== Beginning deployment of MINI contracts ==="
printf "\n"

echo "Deploying MiniDataRepository.sol..."
data_repository_address=$(forge create \
  --rpc-url $rpc_url \
  --private-key $private_key \
  src/MiniDataRepository.sol:MiniDataRepository | grep -oP '(?<=Deployed to:).*')

echo "MiniDataRepository deployed to: ${data_repository_address}"
printf "\n"

echo "Deploying MiniToken.sol..."
mini_token_address=$(forge create \
  --rpc-url $rpc_url \
  --constructor-args $(echo $data_repository_address) \
  --private-key $private_key \
  src/MiniToken.sol:MiniToken | grep -oP '(?<=Deployed to:).*')

echo "MiniToken deployed to: ${mini_token_address}"
printf "\n"

echo "Deploying auction proxy admin contract..."
proxy_admin_address=$(forge create \
  --rpc-url $rpc_url \
  --private-key $private_key \
  src/proxies/MiniAuctionHouseProxyAdmin.sol:MiniAuctionHouseProxyAdmin | grep -oP '(?<=Deployed to:).*')

echo "MiniAuctionHouseProxyAdmin deployed to: ${proxy_admin_address}"
printf "\n"

echo "Deploying MiniAuctionHouse.sol..."
auction_house_address=$(forge create \
  --rpc-url $rpc_url \
  --private-key $private_key \
  src/MiniAuctionHouse.sol:MiniAuctionHouse | grep -oP '(?<=Deployed to:).*')

echo "MiniAuctionHouse deployed to: ${auction_house_address}"
printf "\n"

echo "Deploying MiniAuctionHouseProxy..."
auction_house_proxy_address=$(forge create \
  --rpc-url $rpc_url \
  --constructor-args $auction_house_address $proxy_admin_address "" \
  --private-key $private_key \
  src/proxies/MiniAuctionHouseProxy.sol:MiniAuctionHouseProxy | grep -oP '(?<=Deployed to:).*')

echo "MiniAuctionHouseProxy deployed to: ${auction_house_proxy_address}"
printf "\n"

echo "Initializing MiniAuctionHouse with the following args:"
printf "\n"

echo "_mini: ${mini_token_address}"
echo "_weth: ${WETH_ADDRESS}"
echo "_timeBuffer: ${AUCTION_TIME_BUFFER}"
echo "_reservePrice: ${AUCTION_RESERVE_PRICE}"
echo "_minBidIncrementPercentage: ${AUCTION_MIN_BID_INCREMENT_PERCENTAGE}"
echo "_duration: ${AUCTION_DURATION}"
printf "\n"

echo "publishing auction house initialization transaction..."

cast send $(echo $auction_house_proxy_address) \
--rpc-url $rpc_url \
--private-key $private_key \
"initialize(address,address,uint256,uint256,uint8,uint256)" \
$mini_token_address \
$WETH_ADDRESS \
$AUCTION_TIME_BUFFER \
$AUCTION_RESERVE_PRICE \
$AUCTION_MIN_BID_INCREMENT_PERCENTAGE \
$AUCTION_DURATION

printf "\n"

echo "== Finished contract deployment! ==="

echo "Beginning contract verification on etherscan..."
printf "\n"

echo "Verifying MiniDataRepository.sol on etherscan..."
forge verify-contract \
--chain-id $chain_id \
--num-of-optimizations 200 \
--compiler-version $compiler_version \
$data_repository_address src/MiniDataRepository.sol:MiniDataRepository \
$etherscan_api_key

echo "Verifying MiniToken.sol on etherscan..."
forge verify-contract \
--chain-id $chain_id \
--num-of-optimizations 200 \
--constructor-args $(cast abi-encode "constructor(address)" $data_repository_address) \
--compiler-version $compiler_version \
$mini_token_address src/MiniToken.sol:MiniToken \
$etherscan_api_key

echo "Verifying MiniAuctionHouse.sol on etherscan..."
forge verify-contract \
--chain-id $chain_id \
--num-of-optimizations 200 \
--compiler-version $compiler_version \
$auction_house_address src/MiniAuctionHouse.sol:MiniAuctionHouse \
$etherscan_api_key

echo "Verifying MiniAuctionHouseProxy.sol on etherscan..."
forge verify-contract \
--chain-id $chain_id \
--num-of-optimizations 200 \
--compiler-version $compiler_version \
$auction_house_proxy_address src/proxies/MiniAuctionHouseProxy.sol:MiniAuctionHouseProxy \
$etherscan_api_key
