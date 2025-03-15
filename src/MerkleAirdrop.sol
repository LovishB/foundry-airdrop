// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

//Safe ERC handles the error if for some reason the transfer of token got failed
import { IERC20, SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import { MerkleProof } from "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
// ECDSA algo to verify signature
import { ECDSA } from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
// Importing 712 tx structures
import { EIP712 } from "@openzeppelin/contracts/utils/cryptography/EIP712.sol";

contract MerkleAirdrop is EIP712 {
    using SafeERC20 for IERC20; // we are calling funtions defines in SafeERC for every type IERC20 in this contract

    // Errors
    error MerkleAirdrop_InvalidProof();
    error MerkleAirdrop_AirdropAlreadyClaimed();
    error MerkleAirdrop_InvalidSignature();

    // Variables
    bytes32 private immutable i_merkleRoot;
    IERC20 private immutable i_airdropToken;
    mapping(address claimer => bool claimed) s_hasClaimed; //this will track who has already claimed
    bytes32 public constant CLAIM_TYPEHASH = keccak256("Claim(address account,uint256 amount,bytes32[] merkleProof)");

    // Events
    event Claim(address account, uint256 amount);

    constructor(bytes32 _merkleRoot, IERC20 _airdropToken) 
        EIP712("MerkleAirdrop", "1") // Initialize EIP712 tx with domain name and version, it creates domain seprator internally
    {
        i_merkleRoot = _merkleRoot;
        i_airdropToken = _airdropToken;
    }

    /**
     * @notice Original claim function - recipient claims for themselves
     * @param account The address entitled to the airdrop
     * @param amount The amount of tokens to be claimed
     * @param merkleProof The Merkle proof proving inclusion in the airdrop
     */
    function claim(
        address account, 
        uint256 amount, 
        bytes32[] calldata merkleProof
    ) external {
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

    /* @notice Claim on behalf of another address using their signature as authorization
     * @param account The address entitled to the airdrop
     * @param amount The amount of tokens to be claimed
     * @param merkleProof The Merkle proof proving inclusion in the airdrop
     * @param signature The signature from the account authorizing the claim
    */
    function claimWithSignature(
        address account, 
        uint256 amount, 
        bytes32[] calldata merkleProof,
        bytes calldata signature
    ) external {
        if(s_hasClaimed[account]) {
            revert MerkleAirdrop_AirdropAlreadyClaimed();
        }

        bytes32 leaf =  keccak256(bytes.concat(keccak256(abi.encode(account, amount))));
        if(!MerkleProof.verify(merkleProof, i_merkleRoot, leaf)) {
            revert MerkleAirdrop_InvalidProof();
        }

        // Verify Signature
        // EIP-712 tx structure
        //<0x19><0x01><domain seprator><structured data><signature>
        // Prepare the data hash using EIP-712 structured data
        bytes32 structHash = keccak256(abi.encode(
            CLAIM_TYPEHASH,
            account,
            amount,
            keccak256(abi.encodePacked(merkleProof))
        ));

        // Get the digest using OpenZeppelin's EIP-712 implementation
        bytes32 digest = _hashTypedDataV4(structHash);

        // Recover the signer from the signature
        address signer = ECDSA.recover(digest, signature);
        if (signer != account) {
            revert MerkleAirdrop_InvalidSignature();
        }

        s_hasClaimed[account] = true;
        emit Claim(account, amount);
        
        // Safe transfer the tokens to the original account (not the caller)
        i_airdropToken.safeTransfer(account, amount);
    }

    /**
     * @notice Alternative implementation using v, r, s components of the signature
     */
    function claimWithSignatureVRS(
        address account, 
        uint256 amount, 
        bytes32[] calldata merkleProof,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external {
if(s_hasClaimed[account]) {
            revert MerkleAirdrop_AirdropAlreadyClaimed();
        }

        bytes32 leaf =  keccak256(bytes.concat(keccak256(abi.encode(account, amount))));
        if(!MerkleProof.verify(merkleProof, i_merkleRoot, leaf)) {
            revert MerkleAirdrop_InvalidProof();
        }

        // Verify Signature
        // EIP-712 tx structure
        //<0x19><0x01><domain seprator><structured data><signature>
        // Prepare the data hash using EIP-712 structured data
        bytes32 structHash = keccak256(abi.encode(
            CLAIM_TYPEHASH,
            account,
            amount,
            keccak256(abi.encodePacked(merkleProof))
        ));

        // Get the digest using OpenZeppelin's EIP-712 implementation
        bytes32 digest = _hashTypedDataV4(structHash);

        // Recover the signer from the signature using v,r,s variables
        address signer = ECDSA.recover(digest, v, r, s);
        if (signer != account) {
            revert MerkleAirdrop_InvalidSignature();
        }

        s_hasClaimed[account] = true;
        emit Claim(account, amount);
        
        // Safe transfer the tokens to the original account (not the caller)
        i_airdropToken.safeTransfer(account, amount);
    }

    function getMerkleRoot() external view returns (bytes32) {
        return i_merkleRoot;
    }

    function getAirdropToken() external view returns (IERC20) {
        return i_airdropToken;
    }
}