source config.sh

# Loop through each index
for index in {0..0}; do
    (
        nextNonce=$((CURRENT_NONCE + index))

        # Read the JSON file
        jsonData=$(cat "../RNS-names/finalfinalfinalauction.json")

        # Parse JSON data
        labelsString=$(
            node -e '
            const labels = JSON.parse(process.argv[1]).auctionNames.map(auction => auction.label);
            console.log(labels.join(","));
        ' "$jsonData"
        )

        echo "Labels for AuctionNames${index}: $labelsString"

        execute $nextNonce $(loadAddress RNSAuctionProxy) $(cast calldata "bulkRegister(string[])" "[$labelsString]")
    ) &

    # Check if index is a multiple of 100, then wait
    if [ $((index % 50)) -eq 0 ]; then
        wait
    fi
done

wait
