---
name: query-artblocks-data
description: Query Art Blocks on-chain data using the artblocks-mcp GraphQL tools. Use when fetching projects, tokens, artists, sales, traits, or any Art Blocks on-chain data via graphql_query, build_query, explore_table, graphql_introspection, validate_fields, or query_optimizer. These are advanced escape-hatch tools — prefer domain-specific tools (discover_projects, get_project, get_artist, get_wallet_tokens, get_token_metadata) when they cover the use case.
---

# Querying Art Blocks Data

## When to Use GraphQL vs Domain Tools

The domain-specific tools cover most use cases and are easier to use:

| Need | Tool |
|------|------|
| Browse/search projects | `discover_projects` |
| Full project details | `get_project` |
| Artist's body of work | `get_artist` |
| Portfolio overview | `get_wallet_summary` |
| Collector's tokens | `get_wallet_tokens` |
| Token details | `get_token_metadata` |
| Live mints | `discover_live_mints` |
| Upcoming drops | `discover_upcoming_releases` |
| Mint eligibility | `check_allowlist_eligibility` |

Use the GraphQL tools below as an **escape hatch** for custom queries not covered above — sales history, aggregations, complex joins, or tables without a dedicated tool.

## Resource: `artblocks://about`

Fetch this resource for platform context — vocabulary, verticals, chains, tags, user profiles, and a guide to which tool handles what.

## Tool Hierarchy

Use tools in this order — skip steps you don't need:

1. **Discover schema** → `explore_table` (single table with fields + relationships) or `graphql_introspection` (full schema)
2. **Build a validated query** → `build_query` (validates fields, adds suggestions, auto-filters by chain)
3. **Optimize** → `query_optimizer` (rewrites to preferred tables, e.g. `projects_metadata` over `projects`)
4. **Execute** → `graphql_query`

If you already know the schema, go straight to `build_query` → `graphql_query`.

## Tool: `explore_table`

For well-known tables (`projects_metadata`, `tokens_metadata`), returns a curated shortlist of the most useful fields organized by category (Identity, Status, Media, Market, etc.) plus key relationships with suggested subfields. Pass `showAllFields: true` to see the full schema dump instead.

| Param          | Required | Notes                                                   |
| -------------- | -------- | ------------------------------------------------------- |
| `tableName`    | yes      | Table to explore                                        |
| `showAllFields`| —        | `true` for full schema dump (default: curated shortlist)|

## Preferred Tables

Always use the `_metadata` variants — they include richer joined data:

| Use this              | Not this    |
|-----------------------|-------------|
| `projects_metadata`   | `projects`  |
| `tokens_metadata`     | `tokens`    |
| `contracts_metadata`  | `contracts` |

`query_optimizer` will automatically rewrite queries that use the wrong table.

## Chain IDs

| Chain            | ID      |
|------------------|---------|
| Ethereum mainnet | `1` (default) |
| Arbitrum         | `42161` |
| Base             | `8453`  |

Pass `chainId` to `graphql_query` to make `$chainId` available as a variable in your query.

## Common Query Patterns

These examples show queries that **require** raw GraphQL — things the domain tools can't do.

### Recent sales (no domain tool covers purchases)
```graphql
query {
  purchases_metadata(
    order_by: { block_timestamp: desc }
    limit: 20
    where: { chain_id: { _eq: 1 } }
  ) {
    token_id
    price_in_eth
    block_timestamp
    buyer_address
    seller_address
  }
}
```

### Aggregate token count by owner for a project
```graphql
query {
  tokens_metadata_aggregate(
    where: { project_id: { _eq: "0xa7d8d9ef8d8ce8992df33d8b8cf4aebabd5bd270-78" } }
    distinct_on: owner_address
  ) {
    aggregate { count }
  }
}
```

### All tokens for a project (domain tools only return per-wallet)
```graphql
query {
  tokens_metadata(
    where: { project_id: { _eq: "0xa7d8d9ef8d8ce8992df33d8b8cf4aebabd5bd270-0" } }
    order_by: { invocation: asc }
    limit: 50
  ) {
    token_id
    invocation
    owner_address
    features
  }
}
```

### Projects with specific on-chain attributes
```graphql
query {
  projects_metadata(
    where: {
      script_type_and_version: { _ilike: "%three%" }
      chain_id: { _eq: 1 }
      complete: { _eq: false }
    }
    limit: 20
  ) {
    id
    name
    artist_name
    script_type_and_version
    invocations
    max_invocations
  }
}
```

## Tips

- Use `explore_table` to understand fields and relationships before writing a query — the curated view is much easier to scan than the full schema dump
- `build_query` is the safest way to start — it validates fields and tells you what's available
- Always pass `chainId` when querying multi-chain data to avoid cross-chain noise
- For unknown fields, `validate_fields` is faster than a full introspection
