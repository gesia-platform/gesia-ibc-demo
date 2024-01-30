const CarbonEmissionsHeatingCalculator = artifacts.require(
  "CarbonEmissionsHeatingCalculator"
);
const CarbonNeutralApplication = artifacts.require("CarbonNeutralApplication");
const CarbonNeutralPool = artifacts.require("CarbonNeutralPool");
const CarbonNeutral = artifacts.require("CarbonNeutral");

const APPLICATION_ID = 2;
const PROJECT_ID = 1;

contract("CarbonNeutralPool", function () {
  it("", async function () {
    const instance = await CarbonNeutralPool.deployed();

    const carbonNeutralOffset = await CarbonNeutral.at(await instance.offset());

    const events = await carbonNeutralOffset.getPastEvents("TransferSingle", {
      fromBlock: 0,
      toBlock: "latest",
    });

    console.log("neutral transfer event values: ", events[0].returnValues);

    assert.equal(
      events[0].returnValues.id,
      APPLICATION_ID.toString(),
      "minted application must be 2 not projectId 1"
    );

    assert.equal(events.length, 1, "transfer event must grather than 0.");
  });
});
