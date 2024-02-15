#!/bin/sh

# account variables
account_path="/root/.ethereum/data"
account_file="account-address.txt"

while [ ! -s "$account_path/$account_file" ]; do
    echo "Waiting for account address"
    sleep 5
done

echo "Account file found, proceeding..."

# network variables
network_path="/root/.ethereum/data"
network_modified_file="modified_network.json"

while [ ! -s "$network_path/$network_modified_file" ]; do
    echo "Waiting for network file"
    sleep 5
done

echo "Network file found, proceeding..."

account=$(cat "$account_path/$account_file")
clean_account=${account#0x}

echo "Clean account: $clean_account"

geth    --datadir="/root/.ethereum" \
        --syncmode="full" \
        --gcmode="archive" \
        --port="$CHAIN_NODE_PORT" \
        --http \
        --http.addr="0.0.0.0" \
        --http.port="$CHAIN_PORT" \
        --http.corsdomain="*" \
        --http.api="$CHAIN_ALLOW_API" \
        --http.vhosts="*" \
        --ws \
        --ws.addr="0.0.0.0" \
        --ws.port="$CHAIN_WS_PORT" \
        --ws.api="$CHAIN_ALLOW_API" \
        --networkid="$NETWORK_CHAIN_ID" \
        --ethstats="$CHAIN_NET_STATS_URL" \
        --nat="extip:$MY_IP" \
        --verbosity=5 \
        --unlock="$clean_account" \
        --password=/root/.ethereum/data/password.txt \
        --miner.gasprice=0 \
        --miner.etherbase="$clean_account" \
        --allow-insecure-unlock \
        --nodiscover \
        --mine