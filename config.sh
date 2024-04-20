source .env

EXTRA_ARGS=()
FROM=
TARGET=
CURRENT_NONCE=
EXTRA_GAS_PRICE=
CURRENT_GAS_PRICE=
DEPLOYMENT_ROOT='deployments'

# Function to display script usage
usage() {
    echo "Usage: $0 -c <network> -m <mode> [-eg <extra_gas_price>] -f <from>"
    echo "Options:"
    echo "  -c: Specify the network <ronin-mainnet|ronin-testnet>"
    echo "  -m: Specify running mode <estimate|broadcast|trace>"
    echo "  -f: Specify the sender address"
    echo "  -eg: Extra gas price (default: 0)"
    exit 1
}

# Function to load configuration based on network and mode
loadConfig() {
    if [ "$NETWORK" == 'ronin-mainnet' ]; then
        RPC=$MAINNET_URL
        EXPLORER=https://app.roninchain.com

        ERC721_BATCH_TRANSFER=0x2368dfed532842db89b470fde9fd584d48d4f644

        if [ "$MODE" == "broadcast" ]; then
            PK=$MAINNET_PK
        fi
    else
        RPC=$TESTNET_URL
        EXPLORER=https://saigon-app.roninchain.com

        ERC721_BATCH_TRANSFER=0x2e889348bd37f192063bfec8ff39bd3635949e20

        if [ "$MODE" == "broadcast" ]; then
            PK=$TESTNET_PK
        fi
    fi

    if [ "$MODE" == "broadcast" ]; then
        CURRENT_GAS_PRICE=$(cast gas-price --rpc-url $RPC)

        if [[ "$PK" == op://* ]]; then
            PK=$(op read "$PK")
        fi
    fi

    CURRENT_NONCE=$(cast nonce --rpc-url $RPC $FROM)
    echo "Current nonce: $CURRENT_NONCE"
}

# Function to load address from deployment file
loadAddress() {
    local contract="$1"
    echo $(jq -r '.address' ${DEPLOYMENT_ROOT}/${NETWORK}/${contract}.json)
}

# Function to execute based on the specified mode
execute() {
    local nonce="$1"
    local target="$2"
    local args="$3"

    if [ "$MODE" == "broadcast" ]; then
        broadcast "$nonce" "$target" "$args"
    elif [ "$MODE" == "estimate" ]; then
        estimate "$target" "$args"
    elif [ "$MODE" == "trace" ]; then
        trace "$target" "$args"
    else
        echo "Error: Invalid mode option. Choose either 'broadcast', 'estimate', or 'trace'."
    fi
}

# Function to perform a trace
trace() {
    local target="$1"
    local args="$2"
    cast c $EXTRA_ARGS --from $FROM --trace --rpc-url $RPC $target $args
}

# Function to estimate gas
estimate() {
    local target="$1"
    local args="$2"
    gas=$(cast e $EXTRA_ARGS --from $FROM --rpc-url $RPC $target $args)
    echo estimated gas: $gas
}

# Function to broadcast a transaction
broadcast() {
    local nonce="$1"
    local target="$2"
    local args="$3"

    txHash=$(cast s $EXTRA_ARGS --from $FROM --legacy --gas-price $((CURRENT_GAS_PRICE + EXTRA_GAS_PRICE)) --async --confirmations 0 --nonce $nonce --private-key $PK --rpc-url $RPC $target $args)

    echo $EXPLORER/tx/$txHash
}

# Check if command-line arguments are provided
if [ "$#" -eq 0 ]; then
    usage
fi

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
    --from | -f)
        shift
        FROM="$1"
        ;;
    --chain | -c)
        shift
        NETWORK="$1"
        ;;
    --mode | -m)
        shift
        MODE="$1"
        ;;
    --extra-gas | -eg)
        shift
        EXTRA_GAS_PRICE="$1"
        ;;
    *)
        # Check if the next argument is present
        if [ -n "$2" ]; then
            # Add both the flag and its value to EXTRA_ARGS
            EXTRA_ARGS+=("$1 $2")
            shift
        else
            # Add only the flag to EXTRA_ARGS
            EXTRA_ARGS+=("$1")
        fi
        ;;
    esac
    shift
done

# Check if all required arguments are provided
if [ -z "$NETWORK" ] || [ -z "$MODE" ] || [ -z "$FROM" ]; then
    echo "Error: Missing required arguments!"
    usage
fi

# Validate network and mode options
if [ "$NETWORK" != "ronin-testnet" ] && [ "$NETWORK" != "ronin-mainnet" ]; then
    echo "Error: Invalid network option. Choose either 'ronin-testnet' or 'ronin-mainnet'."
    usage
fi

# Load configuration based on network and mode
loadConfig
