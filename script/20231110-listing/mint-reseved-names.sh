set -ex
FROM=0x0f68edbe14c8f68481771016d7e2871d6a35de11
RPC=https://api.roninchain.com/rpc
TARGET=0x8975923D01132bEB6c412F827f63D44712726E13
CURRENT_GAS_PRICE=$(cast gas-price --rpc-url $RPC)
CURRENT_NONCE=$(cast nonce --rpc-url $RPC $FROM)
PK=$(op read "op://Private/Ronin Mainnet Deployer/private key")

gasPrice=$((CURRENT_GAS_PRICE + 1000000000))
# Define an array of indices [0, 1, 2]

RNS=0x67C409DaB0EE741A1B1Be874bd1333234cfDBF44
RON_ID=84316718148691062097763301062091587921872078571554862844431317764698029807240
RESOLVER=0xadb077d236d9E81fB24b96AE9cb8089aB9942d48
DURATION=31536000

indices=(0)
# Loop through each index
for index in "${indices[@]}"; do
    (
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

        nextNonce=$((CURRENT_NONCE + index))
        echo Nonce: $nextNonce

        echo auctionId $auctionId
        echo addresses $addresses

        # cast e --from $FROM --rpc-url $RPC $TARGET "multiMint(address,uint256,address,uint64,address[],string[])" $RNS $RON_ID $RESOLVER $DURATION "[$(IFS=, echo "${addresses[*]}")]" "[$(IFS=, echo "${labels[*]}")]" 
        txHash=$(cast s --gas-price $gasPrice --async --confirmations 0 --nonce $nextNonce --legacy --private-key $PK --rpc-url $RPC $TARGET "multiMint(address,uint256,address,uint64,address[],string[])" $RNS $RON_ID $RESOLVER $DURATION "[$(IFS=, echo "${addresses[*]}")]" "[$(IFS=, echo "${labels[*]}")]" )
        echo https://app.roninchain.com/tx/$txHash
    ) &

    # Check if index is a multiple of 100, then wait
    if [ $((index % 50)) -eq 0 ]; then
        wait
    fi
done

wait
