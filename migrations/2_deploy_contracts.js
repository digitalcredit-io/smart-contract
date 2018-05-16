var SafeMath = artifacts.require("./SafeMath.sol");
var DGCT = artifacts.require("./DGCT.sol");
var Crowdsale = artifacts.require("./Crowdsale.sol");


module.exports = function(deployer) {
	
	var owner = web3.eth.accounts[0];
	var pre_wallet = web3.eth.accounts[1];
	var main_wallet = web3.eth.accounts[2];

	console.log("Owner address: " + owner);	
	console.log("Pre ICO wallet address: " + pre_wallet);	
	console.log("Main ICO wallet address: " + main_wallet);	

	deployer.deploy(SafeMath, { from: owner });
	deployer.link(SafeMath, DGCT);
	return deployer.deploy(DGCT, { from: owner }).then(function() {
		console.log("DGCT address: " + DGCT.address);
		return deployer.deploy(Crowdsale,{ from: owner }).then(function() {
			console.log("Crowdsale address: " + Crowdsale.address);
			return Crowdsale.deployed().then(function(crowdsale){
				crowdsale.setDGCTAddress(DGCT.address, {from: owner});
				crowdsale.setMultisigPre(pre_wallet, {from: owner});
				crowdsale.setMultisigMain(main_wallet, {from: owner});	
			}).then(function(){
				return DGCT.deployed().then(function(coin) {
					return coin.owner.call().then(function(owner) {
						console.log("DGCT owner : " + owner);
						return coin.transferOwnership(Crowdsale.address, {from: owner}).then(function(txn) {
							console.log("DGCT owner was changed: " + Crowdsale.address);		
						});
					})
				});
			})

		});
	});
};