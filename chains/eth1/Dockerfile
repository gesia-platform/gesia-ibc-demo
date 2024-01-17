FROM ethereum/client-go:latest

ADD password /root/password
ADD genesis.json  /root/genesis.json
ADD private_key  /root/private_key
ADD run.sh  /run.sh

RUN /usr/local/bin/geth --datadir /root/.ethereum init /root/genesis.json

RUN /usr/local/bin/geth account import --password /root/password /root/private_key

ENTRYPOINT ["/run.sh"]

CMD ["--verbosity", "5", "--vmdebug"]
