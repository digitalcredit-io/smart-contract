pragma solidity ^0.4.16;

import "./StandardToken.sol";
import "./Ownable.sol";


/**
 *  DGCT token contract. Implements
 */
contract DGCT is StandardToken, Ownable {
  string public constant name = "Digital Credit";
  string public constant symbol = "DGCT";
  uint public constant decimals = 18;


  // Constructor
  function DGCT() public {
      totalSupply = 10000000000 * 10**18;
      balances[msg.sender] = totalSupply; // Send all tokens to owner
  }

  /**
   *  Burn away the specified amount of SkinCoin tokens
   */
  function burn(uint _value) onlyOwner public returns (bool) {
    balances[msg.sender] = balances[msg.sender].sub(_value);
    totalSupply = totalSupply.sub(_value);
    Transfer(msg.sender, 0x0, _value);
    return true;
  }

}






