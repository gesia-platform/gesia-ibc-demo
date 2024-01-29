const HDWalletProvider = require("@truffle/hdwallet-provider");

module.exports = {
  contracts_directory: "./contracts",
  contracts_build_directory: "./build/contracts",
  migrations_directory: "./migrations",

  networks: {
    neutral: {
      network_id: "*",
      provider: () =>
        new HDWalletProvider({
          mnemonic: {
            phrase:
              "worth winter festival wealth place advance raise salute fever retire process announce",
          },
          providerOrUrl: "http://127.0.0.1:8545",
          addressIndex: 0,
          numberOfAddresses: 10,
        }),
    },
    emissions: {
      network_id: "*",
      provider: () =>
        new HDWalletProvider({
          mnemonic: {
            phrase:
              "math razor capable expose worth grape metal sunset metal sudden usage scheme",
          },
          providerOrUrl: "http://127.0.0.1:8645",
          addressIndex: 0,
          numberOfAddresses: 10,
        }),
    },
    offset: {
      network_id: "*",
      provider: () =>
        new HDWalletProvider({
          mnemonic: {
            phrase:
              "sign addict identify chunk urban captain leg curious purpose treat cheap pave",
          },
          providerOrUrl: "http://127.0.0.1:8745",
          addressIndex: 0,
          numberOfAddresses: 10,
        }),
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
