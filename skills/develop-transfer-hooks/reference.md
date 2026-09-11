# Transfer Hooks — Reference

## Interfaces

### `ITransferHook`

```solidity
interface ITransferHook is IERC165 {
    function onTokenTransfer(
        address coreContract,
        uint256 tokenId,
        address from,
        address to,
        address operator
    ) external;
}
```

Called by the core after the ERC-721 ownership write, on mint and on transfer.
On mint it runs after the token hash seed is assigned, so reading
`tokenIdToHash` returns the final value. **Reverting aborts the mint or
transfer.**

| Param | Notes |
|---|---|
| `coreContract` | The core that performed the update. Equals `msg.sender` when called by a conforming core. Passed explicitly so one hook can serve many cores. |
| `tokenId` | Token whose ownership changed. Unique only within a core. |
| `from` | Previous owner. `address(0)` on mint. |
| `to` | New owner. `address(0)` on burn — Art Blocks cores do not currently burn. |
| `operator` | On transfer, the ERC-721 operator. On mint, the address that initiated the mint (the collector, not the minter contract). |

### `AbstractTransferHook`

Recommended base. Implements `onTokenTransfer` and ERC-165, enforces
`msg.sender == coreContract`, and calls `_onTokenTransfer` with the same
arguments. `onTokenTransfer` is deliberately **not** `virtual` — the caller check
is a security invariant children must not be able to remove by accident.

Children override:

```solidity
function _onTokenTransfer(
    address coreContract,
    uint256 tokenId,
    address from,
    address to,
    address operator
) internal override { ... }
```

An override may tighten mutability to `view` if it only reads.

## Core contract API

```solidity
// Artist or Admin ACL. Reverts if the configuration is locked.
// address(0) clears the hook. A non-zero hook must ERC-165-advertise 0x6344b0e2.
function configureProjectTransferHook(uint256 _projectId, address _hook) external;

// Artist only. One-way. _expectedHook must equal the current hook.
function lockProjectTransferHook(uint256 _projectId, address _expectedHook) external;

// hook is address(0) when none is configured.
function projectTransferHookConfig(uint256 _projectId)
    external view returns (address hook, bool locked);
```

`lockProjectTransferHook` reverts with `TransferHookUnexpectedHook` if
`_expectedHook` does not match. It also reverts if the configuration is already
locked, including by the automatic lock below.

### Locking rules

| Situation | Configurable? |
|---|---|
| Hook set, not locked | Yes, by artist or Admin ACL |
| `lockProjectTransferHook` called | Never again |
| Four-week metadata lock elapsed, **no** hook set | Never again, locked at `address(0)`, no event |
| Four-week metadata lock elapsed, hook **is** set | Still configurable until locked explicitly |

## Events

```solidity
event ProjectTransferHookUpdated(uint256 indexed _projectId, address indexed _hook);
event ProjectTransferHookLocked(uint256 indexed _projectId, address indexed _hook);
```

Both are indexed by the Art Blocks subgraph. `_hook` of `address(0)` in
`ProjectTransferHookUpdated` means the hook was cleared. The automatic lock
emits nothing — it is a function of the clock, not a transaction.

## `supportsInterface` interface IDs

| Interface | ID |
|---|---|
| `ITransferHook` | `0x6344b0e2` |
| `IERC165` | `0x01ffc9a7` |

`0x6344b0e2` is the selector of `onTokenTransfer` alone. Solidity excludes
inherited interface functions from the XOR, so implementers hardcoding the value
must **not** XOR in `IERC165`'s `0x01ffc9a7`. A core rejects any hook that does
not advertise `0x6344b0e2`.

## Compatibility

| Contract | Minimum version |
|---|---|
| `GenArt721CoreV3_Engine` | v3.3.0 |
| `GenArt721CoreV3_Engine_Flex` | v3.3.1 |

Support cannot be retrofitted. Engine cores are ERC-1167 minimal proxies and the
implementation address is fixed in the proxy bytecode at deployment, so a
pre-v3.3 core will never gain hook support.

## Deployed reference hook

`OwnerHistoryTransferHook` — `0x00000000cb60788043f4F779bfC192F1c5bd09FA`, the
same address on every supported network (Ethereum, Arbitrum, Base, Shape, and
the Sepolia environments).

Records each token's chain of owners on chain. It never blocks a transfer, and
it is inert until a project configures it — it asks the calling core whether it
is that project's configured hook and reverts otherwise. Already deployed and
verified, so a project wanting on-chain provenance needs no Solidity.

```solidity
struct OwnerRecord { address owner; uint96 timestamp; }

function ownerHistory(address coreContract, uint256 tokenId)
    external view returns (OwnerRecord[] memory);      // oldest first, unbounded

function ownerHistorySlice(address coreContract, uint256 tokenId, uint256 start, uint256 count)
    external view returns (OwnerRecord[] memory);      // page a long history

function ownerHistoryLength(address coreContract, uint256 tokenId)
    external view returns (uint256);

function previousOwners(address coreContract, uint256 tokenId)
    external view returns (address[] memory);          // excludes the most recent

function lastRecordedOwner(address coreContract, uint256 tokenId)
    external view returns (address);

function isTrackedFromMint(address coreContract, uint256 tokenId)
    external view returns (bool);

event OwnerRecorded(
    address indexed coreContract,
    uint256 indexed tokenId,
    address indexed owner,
    uint256 index,
    uint256 timestamp
);
```

Index 0 of the chain is the owner that *preceded* the first change the hook saw:
`address(0)` if the hook was configured before the token was minted, otherwise
the owner at the moment tracking began. That is what `isTrackedFromMint`
distinguishes, and why `previousOwners` excludes an `address(0)` anchor but
keeps a real one.

`lastRecordedOwner` is the current owner only while the hook stays configured.
If a project clears its hook, recording stops; call `ownerOf` on the core for
the live owner.

## Off-chain data

`projects_metadata` in the Art Blocks GraphQL API:

| Field | Type | Meaning |
|---|---|---|
| `transfer_hook` | `String` | Configured hook address, `null` if none |
| `supports_transfer_hooks` | `Boolean!` | Whether the project's core supports hooks at all |
| `transfer_hook_configuration_locked` | `Boolean!` | Whether the configuration can still change |
| `transfer_hook_locked` | `Boolean` | Raw explicit-lock flag — **avoid** |

Use `transfer_hook_configuration_locked`. The raw `transfer_hook_locked` column
reflects only an explicit `lockProjectTransferHook` call, is `null` rather than
`false` while unlocked, and does not account for the time-based automatic lock.
It is not readable by the `public` role for that reason.

The MCP server's `get_project` returns the same information as a `transferHook`
block.

## External links

- [Transfer Hooks docs](https://docs.artblocks.io/protocol/transfer-hooks/)
- [`ITransferHook.sol`](https://github.com/ArtBlocks/artblocks-contracts/blob/main/packages/contracts/contracts/interfaces/v0.8.x/ITransferHook.sol)
- [`AbstractTransferHook.sol`](https://github.com/ArtBlocks/artblocks-contracts/blob/main/packages/contracts/contracts/engine/V3/transfer-hooks/AbstractTransferHook.sol)
- [`OwnerHistoryTransferHook.sol`](https://github.com/ArtBlocks/artblocks-contracts/blob/main/packages/contracts/contracts/engine/V3/transfer-hooks/OwnerHistoryTransferHook.sol)
- [`IOwnerHistoryTransferHook.sol`](https://github.com/ArtBlocks/artblocks-contracts/blob/main/packages/contracts/contracts/interfaces/v0.8.x/IOwnerHistoryTransferHook.sol)
