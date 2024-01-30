const CarbonEmissionsHeatingCalculator = artifacts.require(
  "CarbonEmissionsHeatingCalculator"
);
const CarbonEmissions = artifacts.require("CarbonEmissions");

const IBC_CHANNEL = "channel-0";
const APPLICATION_ID = 1;

module.exports = async (callback) => {
  const carbonEmissionsHeatingCalculator =
    await CarbonEmissionsHeatingCalculator.deployed();

  let heatingAmount = 15;

  const result = await carbonEmissionsHeatingCalculator.calculate(
    heatingAmount,
    APPLICATION_ID,
    CarbonEmissions.address,
    IBC_CHANNEL
  );

  console.log(result, "caculated");

  callback();
};
