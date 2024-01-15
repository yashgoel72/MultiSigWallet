# MultiSig Smart Contract

## Overview

This Solidity smart contract implements a multi-signature wallet (MultiSig) on the Ethereum blockchain. It allows multiple owners to collectively manage and approve transactions from the wallet. Each transaction requires a predefined number of confirmations from the owners before execution.

## Development Tools

- **Foundry:** Used for the development environment, facilitating Ethereum smart contract development.

## Static Analysis and Auditing

- **Slither:** Employed for automatic static analysis, gas optimization, and auditing of the smart contract.
  
- **Gas Optimization (@audit tags):**
  - Gas optimizations are annotated with `@audit` tags for better readability and understanding during code review.


## Contract Functions

### 1. `submitTransaction`

- **Description:** Allows an owner to submit a new transaction to the wallet.
- **Modifier:** Only callable by an owner.
- **Conditions:** Transaction must not be executed, and the owner's confirmation is automatically added.
- **Events:** Emits `SubmitTransaction` event.

### 2. `approveTransaction`

- **Description:** Allows an owner to approve a pending transaction.
- **Modifier:** Only callable by an owner.
- **Conditions:** Transaction must exist, not be executed, and not be previously approved by the caller.
- **Events:** Emits `ConfirmTransaction` if the required confirmations are reached, otherwise, emits `ConfirmTransaction` for the current approval.

### 3. `revokeConfirmation`

- **Description:** Allows an owner to revoke their confirmation on a pending transaction.
- **Modifier:** Only callable by an owner.
- **Conditions:** Transaction must exist, not be executed, and the caller must have previously confirmed the transaction.
- **Events:** Emits `RevokeConfirmation` event.

### 4. `getOwners`

- **Description:** Retrieves the list of wallet owners.

### 5. `getTransactionCount`

- **Description:** Retrieves the total number of transactions in the wallet.

### 6. `getTransaction`

- **Description:** Retrieves details about a specific transaction.
- **Parameters:** Transaction index.
- **Returns:** Transaction details (to, value, data, executed, numConfirmations).

### 7. `executeTransaction` (Internal Function)

- **Description:** Executes a confirmed transaction.
- **Modifier:** Only callable by an owner.
- **Conditions:** Transaction must exist, not be executed, and have the required number of confirmations.
- **Events:** Emits `ExecuteTransaction` event.

### 8. Receive Function

- **Description:** Accepts Ether transfers to the contract.
- **Events:** Emits `Deposit` event.

## Events

The contract emits several events for transparency:

- `Deposit`: Triggered upon receiving Ether.
- `SubmitTransaction`: Triggered when a new transaction is submitted.
- `ConfirmTransaction`: Triggered when a transaction is confirmed.
- `RevokeConfirmation`: Triggered when confirmation on a transaction is revoked.
- `ExecuteTransaction`: Triggered when a transaction is executed.

## Deployment

The contract is deployed using the provided constructor, which initializes the owners and the required number of confirmations.

```solidity
constructor(address[] memory _owners, uint16 _numConfirmationsRequired) payable
