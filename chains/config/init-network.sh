#!/bin/sh

# account variables
account_path="/root/.ethereum/data"
account_file="account-address.txt"

# if [ ! -s "$account_path/$account_file" ]; then
#     echo "Not found account address"
#     exit 1
# fi

while [ ! -s "$account_path/$account_file" ]; do
    echo "Waiting for account address"
    sleep 5
done

echo "Account file found, proceeding..."

account=$(cat "$account_path/$account_file")
clean_account=${account#0x}

echo "Clean account: $clean_account"

# network variables
network_path="/root/.ethereum/data"
network_file="network.json"
network_modified_file="modified_network.json"

if [ ! -s "$network_path/$network_file" ]; then
    echo "Not found Network"
    exit 1
fi

if [ -s "$network_path/$network_modified_file" ]; then
    echo "Network already exists"
    exit 0
fi

jq  --arg chain_id "$NETWORK_CHAIN_ID" \
    --arg period "$NETWORK_CLIQUE_PERIOD" \
    --arg epoch "$NETWORK_CLIQUE_EPOCH" \
    --arg clean_account "$clean_account" \
    --arg balance "$NETWORK_ALLOC_BALANCE" \
    '.config.chainId = ($chain_id | tonumber) |
    .config.clique.period = ($period | tonumber) |
    .config.clique.epoch = ($epoch | tonumber) |
    .extraData = ("0x0000000000000000000000000000000000000000000000000000000000000000" + $clean_account + "0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000") |
    .alloc[$clean_account] = {balance: $balance}' "$network_path/$network_file" > "$network_path/$network_modified_file"

echo "network.json updated"

output=$(geth init "$network_path/$network_modified_file" 2>&1)

if echo "$output" | grep -q "Successfully"; then
    echo "Network initialized"
    exit 0
else
    echo "Failed to init network."
    echo "$output"
    exit 1
fi
