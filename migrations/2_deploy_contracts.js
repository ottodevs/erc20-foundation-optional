var Erc20Found = artifacts.require("./Erc20Found.sol");

module.exports = function(deployer) {
  deployer.deploy(Erc20Found);
};
