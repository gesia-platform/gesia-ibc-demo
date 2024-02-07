#!/bin/sh

# password variables
password_path="/root/.ethereum/data"
password_file="password.txt"

if [ ! -s "$password_path/$password_file" ]; then
    LC_ALL=C tr -dc 'A-Za-z0-9' < /dev/urandom | head -c 6 > "$password_path/$password_file"
    echo "Password created"
fi

# account variables
account_path="/root/.ethereum/data"
account_file="account-address.txt"

if [ -s "$account_path/$account_file" ]; then
    echo "Account address already exists"
    exit 0
fi

# Create a new account and captue the output
output=$(geth account new --password="$password_path/$password_file" 2>&1)

# Check if the command was successful
if [ $? -eq 0 ]; then
    # Extract the public address using grep and awk
    address=$(echo "$output" | grep -oE '0x[a-fA-F0-9]{40}')
    if [ -n "$address" ]; then
        # Save the public address to a file
        echo -n "$address" > "$account_path/$account_file"
        echo "Address created"
        exit 0
    else
        echo "Failed to extract public address"
        exit 1
    fi
else
    echo "Failed to create new account"
    exit 1
fi