---
name: query-artblocks-data
description: Query Art Blocks on-chain data using the artblocks-mcp GraphQL tools. Use when fetching projects, tokens, artists, sales, traits, or any Art Blocks on-chain data via graphql_query, build_query, explore_table, graphql_introspection, validate_fields, or query_optimizer.
---

# Querying Art Blocks Data

## Tool Hierarchy

Use tools in this order — skip steps you don't need:

1. **Discover schema** → `graphql_introspection` (full schema) or `explore_table` (single table with fields + relationships)
2. **Build a validated query** → `build_query` (validates fields, adds suggestions, auto-filters by chain)
3. **Optimize** → `query_optimizer` (rewrites to preferred tables, e.g. `projects_metadata` over `projects`)
4. **Execute** → `graphql_query`

If you already know the schema, go straight to `build_query` → `graphql_query`.

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

### Projects by artist
```graphql
query {
  projects_metadata(where: {
    artist_address: { _eq: "0xABCD..." }
    chain_id: { _eq: 1 }
  }) {
    id
    name
    invocations
    max_invocations
    script_type
  }
}
```

### Token with traits and owner
```graphql
query {
  tokens_metadata(where: { id: { _eq: "0xa7d8d9ef8d8ce8992df33d8b8cf4aebabd5bd270-78000000" } }) {
    token_id
    hash
    features
    owner_address
    project {
      name
      artist_address
    }
  }
}
```

### Recent sales
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
  }
}
```

### All tokens for a project
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

## Tips

- Use `explore_table` with `includeRelationships: true` to understand how tables join
- `build_query` is the safest way to start — it validates fields and tells you what's available
- Always pass `chainId` when querying multi-chain data to avoid cross-chain noise
- For unknown fields, `validate_fields` is faster than a full introspection
