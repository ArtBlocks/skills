---
name: discover-artblocks-projects
description: Browse, search, and explore Art Blocks projects, collections, and collector portfolios using artblocks-mcp. Use when a user wants to find, filter, browse, or explore Art Blocks projects by name, artist, vertical, chain, tag, floor price, or mintability status, or when asking what is minting now, what is dropping soon, what tokens a wallet holds, or to get a portfolio summary. Uses discover_projects, get_project, discover_live_mints, discover_upcoming_releases, get_wallet_summary, get_wallet_tokens, get_artist, and list_tags.
---

# Discovering Art Blocks Projects

## Choosing the Right Tool

| Goal                                         | Tool                         |
| -------------------------------------------- | ---------------------------- |
| What's minting right now?                    | `discover_live_mints`        |
| What's dropping soon?                        | `discover_upcoming_releases` |
| Browse/filter by vertical, artist, chain, tag | `discover_projects`         |
| Full details on a known project              | `get_project`                |
| All projects by a specific artist            | `get_artist`                 |
| High-level portfolio summary for a collector | `get_wallet_summary`         |
| Individual tokens a collector owns           | `get_wallet_tokens`          |
| See available tags for filtering             | `list_tags`                  |

## Resource: `artblocks://about`

Fetch this resource first if you need platform context — it covers vocabulary, verticals, chains, tags, user profiles, and a quick-start guide for which tool to use.

## Tool: `discover_projects`

Browses and filters Art Blocks collections with optional text search, chain, vertical, tag, floor price, and mintability filters. Returns project metadata with truncated descriptions, floor price, mint progress, featured token image, and a direct artblocks.io link. Test/dev projects (unassigned vertical) are excluded by default.

### Filters

| Param              | Type    | Notes                                                                                                             |
| ------------------ | ------- | ----------------------------------------------------------------------------------------------------------------- |
| `search`           | string  | Searches project name and artist name (case-insensitive partial match)                                            |
| `artistName`       | string  | Filter by artist name (case-insensitive partial match)                                                            |
| `chainId`          | number  | `1` (Ethereum), `42161` (Arbitrum), `8453` (Base)                                                                 |
| `verticalName`     | string  | See verticals below                                                                                               |
| `mintable`         | boolean | `true` = actively mintable projects only                                                                          |
| `tag`              | string  | Filter by tag (e.g. `"ab500"`, `"animated"`, `"curated series 1"`). Use `list_tags` to see all available tags.    |
| `minFloorPrice`    | number  | Minimum floor price in ETH                                                                                        |
| `maxFloorPrice`    | number  | Maximum floor price in ETH — only returns projects with a listing at or below this price                          |
| `isArtblocks`      | boolean | `true` = Art Blocks flagship only, `false` = Engine only, omit for all                                            |
| `includeUnassigned`| boolean | Include test/dev projects (default false)                                                                         |
| `sortBy`           | string  | `newest` (default), `oldest`, `name_asc`, `recently_updated`, `floor_asc`, `floor_desc`, `most_collected`, `edition_size_desc` |
| `limit`            | number  | Default 25, max 200                                                                                               |
| `offset`           | number  | For pagination                                                                                                    |

### Verticals

| Value          | Description                                           |
| -------------- | ----------------------------------------------------- |
| `curated`      | Art Blocks Curated — highest-curation tier            |
| `studio`       | Art Blocks Studio — artist-driven projects            |
| `presents`     | Art Blocks Presents                                   |
| `explorations` | Art Blocks Explorations                               |
| `playground`   | Art Blocks Playground                                 |
| `flex`         | Art Blocks Flex — scripts with off-chain dependencies |
| `fullyonchain` | Fully on-chain — no external dependencies             |

## Tool: `get_project`

Returns full details for a single project. Use this when you need more than `discover_projects` provides — it returns the **complete untruncated description**, **trait/feature distribution with per-value rarity percentages**, artist profiles, tags, floor price, mint progress, minting config, featured token image, and artblocks.io link.

| Param       | Type   | Notes                                                           |
| ----------- | ------ | --------------------------------------------------------------- |
| `projectId` | string | Full project ID (e.g. `"0xa7d8...d270-78"`). Provide this or slug. |
| `slug`      | string | Project slug (e.g. `"fidenza-by-tyler-hobbs"`). Provide this or projectId. |

Key fields unique to `get_project` (not in `discover_projects`):
- `featureFields` — trait distribution: each feature name with all values, counts, and rarity percentages
- Full `description` (not truncated — `discover_projects` truncates at ~800 chars)

## Tool: `get_artist`

