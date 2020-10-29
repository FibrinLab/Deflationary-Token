const SPAMToken = artifacts.require("SPAMToken");

module.exports = function(deployer, network, accounts) {
  let totalSupplyReceiver;

  if (network === "development") {
    totalSupplyReceiver = accounts[0];
  } else if (network === "kovan" || network === "kovan-fork") {
    totalSupplyReceiver = "0x8213Fb521A39daFf48e0c6cEA19DA6458dA1264e";
  } else if (network === "mainnet" || network === "mainnet-fork") {
    totalSupplyReceiver = "0xAb012ed9C8Dd6C955e3652c746888F0FDD686273";
  }

  return deployer.deploy(SPAMToken, totalSupplyReceiver).then(() => {
    console.log(`Address of the SPAM Token: ${SPAMToken.address}`)
  });

}

