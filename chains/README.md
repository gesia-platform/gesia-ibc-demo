## Gesia Chains
Gesia merkle chain

### Configuration
 - Ethereum/data folder needs to be created within each chain folder
 - Also, you need to create “account-address.txt”, “network.json”, “password.txt”, and “modified_network.json” files in the data folder.
 - The “network.json” file must contain the following content:
```
{
    "config": {
        "chainId": 4567,
        "homesteadBlock": 0,
        "eip150Block": 0,
        "eip150Hash": "0x0000000000000000000000000000000000000000000000000000000000000000",
        "eip155Block": 0,
        "eip158Block": 0,
        "byzantiumBlock": 0,
        "constantinopleBlock": 0,
        "petersburgBlock": 0,
        "istanbulBlock": 0,
        "clique": {
            "period": 15,
            "epoch": 30000
        }
    },
    "nonce": "0x0",
    "timestamp": "0x65852297",
    "extraData": "",
    "gasLimit": "0x47b760",
    "difficulty": "0x1",
    "mixHash": "0x0000000000000000000000000000000000000000000000000000000000000000",
    "coinbase": "0x0000000000000000000000000000000000000000",
    "alloc": {},
    "number": "0x0",
    "gasUsed": "0x0",
    "parentHash": "0x0000000000000000000000000000000000000000000000000000000000000000",
    "baseFeePerGas": null
}
```

### Todo
 - MonoRepo
 - Shell Script Refactoring
 - Image Platform Refactoring
 - JQ Library Problem
 - Separate from other codes
