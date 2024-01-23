#!/bin/sh

node "/app/ganache-core.docker.cli.js" \
  --chainId 16 \
  --networkId 16 \
  --db /root/.ethereum \
  --defaultBalanceEther 1000000 \
  --mnemonic "math razor capable expose worth grape metal sunset metal sudden usage scheme" \
  --blockTime 2 \
  $@
