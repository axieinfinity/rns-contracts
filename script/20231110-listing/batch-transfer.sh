set -ex

FROM=0x0f68edbe14c8f68481771016d7e2871d6a35de11
RPC=https://api.roninchain.com/rpc
TARGET=0x2368dfed532842db89b470fde9fd584d48d4f644
CURRENT_GAS_PRICE=$(cast gas-price --rpc-url $RPC)
CURRENT_NONCE=$(cast nonce --rpc-url $RPC $FROM)
PK=$(op read "op://Private/Ronin Mainnet Deployer/private key")

gasPrice=$((CURRENT_GAS_PRICE + 1000000000))
# Define an array of indices [0, 1, 2]

indices=(0)
# Loop through each index
for index in "${indices[@]}"; do
    (
        namehashResults=()
        # Read the JSON file
        jsonData=$(cat "../RNS-names/AirDropNames.json")

        # Parse JSON data
        labels=$(
            node -e '
            const labels = JSON.parse(process.argv[1]).airdropNames.map(auction => auction.label + ".ron");
            labels.forEach(v => console.log(v))
        ' "$jsonData"
        )
        addresses=$(
            node -e '
            const addresses = JSON.parse(process.argv[1]).airdropNames.map(auction => auction.address);
            console.log(addresses.join(","));
        ' "$jsonData"
        )

     
        # Loop through each label and call cast namehash
        for label in ${labels}; do
            result=$(cast namehash "$label")
            echo "Label: $label, Namehash: $result"
            namehashResults+=($result)
        done

        # Join array elements with ","
        joinedString=$(IFS=, echo "${labels[*]}")

        nextNonce=$((CURRENT_NONCE + index))

        # Join array elements with ","
        joinedString=$(
            IFS=,
            echo "${namehashResults[*]}"
        )

        echo Nonce: $nextNonce
        echo addresses $addresses
        echo "Joined String: $joinedString"

        # cast call --trace --from $FROM --rpc-url $RPC $TARGET "safeBatchTransfer(address,uint256[],address[])" 0x67C409DaB0EE741A1B1Be874bd1333234cfDBF44 "[$joinedString]"  "[$addresses]" 
        txHash=$(cast s --gas-price $gasPrice --async --confirmations 0 --nonce $nextNonce --legacy --private-key $PK --rpc-url $RPC $TARGET "safeBatchTransfer(address,uint256[],address[])" 0x67C409DaB0EE741A1B1Be874bd1333234cfDBF44 "[$joinedString]"  "[$addresses]"  )
        echo https://app.roninchain.com/tx/$txHash
    ) &

    # Check if index is a multiple of 100, then wait
    if [ $((index % 50)) -eq 0 ]; then
        wait
    fi
done

wait
