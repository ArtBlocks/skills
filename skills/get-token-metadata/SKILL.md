---
name: get-token-metadata
description: Retrieve rich metadata for a specific Art Blocks token using artblocks-mcp. Use when a user wants to look up a minted token's details, traits, features, media URLs, owner, live view, or project context using get_token_metadata.
---

# Getting Art Blocks Token Metadata

## Tool: `get_token_metadata`

Retrieves a single token's full metadata in one call — traits, media URLs, owner, hash, and project context. Prefer this over `graphql_query` when you need rich token details for a known token ID.

## Token ID Format

`<contract_address>-<token_number>`

Example: `0xa7d8d9ef8d8ce8992df33d8b8cf4aebabd5bd270-78000000`

## Parameters

| Param     | Required | Notes                                      |
|-----------|----------|--------------------------------------------|
| `tokenId` | ✅       | Full token ID `<contract_address>-<token_number>` |
| `chainId` | —        | Default `1` (Ethereum). `1`, `42161` (Arbitrum), `8453` (Base) |

## Response Shape

```
token:
  id, tokenId, chainId, contractAddress, projectId
  hash           — 32-byte hex, the source of all randomness
  invocation     — mint number within the project (0-indexed)
  features       — on-chain traits object
  mintedAt, mintTransactionHash
  ownerAddress

media:
  imageUrl       — primary rendered image
  previewUrl     — preview asset URL
  liveViewUrl    — live interactive generator URL
  hasVideo       — true if a video render exists

project:
  id, name, artistName, description, website, license
  scriptTypeAndVersion
  maxInvocations, invocations, active, paused, complete
  aspectRatio, curationStatus, verticalName, renderComplete
```

## When to Use vs GraphQL

| Use `get_token_metadata` when... | Use `graphql_query` when... |
|---|---|
| You have a specific token ID and want everything about it | You need to query multiple tokens at once |
| You need media URLs (`liveViewUrl`, `imageUrl`) | You need fields not in this response |
| You want features + project context in one call | You're building complex filters or aggregations |

## Notes

- `liveViewUrl` is the canonical way to share or preview a generative token — always include it when presenting a token to a user
- `features` is the on-chain traits object — same data shown on Art Blocks website
- `hash` uniquely identifies the token's visual output — same hash always produces the same artwork
