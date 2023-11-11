# Define an array of indices [0, 1, 2]
indices=(6)

# Declare an array to store results
namehashResults=()

# Loop through each index
for index in "${indices[@]}"; do
    # Read the JSON file
    jsonData=$(cat "script/20231110-listing/data/ProtectedNames${index}.json")
    echo $jsonData

    # Parse JSON data
    labels=$(
        node -e '
            const labels = JSON.parse(process.argv[1]).protectedNames.map(protected => protected.label + ".ron");
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

    # Execute shell command
    cast e --from 0x0f68edbe14c8f68481771016d7e2871d6a35de11 --rpc-url https://api-partner.roninchain.com/rpc 0x67C409DaB0EE741A1B1Be874bd1333234cfDBF44 "bulkSetProtected(uint256[],bool)" "[$joinedString]" true
done
