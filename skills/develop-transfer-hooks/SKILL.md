---
name: develop-transfer-hooks
description: >-
  Design, write, test, deploy, and configure Art Blocks transfer hook contracts
  in Solidity. Use when an artist or developer wants a contract that runs on
  every mint and transfer of a project's tokens — recording provenance on
  chain, emitting richer events, or restricting when a token may move. Covers
  the ITransferHook interface, the AbstractTransferHook base, the two security
  checks a hook must make, Solidity templates, testing in Foundry or Hardhat,
  deployment, and configuring the hook on a project.
---

# Developing Transfer Hooks

A transfer hook is a contract an Art Blocks Engine core calls on every mint and
every transfer of a project's tokens. The core calls it *after* the ERC-721
ownership write and passes the token, the previous owner, the new owner, and the
operator that initiated the move.

**A hook that reverts aborts the mint or transfer.** That makes hooks a real
extension point rather than a passive log — and it makes a buggy hook capable of
freezing a collection.

| | |
|---|---|
| Interface | `ITransferHook` — one function, `onTokenTransfer` |
| ERC-165 ID | `0x6344b0e2` |
| Scope | Per project, not per contract |
| Requires | Core v3.3.0+ (Engine) or v3.3.1+ (Engine Flex) |
| Set by | Artist or Admin ACL, via `configureProjectTransferHook` |

## Step 0 — Check the project can use a hook

Support cannot be added to an existing contract. Engine cores are minimal
proxies and the implementation address is fixed in the proxy's bytecode, so a
pre-v3.3 core will *never* gain hook support. A project needing a hook must be
on a contract deployed after the v3.3 rollout.

Check with the MCP server (`get_project` reports a `transferHook` block), or
directly:

```graphql
query {
  projects_metadata(where: { id: { _eq: "0xCORE-7" } }) {
    supports_transfer_hooks
    transfer_hook
    transfer_hook_configuration_locked
  }
}
```

