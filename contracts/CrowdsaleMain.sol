pragma solidity ^0.4.16;


import "./Ownable.sol";
import "./DGCT.sol";


contract CrowdsaleMain is Ownable{
    
    using SafeMath for uint;

  	struct Backer {
		uint weiReceived; 
		uint coinSent;
		uint coinReadyToSend;
	}

	/*
	* Constants
	*/

	/**
    * ICO Phases.
    *
    * - PreStart: 	tokens are not yet sold/issued
    * - MainIco   	new tokens sold/issued at the regular price
    * - AfterIco: 	tokens are not sold/issued
    */
    enum Phases {PreStart,  MainIco, AfterIco}

	/* Maximum number of DGCT to main ico sell */
	uint public constant MAIN_MAX_CAP = 1000000000 * 10**18; // 1,000,000,000 DGCT

	/* Minimum amount to invest */
	uint public constant MIN_INVEST_ETHER = 100 finney;

	/* Number of DGCT per Ether */
	uint public constant MAIN_COIN_PER_ETHER_ICO = 10000 * 10**18; // 10,000 DGCT

	/*
	* Variables
	*/

	/* Crowdsale period */
	uint private mainStartTime = 1534298400;	// 2018-08-15 10:00 AM (GMT + 08:00)
	uint private mainEndTime = 1536976800;		// 2018-09-15 10:00 AM (GMT + 08:00)

	/* DGCT contract reference */
	DGCT public coin;

	/*Maximum Ether for one address during pre ico or main ico */
	uint public maximumCoinsPerAddress = 200 ether;
    
	/* Multisig contract that will receive the Ether during main ico*/
	address public mainMultisigEther;
	/* Number of Ether received during main ico */
	uint public mainEtherReceived;
	/* Number of DGCT sent to Ether contributors during main ico */
	uint public mainCoinSentToEther;

	/* Backers Ether indexed by their Ethereum address */
	mapping(address => Backer) public mainBackers;
	address[] internal mainReadyToSendAddress;

	/* White List */
	mapping(address => bool) public whiteList;
	address private whiteListOwner;

    /* Current Phase */
    Phases public phase = Phases.PreStart;

	/*
	* Modifiers
	*/

	modifier respectTimeFrame() {
		require((now >= mainStartTime) && (now < mainEndTime ));
		_;
	}

	/*
	 * Event
	*/
	event LogReceivedETH(address addr, uint value);
	event LogCoinsEmited(address indexed from, uint amount);

	/*
	 * Constructor
	*/
	function CrowdsaleMain() public{
		whiteListOwner = msg.sender;
	}

	/**
	*	Allow to set DGCT address
	*/
	function setDGCTAddress(address _addr) onlyOwner public {
		require(_addr != address(0));
		coin = DGCT(_addr);
	}

	/**
	*	Allow owner to set whiteListOwner
	*/
	function setWhiteListOwner(address _addr) onlyOwner public {
		whiteListOwner = _addr;

	}

	/**
	* Check addressExistInWhiteList
	*/ 
	function isExistInWhiteList(address _addr) public view returns (bool) {
		return whiteList[_addr];
	}

	/**
	* change main start time by owner
	*/
	function changeMainStartTime(uint _timestamp) onlyOwner public {

		mainStartTime = _timestamp;
	}

	/**
	* change main stop time by owner
	*/
	function changeMainEndTime(uint _timestamp) onlyOwner public {
		mainEndTime = _timestamp;

	}

	/**
	 * Allow to change the team multisig address in the case of emergency.
	 */
	function setMultisigMain(address _addr) onlyOwner public {
		require(_addr != address(0));
		mainMultisigEther = _addr;
	}

	/**
	*	Allow to change the maximum Coin one address can buy during the ico
	*/
	function setMaximumCoinsPerAddress(uint _cnt) onlyOwner public{
		maximumCoinsPerAddress = _cnt;
	}

	/* 
	 * The fallback function corresponds to a donation in ETH
	 */
	function() respectTimeFrame  payable public{
		require(whiteList[msg.sender]);
		receiveETH(msg.sender);
	}

	/*
	 *	Receives a donation in Ether
	*/
	function receiveETH(address _beneficiary) internal {
		require(msg.value >= MIN_INVEST_ETHER) ; 
		adjustPhaseBasedOnTime();
		uint coinToSend ;

		if (phase == Phases.MainIco){
			Backer storage mainBacker = mainBackers[_beneficiary];
			require(mainBacker.weiReceived.add(msg.value) <= maximumCoinsPerAddress);

			coinToSend = msg.value.mul(MAIN_COIN_PER_ETHER_ICO).div(1 ether); 	
			require(coinToSend.add(mainCoinSentToEther) <= MAIN_MAX_CAP) ;

			mainBacker.coinSent = mainBacker.coinSent.add(coinToSend);
			mainBacker.weiReceived = mainBacker.weiReceived.add(msg.value);   
			mainBacker.coinReadyToSend = mainBacker.coinReadyToSend.add(coinToSend);
			mainReadyToSendAddress.push(_beneficiary);

			// Update the total wei collected during the crowdfunding
			mainEtherReceived = mainEtherReceived.add(msg.value); 
			mainCoinSentToEther = mainCoinSentToEther.add(coinToSend);

			// Send events
			LogReceivedETH(_beneficiary, mainEtherReceived); 
		}
	}

	/*
	*	Adjust phase base on time
	*/
    function adjustPhaseBasedOnTime() internal {

        if (now < mainStartTime ) {
            if (phase != Phases.PreStart) {
                phase = Phases.PreStart;
            }
        } else if (now >= mainStartTime && now < mainEndTime) {
            if (phase != Phases.MainIco) {
                phase = Phases.MainIco;
            }
        }else {
        	if (phase != Phases.AfterIco){
        		phase = Phases.AfterIco;
        	}
        }
    }
	

	/*
	*	Durign the main ico, should be called by owner to send DGCT to beneficiary address
	*/
	function mainSendDGCT() onlyOwner public{
		for(uint i=0; i < mainReadyToSendAddress.length ; i++){
			address backerAddress = mainReadyToSendAddress[i];
			uint coinReadyToSend = mainBackers[backerAddress].coinReadyToSend;
			if ( coinReadyToSend > 0) {
				mainBackers[backerAddress].coinReadyToSend = 0;
				coin.transfer(backerAddress, coinReadyToSend);
				LogCoinsEmited(backerAddress, coinReadyToSend);
			}
		}
		delete mainReadyToSendAddress;
		require(mainMultisigEther.send(this.balance)) ; 

	}

	/*
	*  White list, only address in white list can buy DGCT
	*/
	function addWhiteList(address[] _whiteList) public {
		require(msg.sender == whiteListOwner);
		for (uint i =0;i<_whiteList.length;i++){
			whiteList[_whiteList[i]] = true;
		}	
	}
	/**
	*	Remove address from whiteList by whiteListOwner
	*/
	function removeWhiteList(address[] _whiteList) public {
		require(msg.sender == whiteListOwner);
		for (uint i =0;i<_whiteList.length;i++){
			whiteList[_whiteList[i]] = false;
		}
	}

	/*	
	 * Finalize the crowdsale, should be called after the refund period
	*/
	function finalize() onlyOwner public {
		adjustPhaseBasedOnTime();
		require(phase == Phases.AfterIco);
		require(this.balance > 0);
		require(mainMultisigEther.send(this.balance)) ; 
		uint remains = coin.balanceOf(this);
		if (remains > 0) { 
			coin.transfer(owner,remains);
		}
	}

	/**
	 * Manually back DGCT owner address.
	 */
	function backDGCTOwner() onlyOwner public {
		coin.transferOwnership(owner);
	}

	/**
	 * Transfer remains to owner in case if impossible to do min invest
	 */
	function getMainRemainCoins() onlyOwner public {
		uint mainRemains = MAIN_MAX_CAP - mainCoinSentToEther;
		Backer storage backer = mainBackers[owner];
		coin.transfer(owner, mainRemains); 
		backer.coinSent = backer.coinSent.add(mainRemains);
		mainCoinSentToEther = mainCoinSentToEther.add(mainRemains);

		LogCoinsEmited(this ,mainRemains);
		LogReceivedETH(owner, mainEtherReceived); 
	}

	/**
	*	Refund to specific address 
	*/
	function refund(address _beneficiary) onlyOwner public {
		uint valueToSend = 0;
		Backer storage mainBacker = mainBackers[_beneficiary];
		if (mainBacker.coinReadyToSend > 0){ 
			uint mainValueToSend = mainBacker.coinReadyToSend.mul(1 ether).div(MAIN_COIN_PER_ETHER_ICO);
			mainBacker.coinSent = mainBacker.coinSent.sub(mainBacker.coinReadyToSend);
			mainBacker.weiReceived = mainBacker.weiReceived.sub(mainValueToSend);   
			mainEtherReceived = mainEtherReceived.sub(mainValueToSend); 
			mainCoinSentToEther = mainCoinSentToEther.sub(mainBacker.coinReadyToSend);
			mainBacker.coinReadyToSend = 0;
			valueToSend = valueToSend + mainValueToSend;

		}
		if (valueToSend > 0){
			require(_beneficiary.send(valueToSend));
		}
		
	}


	/**
	*	Refund to all address
	*/	
	function refundAll() onlyOwner public {
		
		for(uint j=0; j < mainReadyToSendAddress.length ; j++){
			refund(mainReadyToSendAddress[j]);

		}

		delete mainReadyToSendAddress;

	}
	

}