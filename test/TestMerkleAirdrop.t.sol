// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.24;

import {Test, console} from "forge-std/Test.sol";
import { MerkleAirdrop, IERC20 } from "../src/MerkleAirdrop.sol";
import { BagelToken } from "../src/BagelToken.sol";
import { DeployMerkleAirdrop } from "../script/DeployMerkleAirdrop.s.sol";


contract TestMerkleAirdrop is Test {

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

    function testAirdropContractSetup() public view {
        assertEq(airdrop.getMerkleRoot(), MERKLE_ROOT, "Merkle root match");
        assertEq(address(airdrop.getAirdropToken()), address(bagelToken), "Token address match");
        assertEq(bagelToken.balanceOf(address(airdrop)), AIRDROP_AMOUNT * 4, "Airdrop contract has enough tokens");
    }

    function testClaimInvalidProof() public {
        bytes32[] memory invalidProof = new bytes32[](1);
        invalidProof[0] = bytes32(0x0fd7c981d39bece61f7499702bf59b3114a90e66b51ba2c53abdf7b62986d00a);
    
        vm.prank(user1);
        vm.expectRevert(
            MerkleAirdrop.MerkleAirdrop_InvalidProof.selector
        );
        airdrop.claim(user1, AIRDROP_AMOUNT, invalidProof);
    }

    function testClaimInvalidUser() public {
        address invalidUser = makeAddr("invalidUser");
        vm.prank(invalidUser);
        vm.expectRevert(
            MerkleAirdrop.MerkleAirdrop_InvalidProof.selector
        );
        airdrop.claim(invalidUser, AIRDROP_AMOUNT, proofs[0]);
    }

    function testClaimInvalidAmount() public {
        vm.prank(user1);
        vm.expectRevert(
            MerkleAirdrop.MerkleAirdrop_InvalidProof.selector
        );
        airdrop.claim(user1, AIRDROP_AMOUNT*2, proofs[0]);
    }

    //test claim
    function testClaim() public {
        vm.startPrank(user2);
        uint256 initialBalance = bagelToken.balanceOf(user2);
        airdrop.claim(user2, AIRDROP_AMOUNT, proofs[1]);
        vm.stopPrank();
        // Check balance after claim
        assertEq(
            bagelToken.balanceOf(user2),
            initialBalance + AIRDROP_AMOUNT,
            "User should receive correct token amount"
        );
        assertEq(bagelToken.balanceOf(address(airdrop)), AIRDROP_AMOUNT * 3, "Airdrop contract has enough tokens");
    }

    //test cannot claim twice
    function testReClaimInvalid() public {
        vm.startPrank(user3);
        airdrop.claim(user3, AIRDROP_AMOUNT, proofs[2]);

        // second claim should fail
        vm.expectRevert(
            MerkleAirdrop.MerkleAirdrop_AirdropAlreadyClaimed.selector
        );
        airdrop.claim(user3, AIRDROP_AMOUNT, proofs[2]);
        vm.stopPrank();
    }
}