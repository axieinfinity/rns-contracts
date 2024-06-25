#!/bin/bash

# Check if foundry is installed
if ! command -v $HOME/.foundry/bin/forge &>/dev/null; then
    # Install foundryup
    curl -L https://foundry.paradigm.xyz | bash
    # Install foundry
    $HOME/.foundry/bin/foundryup -v nightly-de33b6af53005037b463318d2628b5cfcaf39916 # Stable version
fi

# Check if rustup is installed
if ! command -v rustup &>/dev/null; then
    # Install rustup
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
fi

# Update rustup
$HOME/.cargo/bin/rustup update stable
# Install soldeer
$HOME/.cargo/bin/cargo install soldeer
# Update dependencies with soldeer
$HOME/.cargo/bin/soldeer update
# Run forge build
$HOME/.foundry/bin/forge build

# Check if rustup is installed
if ! command -v jq &>/dev/null; then
    # Install jq
    brew install jq
fi
