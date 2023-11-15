source config.sh

# Loop through each index
for index in {0..0}; do
    (
        nextNonce=$((CURRENT_NONCE + index))

        # Declare an array to store results
        namehashResults=()
        # Read the JSON file
        jsonData=$(cat "../RNS-names/AuctionTest.json")

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

        echo auctionId $auctionId
        echo startingPrices $startingPrices

        broadcast $CURRENT_GAS_PRICE $nextNonce $RNS_AUCTION $(cast calldata "listNamesForAuction(bytes32,uint256[],uint256[])" "$auctionId" "[$joinedString]" "[$startingPrices]")
    ) &

    # Check if index is a multiple of 100, then wait
    if [ $((index % 50)) -eq 0 ]; then
        wait
    fi
done

wait
