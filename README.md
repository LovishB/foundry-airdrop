# Bagel Token & Merkle Airdrop

This repository contains Solidity smart contracts for the Bagel Token (BT) ERC20 token and a Merkle tree-based airdrop system that allows for secure and gas-efficient token distribution.

## Contracts

### BagelToken.sol

A simple ERC20 token contract with minting capabilities restricted to the contract owner.

### MerkleAirdrop.sol

A contract that enables token distribution using Merkle proofs for verification. It includes features for both direct claiming and claiming with signature authorization.

## Features

- **ERC20 Token**: Standard-compliant token with minting capability
- **Merkle Tree Airdrop**: Gas-efficient token distribution
- **Multiple Claim Methods**:
  - Direct claiming by eligible addresses
  - Claim via signature authorization (both combined and split-signature formats)
- **Anti-fraud Protection**:
  - Merkle proof verification to validate eligibility
  - EIP-712 signature verification for delegated claims
  - Protection against double-claiming

## Technical Details

### Merkle Tree Implementation

The airdrop uses a Merkle tree approach where:
- Leaves are generated from `keccak256(keccak256(abi.encode(account, amount)))`
- Verification is performed using OpenZeppelin's MerkleProof library
- Double-claiming is prevented through a mapping of claimed addresses

### Signature Verification

For delegated claims, the contract implements EIP-712 typed signatures:
- Structured data format follows the EIP-712 standard
- Domain separator and type hash are used for signature verification
- Supports both combined signatures and split v,r,s components

## Getting Started

### Prerequisites

- Node.js and npm
- Hardhat or Truffle
- OpenZeppelin Contracts

### Installation

1. Clone the repository:
```bash
git clone https://github.com/yourusername/bagel-token.git
cd bagel-token
```

2. Install dependencies:
```bash
npm install
```

### Deployment

1. Set up your environment variables in a `.env` file:
```
PRIVATE_KEY=your_private_key
INFURA_API_KEY=your_infura_api_key
```

2. Deploy the contracts:
```bash
npx hardhat run scripts/deploy.js --network <network_name>
```

## Airdrop Setup

To set up an airdrop:

1. Generate a Merkle root from your airdrop list
2. Deploy the BagelToken contract
3. Mint tokens to the MerkleAirdrop contract address
4. Deploy the MerkleAirdrop contract with the Merkle root and token address

## Usage

### Claiming Tokens

Eligible users can claim their tokens through one of these methods:

#### Direct Claim
```javascript
await merkleAirdrop.claim(userAddress, amount, merkleProof);
```

#### Signature-Based Claim
```javascript
const signature = await wallet.signTypedData(/* EIP-712 formatted data */);
await merkleAirdrop.claimWithSignature(userAddress, amount, merkleProof, signature);
```

## Security

The contracts implement several security measures:
- SafeERC20 for safe token transfers
- Signature verification to prevent unauthorized claims
- Prevention of double-claiming
- Double-hashing of leaf data to prevent pre-image attacks

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Acknowledgements

- OpenZeppelin for their secure contract libraries
- EIP-712 for the structured data signing standard
