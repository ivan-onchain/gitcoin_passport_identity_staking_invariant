// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity 0.8.23;

import {StdInvariant} from "forge-std/StdInvariant.sol";
import {Test} from "forge-std/Test.sol";
import {console} from "forge-std/console.sol";
import {ERC20Mock} from "../mocks/ERC20Mock.sol";
import {IdentityStaking} from "../../src/IdentityStaking.sol";

contract Handler is Test {
    ERC20Mock token;
    IdentityStaking identityStaking;
    address user;
    address initialSlasher;
    address initialReleaser;
    uint88 initialBalance;
    // Ghost functions
    uint64 durationIncrement = 0;
    bool firstRun = true;
    uint64 duration = 0;
    address[] selfStakers;
    address[] communityStakers;
    address[] communityStakees;
    address stakee = makeAddr('stakee');


    constructor(IdentityStaking _identityStaking, ERC20Mock _token, address _user, address _initialSlasher, address _initialReleaser) {
        identityStaking = _identityStaking;
        token = _token;
        user = _user;
        initialSlasher = _initialSlasher;
        initialReleaser = _initialReleaser;
    }

    function selfStake(uint88 amount) public {
        ( uint64 unlockedTime,,,) = identityStaking.selfStakes(user);

        if (firstRun == true) {
            duration = uint64(block.timestamp) + 12 weeks;
        } else {
            duration = uint64(bound(duration, unlockedTime + durationIncrement, uint64(block.timestamp) + 104 weeks));
        }

        vm.assume(token.balanceOf(user) >= 1);

        amount = uint88(bound(amount, 1, token.balanceOf(user)));
        durationIncrement++;
        vm.startPrank(user);
        
        identityStaking.selfStake(amount, duration);
        vm.stopPrank();
    }

    function withdrawSelfStake(uint88 amount) public {
        ( ,uint88 selftStakedAmount,,) = identityStaking.selfStakes(user);
        amount = uint88(bound(amount, 0, selftStakedAmount));

        ( uint64 unlockedTime,,,) = identityStaking.selfStakes(user);
        vm.assume(unlockedTime <= uint64(block.timestamp));
     
        vm.startPrank(user);
        identityStaking.withdrawSelfStake(amount);
        vm.stopPrank();
    }

    function communityStake(uint88 amount) public {

        ( uint64 unlockedTime,,,) = identityStaking.communityStakes(user, stakee);

        if (firstRun == true) {
            duration = uint64(block.timestamp) + 12 weeks;
        } else {
            duration = uint64(bound(duration, unlockedTime + durationIncrement, uint64(block.timestamp) + 104 weeks));
        }

        vm.assume(token.balanceOf(user) >= 1);

        amount = uint88(bound(amount, 1, token.balanceOf(user)));
        durationIncrement++;

        vm.startPrank(user);
        identityStaking.communityStake(stakee, amount, duration);
        vm.stopPrank();
    }

    function withdrawCommunityStake(uint88 amount) public {
        ( ,uint88 communityStakedAmount,,) = identityStaking.communityStakes(user, stakee);

        // For some reason this is showing a FOUNDRY::ASSUME error
        // vm.assume(communityStakedAmount >= 1)

        if (communityStakedAmount < 1) {
            return;
        }

        amount = uint88(bound(amount, 1, communityStakedAmount));

        ( uint64 unlockedTime,,,) = identityStaking.communityStakes(user, stakee);
        vm.assume(unlockedTime <= uint64(block.timestamp));
     
        vm.startPrank(user);
        identityStaking.withdrawCommunityStake(stakee,amount);
        vm.stopPrank();
    }
    
    function slash(uint88 percent) public {
        selfStakers.push(user);
        percent = uint88(bound(percent, 1, 100));
        vm.startPrank(initialSlasher);
        identityStaking.slash(selfStakers, communityStakers, communityStakees, percent);
        vm.stopPrank();
    }

    function release(uint88 amountToRelease) public {
        uint16 slashRound = 1;
        ( ,,uint88 userSlashedAmount,) = identityStaking.selfStakes(user);
        
        // For some reason this is showing a FOUNDRY::ASSUME error
        // vm.assume(userSlashedAmount >= 1);
        if (userSlashedAmount < 1) {
            return;
        }

        amountToRelease = uint88(bound(amountToRelease, 1, userSlashedAmount));
        console.log('amountToRelease: ', amountToRelease);
        
        stakee = user;
        vm.startPrank(initialReleaser);
        identityStaking.release( user, stakee, amountToRelease, slashRound);
        vm.stopPrank();
    }
}
