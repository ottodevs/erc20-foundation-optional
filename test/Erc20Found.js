var Erc20Found = artifacts.require("./Erc20Found.sol");

contract('Erc20Found', function(accounts) {
    var account1 = accounts[0];
    var account2 = accounts[1];
    var account3 = accounts[2];
    var account4 = accounts[3];
    var account5 = accounts[4];
    var account6 = accounts[5];
    var u;
    var adminBalance = 5000;
    var deduct = 2003;
    var deduct2 = 1001;


 /*   it("should NOT approve a user to spend from another user's account and then NOT spend correctly ", function() {
        return MasonCoin.new().then(function(instance) {
            u=instance;
            return u.bid(5, {from: account1, value: 1});
        }).catch(function(error) {
          assert.equal(error.toString(), "Error: VM Exception while processing transaction: invalid opcode", error)
        });
    });*/

    it("get balance of one id ", function() {
        return Erc20Found.new(adminBalance).then(function(instance) {
            u=instance;
            return u.balanceOf(account1);
        }).then(function(balance) {
            assert.equal(balance.toNumber(), adminBalance, "Balance not as expected")
        });
    });

    it("gets foundationids ", function() {
        return Erc20Found.new(adminBalance).then(function(instance) {
            u=instance;
            return u.getFoundId(account3);
        }).then(function(id1) {
            console.log(web3.toAscii(id1).replace(/\u0000/g, ''));
            return u.getFoundId(account4);
        }).then(function(id2) {
            console.log(web3.toAscii(id2).replace(/\u0000/g, ''));
        })
    });


/*    it("returns all addresses associated with a foundId ", function() {
        return Erc20Found.new(adminBalance).then(function(instance) {
            u=instance;
            return u.getFoundAddresses(account3);
        }).then(function(allAddr) {
            console.log(account3);
            console.log(account4);
            console.log(allAddr);
        })
    });*/

    it("transfers balance, gets back expected balance, toggles foundP then gets back total balance", function() {
        return Erc20Found.new(adminBalance).then(function(instance) {
            u=instance;
            return u.transfer(account3, deduct, {from: account1});
        }).then(function(transaction) {
            return u.transfer(account4, deduct2, {from: account1});
        }).then(function(transaction) {
            return u.balanceOf(account3);
        }).then(function(balance) {
            console.log(balance);
            assert.equal(balance.toNumber(), deduct, "Balance not as expected");
            return u.toggleFoundP({from: account3});
        }).then(function(transaction) {
            return u.balanceOf(account3);
        }).then(function(balance) {
            console.log(balance);
            assert.equal(balance.toNumber(), deduct+deduct2, "balance not as expected");
        });
    });


        it("transfers foundationId balance, gets back expected balance in new account", function() {
        return Erc20Found.new(adminBalance).then(function(instance) {
            u=instance;
            return u.transfer(account3, deduct, {from: account1});
        }).then(function(transaction) {
            return u.transfer(account4, deduct2, {from: account1});
        }).then(function(transaction) {
            return u.toggleFoundP({from: account3});
        }).then(function(transaction) {
            return u.transfer(account5, deduct+deduct2, {from: account3});
        }).then(function(transaction) {
            return u.balanceOf(account5);
        }).then(function(balance) {
            console.log(balance);
            assert.equal(balance.toNumber(), deduct+deduct2, "Balance not as expected");
        });
    });

});
