# Define an array of indices [0, 1, 2]
indices=(0)

# Loop through each index
for index in "${indices[@]}"; do
    # Declare an array to store results
    labelhashResults=()

    # Read the JSON file
    jsonData=$(cat "script/20231110-listing/data/FeeProtectedNames${index}.json")

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

    echo "Labels for ProtectedNames${index}: $labels"
    echo "Overriden fees for ProtectedNames${index}: $fees"

    # Loop through each label and call cast namehash
    for label in ${labels}; do
        result=$(cast keccak "$label")
        echo "Label: $label, LabelHash: $result"
        labelhashResults+=($result)
    done

    for res in "${labelhashResults[@]}"; do
        echo $res
    done

    # Join array elements with ","
    lbHash=$(
        IFS=,
        echo "${labelhashResults[*]}"
    )

    # Print the result
    echo "LabelHash String: $lbHash"
    echo "Fees String: $fees"

    # Execute shell command
    cast e --from 0x0f68edbe14c8f68481771016d7e2871d6a35de11 --rpc-url https://api-partner.roninchain.com/rpc 0x2BdC555A87Db9207E5d175f0c12B237736181675 "bulkOverrideRenewalFees(bytes32[],uint256[])" "[$lbHash]" "[$fees]"
done
