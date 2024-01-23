const CarbonOffsetVoucher = artifacts.require("CarbonOffsetVoucher");

module.exports = async (callback) => {
  try {
    const accounts = await web3.eth.getAccounts();
    const account = accounts[0];

    const miniToken = await CarbonOffsetVoucher.deployed();

    const result = await miniToken.sendTransfer(
      account,
      1,
      1_000,
      account,
      "transfer",
      "channel-0",
      {
        from: account,
      }
    );

    console.log(result);
  } catch (error) {
    console.error(error);
  }

  callback();
};
