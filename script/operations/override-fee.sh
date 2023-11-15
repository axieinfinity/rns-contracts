source config.sh

start=0
end=0
# Loop through each index
for index in $(seq $start $end); do
    (
        # Declare an array to store results
        nextNonce=$((CURRENT_NONCE + index - start))

        # Declare an array to store results
        labelhashResults=()
        # Read the JSON file
        jsonData=$(cat "../RNS-names/FeeProtectedNames10.json")

        echo FeeProtectedNames${index}

        # Parse JSON data
        labels=$(
            node -e '
            const labels = JSON.parse(process.argv[1]).protectedNames.map(protected => protected.label);
            labels.forEach(v => console.log(v))
        ' "$jsonData"
        )

        fees=$(
            node -e '
            const fees = JSON.parse(process.argv[1]).protectedNames.map(protected => protected.fee);
            console.log(fees.join(","));
        ' "$jsonData"
        )

        # echo "Labels for ProtectedNames${index}: $labels"
        # echo "Overriden fees for ProtectedNames${index}: $fees"

        # Loop through each label and call cast namehash
        for label in ${labels}; do
            result=$(cast keccak $(cast from-utf8 $label))
            echo "Label: $label, LabelHash: $result"
            labelhashResults+=($result)
        done

        # Join array elements with ","
        lbHash=$(
            IFS=,
            echo "${labelhashResults[*]}"
        )

        broadcast $CURRENT_GAS_PRICE $nextNonce $RNS_DOMAIN_PRICE $(cast calldata "bulkOverrideRenewalFees(bytes32[],uint256[])" "[$lbHash]" "[$fees]")
    ) &
done

wait
