pragma solidity ^0.4.18;

/**
  * @title Interest Helper Contract
  * @author Compound
  * @notice This contract holds the compound interest calculation functions
  *			to be used by Compound contracts.
  */
contract InterestHelper {

	/**
      * @notice `balanceWithInterest` returns the balance with
      *			compound interest over the given period.
      * @param principal The starting principal
      * @param beginTime The time (as an epoch) when interest began to accrue
      * @param endTime The time (as an epoch) when interest stopped accruing (e.g. now)
      * @param interestRate The annual interest rate
      * @param payoutsPerYear The number of payouts per year
      */
	function balanceWithInterest(uint256 principal, uint256 beginTime, uint256 endTime, uint64 interestRate, uint64 payoutsPerYear) public pure returns (uint256) {
		uint256 duration = (endTime - beginTime) / (1 years);
		uint256 payouts = duration * payoutsPerYear;
		uint256 amortization = principal;

		for (uint64 _i = 0; _i < payouts; _i++) {
		    amortization = amortization + ((amortization * interestRate) / 100 / payoutsPerYear);
		}

		return amortization;
	}
}