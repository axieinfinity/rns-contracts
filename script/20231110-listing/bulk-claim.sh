set -ex
FROM=0x0f68edbe14c8f68481771016d7e2871d6a35de11
RPC=https://api.roninchain.com/rpc
TARGET=0xd55e6d80aea1ff4650bc952c1653ab3cf1b940a9
CURRENT_GAS_PRICE=$(cast gas-price --rpc-url $RPC)
CURRENT_NONCE=$(cast nonce --rpc-url $RPC $FROM)
PK=$(op read "op://Private/Ronin Mainnet Deployer/private key")

gasPrice=$((CURRENT_GAS_PRICE + 1000000000))
# Define an array of indices [0, 1, 2]
indices=(0)
# Loop through each index
for index in "${indices[@]}"; do
    (
        namehashResults=()
        # Read the JSON file
        jsonData=$(cat "../RNS-names/finalReservedNames.json")

        # Parse JSON data
        labels=$(
            node -e '
            const labels = JSON.parse(process.argv[1]).auctionNames.map(auction => auction.label + ".ron");
            labels.forEach(v => console.log(v))
        ' "$jsonData"
        )
        startingPrices=$(
            node -e '
            const startingPrices = JSON.parse(process.argv[1]).auctionNames.map(auction => auction.startingPrice);
            console.log(startingPrices.join(","));
        ' "$jsonData"
        )

        # Loop through each label and call cast namehash
        for label in ${labels}; do
            result=$(cast namehash "$label")
            echo "Label: $label, Namehash: $result"
            namehashResults+=($result)
        done

        # Join array elements with ","
        joinedString=$(
            IFS=,
            echo "${namehashResults[*]}"
        )

        auctionId=$(echo "$jsonData" | jq -r '.auctionId')

        nextNonce=$((CURRENT_NONCE + index))
        echo Nonce: $nextNonce

        echo auctionId $auctionId
        echo startingPrices $startingPrices

        txHash=$(cast s --gas-price $gasPrice --async --confirmations 0 --nonce $nextNonce --legacy --private-key $PK --rpc-url $RPC $TARGET "bulkClaimBidNames(uint256[])" "[$joinedString]" )
        echo https://app.roninchain.com/tx/$txHash
    ) &

    # Check if index is a multiple of 100, then wait
    if [ $((index % 50)) -eq 0 ]; then
        wait
    fi
done

wait
