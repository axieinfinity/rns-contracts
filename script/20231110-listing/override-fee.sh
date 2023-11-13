RPC=https://saigon-archive.roninchain.com/rpc
FROM=0x968D0Cd7343f711216817E617d3f92a23dC91c07
TARGET=0x51cAF51678f469e9DD4c878a7b0ceBEbbd4A4AB5
CURRENT_GAS_PRICE=$(cast gas-price --rpc-url $RPC)
CURRENT_NONCE=$(cast nonce --rpc-url $RPC $FROM)
PK=$(op read "op://SC Vault/Testnet Admin/private key")
TX_EXPLORER=https://saigon-app.roninchain.com/tx/

start=0
end=6
# Loop through each index
for index in $(seq $start $end); do
    (
        # Declare an array to store results
        nextNonce=$((CURRENT_NONCE + index - start))
        echo Nonce: $nextNonce
        labelhashResults=()
        # Read the JSON file
        jsonData=$(cat "script/20231110-listing/data/FeeProtectedNames${index}.json")

        echo FeeProtectedNames${index}

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

        # echo "Labels for ProtectedNames${index}: $labels"
        # echo "Overriden fees for ProtectedNames${index}: $fees"

        # Loop through each label and call cast namehash
        for label in ${labels}; do
            if [ "$label" == "0xak" ]; then
                result="0x8028df340f8d924f15f36c880ac12966dec0ac8ac4f8f3f49cdb60a84e4eb083"
            else
                result=$(cast keccak "$label")
            fi
            echo "Label: $label, LabelHash: $result"
            labelhashResults+=($result)
        done

        # Join array elements with ","
        lbHash=$(
            IFS=,
            echo "${labelhashResults[*]}"
        )

        # gas=$(cast e --from $FROM --rpc-url $RPC $TARGET "bulkOverrideRenewalFees(bytes32[],uint256[])" "[$lbHash]" "[$fees]")
        # echo gas $gas

        # Execute shell command
        txHash=$(cast s --private-key $PK --nonce $nextNonce --async --confirmations 0 --legacy --rpc-url $RPC $TARGET "bulkOverrideRenewalFees(bytes32[],uint256[])" "[$lbHash]" "[$fees]")

        echo ${TX_EXPLORER}${txHash}
    ) &
done

wait
