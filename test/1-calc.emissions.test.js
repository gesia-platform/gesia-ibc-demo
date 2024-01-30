const CarbonEmissionsHeatingCalculator = artifacts.require(
  "CarbonEmissionsHeatingCalculator"
);
const CarbonEmissions = artifacts.require("CarbonEmissions");
const CarbonNeutralApplication = artifacts.require("CarbonNeutralApplication");

const APPLICATION_ID = 1;

contract("CarbonEmissions", function () {
  it("", async function () {
    const instance = await CarbonEmissions.deployed();

    const accounts = await web3.eth.getAccounts();

    const resultAccount = await instance.balanceOf(accounts[0], APPLICATION_ID);

    const resultApplication = await instance.balanceOf(
      CarbonNeutralApplication.address,
      APPLICATION_ID
    );

    console.log("result account:", resultAccount);
    console.log("result application:", resultApplication);

    assert.equal(resultAccount, 0, "user account must not own token.");

    assert.notEqual(
      resultApplication,
      0,
      "application account must own token."
    );
  });
});
