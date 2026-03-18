---
name: mint-artblocks-token
description: Mint (purchase) an Art Blocks token using the artblocks-mcp tools. Use when a user wants to mint, purchase, or buy an Art Blocks NFT, or needs to understand minting mechanics, minter types, pricing, allowlists, Dutch auctions, or build_purchase_transaction.
---

# Minting an Art Blocks Token

## Project ID Format

All minting tools require a full project ID: `<contract_address>-<project_index>`

Example: `0xa7d8d9ef8d8ce8992df33d8b8cf4aebabd5bd270-0`

Use `discover_projects` to find the project ID from a name or search term. To find projects currently open for minting, pass `mintable: true` — this filters to only projects with active minters and remaining supply.

## Minting Workflow

### Step 1 — Understand the minter

Call `get_project_minter_config` first. Returns:

- Minter type (set price, Dutch auction, allowlist, RAM, etc.)
- Current price and currency (ETH or ERC-20)
- Remaining supply (`max_invocations - invocations`)
- Auction timing (start/end, price decay curve for DA minters)
- Allowlist details (for gated minters)

### Step 2 — Check eligibility (gated projects only)

If the minter type is `MinterMerkleV5` or `MinterHolderV5`, call `check_allowlist_eligibility` before proceeding.

Accepts a `walletAddress` (including ENS names) or an Art Blocks `username`. When the input resolves to an Art Blocks profile, **all wallets linked to that profile are checked** for eligibility. At least one of `walletAddress` or `username` is required.

| Param           | Type   | Notes                                                                      |
| --------------- | ------ | -------------------------------------------------------------------------- |
| `projectId`     | string | Required. Full project ID.                                                 |
| `walletAddress` | string | Wallet address or ENS name. Provide this or `username`.                    |
| `username`      | string | Art Blocks username — checks all linked wallets.                           |
| `chainId`       | number | Default `1`. `1`, `42161`, `8453`.                                         |

Returns: eligibility status, gate type, which wallets are eligible (for multi-wallet profiles), and for holder-gated minters, which projects the wallet must hold tokens from.

### Step 3 — Build the transaction

`build_purchase_transaction` currently supports **MinterSetPriceV5 (ETH)** only.

| Param        | Required | Notes                                                                                                                                 |
| ------------ | -------- | ------------------------------------------------------------------------------------------------------------------------------------- |
| `projectId`  | yes      | `<contract_address>-<project_index>`                                                                                                  |
| `chainId`    | —        | Default `1`. See chain IDs below.                                                                                                     |
| `purchaseTo` | —        | Mint to a different address (gifting). Check `purchaseTo.disabled` in `get_project_minter_config` first — some projects disable this. |

Returns `{ transaction, project, minter, price, purchaseTo, warnings }`. The `warnings` array contains non-fatal issues (paused project, sold out, complete) — always surface these to the user before they sign.

## Minter Types

| Minter             | Description                           | `build_purchase_transaction` |
| ------------------ | ------------------------------------- | ---------------------------- |
| `MinterSetPriceV5` | Fixed ETH price                       | Supported                    |
| `MinterDAExpV5`    | Dutch auction — exponential decay     | Use wallet directly          |
| `MinterDALinV5`    | Dutch auction — linear decay          | Use wallet directly          |
| `MinterMerkleV5`   | Merkle allowlist gating               | Use wallet directly          |
| `MinterHolderV5`   | Holder-gated (must own another token) | Use wallet directly          |
| `RAM`              | Ranked auction mechanism              | Use wallet directly          |

For unsupported minters, explain the mechanics from `get_project_minter_config` data and direct the user to their wallet.

## Chain IDs

| Chain            | ID      |
| ---------------- | ------- |
| Ethereum mainnet | `1`     |
| Arbitrum         | `42161` |
| Base             | `8453`  |

## Notes

- **User profiles**: When a wallet address or username resolves to an Art Blocks profile, eligibility is checked across all linked wallets. The response includes `walletAddresses` (all checked), `profile` info, and for Merkle gates, `eligibleWallets` showing which specific wallets passed.
- **ERC-20 projects**: `get_project_minter_config` indicates the currency token address. `build_purchase_transaction` only supports ETH — direct ERC-20 users to their wallet.
- **Dutch auctions**: current price decreases over time. Use `start_price`, `end_price`, `auction_start_time`, and `auction_end_time` from `get_project_minter_config` to explain current pricing.
- **`purchaseTo`**: useful for gifting — mints the token directly to a recipient address instead of the signer.
