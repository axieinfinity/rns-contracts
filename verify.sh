# Default network value
network="2021"
networkName="ronin-testnet"
endpoint=https://sourcify.roninchain.com/server

# Function to print usage and exit
usage() {
    echo "Usage: $0 -c <network>"
    echo "  -c: Specify the network (ronin-testnet or ronin-mainnet)"
    exit 1
}

# Parse command-line options
while getopts "c:" opt; do
    case $opt in
    c)
        case "$OPTARG" in
        ronin-testnet)
            child_folder="ronin-testnet"
            network="2021"
            networkName="ronin-testnet"
            ;;
        ronin-mainnet)
            child_folder="ronin-mainnet"
            network="2020"
            networkName="ronin-mainnet"
            ;;
        *)
            echo "Unknown network specified: $OPTARG"
            usage
            ;;
        esac
        ;;
    *)
        usage
        ;;
    esac
done

yarn hardhat sourcify --endpoint ${endpoint} --network ${networkName}

# ToDo(TuDo): make foundry verification perfectly match using sourcify
# # Shift the processed options out of the argument list
# shift $((OPTIND - 1))

# # Define the deployments folder by concatenating it with the child folder
# folder="deployments/$child_folder"

# # Check if the specified folder exists
# if [ ! -d "$folder" ]; then
#     echo "Error: The specified folder does not exist for the selected network."
#     exit 1
# fi
# # Loop through JSON files in the selected folder
# for file in "$folder"/*.json; do
#     # Check if the file exists and is a regular file
#     if [ -f "$file" ]; then
#         # Exclude the .chainId file
#         if [ "$(basename "$file")" != ".chainId" ]; then
#             # Extract contractName and address from the JSON file
#             contractName=$(jq -r '.contractName' "$file")
#             address=$(jq -r '.address' "$file")
#             absolutePath=$(jq -r '.ast.absolutePath' "$file")

#             # Check if contractName and address are not empty
#             if [ -n "$contractName" ] && [ -n "$address" ]; then
#                 echo "$absolutePath"
#                 # Call the forge command for verification with the specified network
#                 forge verify-contract --verifier sourcify --verifier-url ${endpoint} -c "$network" "$address" "$absolutePath:$contractName"
#             else
#                 echo "Error: Missing contractName or address in $file"
#             fi
#         fi
#     fi
# done
