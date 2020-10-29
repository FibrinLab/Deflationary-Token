let { increaseTime } = require("./helpers/time.js");
let { catchRevert } = require("./helpers/exceptions.js");
const SPAMToken = artifacts.require("SPAMToken");


let Web3 = require("web3");
let BN = Web3.utils.BN;

async function latestTime() {
    let block = await latestBlock();
    return block.timestamp;
}

async function latestBlock() {
    return await web3.eth.getBlock("latest");
}

contract("SPAMToken", async(accounts) => {
    let spamToken;
    let owner = accounts[0];
    let investor1 = accounts[1];
    let investor2 = accounts[2];
    let investor3 = accounts[3];
    let WEB3;
    let startTime;

    before(async () => {
        spamToken = await SPAMToken.new(owner, {from: owner});
        WEB3 = new Web3(web3.currentProvider);
        startTime = await latestTime();
    });

    describe("Should run smart contract as desired", async() => {
        it("Should verify the initial set parameter", async() => {
            assert.equal(await spamToken.symbol(), "SPAM");
            assert.equal(await spamToken.name(), "SPAM Token");
            assert.equal((await spamToken.totalSupply()).toString(), WEB3.utils.toWei("100000"));
            assert.equal((await spamToken.balanceOf(accounts[0])).toString(), WEB3.utils.toWei("100000"));
            assert.equal(await spamToken.newAccountDeflationStartTime.call(), startTime);
            assert.equal((await spamToken.nextNewAccountDeflationTimePeriod.call()).toNumber(), parseInt(startTime) + (await spamToken.NEW_ACCOUNT_DEFLATION_TIME.call()).toNumber());
            assert.isTrue(await spamToken.skippedAccountFromDeflation.call(accounts[0]));
        });

        it("Should fail to send tokens more than total supply", async() => {
            await catchRevert(
                spamToken.transfer(investor1, web3.utils.toWei("500000"), {from: owner}),
                "ERC20: transfer amount exceeds balance"
            );
        })

        it("Should fund some token to investor 1", async () => {
            await spamToken.transfer(investor1, web3.utils.toWei("200"), {from: owner});
            assert.equal((await spamToken.balanceOf(investor1)).toString(), web3.utils.toWei("200"));
            assert.equal((await spamToken.deductedAfterTime.call(investor1)).toNumber(), (await spamToken.nextNewAccountDeflationTimePeriod.call()).toNumber());
            assert.isTrue(await spamToken.accountToBeDeducted.call(investor1));
        });

        it("Should burn token with 1 % inflation if tokens are send", async() => {
            await spamToken.transfer(investor2, web3.utils.toWei("100"), {from: investor1});
            assert.equal((await spamToken.balanceOf(investor1)).toString(), web3.utils.toWei("100"));
            assert.equal((await spamToken.balanceOf(investor2)).toString(), web3.utils.toWei("99"));
            assert.equal((await spamToken.deductedAfterTime.call(investor2)).toNumber(), (await spamToken.nextNewAccountDeflationTimePeriod.call()).toNumber());
            assert.isTrue(await spamToken.accountToBeDeducted.call(investor1));
            assert.isTrue(await spamToken.accountToBeDeducted.call(investor2));
        });

        it("Should burn token with 3 % inflation if tokens are send", async() => {
            await increaseTime(5 * 24 * 60 * 60 + 500); // Increase time by 5 days 500 seconds.
            let oldBalanceOfInvestor2 = await spamToken.balanceOf(investor2);
            await spamToken.transfer(investor2, web3.utils.toWei("50"), {from: investor1});
            assert.equal((await spamToken.balanceOf(investor1)).toString(), web3.utils.toWei("47")); // deduction of 50 (actual transfer value) + 3 (because of 3 % inflation).
            assert.equal((await spamToken.balanceOf(investor2)).toString(), 
                ((oldBalanceOfInvestor2.add(new BN(web3.utils.toWei("50"))))
                .sub(new BN(new BN(web3.utils.toWei(".5"))))).toString()
            );
            assert.equal((await spamToken.deductedAfterTime.call(investor2)).toNumber(), (await spamToken.nextNewAccountDeflationTimePeriod.call()).toNumber());
            assert.isTrue(await spamToken.accountToBeDeducted.call(investor2));
            // Delete the related data.
            assert.isFalse(await spamToken.accountToBeDeducted.call(investor1));
            assert.equal(await spamToken.deductedAfterTime.call(investor1), 0);
        });

        it("Should burn token with 3 % inflation if tokens are send from investor 2 to new investor 3", async() => {
            let oldBalanceOfInvestor2 = await spamToken.balanceOf(investor2);
            let deductedAmount = (new BN(3).mul(oldBalanceOfInvestor2)).div(new BN(100));
            let nextTimePeriod = new BN(startTime).add((await spamToken.NEW_ACCOUNT_DEFLATION_TIME.call()).mul(new BN(2)));
            await spamToken.transfer(investor3, web3.utils.toWei("20"), {from: investor2});
            assert.equal((await spamToken.balanceOf(investor3)).toString(), web3.utils.toWei("19.8")); // 20 (actual transfer value) - 3 (because of 1 % inflation).
            assert.equal((await spamToken.balanceOf(investor2)).toString(), 
                ((oldBalanceOfInvestor2.sub(new BN(web3.utils.toWei("20"))))
                .sub(deductedAmount)).toString()
            );
            assert.equal((await spamToken.nextNewAccountDeflationTimePeriod.call()).toNumber(), nextTimePeriod.toNumber());
            assert.equal((await spamToken.deductedAfterTime.call(investor3)).toNumber(), (await spamToken.nextNewAccountDeflationTimePeriod.call()).toNumber());
            assert.isTrue(await spamToken.accountToBeDeducted.call(investor3));
            // Delete the related data.
            assert.isFalse(await spamToken.accountToBeDeducted.call(investor2));
            assert.equal(await spamToken.deductedAfterTime.call(investor2), 0);
        });

        it("Should skip investor 3 to freely transfer", async() => {
            await catchRevert(
                spamToken.skipAccountFromDeflation(investor3, {from: investor1}),
                "Ownable: caller is not the owner"
            );

            await spamToken.skipAccountFromDeflation(investor3, {from: owner});
            let oldBalanceOfInvestor2 = await spamToken.balanceOf(investor2);
            let oldBalanceOfInvestor3 = await spamToken.balanceOf(investor3);
            await spamToken.transfer(investor2, web3.utils.toWei("5"), {from: investor3});
            assert.equal((await spamToken.balanceOf(investor2)).toString(), (oldBalanceOfInvestor2.add(new BN(web3.utils.toWei("5")))).toString());
            assert.equal((await spamToken.balanceOf(investor3)).toString(), (oldBalanceOfInvestor3.sub(new BN(web3.utils.toWei("5")))).toString())
        });
    });
});