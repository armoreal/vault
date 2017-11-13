const BigNumber = require('bignumber.js');
const Loaner = artifacts.require("./Loaner.sol");
const EtherToken = artifacts.require("./tokens/EtherToken.sol");
const utils = require('./utils');
const moment = require('moment');

contract('Loaner', function(accounts) {
  var loaner;
  var etherToken;

  beforeEach(async () => {
    [loaner, etherToken] = await Promise.all([Loaner.new(), EtherToken.new()]);
  });

  describe('#newLoan', () => {
    describe('when the loan is valid', () => {
      it("pays out the amount requested", async () => {
        // fund the loaner
        await etherToken.deposit({from: web3.eth.accounts[0], value: 100});
        await etherToken.transfer(loaner.address, 100, {from: web3.eth.accounts[0]});

        // Check return value
        const amountLoaned = await loaner.newLoan.call(etherToken.address, 20, {from: web3.eth.accounts[1]});
        assert.equal(amountLoaned.valueOf(), 20);

        // Call actual function
        await loaner.newLoan(etherToken.address, 20, {from: web3.eth.accounts[1]});

        // verify balances in W-Eth
        assert.equal(await utils.tokenBalance(etherToken, loaner.address), 80);
        assert.equal(await utils.tokenBalance(etherToken, web3.eth.accounts[1]), 20);
      });
    });
  });
});
