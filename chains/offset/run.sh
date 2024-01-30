#!/bin/sh

node "/app/ganache-core.docker.cli.js" \
  --chainId 17 \
  --networkId 17 \
  --db /root/.ethereum \
  --defaultBalanceEther 300000000 \
  --mnemonic "sign addict identify chunk urban captain leg curious purpose treat cheap pave" \
  --blockTime 2 \
  $@
