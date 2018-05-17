pragma solidity 0.4.23;

import "./DigitalCreditToken.sol";
import "./DigitalCreditTokenVesting.sol";
import "./SafeMath.sol";
import "./Ownable.sol";
import "./ERC20.sol";


contract ICO is Ownable {
    using SafeMath for uint256;
	
	/*
	* Constants
	*/
	/* Minimum amount to invest */
	uint public constant MIN_INVEST_ETHER = 100 finney;
	
	/* Maximum Token Supply 10,000,000,000 DGCT, will not be changed*/
	uint256 public constant TOTAL_TOKEN_SUPPLY = 1000000000 * (10 ** 18);

	/*
	* Variables
	*/
	/* Remaining Token Supply, will be 10,000,000,000 from the beginning, will be changed during token sales.*/
	uint256 public remainingTokenSupply = TOTAL_TOKEN_SUPPLY; 

	//whitelist
    mapping(address => bool) public whitelist;

    DigitalCreditToken public token;
    address public wallet; // Address where funds are collected
    uint256 public rate;   // How many token units a buyer gets per eth
    uint256 public initialTime;
	uint256 public endTime;
    bool public saleClosed;
    uint256 public weiCap;
    uint256 public weiRaised;    

    event BuyTokens(uint256 weiAmount, uint256 rate, uint256 token, address beneficiary);

    /**
    * @dev constructor
    */
    constructor(address _wallet, uint256 _rate, uint256 _startDate, uint256 _endDate, uint256 _weiCap) public {
        require(_rate > 0);
        require(_wallet != address(0));
        require(_weiCap.mul(_rate) <= remainingTokenSupply);

        wallet = _wallet;
        rate = _rate;
        initialTime = _startDate;
		endTime = _endDate;
        saleClosed = false;
        weiCap = _weiCap;
        weiRaised = 0;

        token = new DigitalCreditToken();
    }

    /**
     * @dev fallback function ***DO NOT OVERRIDE***
     */
    function() external payable {
        buyTokens();
    }
	
    /**
     * @dev Adds single address to whitelist.
     * @param _beneficiary Address to be added to the whitelist
     */
    function addToWhitelist(address _beneficiary) external onlyOwner {
      whitelist[_beneficiary] = true;
    }

    /**
     * @dev Adds list of addresses to whitelist. Not overloaded due to limitations with truffle testing.
     * @param _beneficiaries Addresses to be added to the whitelist
     */
    function addManyToWhitelist(address[] _beneficiaries) external onlyOwner {
      for (uint256 i = 0; i < _beneficiaries.length; i++) {
        whitelist[_beneficiaries[i]] = true;
      }
    }

    /**
     * @dev Removes single address from whitelist.
     * @param _beneficiary Address to be removed to the whitelist
     */
    function removeFromWhitelist(address _beneficiary) external onlyOwner {
      whitelist[_beneficiary] = false;
    }

    /**
     * @dev buy tokens
     */
    function buyTokens() public payable {		
        validatePurchase(msg.value);
		require(msg.value >= MIN_INVEST_ETHER);
        uint256 tokenToBuy = msg.value.mul(rate);
        
        weiRaised = weiRaised.add(msg.value);
        token.mint(msg.sender, tokenToBuy);
        wallet.transfer(msg.value);
        emit BuyTokens(msg.value, rate, tokenToBuy, msg.sender);
    }

    /**
     * @dev mint token to new address, either contract or a wallet
     * param DigitalCreditTokenVesting vesting contract
     * param uint256 total token number to mint
    */
    function mintToken(address target, uint256 tokenToMint) public onlyOwner {
      token.mint(target, tokenToMint);
    }

    /**
     * @dev close the ICO
     */
    function closeSale() public onlyOwner {
        saleClosed = true;
		remainingTokenSupply = remainingTokenSupply.sub(token.totalSupply());
        token.mint(owner, remainingTokenSupply);        
    }

	/**
     * @dev stop Minting(token cannot be mint anymore)
     */
    function stopMinting() public onlyOwner {
        token.finishMinting();
        token.transferOwnership(owner);
    }
	
    function validatePurchase(uint256 weiPaid) internal view{
        require(!saleClosed);
        require(now >= initialTime && now < endTime);
        require(whiteList[msg.sender]);
        require(weiPaid <= weiCap.sub(weiRaised));        
    }
}
