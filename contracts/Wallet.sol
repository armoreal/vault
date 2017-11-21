pragma solidity ^0.4.18;

import "./base/Owned.sol";
import "./Vault.sol";
import "./tokens/EtherToken.sol";

/**
  * @title The Compound Smart Wallet
  * @author Compound
  * @notice The Compound Smart Wallet allows customers to easily access
  *         the Compound core contracts.
  */
contract Wallet is Owned {
    Vault vault;
    EtherToken etherToken;

    event Deposit(address acct, address asset, uint256 amount);
    event Withdrawal(address acct, address asset, uint256 amount);

    /**
      * @notice Creates a new Wallet.
      * @param vaultAddress Address of Compound Vault contract
      * @param etherTokenAddress Address of EtherToken contract
      */
    function Wallet(address owner_, address vaultAddress, address etherTokenAddress) public {
        owner = owner_;
        vault = Vault(vaultAddress);
        etherToken = EtherToken(etherTokenAddress);
    }

    /**
      * @notice Deposits eth into the Compound Vault contract
      */
    function depositEth() public payable {
        // Transfer eth into EtherToken
        etherToken.deposit.value(msg.value)();

        depositInteral(address(etherToken), msg.value);
    }

    /**
      * @notice Deposits token into Compound Vault contract
      * @param asset Address of token
      * @param amount Amount of token to transfer
      */
    function depositAsset(address asset, uint256 amount) public {
        // First, transfer in to this wallet
        if (!Token(asset).transferFrom(msg.sender, address(this), amount)) {
            revert();
        }

        depositInteral(asset, amount);
    }

    function depositInteral(address asset, uint256 amount) private {
        // Approve the vault to pull in this asset
        Token(asset).approve(address(vault), amount);

        // Deposit asset in Compound Vault contract
        vault.deposit(asset, amount, address(this));

        // Log this deposit
        Deposit(msg.sender, asset, amount);
    }

    /**
      * @notice Withdraws eth from Compound Vault contract
      * @param amount Amount to withdraw
      * @param to Address to withdraw to
      */
    function withdrawEth(uint256 amount, address to) public onlyOwner {
        // Withdraw from Compound Vault contract to EtherToken
        vault.withdraw(address(etherToken), amount, address(this));

        // Now we have EtherTokens, let's withdraw them to Eth
        etherToken.withdraw(amount);

        // Now, we should have the ether from the withdraw,
        // let's send that to the `to` address
        to.transfer(amount);

        // Log event
        Withdrawal(msg.sender, address(etherToken), amount);
    }

    /**
      * @notice Withdraws asset from Compound Vault contract
      * @param asset Asset to withdraw
      * @param amount Amount to withdraw
      * @param to Address to withdraw to
      */
    function withdrawAsset(address asset, uint256 amount, address to) public onlyOwner {
        // Withdraw the asset
        vault.withdraw(asset, amount, to);

        // Log event
        Withdrawal(msg.sender, asset, amount);
    }

    /**
      * @notice Returns the balance of Eth in this wallet via Vault Contract
      * @return Eth balance from Vault Contract
      */
    function balanceEth() public view returns (uint256) {
      return balance(address(etherToken));
    }

    /**
      * @notice Returns the balance of given asset in this wallet via Vault Contract
      * @return Asset balance from Vault Contract
      */
    function balance(address asset) public view returns (uint256) {
      return vault.getBalanceAtLastCheckpoint(address(this), asset);
    }

    /**
      * @notice Deposit Eth into Compound Vault contract.
      * @dev We allow arbitrary deposits in from `etherToken`
      */
    function() public payable {
        if (msg.sender == address(etherToken)) {
            /* This contract unwraps EtherTokens during withdrawals.
             *
             * When we unwrap a token, EtherToken sends this contract
             * the value of the tokens in Ether. We should not treat this
             * as a new deposit (!!), and as such, we choose to not call
             * `depositEth` for Ether transfers from EtherToken.
             */

            return;
        } else {
            depositEth();
        }
    }
}