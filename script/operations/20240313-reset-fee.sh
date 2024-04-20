source config.sh

# Declare an array to store results

# Read the JSON file
jsonData=$(cat "script/data/517 Community names (Tier 1) - _3 characters.json")

# Parse JSON data
labels=$(
    node -e '
            const labels = JSON.parse(process.argv[1]).communityNames.map(name => name.domain);
            labels.forEach(v => console.log(v))
        ' "$jsonData"
)

tiers=$(
    node -e '
            const tiers = JSON.parse(process.argv[1]).communityNames.map(name => name.tier);
            tiers.forEach(v => console.log("0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff"))
        ' "$jsonData"
)

batchSize=100
length=${#labels[@]}
labels=($labels)
tiers=($tiers)
length=${#labels[@]}
echo "Num reset tier: $length \n"

# Calculate the number of batches
numBatches=$(((length + batchSize - 1) / batchSize))
echo "Number of Batches: $numBatches \n"

# Loop through each batch
for ((batch = 0; batch < numBatches; batch++)); do
    (
        # Increment nextNonce
        nextNonce=$((CURRENT_NONCE + batch))

        # Calculate the start and end index for the current batch
        start=$((batch * batchSize))
        end=$((start + batchSize - 1))
        if ((end >= length)); then
            end=$((length - 1))
        fi

        echo "Next Nonce: $nextNonce"
        echo "Batch: $batch"
        echo "Start: $start, End: $end \n"

        # Declare arrays to store results
        labelhashResults=()
        tiersBatch=()

        # Loop through each label and call cast namehash
        for ((i = start; i <= end; i++)); do
            label=${labels[i]}
            tier=${tiers[i]}
            result=$(cast keccak $(cast from-utf8 $label))
            labelhashResults+=($result)
            tiersBatch+=($tier)
        done

        # Join array elements with ","
        lbHash=$(
            IFS=,
            echo "${labelhashResults[*]}"
        )

        tiersBatch=$(
            IFS=,
            echo "${tiersBatch[*]}"
        )

        execute $nextNonce $(loadAddress RNSDomainPriceProxy) $(cast calldata "bulkOverrideRenewalFees(bytes32[],uint256[])" "[$lbHash]" "[$tiersBatch]")
    ) &
done

wait
