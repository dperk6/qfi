const Staking = artifacts.require("QPoolStakingFactory.sol")

module.exports = function (deployer) {
    deployer.deploy(Staking, "0x167e796Ce55ac660cb45671a1358c60e6a4e00b4", 1606186697);
}