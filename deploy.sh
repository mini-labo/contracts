#!/bin/sh

rpc_url=$RINKEBY_RPC_URL
private_key=$TEST_DEPLOY_PK
etherscan_api_key=$ETHERSCAN_API_KEY
compiler_version="v0.8.10+commit.fc410830"
chain_id="4" # rinkeby by default

seed_data_name="NUMBER ONE" 
seed_data_description="The first MINI"
seed_data_artist_name="three"
seed_generation="1"
seed_image_data="data:image/svg+xml;base64,PHN2ZyBpbWFnZS1yZW5kZXJpbmc9InBpeGVsYXRlZCIgcHJlc2VydmVBc3BlY3RSYXRpbz0ieE1pbllNaW4gbWVldCIgdmlld0JveD0iMCAwIDM1MCAzNTAiIHhtbG5zPSJodHRwOi8vd3d3LnczLm9yZy8yMDAwL3N2ZyIgeG1sbnM6eGxpbms9Imh0dHA6Ly93d3cudzMub3JnLzE5OTkveGxpbmsiPjxpbWFnZSB3aWR0aD0iMTAwJSIgaGVpZ2h0PSIxMDAlIiB4bGluazpocmVmPSJkYXRhOmltYWdlL2dpZjtiYXNlNjQsUjBsR09EZGhJQUFnQUpFQUFBQUFBUC8vL3dBQUFBQUFBQ0gvQzA1RlZGTkRRVkJGTWk0d0F3RUFBQUFoK1FRSkNnQUFBQ3dBQUFBQUlBQWdBQUFDYW95UHFjdnQzNFJFVXNCNGJORDdLbTVNM2VpRnBpYVM1VmhWNWtxMU1oekxNMjNuNEtWYmQ1bXJwU0RCUkF2NEV5SmRLdC9RWVd1R25nK25kTFBqWlNtMERHTzcwblc1SXVZWU5RTVRwMUUxaHQyR29jWHViOCtNNjQxZnZ0ZWVrMUpIVkVhMVozaUlVQUFBSWZrRUNRb0FBQUFzQUFBQUFDQUFJQUFBQW1tTWo2bkw3ZCtFUkZMQWVHelEreXB1VE4zb2hhWW1rdVZZVmVaS3RUSWN5ek50NStDbFczZVpxNlVnd1VRTCtCTWlYUXdtY1phYU9Ia2JIeVcwNDJXdnROZW5LenlDVDZnaERudmNVcXMybFlmVGN4UFJRYldqSis3aXg2dytIdzdIeDRZbVdHaUlVQUFBSWZrRUNRb0FBQUFzQUFBQUFDQUFJQUFBQW1tTWo2bkw3ZCtFUkZMQWVHelEreXB1VE4zb2hhWW1rdVZZVmVaS3RUSWN5ek50NStDbFczZVpxNlVnd1VRTCtCTWlYUXdtTVdrY0VqYyt6a1RLMnhscG1TWlhlUHllVU5nVithajFuR2ZwaDFXbjRvVjY4V3l2ckthTFVTenhpOXJseCtUa1YyaUlVQUFBSWZrRUNRb0FBQUFzQUFBQUFDQUFJQUFBQW1tTWo2bkw3ZCtFUkZMQWVHelEreXB1VE4zb2hhWW1rdVZZVmVaS3RUSWN5ek50NStDbFczZVpxNlVnd1VRTCtCTWlYUXdtY1phYU9Ia2JIeVcwNDJXdnROZW5LenlDVDZnaERudmNVcXMybFlmVGN4UFJRYldqSis3aXg2dytIdzdIeDRZbVdHaUlVQUFBSWZrRUNRb0FBQUFzQUFBQUFDQUFJQUFBQW1xTWo2bkw3ZCtFUkZMQWVHelEreXB1VE4zb2hhWW1rdVZZVmVaS3RUSWN5ek50NStDbFczZVpxNlVnd1VRTCtCTWlYU3JmMEdGcmhwNFBwM1N6NDJVcHRBeGp1OUoxdVNMbUdEVURFNmRSTlliZGhxSEY3bS9Qak91Tlg3N1hucE5TUjFSR3RXZDRpRkFBQURzPSIvPjwvc3ZnPg=="

