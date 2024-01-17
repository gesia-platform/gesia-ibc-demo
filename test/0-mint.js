const CarbonOffsetVoucher = artifacts.require("CarbonOffsetVoucher");

module.exports = async (callback) => {
  const accounts = await web3.eth.getAccounts();
  console.log("accounts:", accounts);
  const account = accounts[0];
  console.log("account:", account);

  const mintId = 1;
  const mintAmount = 10_000;

  console.log("minted info:", mintId, mintAmount);

  const carbonOffsetVoucher = await CarbonOffsetVoucher.deployed();
  const block = await web3.eth.getBlockNumber();
  console.log("tx executed block number:", block);
  await carbonOffsetVoucher.mint(account, mintId, mintAmount);
  const mintEvent = await carbonOffsetVoucher.getPastEvents("TransferSingle", {
    fromBlock: block,
  });
  console.log(mintEvent);

  callback();
};
