// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console2} from "forge-std/Test.sol";
import {MultiSig} from "../src/MultiSig.sol";

contract MultiSigTest is Test {
    MultiSig public multiSig;
    address[] owners = new address[](4);
    function setUp() public {
        owners[0] = address(1);
        owners[1] = address(2);
        owners[2] = address(3);
        owners[3] = address(4);
        multiSig = new MultiSig(owners , 3);
    }

    function testInitialization() public{
        assertEq(multiSig.getOwners(), owners);
        assertEq(multiSig.numConfirmationsRequired(), 3);
    }

    function testSubmitTransaction() public{
        uint t1 = multiSig.getTransactionCount();
        vm.prank(address(1));
        multiSig.submitTransaction(address(2) , 1 , bytes("Data"));
        uint t2 = multiSig.getTransactionCount();
        assertEq(t2-t1 , 1);
        (
            address to,
            uint256 value,
            bytes memory data,
            ,
        ) = multiSig.getTransaction(t1);
        assertEq(to , address(2));
        assertEq(value, 1);
        assertEq(data, bytes("Data"));

    }

    function testApproveTransaction() public{
        uint txIdx = multiSig.getTransactionCount();
        vm.prank(address(1));
        multiSig.submitTransaction(address(2) , 1 , bytes("Data"));
        vm.startPrank(address(2));
        assertEq(multiSig.isTransactionConfirmed(txIdx , address(2)) , false);
        multiSig.approveTransaction(txIdx);
        assertEq(multiSig.isTransactionConfirmed(txIdx , address(2)) , true);
        vm.stopPrank();
    }

    function testRevokeTransaction() public{
        uint txIdx = multiSig.getTransactionCount();
        vm.prank(address(1));
        multiSig.submitTransaction(address(2) , 1 , bytes("Data"));
        vm.startPrank(address(2));
        assertEq(multiSig.isTransactionConfirmed(txIdx , address(2)) , false);
        multiSig.approveTransaction(txIdx);
        assertEq(multiSig.isTransactionConfirmed(txIdx , address(2)) , true);
        multiSig.revokeConfirmation(txIdx);
        assertEq(multiSig.isTransactionConfirmed(txIdx , address(2)) , false);
        vm.stopPrank();
    }
}
