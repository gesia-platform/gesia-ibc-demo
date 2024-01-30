const CarbonOffset = artifacts.require("CarbonOffset");

const IBC_CHANNEL = "channel-0";
const APPLICATION_ID = 2;
const PROJECT_ID = 1;

module.exports = async (callback) => {
  const carbonOffset = await CarbonOffset.deployed();

  const accounts = await web3.eth.getAccounts();
  const account = accounts[0];

  const mintResult = await carbonOffset.mint(account, PROJECT_ID, 10_000);

  console.log("mint result: ", mintResult);

  const donateResult = await carbonOffset.donate(
    PROJECT_ID,
    10_000,
    APPLICATION_ID,
    IBC_CHANNEL
  );

  console.log("donate result: ", donateResult);

  callback();
};
