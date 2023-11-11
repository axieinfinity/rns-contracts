# Define an array of indices [0, 1, 2]
indices=(0)

# Declare an array to store results
namehashResults=()

# Loop through each index
for index in "${indices[@]}"; do
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

    # Execute shell command
    cast e --from 0x0f68edbe14c8f68481771016d7e2871d6a35de11 --rpc-url https://api-partner.roninchain.com/rpc 0x662852853614cbBb5D04BF2E29955b97E3C50B69 "bulkWhitelistProtectedNames(uint256[],address[],bool)" "[$ids]" "[$owners]" true
done
