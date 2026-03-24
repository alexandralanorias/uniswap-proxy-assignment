require("@nomicfoundation/hardhat-toolbox");
require("@matterlabs/hardhat-zksync-deploy");
require("@matterlabs/hardhat-zksync-solc");
require("@matterlabs/hardhat-zksync-verify");
require("@openzeppelin/hardhat-upgrades");
require("dotenv").config();

module.exports = {
  solidity: "0.8.28",

  zksolc: {
    version: "1.5.13",
    compilerSource: "binary",
    settings: {
      optimizer: { enabled: true, runs: 200 },
      codegen: "evmla",
    },
  },

  networks: {
    zkSyncTestnet: {
      url: "https://sepolia.era.zksync.dev",
      ethNetwork: "sepolia",
      zksync: true,
      accounts: [process.env.ZKSYNC_TESTNET_KEY],
    },
  },
};