# Art Blocks Skills

Agent skills for the [Art Blocks MCP server](https://mcp.artblocks.io/mcp). Each skill teaches the AI agent domain-specific workflows and best practices for working with Art Blocks on-chain data, minting, and generative art development.

Compatible with Cursor, Claude Code, Codex, and [37+ other agents](https://github.com/vercel-labs/skills#supported-agents) via the [open agent skills ecosystem](https://skills.sh).

## Setup

### 1. Connect the Art Blocks MCP server

The MCP server is hosted at `https://mcp.artblocks.io/mcp` and uses OAuth for authentication.

**Cursor** — add to `.cursor/mcp.json` in your project (or `~/.cursor/mcp.json` globally):

```json
{
  "mcpServers": {
    "artblocks-mcp": {
      "url": "https://mcp.artblocks.io/mcp"
    }
  }
}
```

Cursor will prompt you to authenticate via OAuth the first time a tool is called.

**Claude Code** — run once in your terminal:

```bash
claude mcp add artblocks-mcp https://mcp.artblocks.io/mcp
```

### 2. Install the skills

```bash
npx skills add ArtBlocks/skills
```

Install globally (available across all your projects):

```bash
npx skills add ArtBlocks/skills -g
```

Install to a specific agent only:

```bash
npx skills add ArtBlocks/skills -a cursor
npx skills add ArtBlocks/skills -a claude-code
```

After installing, reload Cursor (`Cmd+Shift+P` → "Reload Window") for skills to take effect.

### 3. Start prompting

Skills activate automatically — just ask naturally in chat:

> *"Find all fully on-chain Art Blocks projects mintable on Base"*
> *"Help me convert my p5.js sketch to Art Blocks format"*
> *"Build a mint transaction for project 0xa7d8...d270-12 on Arbitrum"*
> *"Show me all projects by Tyler Hobbs"*
> *"What does snowfro's Art Blocks portfolio look like?"*

---

## Available Skills

| Skill | Use when... |
|-------|-------------|
| [`discover-artblocks-projects`](./skills/discover-artblocks-projects/SKILL.md) | Browsing, searching, or filtering Art Blocks projects — what's live, dropping soon, in a wallet, or matching a tag/price range |
| [`get-artist`](./skills/get-artist/SKILL.md) | Looking up an artist and exploring their body of work across Art Blocks |
| [`query-artblocks-data`](./skills/query-artblocks-data/SKILL.md) | Custom GraphQL queries for data not covered by domain-specific tools (sales history, aggregations, complex joins) |
| [`get-token-metadata`](./skills/get-token-metadata/SKILL.md) | Looking up a specific token's traits, media URLs, listing info, owner, hash, and project context |
| [`mint-artblocks-token`](./skills/mint-artblocks-token/SKILL.md) | Minting a token — pricing, minter types, allowlists, multi-wallet eligibility, building transactions |
| [`scaffold-art-script`](./skills/scaffold-art-script/SKILL.md) | Creating or converting a generative art script for Art Blocks |
| [`configure-postparams`](./skills/configure-postparams/SKILL.md) | Setting on-chain PostParam values on a minted token |

---

## Supported Agents

Skills work with any agent that supports the [open agent skills spec](https://github.com/vercel-labs/skills#supported-agents). The Art Blocks MCP server can be connected to any agent that supports MCP over HTTP.

| Agent | MCP | Skills |
|-------|-----|--------|
| Cursor | ✅ | ✅ |
| Claude Code | ✅ | ✅ |
| Claude Desktop | ✅ | — |
| Codex | ✅ | ✅ |

---

## Manual Installation

Copy any skill directory into `.cursor/skills/` in your project, or `~/.cursor/skills/` for personal use:

```bash
cp -r skills/query-artblocks-data /your-project/.cursor/skills/
```

---

## Feedback

Found a bug, missing a tool, or have a suggestion? We'd love to hear from you:

- **GitHub Issues** — [open an issue](https://github.com/ArtBlocks/skills/issues) in this repo
- **Discord** — reach out in the [Art Blocks Discord](https://discord.gg/artblocks)

## License

MIT — see [LICENSE](./LICENSE)
