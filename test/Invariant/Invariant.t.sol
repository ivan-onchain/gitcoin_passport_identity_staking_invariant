// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity 0.8.23;

import {Test} from "forge-std/Test.sol";
import {console} from "forge-std/console.sol";
import {StdInvariant} from "forge-std/StdInvariant.sol";

import {Handler} from "./Handler.t.sol";

import {ERC20Mock} from "../mocks/ERC20Mock.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IdentityStaking} from "../../src/IdentityStaking.sol";

contract Invariant is StdInvariant, Test {
    ERC20Mock token;
    address user = makeAddr("USER");
    Handler handler;
    uint88 initialBalance;

    address initialAdmin = makeAddr("IA");
    address initialSlasher = makeAddr("IS");
    address initialReleaser = makeAddr("IR");
    address stakee = makeAddr("stakee");
    address burnAddress = address(0);
    IdentityStaking identityStaking;

    address[] initialSlashers = new address[](1);
    address[] initialReleasers = new address[](1);

    function setUp() public {
        vm.startPrank(user);
        token = new ERC20Mock();
        initialBalance = 1000 ether;
        token.mint(user, initialBalance);
        vm.stopPrank();
        
        initialSlashers.push(initialSlasher);
        initialReleasers.push(initialReleaser);
        identityStaking =
            new IdentityStaking(address(token), burnAddress, initialAdmin, initialSlashers, initialReleasers);
        vm.startPrank(user);
        initialBalance = 1000 ether;
        token.approve(address(identityStaking), initialBalance);
        vm.stopPrank();

        handler = new Handler(identityStaking, token, user, initialSlasher, initialReleaser);
        bytes4[] memory selectors = new bytes4[](6);

        selectors[0] = handler.selfStake.selector;
        selectors[1] = handler.withdrawSelfStake.selector;
        selectors[2] = handler.communityStake.selector;
        selectors[3] = handler.withdrawCommunityStake.selector;
        selectors[4] = handler.slash.selector;
        selectors[5] = handler.release.selector;

        targetSelector(FuzzSelector({addr: address(handler), selectors: selectors}));
        targetContract(address(handler));
    }

    function testInitialBalance() public view {
        assert(token.balanceOf(user) == initialBalance);
    }

    function testCanSelfStake() public {
        uint88 selfStakeAmount = 100;
        uint64 duration = uint64(block.timestamp + 13 weeks);
        vm.startPrank(user);
        identityStaking.selfStake(selfStakeAmount, duration);
        vm.stopPrank();
    }

    function statefulFuzz_userTotalStakedMustBeEqualThanSelfAndCommunityStake() public view {
      ( ,uint88 selfStakedAmount,,) = identityStaking.selfStakes(user);
      ( ,uint88 communityStakedAmount,,) = identityStaking.communityStakes(user, stakee);
      uint88 userTotalStaked = identityStaking.userTotalStaked(user);
      console.log('userTotalStaked: ', userTotalStaked);
      console.log('selfStakedAmount + communityStakedAmount : ', selfStakedAmount + communityStakedAmount);
      console.log('Difference [userTotalStaked <> selfStakedAmount + communityStakedAmount ] ',  (selfStakedAmount + communityStakedAmount) - userTotalStaked);
       assertEq( userTotalStaked , selfStakedAmount + communityStakedAmount, "Invariant Failed!");
   } 
}
