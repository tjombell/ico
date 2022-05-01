const ICO = artifacts.require("./contracts/ICO.sol");

module.exports = function(deployer) {
  deployer.deploy(ICO);
};