const CarbonOffset = artifacts.require("CarbonOffset");
const CarbonNeutralApplication = artifacts.require("CarbonNeutralApplication");

module.exports = async (callback) => {
  const carbonOffset = await CarbonOffset.deployed();
  
  const carbonNeutralApplication = await CarbonNeutralApplication.deployed();
  const escrowAddress = await carbonNeutralApplication.getEscrowAddress();

  console.log("carbonNeutralApplication: ", carbonNeutralApplication.address);
  console.log("escrow: ",escrowAddress);

  const events = await carbonOffset.getPastEvents("TransferSingle", {
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
      "carbonOffset balance of " +
        address +
        ": " +
        (await carbonOffset.balanceOf(address, 1))
    );
  }

  callback();
};