# Auction House vars
if [ "$chain_id" = "4" ] ; then
  weth_address=0xc778417e063141139fce010982780140aa0cd5ab # rinkeby
elif [ "$chain_id" == "1" ] ; then
  weth_address=0xc02aaa39b223fe8d0a0e5c4f27ead9083c756cc2 # mainnet
else
  echo "No WETH address found for given chain_id"
  exit 1
fi

auction_reserve_price=1
auction_min_bid_increment_percentage=2
auction_artist_distribution_percentage=40
auction_time_buffer=300
auction_duration=86400

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

echo "== Finished contract deployment! ==="

echo "Beginning setup transactions..."
printf "\n"

echo "Initializing MiniAuctionHouse with the following args:"
printf "\n"

echo "_mini: ${mini_token_address}"
echo "_dataRepository: ${data_repository_address}"
echo "_weth: ${weth_address}"
echo "_timeBuffer: ${auction_time_buffer}"
echo "_reservePrice: ${auction_reserve_price}"
echo "_minBidIncrementPercentage: ${auction_min_bid_increment_percentage}"
echo "_artistDistributionPercentage: ${auction_artist_distribution_percentage}"
echo "_duration: ${auction_duration}"
printf "\n"

echo "publishing auction house initialization transaction..."
cast send $auction_house_proxy_address \
--rpc-url $rpc_url \
--private-key $private_key \
"initialize(address,address,address,uint256,uint256,uint8,uint8,uint256)" \
$mini_token_address \
$data_repository_address \
$weth_address \
$auction_time_buffer \
$auction_reserve_price \
$auction_min_bid_increment_percentage \
$auction_artist_distribution_percentage \
$auction_duration

printf "\n"

echo "publishing MiniToken auction house address set transaction..."
cast send $mini_token_address \
--rpc-url $rpc_url \
--private-key $private_key \
"setAuctionHouse(address)" $auction_house_proxy_address

printf "\n"

echo "publishing MiniDataRepository MINI token address set transaction..."
cast send $data_repository_address \
--rpc-url $rpc_url \
--private-key $private_key \
"setMiniTokenAddress(address)" $mini_token_address

encoded_seed_data=$(cast abi-encode \
"func(string, string, string, string, string)" \
"$seed_data_name" "$seed_data_description" "$seed_data_artist_name" "$seed_generation" "$seed_image_data")

echo "publishing token seed data to MiniDataRepository..."
cast send $data_repository_address \
--rpc-url $rpc_url \
--private-key $private_key \
"addData(bytes)" $encoded_seed_data

printf "\n"

echo "== Finished contract deployment! ==="

printf "\n"
echo "Beginning contract verification on etherscan..."
printf "\n"

echo "Verifying MiniDataRepository.sol on etherscan..."
forge verify-contract \
--chain-id $chain_id \
--num-of-optimizations 200 \
--compiler-version $compiler_version \
$data_repository_address src/MiniDataRepository.sol:MiniDataRepository \
$etherscan_api_key

printf "\n"

echo "Verifying MiniToken.sol on etherscan..."
forge verify-contract \
--chain-id $chain_id \
--num-of-optimizations 200 \
--constructor-args $(cast abi-encode "constructor(address)" $data_repository_address) \
--compiler-version $compiler_version \
$mini_token_address src/MiniToken.sol:MiniToken \
$etherscan_api_key

printf "\n"

echo "Verifying MiniAuctionHouse.sol on etherscan..."
forge verify-contract \
--chain-id $chain_id \
--num-of-optimizations 200 \
--compiler-version $compiler_version \
$auction_house_address src/MiniAuctionHouse.sol:MiniAuctionHouse \
$etherscan_api_key

printf "\n"

echo "Finished deploying and verifying contracts!"
printf "\n"
echo "MiniToken: ${mini_token_address}"
echo "MiniDataRepository: ${data_repository_address}"
echo "MiniAuctionHouse: ${auction_house_address}"
echo "MiniAuctionHouse (proxy): ${auction_house_proxy_address}"
echo "Proxy Admin: ${proxy_admin_address}"
