#!/bin/sh

node "/app/ganache-core.docker.cli.js" \
  --chainId 15 \
  --networkId 15 \
  --db /root/.ethereum \
  --defaultBalanceEther 300000000 \
  --mnemonic "worth winter festival wealth place advance raise salute fever retire process announce" \
  --blockTime 2 \
  $@
