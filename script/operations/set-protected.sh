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
        jsonData=$(cat "../RNS-names/removeProtectedNames.json")
        echo $jsonData

        # Parse JSON data
        labels=$(
            node -e '
            const labels = JSON.parse(process.argv[1]).reservedNames.map(protected => protected.label + ".ron");
            labels.forEach(v => console.log(v))
        ' "$jsonData"
        )

        echo "Labels for ProtectedNames${index}: $labels"

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
        joinedString=$(
            IFS=,
            echo "${namehashResults[*]}"
        )

        # Print the result
        echo "Joined String: $joinedString"

        broadcast $CURRENT_GAS_PRICE $nextNonce $RNS_UNIFIED $(cast calldata "bulkSetProtected(uint256[],bool)" "[$joinedString]" false)
    ) &

    # Check if index is a multiple of 100, then wait
    if [ $((index % 50)) -eq 0 ]; then
        wait
    fi
done

wait
