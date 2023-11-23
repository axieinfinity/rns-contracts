source config.sh

RON_ID=84316718148691062097763301062091587921872078571554862844431317764698029807240
DURATION=31536000

# Define an array of indices [0, 1, 2]
indices=(0)
# Loop through each index
for index in "${indices[@]}"; do
    (
        nextNonce=$((CURRENT_NONCE + index))

        # Declare an array to store results
        namehashResults=()
        # Read the JSON file
        jsonData=$(cat "../RNS-names/finalfinalReservedNames.json")

        # Parse JSON data
        labels=$(
            node -e '
            const labels = JSON.parse(process.argv[1]).protectedNames.map(auction => auction.label);
            console.log(labels.join(","));
        ' "$jsonData"
        )
        addresses=$(
            node -e '
            const addresses = JSON.parse(process.argv[1]).protectedNames.map(auction => auction.address);
            console.log(addresses.join(","));
        ' "$jsonData"
        )

        # Join array elements with ","
        joinedString=$(IFS=, echo "${labels[*]}")

        auctionId=$(echo "$jsonData" | jq -r '.auctionId')

        echo auctionId $auctionId
        echo addresses $addresses

        execute $nextNonce $(loadAddress OwnedMulticaller) $(cast calldata "multiMint(address,uint256,address,uint64,address[],string[])" $(loadAddress RNSUnifiedProxy) $RON_ID $(loadAddress PublicResolverProxy) $DURATION "[$(IFS=, echo "${addresses[*]}")]" "[$(IFS=, echo "${labels[*]}")]")
    ) &

    # Check if index is a multiple of 100, then wait
    if [ $((index % 50)) -eq 0 ]; then
        wait
    fi
done

wait
