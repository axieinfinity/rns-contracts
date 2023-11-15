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
        jsonData=$(cat "script/20231110-listing/data/AddressProtectedNames${index}.json")

        # Parse JSON data
        labels=$(
            node -e '
            const labels = JSON.parse(process.argv[1]).protectedNames.map(protected => protected.label + ".ron");
            labels.forEach(v => console.log(v))
        ' "$jsonData"
        )

        owners=$(
            node -e '
            const owners = JSON.parse(process.argv[1]).protectedNames.map(protected => protected.address);
            console.log(owners.join(","));
        ' "$jsonData"
        )

        echo "Labels for ProtectedNames${index}: $labels"
        echo "Whitelisted owners for ProtectedNames${index}: $owners"

        # Loop through each label and call cast namehash
        for label in ${labels}; do
            result=$(cast namehash "$label")
            echo "Label: $label, Namehash: $result"
            namehashResults+=($result)
        done

        for res in "${namehashResults[@]}"; do
            echo $res
        done

        # Join array elements with ","
        ids=$(
            IFS=,
            echo "${namehashResults[*]}"
        )

        # Print the result
        echo "Ids String: $ids"
        echo "Owners String: $owners"

        broadcast $CURRENT_GAS_PRICE $nextNonce $CONTROLLER $(cast calldata "bulkWhitelistProtectedNames(uint256[],address[],bool)" "[$ids]" "[$owners]" true)
    ) &

    # Check if index is a multiple of 100, then wait
    if [ $((index % 50)) -eq 0 ]; then
        wait
    fi
done

wait
