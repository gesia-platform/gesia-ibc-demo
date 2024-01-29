const CarbonEmissions = artifacts.require("CarbonEmissions");
const CarbonNeutralApplication = artifacts.require("CarbonNeutralApplication");

module.exports = async (callback) => {
  const accounts = await web3.eth.getAccounts();
  const account = accounts[0];
  console.log("account:", account);

  const carbonNeutralApplication = await CarbonNeutralApplication.deployed();
  const carbonEmissions = await CarbonEmissions.deployed();
  const escrowAddress = await carbonNeutralApplication.getEscrowAddress();

  console.log("carbonNeutralApplication: ", carbonNeutralApplication.address);
  console.log("escrow: ", escrowAddress);

  const events = await carbonEmissions.getPastEvents("TransferSingle", {
    fromBlock: 0,
    toBlock: "latest",
  });

  console.log(
    "TransferSingle events: ",
    events.map((x) => ({ from: x.returnValues.from, to: x.returnValues.to }))
  );

  const toAddresses = new Set([...events.map((x) => x.returnValues.to)]);

  for await (let address of toAddresses) {
    console.log(
      "carbonEmissions balance of " +
        address +
        ": " +
        (await carbonEmissions.balanceOf(address, 1))
    );
  }

  callback();
};
