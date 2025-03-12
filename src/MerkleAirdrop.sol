// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

//Safe ERC handles the error if for some reason the transfer of token got failed
import { IERC20, SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import { MerkleProof } from "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

contract MerkleAirdrop {
    using SafeERC20 for IERC20; // we are calling funtions defines in SafeERC for every type IERC20 in this contract

    error MerkleAirdrop_InvalidProof();
    error MerkleAirdrop_AirdropAlreadyClaimed();

    bytes32 private immutable i_merkleRoot;
    IERC20 private immutable i_airdropToken;
    mapping(address claimer => bool claimed) s_hasClaimed; //this will track who has already claimed

    event Claim(address account, uint256 amount);

    constructor(bytes32 _merkleRoot, IERC20 _airdropToken) {
        i_merkleRoot = _merkleRoot;
        i_airdropToken = _airdropToken;
    }

    function claim(address account, uint256 amount, bytes32[] calldata merkleProof) external {
        if(s_hasClaimed[account]) {
            revert MerkleAirdrop_AirdropAlreadyClaimed();
        }
        // generate how leaf hash will look like, hash of data userAddress + amount
        // standard is to hash the data twice to avoid clashes (pre image attacks)
        bytes32 leaf =  keccak256(bytes.concat(keccak256(abi.encode(account, amount))));

        // merkleProofs are basically a set of hash which re genrated path from root to leaf
        // verify function verifies this path. By iterating on proof array and comparing hash with previously computed hash
        if(!MerkleProof.verify(merkleProof, i_merkleRoot, leaf)) {
            revert MerkleAirdrop_InvalidProof();
        }

        emit Claim(account, amount);
        s_hasClaimed[account] = true;

        //safe transfer the tokens
        i_airdropToken.safeTransfer(account, amount);
    }

    function getMerkleRoot() external view returns (bytes32) {
        return i_merkleRoot;
    }

    function getAirdropToken() external view returns (IERC20) {
        return i_airdropToken;
    }
}