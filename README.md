## Proof of concept of userTotalStaked broken Invariant .

This repository implement `Invariant Tests` functionality provided by Foundry to find a broken invariant in the `IdentityStaking` contract of the Gitcoin Passport protocol.

This broken Invariant was found manually in a Code4rena Bug Bounty round, here the link to check further details - [audit report](https://solodit.xyz/issues/h-01-usertotalstaked-invariant-will-be-broken-due-to-vulnerable-implementations-in-release-code4rena-gitcoin-passport-gitcoin-passport-git).

The broken invariant is a protocol-defined rule stating that the user's total staked amount must equal the sum of their self-staked amount and the sum of all community staked amounts made by the user.

```js
userTotalStaked[user] = selfStakes[user].amount + sum(communityStakes[user][stakee].amount for all x staked on by user)
```

`Invariant::statefulFuzz_userTotalStakedMustBeEqualThanSelfAndCommunityStake` is the function in the `test/invariant/Invariant.sol `file that checks the invariant.  

The Handler.sol file contains the main functions that impact the self, community, and total balances. Each function is configured to run in a random manner, accounting for potential revert errors due to disallowed values, ensuring the correct functionality of the protocol.

When you run the test, the logs will display the self, community, and total balances. The logs preceding the error show a discrepancy between `userTotalStaked` and `selfStakedAmount` + `communityStakedAmount`, which should not exist. Additionally, the `amountToRelease` value matches this discrepancy, indicating that the error occurs during the token release process. Thus, the error is happening in the `IdentityStaking::release` function, the last function called according to the Traces logs.

```logs
  amountToRelease:  2413
  userTotalStaked:  730
  selfStakedAmount + communityStakedAmount :  3143
  Difference [userTotalStaked <> selfStakedAmount + communityStakedAmount ]  2413
```
```shell
     ├─ [0] VM::assertEq(730, 3143, "Invariant Failed!") [staticcall]
    │   └─ ← [Revert] Invariant Failed!: 730 != 3143
    └─ ← [Revert] Invariant Failed!: 730 != 3143
```    

If you examine the `IdentityStaking::release` function, you'll notice that it updates `selfStakes` and `communityStakes`, but it does not update `userTotalStaked`.

> Upgradeability functionality was removed from contracts to facilitate the PoC.

### Install dependencies
```shell
make install
```

### Run invariant test

```shell
 forge test --match-test statefulFuzz_userTotalStakedMustBeEqualThanSelfAndCommunityStake -vvv
```