If `supports_transfer_hooks` is `false`, stop — contact Art Blocks about a new
contract. If `transfer_hook_configuration_locked` is `true`, the project's hook
can never change again; see [Locking](#step-6--configure-the-hook-on-a-project).

## Step 1 — Decide what the hook does

**Observer** — records or emits, never reverts. Provenance chains, transfer
counts, per-owner state. This is the safe default, and it cannot brick a
project. Start from
[templates/ObserverTransferHook.sol](templates/ObserverTransferHook.sol).

**Restrictive** — rejects some transfers. Time locks, allowlisted recipients,
conditional soulbinding. Start from
[templates/RestrictiveTransferHook.sol](templates/RestrictiveTransferHook.sol),
and read the warnings in it before deploying anything to mainnet.

Before writing either, check whether
[`OwnerHistoryTransferHook`](reference.md#deployed-reference-hook) already does
what you want — it is deployed and verified on every supported network, so
using it requires no Solidity at all.

## Step 2 — Set up your project

`AbstractTransferHook` and `ITransferHook` depend only on OpenZeppelin's
`IERC165` and `ERC165`.

**Foundry (recommended)** — copy the two sources into `src/`, and change their
`@openzeppelin-5.0/contracts/...` imports to `@openzeppelin/contracts/...`:

- [`ITransferHook.sol`](https://github.com/ArtBlocks/artblocks-contracts/blob/main/packages/contracts/contracts/interfaces/v0.8.x/ITransferHook.sol)
- [`AbstractTransferHook.sol`](https://github.com/ArtBlocks/artblocks-contracts/blob/main/packages/contracts/contracts/engine/V3/transfer-hooks/AbstractTransferHook.sol)

```bash
forge install OpenZeppelin/openzeppelin-contracts
```

**Hardhat / npm** — the package ships the sources, but they import through an
aliased OpenZeppelin path, so install the alias too:

```bash
npm install @artblocks/contracts \
  "@openzeppelin-5.0/contracts@npm:@openzeppelin/contracts@5.0.1"
```

You will also want `IGenArt721CoreContractV3_Engine` for the required
configuration check in Step 3.

## Step 3 — Write the hook

Inherit `AbstractTransferHook` and implement `_onTokenTransfer`. The base
handles ERC-165 and rejects a caller that is not the `coreContract` it was
handed.

```solidity
contract MyTransferHook is AbstractTransferHook {
    uint256 private constant ONE_MILLION = 1_000_000;

    function _onTokenTransfer(
        address coreContract,
        uint256 tokenId,
        address from,
        address to,
        address operator
    ) internal override {
        // REQUIRED — see below
        _onlyConfiguredForProject(coreContract, tokenId / ONE_MILLION);

        if (from == to) return; // ERC-721 permits transferFrom(a, a, id)

        // your logic
    }
}
```

### The two checks every hook must make

`AbstractTransferHook` guarantees `msg.sender == coreContract`. It cannot know
*which* cores your hook is meant to serve, and it cannot know whether the
project actually configured you. Both gaps are exploitable:

1. **Is this a core I serve?** Without a check, anyone can deploy a contract
   that calls your hook from its own address with any `tokenId`, `from`, `to`
   and `operator` it likes, and your hook will believe it.
2. **Is this project actually configured to use me?** Ask the core:

```solidity
(address configuredHook, ) = IGenArt721CoreContractV3_Engine(coreContract)
    .projectTransferHookConfig(projectId);
if (configuredHook != address(this)) revert HookNotConfiguredForProject(...);
```

That single call covers both: a core that reports you as its configured hook is
a real Art Blocks core *and* has opted this project in. Both templates do it.

### Two constraints to design around

- **No reentrancy into the core.** For the duration of your hook call, the core
  blocks mints and transfers on *every* project of that core. A hook that tries
  to mint or transfer on the calling core reverts the transaction that triggered
  it.
- **Gas is paid by whoever moves the token,** on every mint and every secondary
  transfer, forever. Storage writes dominate. An expensive hook makes the token
  permanently more expensive to trade.

### If the token's image must change on transfer

Running a hook does not re-render the token. The rendering pipeline is not
watching for hook calls, so the stored image and features stay as they were.

This bites exactly the projects most likely to want a hook. If the artwork
reacts to its owner — through the `InjectTokenOwner` augment hook, or your own
hook's state — the live generator is correct the moment the token transfers,
while the thumbnail on artblocks.io and in marketplaces still shows the previous
owner's output.

Writing a **PostParam** is the signal that does trigger a re-render, along with
a features recompute. So write one from inside `_onTokenTransfer`:

```solidity
IPMPV0 constant PMP = IPMPV0(0x00000000A78E278b2d2e2935FaeBe19ee9F1FF14);

function _onTokenTransfer(
    address coreContract,
    uint256 tokenId,
    address from,
    address to,
    address /* operator */
) internal override {
    _onlyConfiguredForProject(coreContract, tokenId / ONE_MILLION);
    if (from == to) return;

    // Skip mints. A freshly minted token is rendered by the pipeline as part
    // of minting, so there is nothing to invalidate — and keeping the mint
    // path out of this call keeps it out of every way the call can fail.
    if (from == address(0)) return;

    // Any value the pipeline has not seen before will do. A timestamp needs
    // no extra storage of its own and is useful to the generator besides.
    IPMPV0.PMPInput[] memory inputs = new IPMPV0.PMPInput[](1);
    inputs[0] = IPMPV0.PMPInput({
        key: "lastTransferAt",
        configuredParamType: IPMPV0.ParamType.Timestamp,
        configuredValue: bytes32(block.timestamp),
        configuringArtistString: false,
        configuredValueString: ""
    });

    // Never let the PostParam write take the transfer down with it.
    try PMP.configureTokenParams(coreContract, tokenId, inputs) {} catch {}
}
```

For that call to be authorized, the artist configures the parameter with the
`Address` authorization option and sets its authorized address to the hook
contract. `AuthOption.Address` exists precisely for programmatic writers like
this; the combined options (`TokenOwnerAndAddress`, and so on) let a collector
keep write access alongside the hook.

**The `try`/`catch` is not decoration.** `configureTokenParams` reverts for several reasons that are outside your hook's
control and can begin applying long after the hook is set — and an uncaught
revert here freezes every transfer of every token in the project:

- **The artist reconfigures the project's PostParams without this key.** Each
  project configuration bumps a nonce, and PMPV0 rejects any param whose
  `highestConfigNonce` is not the current one: *"param not part of most recently
  configured PMP params"*. This is the likely one. An artist tidying up their
  parameters months later would silently brick their own collection.
- **The authorized address is changed, or the param's type is changed.**
  *"address auth required"*, *"paramType mismatch"*.
- **A post-config hook is set on the project and reverts.** PMPV0 deliberately
  propagates that rather than swallowing it.

Catching means a misconfiguration costs a stale thumbnail instead of a frozen
collection. Verify on staging that the write actually lands — a swallowed error
is silent by design.

Two more things make this viable or not:

- **It is allowed.** The core blocks reentrant mints and transfers, not calls to
  other contracts, so writing to PMPV0 during the hook goes through.
- **It doubles the storage cost.** Your hook's write plus the PostParam write,
  on every transfer, for the life of the project. If the image does not actually
  depend on the transfer, do not do this.

## Step 4 — Test

The interfaces are small enough that unit tests need no fork.

```solidity
// A mock core lets you drive the hook directly.
contract MockCore {
    address public hook;
    function setHook(address h) external { hook = h; }
    function projectTransferHookConfig(uint256) external view
        returns (address, bool) { return (hook, false); }
    function fire(uint256 tokenId, address from, address to, address op) external {
        ITransferHook(hook).onTokenTransfer(address(this), tokenId, from, to, op);
    }
}

function test_rejects_spoofed_caller() public {
    // calling with a coreContract that is not msg.sender must revert
    vm.expectRevert();
    hook.onTokenTransfer(address(mockCore), 1_000_000, alice, bob, alice);
}

function test_rejects_unconfigured_project() public {
    mockCore.setHook(address(0xdead));
    vm.expectRevert();
    mockCore.fire(1_000_000, alice, bob, alice);
}

function test_supportsInterface() public {
    assertTrue(hook.supportsInterface(0x6344b0e2)); // ITransferHook
    assertTrue(hook.supportsInterface(0x01ffc9a7)); // IERC165
}
```

Test the **mint** path explicitly (`from == address(0)`). A restrictive hook
that forgets to allow mints blocks the project from selling.

Then run it end to end on Sepolia artist-staging with a real v3.3 core before
mainnet. Configure the hook, mint, and transfer.

## Step 5 — Deploy

```bash
# Foundry
forge create src/MyTransferHook.sol:MyTransferHook \
  --rpc-url $SEPOLIA_RPC_URL --private-key $PRIVATE_KEY

forge verify-contract <address> src/MyTransferHook.sol:MyTransferHook \
  --chain sepolia --etherscan-api-key $ETHERSCAN_API_KEY
```

```bash
# Hardhat
npx hardhat run scripts/deploy.js --network sepolia
npx hardhat verify <address> --network sepolia
```

Verify the source. An unverified hook is one collectors cannot audit, on a
contract that can block their transfers.

## Step 6 — Configure the hook on a project

Artist or Admin ACL:

```solidity
core.configureProjectTransferHook(projectId, hookAddress);
```

The core checks ERC-165 and reverts if the address does not advertise
`0x6344b0e2`. Passing `address(0)` clears the hook and restores standard
transfer behavior.

The [Creator Dashboard](https://create.artblocks.io) exposes this for projects
on a supporting contract.

### Locking

```solidity
core.lockProjectTransferHook(projectId, expectedHook); // artist only, one-way
```

`expectedHook` must equal the currently configured hook. It exists because the
Admin ACL can also change the hook — without it, a configure transaction landing
first could permanently lock in a hook nobody intended.

Locking at `address(0)` is a real commitment: the project can never have a
transfer hook.

There is also an **automatic lock**. Every project's metadata locks four weeks
after completion. If that elapses with no hook set, the configuration locks at
`address(0)` permanently. A project that *does* have a hook set stays
configurable until the artist locks explicitly.

> **Locking freezes the address, not the behavior.** Locking to an upgradeable
> proxy leaves that proxy's owner able to change what runs on every transfer,
> forever, with no way out. Only lock at code you have read and that cannot
> change.

## Critical gotchas

- **Check `projectTransferHookConfig`.** Skipping it means any contract can feed
  your hook fabricated transfers.
- **Hooks fire on mints too.** `from == address(0)`. Restrictive logic that
  forgets this blocks minting.
- **`transferFrom(a, a, id)` is legal** and reaches your hook with
  `from == to`. Most hooks should return early.
- **Token IDs are per-core.** Key storage by `(coreContract, tokenId)`; a bare
  `tokenId` collides across contracts. `projectId = tokenId / 1_000_000`.
- **You cannot reenter the calling core.** No minting or transferring on it from
  inside the hook.
- **Setting a hook does not backfill.** It only sees transfers after it is
  configured.
- **Clearing a hook does not undo it.** State already written stays written.
- **A hook does not re-render the token.** If the image depends on the transfer,
  the hook must also write a PostParam — see
  [If the token's image must change on transfer](#if-the-tokens-image-must-change-on-transfer).
- **Read `transfer_hook_configuration_locked`, not `transfer_hook_locked`.** The
  raw column is `null` rather than `false` while unlocked and ignores the
  automatic lock.

## Additional resources

- [reference.md](reference.md) — interface spec, events, deployed addresses, data fields
- [templates/ObserverTransferHook.sol](templates/ObserverTransferHook.sol) — records, never blocks
- [templates/RestrictiveTransferHook.sol](templates/RestrictiveTransferHook.sol) — can reject a transfer
- [Transfer Hooks docs](https://docs.artblocks.io/protocol/transfer-hooks/) — full protocol reference
- [`OwnerHistoryTransferHook`](https://github.com/ArtBlocks/artblocks-contracts/blob/main/packages/contracts/contracts/engine/V3/transfer-hooks/OwnerHistoryTransferHook.sol) — deployed reference implementation
