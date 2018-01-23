[![CircleCI](https://circleci.com/gh/compound-finance/vault.svg?style=svg&circle-token=d58f8a4064fc9f3b462d8629cc5187f8a7dcb673)](https://circleci.com/gh/compound-finance/vault)

The Compound Vault
==============

The Compound Vault contract is where Compound stores customer deposits. These
contracts should be as simple as possible to avoid bugs and vulnerabilities.

Initially we will have a limited number of account types defined. Once we can
ensure these contracts are well tested an secure we plan to make an abstract
account
contract that will be non-upgradable. This contract will be able to represent
all future account types.

Installation
------------
To install the Compound Vault first pull the repository from GitHub and then
install its dependencies:

    git clone https://github.com/compound-finance/vault
    cd vault
    yarn
    truffle compile
    truffle migrate

Testing
-------
Contract tests are defined under the [test
directory](https://github.com/compound-finance/vault/tree/master/test). To run the tests run:

    truffle test
    
Assertions used in our tests are provided by [ChaiJS](http://chaijs.com).    

Deployment
----------
To deploy the Vault contracts run:

    truffle deploy

_© Copyright 2017 Compound_
