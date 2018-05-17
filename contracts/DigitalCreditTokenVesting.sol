pragma solidity 0.4.23;

import "./DigitalCreditToken.sol";
import "./SafeMath.sol";
import "./Ownable.sol";

contract DigitalCreditTokenVesting is Ownable{
    using SafeMath for uint256;

    event Released(uint256 amount);

    // beneficiary of tokens after they are released
    address public beneficiary;

    uint256 public startFrom;
    uint256 public period;
    uint256 public tokensReleasedPerPeriod;

    uint256 public elapsedPeriods;

    DigitalCreditToken private token;

    /**
     * @dev Creates a vesting contract for DigitalCreditToken
     * @param _beneficiary address of the beneficiary to whom vested tokens are transferred
     * @param _startFrom Datetime when the vesting will begin
     * @param _period The preiod to release the token
     * @param _tokensReleasedPerPeriod the token to release per period
     */
    constructor(
        address _beneficiary,
        uint256 _startFrom,
        uint256 _period,
        uint256 _tokensReleasedPerPeriod,
        DigitalCreditToken _token
    ) public {
        require(_beneficiary != address(0));
        require(_startFrom >= now);

        beneficiary = _beneficiary;
        startFrom = _startFrom;
        period = _period;
        tokensReleasedPerPeriod = _tokensReleasedPerPeriod;
        elapsedPeriods = 0;
        token = _token;
    }

    /**
     *  @dev getToken this may be more convinience for user
     *        to check if their vesting contract is binded with a right token
     * return DigitalCreditToken
     */
     function getToken() public view returns(DigitalCreditToken) {
       return token;
     }

    /**
     * @dev release
     * param _token DigitalCreditToken that will be released to beneficiary
     */
    function release() public {
        require(msg.sender == owner || msg.sender == beneficiary);
        require(token.balanceOf(this) >= 0 && now >= startFrom);
        uint256 elapsedTime = now.sub(startFrom);
        uint256 periodsInCurrentRelease = elapsedTime.div(period).sub(elapsedPeriods);
        uint256 tokensReadyToRelease = periodsInCurrentRelease.mul(tokensReleasedPerPeriod);
        uint256 amountToTransfer = tokensReadyToRelease > token.balanceOf(this) ? token.balanceOf(this) : tokensReadyToRelease;
        require(amountToTransfer > 0);
        elapsedPeriods = elapsedPeriods.add(periodsInCurrentRelease);
        token.transfer(beneficiary, amountToTransfer);
        emit Released(amountToTransfer);
    }
}
