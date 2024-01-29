const CarbonOffset = artifacts.require("CarbonOffset");

module.exports = async (callback) => {
  const accounts = await web3.eth.getAccounts();
  const account = accounts[0];
  console.log("account:", account);

  const channel = "channel-0";
  const port = "offset";
  const applicationId = 1;
  const amount = 100;

  const carbonOffset = await CarbonOffset.deployed();

  const mintResult = await carbonOffset.mint(account, applicationId, amount);
  console.log(mintResult, "minted");

  const donateResult = await carbonOffset.donate(
    applicationId,
    amount,
    port,

    channel
  );
  console.log(donateResult, "donated");

  callback();
};
