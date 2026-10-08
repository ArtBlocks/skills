---
name: mint-artblocks-token
description: Mint (purchase) an Art Blocks token using the artblocks-mcp tools. Use when a user wants to mint, purchase, or buy an Art Blocks NFT, or needs to understand minting mechanics, minter types, pricing, allowlists, Dutch auctions, sliding-scale mints, or build_purchase_transaction.
---

# Minting an Art Blocks Token

This path is primary mints only. Secondary listings are not on it.

## Project ID Format

All minting tools require a full project ID: `<contract_address>-<project_index>`

Example: `0xa7d8d9ef8d8ce8992df33d8b8cf4aebabd5bd270-0`

Use `discover_projects` to find the project ID from a name or search term.

## Minting Workflow

### Step 1 — Find what is mintable now

Call `discover_live_mints`. Each result includes project id, chain, minter type, remaining supply, and price (`minting.price.wei`, `display`, and `currency`). For ERC-20 prices, `wei` is the token's smallest unit, not ETH.

Scope: projects that launched within the last 12 months and have an indexed minter. Older open mints, or projects without indexed minter metadata, are found with `discover_projects` and `mintable: true`.

### Step 2 — Understand the minter

Call `get_project_minter_config` before building a transaction. Returns:

- Minter type (set price, sliding scale, Dutch auction, allowlist, RAM, etc.)
- Current price and currency (ETH or ERC-20)
- Remaining supply (`max_invocations - invocations`)
- Auction timing (start/end, price decay curve for DA minters)
- Allowlist or holder-gate details
- `purchaseTo.disabled` — some projects refuse minting to another address

`build_purchase_transaction` supports native-ETH **MinterSetPriceV5** and **MinterSlidingScaleV\*** only. Dutch auctions, allowlists, holder gates, RAM, and ERC-20 prices are not built by the tool yet. For those, explain the mechanics from this response and direct the user to their wallet.

### Step 3 — Check eligibility (gated projects only)

If the minter type is `MinterMerkleV5` or `MinterHolderV5`, call `check_allowlist_eligibility` before proceeding. This checks eligibility only. It does not make `build_purchase_transaction` able to build those mints.

Accepts a `walletAddress` (including ENS names) or an Art Blocks `username`. When the input resolves to an Art Blocks profile, **all wallets linked to that profile are checked** for eligibility. At least one of `walletAddress` or `username` is required.

| Param           | Type   | Notes                                                   |
| --------------- | ------ | ------------------------------------------------------- |
| `projectId`     | string | Required. Full project ID.                              |
| `walletAddress` | string | Wallet address or ENS name. Provide this or `username`. |
| `username`      | string | Art Blocks username — checks all linked wallets.        |
| `chainId`       | number | Default `1`. `1`, `42161`, `8453`.                      |

Returns: eligibility status, gate type, which wallets are eligible (for multi-wallet profiles), and for holder-gated minters, which projects the wallet must hold tokens from.

### Step 4 — Build the transaction

| Param        | Required | Notes                                                                                                                                                          |
| ------------ | -------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `projectId`  | yes      | `<contract_address>-<project_index>`                                                                                                                           |
| `chainId`    | —        | Default `1`. See chain IDs below.                                                                                                                              |
| `purchaseTo` | —        | Mint to a different address (gifting). Check `purchaseTo.disabled` in `get_project_minter_config` first — some projects disable this. Accepts an address or ENS. |
| `valueWei`   | —        | Decimal wei string, no `0x`. See pricing rules below.                                                                                                          |

Pricing rules:

- **MinterSetPriceV5:** `value` is exactly the list price. Omit `valueWei`, or set it to that exact wei amount. Any other amount errors.
- **MinterSlidingScaleV\* (ETH):** pass `valueWei` between the minimum and 20× the minimum, or omit it to use the minimum.

Returns `{ transaction, project, minter, price, purchaseTo, warnings }`. `transaction` is an unsigned `{ to, data, value, chainId }`. The `warnings` array contains non-fatal issues (paused project, sold out, complete) — always surface these to the user before they sign.

The user signs and sends that transaction from their own wallet on `chainId`. Payment and mint happen in one transaction. Art Blocks does not hold the funds. The token goes to the sender, or to `purchaseTo`. Its artwork is generated from the mint transaction hash.

## Minter Types

| Minter                 | Description                           | `build_purchase_transaction`           |
| ---------------------- | ------------------------------------- | -------------------------------------- |
| `MinterSetPriceV5`     | Fixed ETH price                       | Supported                              |
| `MinterSlidingScaleV*` | ETH price chosen by the buyer         | Supported (`valueWei`, min to 20× min) |
| `MinterDAExpV5`        | Dutch auction — exponential decay     | Not built yet                          |
| `MinterDALinV5`        | Dutch auction — linear decay          | Not built yet                          |
| `MinterMerkleV5`       | Merkle allowlist gating               | Not built yet                          |
| `MinterHolderV5`       | Holder-gated (must own another token) | Not built yet                          |
| `RAM`                  | Ranked auction mechanism              | Not built yet                          |

For unsupported minters, explain the mechanics from `get_project_minter_config` data and direct the user to their wallet.

## Chain IDs

| Chain            | ID         |
| ---------------- | ---------- |
| Ethereum mainnet | `1`        |
| Arbitrum         | `42161`    |
| Base             | `8453`     |
| Sepolia          | `11155111` |
| Hoodi            | `560048`   |

## Notes

- **User profiles**: When a wallet address or username resolves to an Art Blocks profile, eligibility is checked across all linked wallets. The response includes `walletAddresses` (all checked), `profile` info, and for Merkle gates, `eligibleWallets` showing which specific wallets passed.
- **ERC-20 projects**: `get_project_minter_config` indicates the currency token address. `build_purchase_transaction` only supports native ETH — direct ERC-20 users to their wallet.
- **Dutch auctions**: current price decreases over time. Use `start_price`, `end_price`, `auction_start_time`, and `auction_end_time` from `get_project_minter_config` to explain current pricing.
- **`purchaseTo`**: useful for gifting — mints the token directly to a recipient address instead of the signer. Skip it when `purchaseTo.disabled` is true.
