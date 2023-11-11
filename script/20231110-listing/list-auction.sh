# Define an array of indices [0, 1, 2]
indices=(0)

# Loop through each index
for index in "${indices[@]}"; do
    # Read the JSON file
    jsonData=$(cat "script/20231110-listing/data/AuctionNames${index}.json")

    # Parse JSON data
    labelsString=$(
        node -e '
            const labels = JSON.parse(process.argv[1]).auctionNames.map(auction => auction.label);
            console.log(labels.join(","));
        ' "$jsonData"
    )
    startingPrices=$(
        node -e '
            const startingPrices = JSON.parse(process.argv[1]).auctionNames.map(auction => auction.startingPrice);
            console.log(startingPrices.join(","));
        ' "$jsonData"
    )

    startedAt=$(echo "$jsonData" | jq -r '.auctionEvent.startedAt')
    endedAt=$(echo "$jsonData" | jq -r '.auctionEvent.endedAt')

    # Print the extracted values
    echo event started at: $startedAt
    echo event ended at: $endedAt

    auctionId=$(cast call --from 0x0f68edbe14c8f68481771016d7e2871d6a35de11 --rpc-url https://api-partner.roninchain.com/rpc 0xD55e6d80aeA1FF4650BC952C1653ab3CF1b940A9 "createAuctionEvent((uint256,uint256))" "($startedAt, $endedAt)")
    echo auctionId $auctionId
    listNamesForAuctionGas=$(cast e --from 0x0f68edbe14c8f68481771016d7e2871d6a35de11 --rpc-url https://api-partner.roninchain.com/rpc 0xD55e6d80aeA1FF4650BC952C1653ab3CF1b940A9 "listNamesForAuction(bytes32,uint256[],uint256[])" $auctionId "[$labelsString]" "[$startingPrices]")
    echo "listNamesForAuctionGas" $listNamesForAuctionGas
done
