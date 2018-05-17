pragma solidity 0.4.23;

import "./SafeMath.sol";
import "./MintableToken.sol";


/**
* @title Digital Credit Token
* @dev this is the Digital Credit token
*/
contract DigitalCreditToken is MintableToken {
    using SafeMath for uint256;

    string public name = "Digital Credit";
    string public symbol = "DGCT";
    uint8 public decimals = 18;
    bool public active = false;
    /**
     * @dev restrict function to be callable when token is active
     */
    modifier activated() {
        require(active == true);
        _;
    }

    /**
     * @dev activate token transfers
     */
    function activate() public onlyOwner {
        active = true;
    }

    /**
     * @dev transfer    ERC20 standard transfer wrapped with `activated` modifier
     */
    function transfer(address to, uint256 value) public activated returns (bool) {
        return super.transfer(to, value);
    }

    /**
     * @dev transfer    ERC20 standard transferFrom wrapped with `activated` modifier
     */
    function transferFrom(address from, address to, uint256 value) public activated returns (bool) {
        return super.transferFrom(from, to, value);
    }
}
