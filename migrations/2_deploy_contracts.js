const EducationToken = artifacts.require("EducationToken");

module.exports = function(deployer, network, accounts) {
  let totalSupplyReceiver;

  if (network === "development") {
    totalSupplyReceiver = accounts[0];
  } else if (network === "ropsten" || network === "ropsten-fork") {
    totalSupplyReceiver = "0xA510c72570561E036895d827BF74b5b22d3235B4";
  } else if (network === "mainnet" || network === "mainnet-fork") {
    totalSupplyReceiver = "0xAb012ed9C8Dd6C955e3652c746888F0FDD686273";
  }

  return deployer.deploy(EducationToken, totalSupplyReceiver).then(() => {
    console.log(`Address of the Education Token: ${EducationToken.address}`)
  });

}

