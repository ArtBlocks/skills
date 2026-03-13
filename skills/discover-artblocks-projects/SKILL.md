---
name: discover-artblocks-projects
description: Browse and search Art Blocks projects and collections using artblocks-mcp. Use when a user wants to find, filter, browse, or explore Art Blocks projects by name, artist, vertical, chain, or mintability status, or when asking what is minting now, what is dropping soon, or what tokens a wallet holds. Uses discover_projects, discover_live_mints, discover_upcoming_releases, and get_wallet_tokens.
---

# Discovering Art Blocks Projects

## Choosing the Right Tool

| Goal | Tool |
|------|------|
| What's minting right now? | `discover_live_mints` |
| What's dropping soon? | `discover_upcoming_releases` |
| Browse/filter by vertical, artist, chain | `discover_projects` |
| What does a wallet own? | `get_wallet_tokens` |

## Tool: `discover_live_mints`

Returns projects that are currently active, unpaused, not complete, and have already started. Ordered by most recently started.

| Param     | Type   | Notes                          |
|-----------|--------|--------------------------------|
| `search`  | string | Filter by project/artist name  |
| `chainId` | number | `1`, `42161`, `8453`           |
| `limit`   | number | Default 10, max 50             |

## Tool: `discover_upcoming_releases`

Returns projects with a future `start_datetime` or future auction start time, ordered by soonest first.

| Param     | Type   | Notes                          |
|-----------|--------|--------------------------------|
| `search`  | string | Filter by project/artist name  |
| `chainId` | number | `1`, `42161`, `8453`           |
| `limit`   | number | Default 10, max 50             |

## Tool: `get_wallet_tokens`

Returns Art Blocks tokens owned by a wallet address.

| Param           | Type    | Notes                                                                               |
|-----------------|---------|-------------------------------------------------------------------------------------|
| `walletAddress` | string  | Required. Ethereum wallet address.                                                  |
| `chainId`       | number  | Optional chain filter.                                                              |
| `projectId`     | string  | Optional — filter to tokens from a specific project.                                |
| `sortBy`        | string  | `recently_collected` (default), `first_collected`, `newest_mint`, `oldest_mint`    |
| `limit`         | number  | Default 25, max 50                                                                  |
| `offset`        | number  | For pagination                                                                      |

## Tool: `discover_projects`

Browses and filters Art Blocks collections with optional text search, chain, vertical, and mintability filters. Returns project metadata, mint progress, and a featured token image per result.

### Filters

| Param          | Type    | Notes                                                     |
|----------------|---------|-----------------------------------------------------------|
| `search`       | string  | Searches project name and artist name                     |
| `artistName`   | string  | Filter by artist name (case-insensitive partial match)    |
| `chainId`      | number  | `1` (Ethereum), `42161` (Arbitrum), `8453` (Base)        |
| `verticalName` | string  | See verticals below                                       |
| `mintable`     | boolean | `true` = actively mintable projects only                  |
| `sortBy`       | string  | `newest` (default), `oldest`, `name_asc`, `recently_updated` |
| `limit`        | number  | Default 10, max 50                                        |
| `offset`       | number  | For pagination                                            |

### Verticals

| Value          | Description                                         |
|----------------|-----------------------------------------------------|
| `curated`      | Art Blocks Curated — highest-curation tier          |
| `studio`       | Art Blocks Studio — artist-driven projects          |
| `presents`     | Art Blocks Presents                                 |
| `explorations` | Art Blocks Explorations                             |
| `playground`   | Art Blocks Playground                               |
| `flex`         | Art Blocks Flex — scripts with off-chain dependencies|
| `fullyonchain` | Fully on-chain — no external dependencies           |

## Project ID Format

The `id` field in results is the full project ID used by all downstream tools:

`<contract_address>-<project_index>`

Example: `0xa7d8d9ef8d8ce8992df33d8b8cf4aebabd5bd270-0`

Use this directly with `get_project_minter_config`, `build_purchase_transaction`, and `check_allowlist_eligibility`.

## Following Up with GraphQL

`discover_projects` is optimized for browsing. For deeper data (traits distribution, sales history, minter config details, script source), use the GraphQL tools:

```graphql
query {
  projects_metadata(where: { id: { _eq: "0xa7d8d9ef8d8ce8992df33d8b8cf4aebabd5bd270-0" } }) {
    id
    name
    artist_address
    description
    script_type
    invocations
    max_invocations
    minter_configuration {
      base_price
      currency_symbol
    }
    tokens(limit: 5, order_by: { invocation: asc }) {
      token_id
      features
    }
  }
}
```

## Pagination

```
# Page 1
discover_projects(search: "geometry", verticalName: "curated", limit: 10, offset: 0)

# Page 2
discover_projects(search: "geometry", verticalName: "curated", limit: 10, offset: 10)
```
