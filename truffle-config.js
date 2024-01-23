const HDWalletProvider = require("@truffle/hdwallet-provider");

const privateKey =
  "e517af47112e4f501afb26e4f34eadc8b0ad8eadaf4962169fc04bc8ddbfe091";

module.exports = {
  contracts_directory: "./contracts",
  contracts_build_directory: "./build/contracts",
  migrations_directory: "./migrations",
  networks: {
    eth0: {
      host: "127.0.0.1",
      port: 8545,
      network_id: 15,
      websockets: true,
      provider: () => new HDWalletProvider(privateKey, "http://127.0.0.1:8545"),
    },
    eth1: {
      host: "127.0.0.1",
      port: 8645,
      network_id: 16,
      websockets: true,
      provider: () => new HDWalletProvider(privateKey, "http://127.0.0.1:8645"),
    },
  },
  compilers: {
    solc: {
      version: "0.8.12",
      settings: {
        optimizer: {
          enabled: true,
          runs: 1000,
        },
      },
    },
  },
};
