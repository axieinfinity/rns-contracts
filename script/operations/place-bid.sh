source config.sh

# Define an array of indices [0, 1, 2]
indices=(1 2)
namehashResults=()
# Read the JSON file
jsonData=$(cat "../RNS-names/GTMGamingAuctionNames.json")

# Parse JSON data
labels=$(
    node -e '
            const labels = JSON.parse(process.argv[1]).auctionNames.map(auction => auction.label + ".ron");
            labels.forEach(v => console.log(v))
        ' "$jsonData"
)

# Loop through each label and call cast namehash
for label in ${labels}; do
    result=$(cast namehash "$label")
    echo "Label: $label, Namehash: $result"
    namehashResults+=($result)
done

index=0
# Loop through each index
for id in "${namehashResults[@]}"; do
    (
        nextNonce=$((CURRENT_NONCE + index))
        broadcast $CURRENT_GAS_PRICE $nextNonce $RNS_AUCTION $(cast calldata "placeBid(uint256)" "$id")
    ) &

    # Increment the index
    ((index++))

    # Check if index is a multiple of 100, then wait
    if [ $((index % 50)) -eq 0 ]; then
        wait
    fi
done

wait
