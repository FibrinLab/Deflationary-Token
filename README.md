## ERC20 Token

An ERC20 token which has the deflationary in nature. Every token transfer has led a burn of 1 % of the transfer amount and it reflect with in the receiver account.
eg.- Alice sends 100 token to Bob then bob will receive 99 tokens.
Whilst this nature can be skipped for a sender by adding that sender in `skippedAccountFromDeflation` list.

Similarly there is a 5 days deflationary cycle for the new investors [def - A token holder whose balance changes from the 0 to non-zero]. 3 % of there balance get burned at the end of
5 day cycle. Burning of 3 % of the token holder balance is the lazy evaluation process. Again issuer can save the new investor from this deflationary cycle by adding investors addresses in `skippedAccountFromDeflation` list.
eg.- Alice sends 100 tokens to Bob (current balance of Bob is 0) during the 5 days deflationary cycle. Bob will receive 99 tokens.
Bob sends 50 tokens to Charlie at the end of current 5 day cycle. Charlie wil receive 49.5 tokens while Bob remaining balance will be 46.03 tokens. 

## Pre-requisite.
* node >= v10.13.0.
* yarn >= 1.10.1

## Setup
Setup -1   

```
git clone https://github.com/satyamakgec/deflationary-token.git
```

Step - 2   

```
yarn install
```

## Build, Deploy and test the code

To compile      

```
npm run compile
```

To test

```
npm run ganache-cli && npm run test
```

To deploy using the remix IDE run `npm run flatten`, It will create a new file `SPAMToken.sol` in the current directory which can be used for the deployment
using remix.



