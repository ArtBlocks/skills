---
name: scaffold-art-script
description: Build or convert Art Blocks generative art scripts using artblocks-mcp. Use when helping a user create, scaffold, port, or convert an art script for Art Blocks, or when working with tokenData, hash-based PRNG, FLEX dependencies, PostParams, window.$features traits, p5.js, Three.js, or the Art Blocks generator format.
---

# Scaffolding Art Blocks Projects

## Always Fetch the Generator Spec First

Before any art script work, fetch this MCP resource:

```
artblocks://generator-spec
```

It contains the authoritative reference for: `tokenData` structure, hash-based PRNG patterns, FLEX dependency types (IPFS, Arweave, ONCHAIN, Dependency Registry), supported script types and library versions, HTML structure requirements, and `window.$features`. It also includes the step-by-step conversion guide for porting existing scripts.

## Scaffolding a New Project

Use `scaffold_artblocks_project` to generate a ready-to-run `index.html` + starter art script.

### Parameters

| Param                    | Options / Notes                                                                                   |
|--------------------------|---------------------------------------------------------------------------------------------------|
| `scriptType`             | `"js"` (vanilla), `"p5js"`, `"threejs"` — **required**                                          |
| `dependencyVersion`      | p5.js: `"1.0.0"`, `"1.9.0"`, or `"1.11.11"` (default). Three.js: `"0.124.0"`, `"0.160.0"`, `"0.167.0"` (default). Ignored for `"js"`. |
| `includePostParams`      | `true` — adds ONCHAIN/PostParams (PMP) stubs in `tokenData` and example usage                    |
| `includeFlexDependencies`| `true` — adds IPFS and Arweave dependency stubs with usage patterns                              |
| `includeFeatures`        | `true` — adds `window.$features` trait assignment stub                                           |

**Note on Three.js v0.167.0**: uses ES module import maps instead of a global `<script>` tag. This affects script type detection on-chain — see the generator spec for details.

### Other supported script types

`scaffold_artblocks_project` covers vanilla JS, p5.js, and Three.js. Art Blocks supports many more via the on-chain dependency registry: regl, Tone.js, Babylon.js, A-Frame, Paper.js, Zdog, Processing, and custom types. See `artblocks://generator-spec` for the full list and how to reference them.

## Converting an Existing Script

When a user has an existing piece to convert to Art Blocks format:

1. Fetch `artblocks://generator-spec` — it contains a detailed step-by-step conversion guide
2. Use `scaffold_artblocks_project` with the matching `scriptType` to get the correct HTML shell
3. Walk through conversion:

**Conversion checklist:**
- Replace `Math.random()` with hash-based PRNG derived from `tokenData.hash`
- Replace hardcoded canvas dimensions with `window.innerWidth` / `window.innerHeight`
- Ensure the **initial render** is deterministic from the hash alone — same hash must always produce the same initial visual output
- Interactive elements (mouse, keyboard, touch) are allowed and encouraged, but must not change the initial render. Interaction should only modify the view *after* the artwork has loaded deterministically.
- Remove any time-based variation (`Date.now()`, `setTimeout`) that affects the initial render (time-based animation after load is fine)
- Extract visual traits into `window.$features` (optional but recommended for reveals) — features must be set synchronously before or during initial render
- Verify determinism: reload the page with the same `tokenData.hash` and confirm identical initial output

## When to Enable Each Flag

| Flag                     | Enable when...                                                        |
|--------------------------|-----------------------------------------------------------------------|
| `includeFeatures`        | Script has distinct visual categories worth exposing as traits        |
| `includePostParams`      | Script will have configurable on-chain parameters after minting (PMP) |
| `includeFlexDependencies`| Script loads external assets from IPFS or Arweave                    |
