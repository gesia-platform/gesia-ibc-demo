const CarbonEmissionsHeatingCalculator = artifacts.require(
  "CarbonEmissionsHeatingCalculator"
);
const CarbonEmissions = artifacts.require("CarbonEmissions");

module.exports = async (callback) => {
  const accounts = await web3.eth.getAccounts();
  const account = accounts[0];
  console.log("account:", account);

  const carbonEmissionsHeatingCalculator =
    await CarbonEmissionsHeatingCalculator.deployed();

  const channel = "channel-1";
  const port = "emissions";
  
  const applicationId = 1;
  const amount = 100;

  const result = await carbonEmissionsHeatingCalculator.calculate(
    amount,
    applicationId,
    CarbonEmissions.address,
    port,
    channel
  );

  console.log(result, "caculated");

  callback();
};
