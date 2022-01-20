require('dotenv').config();
const NonceTrackerSubprovider = require("web3-provider-engine/subproviders/nonce-tracker")
const fs = require('fs');
const mnemonic = fs.readFileSync(".secret").toString().trim();

const HDWalletProvider = require("truffle-hdwallet-provider");
module.exports = {
  networks: {
    development: {
      host: "localhost",
      port: 8545,
      network_id: "*", // Match any network id
      gas: 5000000
    },
    mainnet: {
      provider: () => {
        let wallet = new HDWalletProvider(process.env.PRIVATE_KEY, process.env.MAINNET_ENDPOINT)
        var nonceTracker = new NonceTrackerSubprovider()
        wallet.engine._providers.unshift(nonceTracker)
        nonceTracker.setEngine(wallet.engine)
        return wallet
      },
      network_id: '1', // Match any network id
      gasPrice: 50000000000, // 10 gwei
      skipDryRun: false
    },
    ropsten: {
      provider:()=> new HDWalletProvider(mnemonic, `https://ropsten.infura.io/v3/9aa3d95b3bc440fa88ea12eaa4456161`),
      network_id: '3', // Match any network id
      gas: 4500000,
      gasPrice: 150000000000,
      skipDryRun: true
    },
  },
  compilers: {
    solc: {
      version: "0.6.2", // A version or constraint - Ex. "^0.5.0"
      docker: false, // Use a version obtained through docker
      parser: "solcjs",
      settings: {
        optimizer: {
          enabled: true, // Default: false
          runs: 200      // Default: 200
        },
      }
    }
  }
};