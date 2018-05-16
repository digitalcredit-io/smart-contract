var SafeMath = artifacts.require("./SafeMath.sol");
var DGCT = artifacts.require("./DGCT.sol");
var CrowdsaleMain = artifacts.require("./CrowdsaleMain.sol");


module.exports = function(deployer) {
	
	var owner = web3.eth.accounts[0];
	var main_wallet = web3.eth.accounts[2];

	console.log("Owner address: " + owner);	
	console.log("Main ICO wallet address: " + main_wallet);	

	deployer.deploy(SafeMath, { from: owner });
	deployer.link(SafeMath, DGCT);
	return deployer.deploy(DGCT, { from: owner }).then(function() {
		console.log("DGCT address: " + DGCT.address);
		return deployer.deploy(CrowdsaleMain,{ from: owner }).then(function() {
			console.log("Crowdsale address: " + CrowdsaleMain.address);
			return CrowdsaleMain.deployed().then(function(crowdsale){
				crowdsale.setDGCTAddress(DGCT.address, {from: owner});
				crowdsale.setMultisigMain(main_wallet, {from: owner});	
			}).then(function(){
				return DGCT.deployed().then(function(coin) {
					return coin.owner.call().then(function(owner) {
						console.log("DGCT owner : " + owner);
						return coin.transferOwnership(CrowdsaleMain.address, {from: owner}).then(function(txn) {
							console.log("DGCT owner was changed: " + CrowdsaleMain.address);		
						});
					})
				});
			})

		});
	});
};