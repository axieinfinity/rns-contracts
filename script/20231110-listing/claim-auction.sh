# Define an array of indices [0, 1, 2]
indices=(0)

# Loop through each index
for index in "${indices[@]}"; do
    # Read the JSON file
    jsonData=$(cat "script/20231110-listing/data/AuctionNames${index}.json")

    # Parse JSON data
    labelsString=$(
        node -e '
            const labels = JSON.parse(process.argv[1]).auctionNames.map(auction => auction.label);
            console.log(labels.join(","));
        ' "$jsonData"
    )

    echo "Labels for AuctionNames${index}: $labelsString"

    # Execute shell command
    cast e --from 0x0f68edbe14c8f68481771016d7e2871d6a35de11 --rpc-url https://api-partner.roninchain.com/rpc 0xD55e6d80aeA1FF4650BC952C1653ab3CF1b940A9 "bulkRegister(string[])" "[$labelsString]"
done
