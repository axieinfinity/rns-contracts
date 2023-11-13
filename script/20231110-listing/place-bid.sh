RPC=https://saigon-archive.roninchain.com/rpc
FROM=0x968D0Cd7343f711216817E617d3f92a23dC91c07
TARGET=0xb962eddeD164f55D136E491a3022246815e1B5A8
CURRENT_GAS_PRICE=$(cast gas-price --rpc-url $RPC)
CURRENT_NONCE=$(cast nonce --rpc-url $RPC $FROM)
PK=$(op read "op://SC Vault/Testnet Admin/private key")
echo current nonce $CURRENT_NONCE
gasPrice=$((CURRENT_GAS_PRICE + 1000000000))
# Define an array of indices [0, 1, 2]
indices=(1 2)

namehashResults=()
# Read the JSON file
jsonData=$(cat "script/20231110-listing/data/PlaceBid.json")

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

        nextNonce=$((CURRENT_NONCE + index))
        echo Nonce: $nextNonce

        # fee=$(cast e --from $FROM --rpc-url $RPC $TARGET "placeBid(uint256)" "$id")
        # echo fee: $fee

        # TO-DO: remove --value
        txHash=$(cast s --gas-price $gasPrice --value 2 --async --confirmations 0 --nonce $nextNonce --legacy --from $FROM --private-key $PK --rpc-url $RPC $TARGET "placeBid(uint256)" "$id")

        echo https://saigon-app.roninchain.com/tx/$txHash
    ) &

    # Check if index is a multiple of 100, then wait
    if [ $((index % 50)) -eq 0 ]; then
        wait
    fi
done

wait
