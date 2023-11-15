RPC=https://api.roninchain.com/rpc
FROM=0x0f68edbe14c8f68481771016d7e2871d6a35de11
TARGET=0x2BdC555A87Db9207E5d175f0c12B237736181675
CURRENT_GAS_PRICE=$(cast gas-price --rpc-url $RPC)
CURRENT_NONCE=$(cast nonce --rpc-url $RPC $FROM)
PK=$(op read "op://Private/Ronin Mainnet Deployer/private key")
TX_EXPLORER=https://app.roninchain.com/tx/

start=0
end=0
# Loop through each index
for index in $(seq $start $end); do
    (
        # Declare an array to store results
        nextNonce=$((CURRENT_NONCE + index - start))
        echo Nonce: $nextNonce
        labelhashResults=()
        # Read the JSON file
        jsonData=$(cat "../RNS-names/FeeProtectedNames10.json")

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
            result=$(cast keccak $(cast from-utf8 $label))
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
