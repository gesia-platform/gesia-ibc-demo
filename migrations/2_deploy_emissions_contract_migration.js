const IBCClient = artifacts.require("IBCClient");
const IBCConnectionSelfStateNoValidation = artifacts.require(
  "IBCConnectionSelfStateNoValidation"
);
const IBCChannelHandshake = artifacts.require("IBCChannelHandshake");
const IBCHandler = artifacts.require("OwnableIBCHandler");
const IBCChannelPacketSendRecv = artifacts.require(
  "IBCChannelPacketSendRecv.sol"
);
const IBCChannelPacketTimeout = artifacts.require(
  "IBCChannelPacketTimeout.sol"
);
const MockClient = artifacts.require("MockClient.sol");

const CarbonNeutralApplication = artifacts.require(
  "CarbonNeutralApplication.sol"
);

const CarbonEmissionsHeatingCalculator = artifacts.require(
  "CarbonEmissionsHeatingCalculator.sol"
);

const CarbonEmissions = artifacts.require("CarbonEmissions.sol");

const PortEmisionsToNeutral = "emissions";
const MockClientType = "mock-client";
const EmptyAddress = "0x0000000000000000000000000000000000000000";

const TokenName = "Heating Carbon Footprint Calculator";
const TokenSymbol = "HEATING";

const deployIBCCore = async (deployer) => {
  await deployer.deploy(IBCClient);
  await deployer.deploy(IBCChannelPacketTimeout);
  await deployer.deploy(IBCConnectionSelfStateNoValidation);
  await deployer.deploy(IBCChannelHandshake);
  await deployer.deploy(IBCChannelPacketSendRecv);

  await deployer.deploy(
    IBCHandler,
    IBCClient.address,
    IBCConnectionSelfStateNoValidation.address,
    IBCChannelHandshake.address,
    IBCChannelPacketSendRecv.address,
    IBCChannelPacketTimeout.address
  );

  await deployer.deploy(MockClient, IBCHandler.address);
};

const deployApp = async (deployer) => {
  await deployer.deploy(
    CarbonNeutralApplication,
    IBCHandler.address,
    EmptyAddress
  );

  await deployer.deploy(CarbonEmissionsHeatingCalculator);

  await deployer.deploy(
    CarbonEmissions,
    TokenName,
    TokenSymbol,
    CarbonEmissionsHeatingCalculator.address,
    CarbonNeutralApplication.address
  );
};

const setupIBC = async () => {
  const ibcHandler = await IBCHandler.deployed();

  await ibcHandler.bindPort(PortEmisionsToNeutral, CarbonNeutralApplication.address);

  await ibcHandler.registerClient(MockClientType, MockClient.address);
};

module.exports = async function (deployer, _) {
  await deployIBCCore(deployer);
  await deployApp(deployer);
  await setupIBC();
};
