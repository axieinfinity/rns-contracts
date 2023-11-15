# Define an array of indices [0, 1, 2]
indices=(0)

PK=$(op read "op://Private/Ronin Mainnet Deployer/private key")
# Declare an array to store results
namehashResults=()

# Loop through each index
for index in "${indices[@]}"; do
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

    # Execute shell command
    cast s --legacy --private-key $PK --rpc-url https://api-partner.roninchain.com/rpc 0x67C409DaB0EE741A1B1Be874bd1333234cfDBF44 "bulkSetProtected(uint256[],bool)" "[$joinedString]" false
done
