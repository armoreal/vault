pragma solidity ^0.4.19;

import "./base/Owned.sol";

/**
  * @title The Compound Interest Model Contract
  * @author Compound
  * @notice This contract holds the math for calculating interest rates
  */
contract InterestModel {
    uint16 public supplyRateSlopeBPS = 1000;
    uint16 public borrowRateSlopeBPS = 3000;
    uint16 public minimumBorrowRateBPS = 1000;
    uint64 constant blocksPerYear = 2102400; // = (365 * 24 * 60 * 60) seconds per year / 15 seconds per block
    // Given a real number decimal, to convert it to basis points you multiply by 10000.
    // For example, we know 100 basis points = 1% = .01.  We get the basis points from the decimal: .01 * 10000 = 100
    uint16 basisPointMultiplier = 10000;
    uint16 constant public oneMinusSpreadBPS = 8500;
    uint64 constant interestRateScale = 10 ** 17;

    function getDivisionSafeSupply(uint256 supply) public pure returns (uint256) {
        // avoid division by 0 without altering calculations in the happy path (at the cost of an extra comparison)
        if (supply == 0) {
            return 1;
        }
        return supply;
    }

    /**
      * @notice `getScaledSupplyRatePerBlock` returns the current borrow interest rate based on the balance sheet
      * @param supply total supply available of asset from balance sheet
      * @param borrows total borrows of asset from balance sheet
      * @return the current supply interest rate (in scale points, aka divide by 10^17 to get real rate)
      */
    function getScaledSupplyRatePerBlock(uint256 supply, uint256 borrows) public view returns (uint64) {
        uint256 divisionSafeSupply = getDivisionSafeSupply(supply);

        // `utilization a` = `borrows a` / `supply a`
        // `supply interest rate a` = `borrow rate a` *`utilization a` * `1-minus-spread`
        // thus: `supply interest rate a` = `borrow rate a` * (`borrows a` / `supply a`) * `1-minus-spread`
        // when utilization exceeds 1, the supply rate can exceed the borrow rate. However, the distribution of
        // assets across borrows and supplies in such cases means that total income from borrow interest will still
        // exceed outlays from supply interest.

        // note: this is done in one-line (including re-implementation of borrowRate) since intermediate results would be truncated
        return uint64(
            (
                (
                    borrowRateSlopeBPS * (
                        ( interestRateScale * borrows ) / divisionSafeSupply
                    ) + ( uint256(minimumBorrowRateBPS) * interestRateScale )
                ) * borrows * oneMinusSpreadBPS
            ) / (divisionSafeSupply * basisPointMultiplier * blocksPerYear * basisPointMultiplier));
    }

    /**
      * @notice `getScaledBorrowRatePerBlock` returns the current borrow interest rate based on the balance sheet
      * @param supply total supply available of asset from balance sheet
      * @param borrows total borrows of asset from balance sheet
      * @return the current borrow interest rate (in scale points, aka divide by 10^17 to get real rate)
      */
    function getScaledBorrowRatePerBlock(uint256 supply, uint256 borrows) public view returns (uint64) {
        uint256 divisionSafeSupply = getDivisionSafeSupply(supply);

        // `utilization a` = `borrows a` / `supply a`
        // `borrow interest rate a` = 10% + `utilization a` * 30%
        // thus: `borrow interest rate a` = 10% + 30% * `borrows a` / `supply a`

        // note: this is done in one-line since intermediate results would be truncated
        return uint64(
            (
                borrowRateSlopeBPS * (
                    ( interestRateScale * borrows ) / divisionSafeSupply
                ) + ( uint256(minimumBorrowRateBPS) * interestRateScale )
            ) / ( blocksPerYear * basisPointMultiplier )
        );
    }

}