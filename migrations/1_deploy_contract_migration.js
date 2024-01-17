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
  await deployer.deploy(IBCClient);
  console.log("deployed IBCClient");
  await deployer.deploy(IBCConnectionSelfStateNoValidation);
  console.log("deployed IBCConnectionSelfStateNoValidation");
  await deployer.deploy(IBCChannelHandshake);
  console.log("deployed IBCChannelHandshake");
  await deployer.deploy(IBCChannelPacketSendRecv);
  console.log("deployed IBCChannelPacketSendRecv");
  await deployer.deploy(IBCChannelPacketTimeout);
  console.log("deployed IBCChannelPacketTimeout");

  await deployer.deploy(
    IBCHandler,
    IBCClient.address,
    IBCConnectionSelfStateNoValidation.address,
    IBCChannelHandshake.address,
    IBCChannelPacketSendRecv.address,
    IBCChannelPacketTimeout.address
  );
  console.log("deployed IBCHandler");

  await deployer.deploy(MockClient, IBCHandler.address);
  console.log("deployed MockClient");
};

const deployApp = async (deployer) => {
  await deployer.deploy(CarbonOffsetVoucher, IBCHandler.address);
  console.log("deployed CarbonOffsetVoucher");
};

const init = async (deployer) => {
  const ibcHandler = await IBCHandler.deployed();

  for (const promise of [
    () => ibcHandler.bindPort(PortTransfer, CarbonOffsetVoucher.address),
    () => ibcHandler.registerClient(MockClientType, MockClient.address),
  ]) {
    const result = await promise();
    if (!result.receipt.status) {
      throw new Error(`transaction failed to execute. ${result.tx}`);
    } else {
      console.log("binded");
    }
  }
};

module.exports = async function (deployer, network) {
  await deployCore(deployer);
  await deployApp(deployer);
  await init(deployer);

  console.log(`${network} ibc_address:`, IBCHandler.address);
};
