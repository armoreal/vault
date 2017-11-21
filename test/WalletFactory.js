const BigNumber = require('bignumber.js');
const WalletFactory = artifacts.require("./WalletFactory.sol");
const Wallet = artifacts.require("./Wallet.sol");
const Vault = artifacts.require("./Vault.sol");
const EtherToken = artifacts.require("./tokens/EtherToken.sol");
const utils = require('./utils');
const moment = require('moment');

contract('WalletFactory', function(accounts) {
  var walletFactory;
  var vault;
  var etherToken;

  beforeEach(async () => {
    [vault, etherToken] = await Promise.all([Vault.new(), EtherToken.new()]);

    walletFactory = await WalletFactory.new(vault.address, etherToken.address);
  });

  describe("#newWallet", () => {
    it("should create a new wallet", async () => {
      // Find out where wallet will be created
      const walletAddress = (await walletFactory.newWallet.call(web3.eth.accounts[1], {from: web3.eth.accounts[0]})).valueOf();

      // Actually create the wallet
      await walletFactory.newWallet(web3.eth.accounts[1], {from: web3.eth.accounts[0]});

      // Make a Wallet variable pointed at the address from above
      const wallet = Wallet.at(walletAddress);

      // Deposit eth into wallet
      await wallet.depositEth({from: web3.eth.accounts[1], value: 55});

      // Verify balance
      assert.equal((await wallet.balanceEth.call()).valueOf(), 55);

      // Withdraw eth
      await wallet.withdrawEth(22, web3.eth.accounts[1], {from: web3.eth.accounts[1]});

      // Verify balance
      assert.equal((await wallet.balanceEth.call()).valueOf(), 33);
    });

    it("should only work if by wallet factory owner", async () => {
      utils.assertFailure(async () => {
        await walletFactory.newWallet(web3.eth.accounts[1], {from: web3.eth.accounts[1]});
      });
    });

    it("should be owned by set owner", async () => {
      // Find out where wallet will be created
      const walletAddress = (await walletFactory.newWallet.call(web3.eth.accounts[1], {from: web3.eth.accounts[0]})).valueOf();

      // Actually create the wallet
      await walletFactory.newWallet(web3.eth.accounts[1], {from: web3.eth.accounts[0]});

      // Make a Wallet variable pointed at the address from above
      const wallet = Wallet.at(walletAddress);

      // Deposit eth into wallet
      await wallet.depositEth({from: web3.eth.accounts[1], value: 55});

      // Withdraw non-owner
      utils.assertFailure("VM Exception while processing transaction: revert", async () => {
        await wallet.withdrawEth(22, web3.eth.accounts[1], {from: web3.eth.accounts[2]});
      });

      // Withdraw owner
      await wallet.withdrawEth(22, web3.eth.accounts[1], {from: web3.eth.accounts[1]});
    });

    it("should emit new wallet event", async () => {
      // Find out where wallet will be created
      const walletAddress = (await walletFactory.newWallet.call(web3.eth.accounts[1], {from: web3.eth.accounts[0]})).valueOf();

      // Actually create the wallet
      await walletFactory.newWallet(web3.eth.accounts[1], {from: web3.eth.accounts[0]});

      await utils.assertEvents(walletFactory, [
      {
        event: "NewWallet",
        args: {
          walletOwner: web3.eth.accounts[1],
          newWalletAddress: walletAddress
        }
      }]);
    });
  });
});
