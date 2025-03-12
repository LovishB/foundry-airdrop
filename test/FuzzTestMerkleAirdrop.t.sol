// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.24;

import {Test, console} from "forge-std/Test.sol";
import { MerkleAirdrop, IERC20 } from "../src/MerkleAirdrop.sol";
import { BagelToken } from "../src/BagelToken.sol";
import { DeployMerkleAirdrop } from "../script/DeployMerkleAirdrop.s.sol";

// run fuzz tests using
//forge test --match-contract TestMerkleAirdrop --match-test testFuzz -vvv
contract FuzzTestMerkleAirdrop is Test {
    MerkleAirdrop public airdrop;
    BagelToken public bagelToken;

    // Addresses from the provided Merkle tree data
    address public user1 = 0x6CA6d1e2D5347Bfab1d91e883F1915560e09129D;
    address public user2 = 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266;
    address public user3 = 0x2ea3970Ed82D5b30be821FAAD4a731D35964F7dd;
    address public user4 = 0xf6dBa02C01AF48Cf926579F77C9f874Ca640D91D;
    
    // Proofs from the provided Merkle tree data
    bytes32[][] public proofs = [
        // User 1 proof
        [
            bytes32(0x0fd7c981d39bece61f7499702bf59b3114a90e66b51ba2c53abdf7b62986c00a),
            bytes32(0xe5ebd1e1b5a5478a944ecab36a9a954ac3b6b8216875f6524caa7a1d87096576)
        ],
        // User 2 proof
        [
            bytes32(0xd1445c931158119b00449ffcac3c947d028c0c359c34a6646d95962b3b55c6ad),
            bytes32(0xe5ebd1e1b5a5478a944ecab36a9a954ac3b6b8216875f6524caa7a1d87096576)
        ],
        // User 3 proof
        [
            bytes32(0x4fd31fee0e75780cd67704fbc43caee70fddcaa43631e2e1bc9fb233fada2394),
            bytes32(0x81f0e530b56872b6fc3e10f8873804230663f8407e21cef901b8aeb06a25e5e2)
        ],
        // User 4 proof
        [
            bytes32(0x0c7ef881bb675a5858617babe0eb12b538067e289d35d5b044ee76b79d335191),
            bytes32(0x81f0e530b56872b6fc3e10f8873804230663f8407e21cef901b8aeb06a25e5e2)
        ]
    ];

    uint256 public constant AIRDROP_AMOUNT = 25 * 1e18; // 25 tokens per user
    bytes32 public constant MERKLE_ROOT = 0xaa5d581231e596618465a56aa0f5870ba6e20785fe436d5bfb82b08662ccc7c4;

    function setUp() public {
        //Deploy contracts
        DeployMerkleAirdrop deployer = new DeployMerkleAirdrop();
        (airdrop, bagelToken) = deployer.run();
    }

    //Foundry will generate many different randomAmount (by default it is 256 times)
    function testFuzzInvalidAmount(uint256 randomAmount) public {
        //Skip if randomAmount is the correct amount
        vm.assume(randomAmount != AIRDROP_AMOUNT);
        //User1 will not be able to claim with random amount
        vm.prank(user1);
        vm.expectRevert(
            MerkleAirdrop.MerkleAirdrop_InvalidProof.selector
        );
        airdrop.claim(user1, randomAmount, proofs[0]);
    }

    function testFuzzInvalidUser(address randomUser) public {
        vm.assume(randomUser != user1);
        vm.assume(randomUser != user2);
        vm.assume(randomUser != user3);
        vm.assume(randomUser != user4);
        vm.assume(randomUser != address(0));

        //so that random user can pay gas fee
        deal(randomUser, 1 ether);

        vm.prank(randomUser);
        vm.expectRevert(
            MerkleAirdrop.MerkleAirdrop_InvalidProof.selector
        );
        airdrop.claim(randomUser, AIRDROP_AMOUNT, proofs[0]);
    }

    //This test makes change in the proof bytes
    function testFuzzManipulatedProof(uint8 byteIndex) public {
        // Make sure byteIndex is in valid range (0-31)
        byteIndex = byteIndex % 32;

        //creates a copy of user1 proof
        bytes32[] memory manipulatedProof = new bytes32[](proofs[0].length);
        for (uint i = 0; i < proofs[0].length; i++) {
            manipulatedProof[i] = proofs[0][i];
        }

        //converts bytes32 to bytes, solidity doesn't allow the modification directly
        bytes memory proofBytes = abi.encodePacked(manipulatedProof[0]);

        //XOR at byteindex 
        proofBytes[byteIndex] = bytes1(uint8(proofBytes[byteIndex]) ^ 1);

        // Convert bytes back to bytes32
        manipulatedProof[0] = abi.decode(abi.encodePacked(proofBytes), (bytes32));

        //test then
        vm.prank(user1);
        vm.expectRevert(
            MerkleAirdrop.MerkleAirdrop_InvalidProof.selector
        );
        airdrop.claim(user1, AIRDROP_AMOUNT, manipulatedProof);
    }
}