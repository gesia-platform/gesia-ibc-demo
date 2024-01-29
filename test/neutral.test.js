const CarbonNeutralToken = artifacts.require("CarbonNeutralToken");
const CarbonNeutralPool = artifacts.require("CarbonNeutralPool");

module.exports = async (callback) => {
  const carbonNeutralPool = await CarbonNeutralPool.deployed();

  const carbonNeutralTokenEmissions = await CarbonNeutralToken.at(
    await carbonNeutralPool.emissionsToken()
  );

  const carbonNeutralTokenOffset = await CarbonNeutralToken.at(
    await carbonNeutralPool.offsetToken()
  );

  const emissionsEvent = await carbonNeutralTokenEmissions.getPastEvents(
    "TransferSingle",
    {
      fromBlock: 0,
      toBlock: "latest",
    }
  );

  const offsetEvents = await carbonNeutralTokenOffset.getPastEvents(
    "TransferSingle",
    {
      fromBlock: 0,
      toBlock: "latest",
    }
  );

  console.log(
    "TransferSingle emissionsEvent: ",
    emissionsEvent.map((x) => ({
      from: x.returnValues.from,
      to: x.returnValues.to,
    }))
  );

  console.log(
    "TransferSingle offsetEvents: ",
    offsetEvents.map((x) => ({
      from: x.returnValues.from,
      to: x.returnValues.to,
    }))
  );

  const toAddresses = new Set([
    ...emissionsEvent.map((x) => x.returnValues.to),
    ...offsetEvents.map((x) => x.returnValues.to),
  ]);

  for await (let address of toAddresses) {
    console.log(
      "carbonNeutralTokenEmissions balance of " +
        address +
        " (account): " +
        (await carbonNeutralTokenEmissions.balanceOf(address, 1))
    );

    console.log(
      "carbonNeutralTokenOffset balance of " +
        address +
        " (account): " +
        (await carbonNeutralTokenOffset.balanceOf(address, 1))
    );
  }

  callback();
};
