---
name: get-artist
description: Look up an Art Blocks artist and their body of work using artblocks-mcp. Use when a user wants to find an artist, see their projects, explore an artist's portfolio, or search by artist name, slug, or wallet address using get_artist.
---

# Looking Up Art Blocks Artists

## Tool: `get_artist`

Finds an artist and returns all their Art Blocks projects with full metadata, floor prices, tags, and direct artblocks.io links. Results are ordered by most recently launched.

## Search Options

Provide at least one — they can be combined:

| Param          | Type   | Notes                                                          |
| -------------- | ------ | -------------------------------------------------------------- |
| `artistName`   | string | Case-insensitive partial match (e.g. `"hobbs"` finds Tyler Hobbs) |
| `artistSlug`   | string | Exact artist profile slug (e.g. `"tyler-hobbs"`)               |
| `artistAddress`| string | Artist's wallet address (exact match)                          |
| `chainId`      | number | Optional — filter projects to a specific chain                 |
| `limit`        | number | Max projects to return (1–100, default 50)                     |

## Response Shape

```
artistNames        — deduplicated list of artist display names matched
artistProfiles     — unique artist profile objects: { slug, displayName }
totalProjects      — total project count matching the query
projects[]         — array of project objects, each containing:
  id                 — full project ID (contract_address-project_index)
  name, artistName, description, slug
  artBlocksUrl       — direct link to project on artblocks.io
  chainId, contractAddress, projectIndex
  verticalName, verticalDisplay, curationStatus
  active, paused, complete, invocations, maxInvocations, remaining
  startDatetime, completedAt
  aspectRatio, scriptTypeAndVersion, renderComplete
  website, license
  lowestListing      — floor price in ETH (null if no listings)
  featuredTokenImageUrl — hero image URL (null if none)
  tags[]             — tag name strings (e.g. "ab500", "animated")
  artistProfiles[]   — { slug, displayName }
```

## When to Use vs Other Tools

| Use `get_artist` when...                              | Use something else when...                        |
| ----------------------------------------------------- | ------------------------------------------------- |
| You want all projects by a specific artist             | You want to browse projects broadly → `discover_projects` |
| You know the artist's name, slug, or wallet address    | You have a specific project ID → `get_project`    |
| You want to compare an artist's body of work           | You need token-level data → `get_token_metadata`  |

## Notes

- Results include `artBlocksUrl` for each project — use these when presenting projects to users
- The `artistSlug` field in results (under `artistProfiles`) can be used for subsequent lookups
- The tool excludes unassigned/test projects automatically
- If the artist name is ambiguous (partial match returns multiple artists), the `artistNames` array will show all matched names
- `projectIndex` is the project number on the contract (e.g. `78`); `id` is the full project ID (e.g. `0xa7d8...d270-78`)
