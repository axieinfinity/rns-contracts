source config.sh

# Define an array of indices [0, 1, 2]
indices=(0)
# Loop through each index
for index in "${indices[@]}"; do
    (
        nextNonce=$((CURRENT_NONCE + index))

        # Declare an array to store results
        namehashResults=()
        # Read the JSON file
        jsonData=$(cat "../RNS-names/AirDropNames.json")

        # Parse JSON data
        labels=$(
            node -e '
            const labels = JSON.parse(process.argv[1]).airdropNames.map(auction => auction.label + ".ron");
            labels.forEach(v => console.log(v))
        ' "$jsonData"
        )
        addresses=$(
            node -e '
            const addresses = JSON.parse(process.argv[1]).airdropNames.map(auction => auction.address);
            console.log(addresses.join(","));
        ' "$jsonData"
        )

        # Loop through each label and call cast namehash
        for label in ${labels}; do
            result=$(cast namehash "$label")
            echo "Label: $label, Namehash: $result"
            namehashResults+=($result)
        done

        # Join array elements with ","
        joinedString=$(IFS=, echo "${labels[*]}")

        # Join array elements with ","
        joinedString=$(
            IFS=,
            echo "${namehashResults[*]}"
        )

        execute $nextNonce $ERC721_BATCH_TRANSFER $(cast calldata "safeBatchTransfer(address,uint256[],address[])" $(loadAddress RNSUnifiedProxy) "[$joinedString]" "[$addresses]")
    ) &

    # Check if index is a multiple of 100, then wait
    if [ $((index % 50)) -eq 0 ]; then
        wait
    fi
done

wait
