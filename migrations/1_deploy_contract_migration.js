const CarbonOffsetVoucher = artifacts.require("CarbonOffsetVoucher");
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

const PortTransfer = "transfer";
const MockClientType = "mock-client";

const deployCore = async (deployer) => {
  await deployer.deploy(IBCChannelPacketTimeout);
  await deployer.deploy(IBCClient);
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
  await deployer.deploy(CarbonOffsetVoucher, IBCHandler.address);
};

const bind = async (deployer) => {
  const ibcHandler = await IBCHandler.deployed();

  await ibcHandler.bindPort(PortTransfer, CarbonOffsetVoucher.address);
  console.log("binded port: ", PortTransfer);

  await ibcHandler.registerClient(MockClientType, MockClient.address);

  console.log("registered client: ", MockClientType, MockClient.address);
};

module.exports = async function (deployer, network) {
  await deployCore(deployer);
  await deployApp(deployer);
  await bind(deployer);

  console.log(`${network} ibc_address:`, IBCHandler.address);
};
