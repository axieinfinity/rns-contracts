RPC=https://saigon-archive.roninchain.com/rpc
FROM=0x968D0Cd7343f711216817E617d3f92a23dC91c07
TARGET=0xb962eddeD164f55D136E491a3022246815e1B5A8
CURRENT_GAS_PRICE=$(cast gas-price --rpc-url $RPC)
CURRENT_NONCE=$(cast nonce --rpc-url $RPC $FROM)
PK=$(op read "op://SC Vault/Testnet Admin/private key")

gasPrice=$((CURRENT_GAS_PRICE + 1000000000))
# Define an array of indices [0, 1, 2]
indices=(1 2)
# Loop through each index
for index in "${indices[@]}"; do
    (
        namehashResults=()
        # Read the JSON file
        jsonData=$(cat "script/20231110-listing/data/AuctionNames${index}.json")

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

        nextNonce=$((CURRENT_NONCE + index - 1))
        echo Nonce: $nextNonce

        echo auctionId $auctionId
        echo startingPrices $startingPrices

        # fee=$(cast e --from $FROM --rpc-url $RPC $TARGET "listNamesForAuction(bytes32,uint256[],uint256[])" "$auctionId" "[$joinedString]" "[$startingPrices]")
        # echo fee: $fee

        txHash=$(cast s --gas-price $gasPrice --async --confirmations 0 --nonce $nextNonce --legacy --from $FROM --private-key $PK --rpc-url $RPC $TARGET "listNamesForAuction(bytes32,uint256[],uint256[])" "$auctionId" "[$joinedString]" "[$startingPrices]")
        echo https://saigon-app.roninchain.com/tx/$txHash
    ) &

    # Check if index is a multiple of 100, then wait
    if [ $((index % 50)) -eq 0 ]; then
        wait
    fi
done

wait