Looks up an artist and returns all their projects with metadata, floor price, tags, and artblocks.io links. Search by name (partial), profile slug (exact), or wallet address.

| Param          | Type   | Notes                                                   |
| -------------- | ------ | ------------------------------------------------------- |
| `artistName`   | string | Case-insensitive partial match                          |
| `artistSlug`   | string | Exact profile slug (e.g. `"tyler-hobbs"`)               |
| `artistAddress`| string | Wallet address (exact match)                            |
| `chainId`      | number | Optional chain filter                                   |
| `limit`        | number | Max projects to return (1–100, default 50)              |

At least one of `artistName`, `artistSlug`, or `artistAddress` is required.

## Tool: `discover_live_mints`

Returns projects currently active, unpaused, not complete, and past their start date. Ordered by most recently started. Includes minter type, pricing, supply, and artblocks.io links.

| Param     | Type   | Notes                         |
| --------- | ------ | ----------------------------- |
| `search`  | string | Filter by project/artist name |
| `chainId` | number | `1`, `42161`, `8453`          |
| `limit`   | number | Default 25, max 200           |

## Tool: `discover_upcoming_releases`

Returns projects with a future `start_datetime`, ordered by soonest first. Includes minter configuration and artblocks.io links.

| Param     | Type   | Notes                         |
| --------- | ------ | ----------------------------- |
| `search`  | string | Filter by project/artist name |
| `chainId` | number | `1`, `42161`, `8453`          |
| `limit`   | number | Default 25, max 100           |

## Tool: `list_tags`

Returns all distinct tag names that can be used with the `discover_projects` `tag` filter. No parameters. Common tags: `"ab500"`, `"animated"`, `"interactive"`, `"audio"`, `"responsive"`, `"curated series 1"`, `"evolving"`.

## Tool: `get_wallet_summary`

High-level portfolio summary for an Art Blocks collector. Returns total token count, unique project count, chain distribution, and a per-project breakdown (project name, artist, token count, artblocks.io link) sorted by number held.

| Param           | Type   | Notes                                                                             |
| --------------- | ------ | --------------------------------------------------------------------------------- |
| `walletAddress` | string | Wallet address or ENS name. Provide this or `username` (at least one required).   |
| `username`      | string | Art Blocks username — aggregates across all linked wallets.                        |
| `chainId`       | number | Optional chain filter                                                             |
| `projectId`     | string | Filter to a specific project                                                      |
| `limit`         | number | Max projects in breakdown (1–100, default 25)                                     |
| `offset`        | number | Pagination offset                                                                 |

## Tool: `get_wallet_tokens`

Returns individual Art Blocks tokens owned by a collector with project context, media URLs, features/traits, mint date, and artblocks.io links.

| Param           | Type   | Notes                                                                             |
| --------------- | ------ | --------------------------------------------------------------------------------- |
| `walletAddress` | string | Wallet address or ENS name. Provide this or `username` (at least one required).   |
| `username`      | string | Art Blocks username — aggregates across all linked wallets.                        |
| `chainId`       | number | Optional chain filter                                                             |
| `projectId`     | string | Filter to tokens from a specific project                                          |
| `sortBy`        | string | `recently_collected` (default), `first_collected`, `newest_mint`, `oldest_mint`   |
| `limit`         | number | Default 100, max 250                                                              |
| `offset`        | number | For pagination                                                                    |

## User Profiles and Linked Wallets

Art Blocks users can link multiple wallets to a single profile. `get_wallet_summary`, `get_wallet_tokens`, and `check_allowlist_eligibility` all accept either a `walletAddress` (including ENS) or an Art Blocks `username`. When a profile is found, tokens and eligibility are aggregated across **all linked wallets**, giving a complete view of a collector's holdings.

## Project ID Format

The `id` field in results is the full project ID used by all downstream tools:

`<contract_address>-<project_index>`

Example: `0xa7d8d9ef8d8ce8992df33d8b8cf4aebabd5bd270-0`

Use this directly with `get_project`, `get_project_minter_config`, `build_purchase_transaction`, and `check_allowlist_eligibility`.

## Following Up with GraphQL

The domain-specific tools above handle most use cases. For deeper data (sales history, aggregations, custom joins), use the GraphQL tools (`graphql_query`, `build_query`, `explore_table`) as an escape hatch.

## Pagination

```
# Page 1
discover_projects(tag: "ab500", sortBy: "floor_asc", limit: 25, offset: 0)

# Page 2
discover_projects(tag: "ab500", sortBy: "floor_asc", limit: 25, offset: 25)
```
