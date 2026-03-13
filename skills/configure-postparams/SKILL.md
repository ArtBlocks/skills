---
name: configure-postparams
description: Configure PostParam (Post-Mint Parameter / PMP) values on Art Blocks tokens using artblocks-mcp. Use when a user wants to customize, update, or set on-chain parameters on a minted token, or when working with build_configure_postparams_transaction, discover_postparams, or post-mint configuration.
---

# Configuring PostParams on Art Blocks Tokens

## What Are PostParams?

PostParams (Post-Mint Parameters / PMP) are on-chain configurable parameters embedded in certain Art Blocks art scripts. After minting, authorized wallets can set values that directly affect the token's on-chain visual output — no re-mint required.

Each parameter has an `authOption` controlling who can configure it:

| `authOption` | Who can configure |
|---|---|
| `Artist` | Project artist only |
| `TokenOwner` | Current token owner only |
| `Address` | A specific configured contract address only |
| `ArtistAndTokenOwner` | Artist or token owner |
| `ArtistAndAddress` | Artist or specific contract address |
| `TokenOwnerAndAddress` | Token owner or specific contract address |
| `ArtistAndTokenOwnerAndAddress` | Artist, token owner, or specific contract address |

## Token ID Format

`<contract_address>-<token_number>`

Example: `0xa7d8d9ef8d8ce8992df33d8b8cf4aebabd5bd270-78000000`

## Workflow

### Step 1 — Discover available params

```
discover_postparams(tokenId, chainId?)
```

Returns: param keys, types, value constraints, current values, and `authOption` for each param. Always show this to the user before asking for values — they need to know what's configurable and within what constraints.

### Step 2 — Build the configuration transaction

```
build_configure_postparams_transaction(tokenId, values, chainId?, signerAddress?)
```

- `values` is a key-value object — keys must match param keys from `discover_postparams`
- Always pass `signerAddress` when known — needed to determine artist status and validate authorization
- One transaction configures all passed params at once

Returns an unsigned transaction object ready to sign and submit.

## Value Formats by Type

| Type           | Format                              | Example           |
|----------------|-------------------------------------|-------------------|
| `Bool`         | `"true"` or `"false"`              | `"true"`          |
| `Select`       | One of the allowed option strings   | `"red"`           |
| `Uint256Range` | Non-negative integer string         | `"42"`            |
| `Int256Range`  | Integer string (can be negative)    | `"-5"`            |
| `DecimalRange` | Decimal string                      | `"3.14"`          |
| `HexColor`     | Hex color with `#`                  | `"#FF0000"`       |
| `Timestamp`    | Unix timestamp in seconds           | `"1700000000"`    |
| `String`       | Any text string                     | `"hello world"`   |

## Notes

- **Always call `discover_postparams` first** — param keys and types are project-specific and not guessable
- **`String` params**: the `configuringArtistString` flag on the built transaction depends on whether `signerAddress` matches the project artist — always pass `signerAddress` for `String` type params
- **Authorization**: if the user's address doesn't match the `authOption` for a param, the transaction will revert on-chain. Check `authOption` against the user's role before proceeding
- **One transaction per call**, but you can configure multiple params in a single call by passing multiple keys in `values`
