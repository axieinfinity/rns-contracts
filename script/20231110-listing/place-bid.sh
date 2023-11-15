RPC=https://api.roninchain.com/rpc
FROM=0x0f68edbe14c8f68481771016d7e2871d6a35de11
TARGET=0xd55e6d80aea1ff4650bc952c1653ab3cf1b940a9
CURRENT_GAS_PRICE=$(cast gas-price --rpc-url $RPC)
CURRENT_NONCE=$(cast nonce --rpc-url $RPC $FROM)
PK=$(op read "op://Private/Ronin Mainnet Deployer/private key")
echo current nonce $CURRENT_NONCE
gasPrice=$((CURRENT_GAS_PRICE + 1000000000))
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
    # Increment the index
    ((index++))
    (

        nextNonce=$((CURRENT_NONCE + index - 1))
        echo Nonce: $nextNonce

        # fee=$(cast e --from $FROM --rpc-url $RPC $TARGET "placeBid(uint256)" "$id")
        # echo fee: $fee

        # TO-DO: remove --value
        txHash=$(cast s --gas-price $gasPrice --value 0 --async --confirmations 0 --nonce $nextNonce --legacy --from $FROM --private-key $PK --rpc-url $RPC $TARGET "placeBid(uint256)" "$id")

        echo https://app.roninchain.com/tx/$txHash
    ) &

    # Check if index is a multiple of 100, then wait
    if [ $((index % 50)) -eq 0 ]; then
        wait
    fi
done

wait
