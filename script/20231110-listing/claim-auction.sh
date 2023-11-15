# Define an array of indices [0, 1, 2]
PK=$(op read "op://Private/Ronin Mainnet Deployer/private key")
set -ex

# Loop through each index
for index in {0..0}; do
    # Read the JSON file
    jsonData=$(cat "../RNS-names/finalfinalfinalauction.json")

    # Parse JSON data
    labelsString=$(
        node -e '
            const labels = JSON.parse(process.argv[1]).auctionNames.map(auction => auction.label);
            console.log(labels.join(","));
        ' "$jsonData"
    )

    echo "Labels for AuctionNames${index}: $labelsString"

    # Execute shell command
    cast s --legacy --from 0x0f68edbe14c8f68481771016d7e2871d6a35de11 --rpc-url https://api-partner.roninchain.com/rpc 0xD55e6d80aeA1FF4650BC952C1653ab3CF1b940A9 "bulkRegister(string[])" "[$labelsString]" --private-key $PK
done
