
# 📘 Virtual IP Rights Exchange

A decentralized platform enabling creators to mint, list, and trade their **digital intellectual property (IP)** securely with **on-chain royalty tracking**, **ownership transfer**, and **premium content grading**.

---

## 🚀 Overview

The **Virtual IP Rights Exchange** empowers content creators to:

* Mint digital intellectual assets as tradable NFTs.
* Assign commission structures and licensing durations.
* Track acquisitions and ownership rights.
* Enforce royalty payments for creators on final usage.
* Establish reputation metrics for trusted contributors.

---

## 📦 Features

### ✅ Asset Minting

Creators can tokenize their digital content with metadata, access restrictions, and premium classification:

* Content summary and CDN path storage
* Commission rate enforcement
* Validity duration and grading bounds
* Portfolio tracking (latest 10 assets per creator)

### ✅ Ownership Acquisition

Buyers can acquire usage rights for assets:

* Funds are transferred to the original creator.
* Ownership is time-bound based on the asset's validity.
* Assets marked as *"RIGHTS\_TRANSFERRED"* after acquisition.

### ✅ Acquisition Finalization

Holders finalize their acquisition after rights duration:

* Royalties and surcharges are calculated.
* Premium classification affects cost.
* Creator reputation is incremented.

### ✅ Account Funding

Users can fund their wallet ledger using `fund-account`.

### ✅ Asset Withdrawal

Creators can withdraw unclaimed assets from the market.

---

## 🧠 Data Structures

* **`intellectual-property-vault`**: Stores asset metadata and lifecycle status.
* **`wallet-ledger`**: Tracks account balances.
* **`creator-merit-index`**: Creator reputation scores.
* **`client-acquisition-ledger`**: Tracks recent assets per user (max 10).

---

## ⚙️ Contract Functions

### 🛠 Public Functions

| Function               | Description                                             |
| ---------------------- | ------------------------------------------------------- |
| `mint-virtual-asset`   | Mint a new IP asset with metadata and royalty config    |
| `acquire-rights`       | Purchase rights to an asset                             |
| `finalize-acquisition` | Complete asset usage after time delay and pay royalties |
| `withdraw-from-market` | Remove an asset from active listing                     |
| `fund-account`         | Fund your wallet with testnet tokens                    |

### 🔍 Read-Only Queries

| Function                 | Description                                       |
| ------------------------ | ------------------------------------------------- |
| `query-asset-metadata`   | Get asset metadata and status                     |
| `view-account-balance`   | Check wallet balance                              |
| `fetch-creator-standing` | View a creator’s reputation                       |
| `list-owned-assets`      | View the assets owned by a user                   |
| `compute-premium-factor` | Return premium multiplier based on classification |

---

## 🧪 Sample Workflow

1. **Fund your account**

   ```clojure
   (contract-call? .virtual-ip-exchange fund-account u1000)
   ```

2. **Mint a new IP asset**

   ```clojure
   (contract-call? .virtual-ip-exchange 
     mint-virtual-asset 
     u500 u10 u100 u3 
     "https://cdn.com/ip.mp4" "IP summary")
   ```

3. **Acquire asset rights**

   ```clojure
   (contract-call? .virtual-ip-exchange acquire-rights u1)
   ```

4. **Finalize acquisition (after duration)**

   ```clojure
   (contract-call? .virtual-ip-exchange finalize-acquisition u1)
   ```

---

## 📒 Error Codes

| Code   | Meaning                        |
| ------ | ------------------------------ |
| `u201` | Access denied                  |
| `u202` | Rights already claimed         |
| `u203` | Insufficient funds             |
| `u204` | Item not found                 |
| `u205` | Rights transfer too early      |
| `u206` | Data volume too small          |
| `u207` | Commission out of bounds       |
| `u208` | Invalid rights duration        |
| `u209` | Invalid item handle            |
| `u210` | Invalid premium classification |
| `u211` | Asset was withdrawn            |
| `u212` | Quantum too small              |
| `u213` | CDN path is empty              |
| `u214` | Content summary is empty       |

---

## 📈 Reputation System

Creators earn 1 point per successful acquisition finalization, stored in `creator-merit-index`. This can be used for leaderboards or premium visibility in dApps.

---

## 🧩 Future Improvements

* NFT metadata standardization (e.g., SIP-009)
* External royalty enforcement
* Delegated asset rights
* Integration with decentralized CDN (e.g., Arweave/IPFS)
