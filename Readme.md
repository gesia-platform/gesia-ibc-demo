# Demo of ERC1155 bridging between heterogeneous chains for GESIA

IBC-based heterogeneous chain communication
<br/>
(https://www.ibcprotocol.dev)

significant portion of the golang implementation is implemented in solidity.
<br/>
(https://github.com/cosmos/ibc-go)

## Diagram

![Geasia Diagram](./docs/assets/diagram.jpg)

## Setup & Deploy & Test

```bash
# 1. Install dependencies
npm install

# 2. Build
npx truffle compile
cd chains && docker compose build --no-cache && cd ..
cd relayer && go build -o ../build/relayer . && cd ..

# 3. Run chains A, B

cd chains && docker compose up -d --build && cd ..

# 4. Migrate all contracts

npx truffle migrate --network eth0
npx truffle migrate --network eth1

# 5. Handshake relayer between chains
# Note: you should update ibc_address field to ${logged form #4 ibc_address: {}} at configs/relayer/chains/*.json
./scripts/relayer/handshake.sh

# 6. Start relayer for bridging
./scripts/relayer/start.sh

# 7. Mint carbon offset voucher NFT(ERC1155)
npx truffle exec test/0-mint.js --network eth0

# 8. Send packet (store packet request it self(source chain))
# Note: relayer will transfer packet to dest chain from source chain.
npx truffle exec test/1-send.js --network eth0

# then you can check minted token balance each chain
```
