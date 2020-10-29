// Special non-standard methods implemented by testrpc that
// aren’t included within the original RPC specification.
// See https://github.com/ethereumjs/testrpc#implemented-methods

async function advanceBlock() {
return new Promise((resolve, reject) => {
    web3.currentProvider.send({
        jsonrpc: '2.0',
        method: 'evm_mine',
    },
    (err, result) => {
        if (err) {
        return reject(err);
        }
        resolve(result.result);
    }
    );
});
}

// Increases ganache time by the passed duration in seconds
async function increaseTime(duration) {
await new Promise((resolve, reject) => {
    web3.currentProvider.send({
        jsonrpc: '2.0',
        method: 'evm_increaseTime',
        params: [duration],
    },
    (err, result) => {
        if (err) {
        return reject(err);
        }
        resolve(result.result);
    }
    );
});
await advanceBlock();
}

async function jumpToTime(timestamp) {
    await new Promise(
        (resolve, reject) => {
        web3.currentProvider.send({
            jsonrpc: '2.0',
            method: "evm_mine",
            params: [timestamp],
        },
        (err, result) => {
            if (err) {
            return reject(err);
            }
            resolve(result.result);
        }
        );
    }); 
    await advanceBlock();
}

module.exports = { increaseTime, jumpToTime };
