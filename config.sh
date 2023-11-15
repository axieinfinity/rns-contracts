# Function to print usage and exit
usage() {
    echo "Usage: $0 -c <network>"
    echo "  -c: Specify the network (ronin-testnet or ronin-mainnet)"
    exit 1
}

loadConfig() {
    local network="$1"

    if [ "$network" == 'ronin-mainnet' ]; then
        RPC=https://api.roninchain.com/rpc
        EXPLORER=https://app.roninchain.com/tx
        FROM=0x968D0Cd7343f711216817E617d3f92a23dC91c07

        RESOLVER=0xadb077d236d9E81fB24b96AE9cb8089aB9942d48
        CONTROLLER=0x662852853614cbBb5D04BF2E29955b97E3C50B69
        RNS_UNIFIED=0xf0c99c9677EDa0D13291C093b27E6512E4ACdF83
        RNS_AUCTION=0xD55e6d80aeA1FF4650BC952C1653ab3CF1b940A9
        RNS_DOMAIN_PRICE=0x2BdC555A87Db9207E5d175f0c12B237736181675
        OWNED_MULTICALLER=0x8975923D01132bEB6c412F827f63D44712726E13
        ERC721_BATCH_TRANSFER=0x2368dfed532842db89b470fde9fd584d48d4f644

        CURRENT_GAS_PRICE=$(cast gas-price --rpc-url $RPC)
        CURRENT_NONCE=$(cast nonce --rpc-url $RPC $FROM)

        PK=$(op read "op://Private/Ronin Mainnet Deployer/private key")
    else
        RPC=https://saigon-archive.roninchain.com/rpc
        FROM=0x057B3862d021f8931c96f789f2A7c4d3eA3C665f
        EXPLORER=https://saigon-app.roninchain.com/tx

        RESOLVER=0x803c459dCB8771e5354D1fC567Ecc6885A9fd5E6
        CONTROLLER=0x512699B52ac2dC2b2aD505d9f29DcDad078FA799
        RNS_UNIFIED=0x67C409DaB0EE741A1B1Be874bd1333234cfDBF44
        RNS_AUCTION=0xb962eddeD164f55D136E491a3022246815e1B5A8
        RNS_DOMAIN_PRICE=0x51cAF51678f469e9DD4c878a7b0ceBEbbd4A4AB5
        OWNED_MULTICALLER=0x8975923D01132bEB6c412F827f63D44712726E13
        ERC721_BATCH_TRANSFER=0x2e889348bd37f192063bfec8ff39bd3635949e20

        CURRENT_GAS_PRICE=$(cast gas-price --rpc-url $RPC)
        CURRENT_NONCE=$(cast nonce --rpc-url $RPC $FROM)

        PK=$(op read "op://SC Vault/Testnet Admin/private key")
    fi
}

estimate() {
    local target="$1"
    local args="$2"

    gas=$(cast e --from $FROM --rpc-url $RPC $target $args)
    echo estimated gas: $gas
}

broadcast() {
    local gasPrice="$1"
    local nonce="$2"
    local target="$3"
    local args="$4"

    txHash=$(cast s --from $FROM --legacy --gas-price $gasPrice --async --confirmations 0 --nonce $nonce --private-key $PK --rpc-url $RPC $target $args)

    echo $EXPLORER/$txHash
}

# Parse command-line options
if [ "$#" -eq 0 ]; then
    usage
fi

# Parse command-line options
while getopts "c:" opt; do
    case $opt in
    c)
        case "$OPTARG" in
        ronin-testnet)
            loadConfig "ronin-testnet"
            ;;
        ronin-mainnet)
            loadConfig "ronin-mainnet"
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
