# PostParam Hooks — Reference

## Interfaces

### `IPMPAugmentHook`

Called on every `getTokenParams()` read. Must be a `view` function.

```solidity
interface IPMPAugmentHook is IERC165 {
    /// @notice Augment the token parameters for a given token.
    /// @dev Must return ALL desired tokenParams, not just additional data.
    /// @param coreContract The core NFT contract address.
    /// @param tokenId The token to augment.
    /// @param tokenParams The existing configured params for this token.
    /// @return augmentedTokenParams The full augmented param array.
    function onTokenPMPReadAugmentation(
        address coreContract,
        uint256 tokenId,
        IWeb3Call.TokenParam[] calldata tokenParams
    ) external view returns (IWeb3Call.TokenParam[] memory augmentedTokenParams);
}
```

Source: [`IPMPAugmentHook.sol`](https://github.com/ArtBlocks/artblocks-contracts/blob/main/packages/contracts/contracts/interfaces/v0.8.x/IPMPAugmentHook.sol)

---

### `IPMPConfigureHook`

Called after every successful `configureTokenParams()` write. May revert.

```solidity
interface IPMPConfigureHook is IERC165 {
    /// @notice Execution logic after a token's PMP is configured.
    /// @dev Revert here to block the collector's entire configureTokenParams tx.
    /// @param coreContract The core NFT contract address.
    /// @param tokenId The token that was configured.
    /// @param pmpInput The param input that was successfully stored.
    function onTokenPMPConfigure(
        address coreContract,
        uint256 tokenId,
        IPMPV0.PMPInput calldata pmpInput
    ) external;
}
```

Source: [`IPMPConfigureHook.sol`](https://github.com/ArtBlocks/artblocks-contracts/blob/main/packages/contracts/contracts/interfaces/v0.8.x/IPMPConfigureHook.sol)

---

### `IWeb3Call.TokenParam`

The shared data shape for all params:

```solidity
struct TokenParam {
    string key;   // parameter name (matches the key used in your art script)
    string value; // always a string — numeric types are stringified
}
```

---

### `IPMPV0.PMPInput`

Passed to configure hooks:

```solidity
struct PMPInput {
    string key;
    ParamType configuredParamType;
    bytes32 configuredValue;          // non-string types
    bool configuringArtistString;
    string configuredValueString;     // String param type only
}
```

---

### `IPMPV0.configureProjectHooks`

Call this to register hooks for a project (artist wallet only):

```solidity
function configureProjectHooks(
    address coreContract,
    uint256 projectId,
    IPMPConfigureHook tokenPMPPostConfigHook,      // address(0) if unused
    IPMPAugmentHook tokenPMPReadAugmentationHook   // address(0) if unused
) external;
```

---

## PMPV0 Deployed Addresses

Same address on all chains (deterministic CREATE2 deployment):

| Chain | Address |
|---|---|
| Ethereum mainnet | `0x00000000A78E278b2d2e2935FaeBe19ee9F1FF14` |
| Sepolia testnet | `0x00000000A78E278b2d2e2935FaeBe19ee9F1FF14` |
| Arbitrum | `0x00000000A78E278b2d2e2935FaeBe19ee9F1FF14` |
| Base | `0x00000000A78E278b2d2e2935FaeBe19ee9F1FF14` |

---

## Standard Augment Hooks

Pre-deployed by Art Blocks. Same address on all chains. No Solidity required — register directly via Creator Dashboard.

> **Note:** These are experimental contracts. Verify behavior before using in production.

| Hook contract | Injected key | Value description |
|---|---|---|
| `InjectTokenOwner` | `tokenOwner` | Current owner address (checksummed hex) |
| `InjectBlockHeight` | `blockHeight` | Current block number as string |
| `InjectBlockTimestamp` | `blockTimestamp` | Current block timestamp (Unix seconds) |
| `InjectBaseGasFee` | `baseGasFee` | Current base fee in wei as string |
| `InjectIsProjectFullyMinted` | `isProjectFullyMinted` | `"true"` or `"false"` |
| `InjectTokenHashSeed` | `tokenHashSeed` | Token hash seed as string |
| `InjectTokenOwnerEthBalance` | `tokenOwnerEthBalance` | Owner ETH balance in wei as string |
| `InjectBlockHeightAndArtistProjectOverrides` | `blockHeight` + artist overrides | Block height with per-project artist overrides |

### Standard hook addresses (all chains)

| Hook | Address |
|---|---|
| `InjectTokenOwner` | `0xD70938ef6d8A875d9D9958C6Ad8e708b419dddc6` |
| `InjectBlockHeight` | `0x78B1E2Ff2e82Bf9cf5d3d38b77CEff84F118d894` |
| `InjectBlockTimestamp` | `0x28Fa000605836c29C93Df8dCd07F03ae2273fFFB` |
| `InjectBaseGasFee` | `0xf37e7A154B6c09186a0659a4f2bF276Fc2fa7E50` |
| `InjectIsProjectFullyMinted` | `0x908014A0B584F8a1c15b30B711054d77C84b4705` |
| `InjectTokenHashSeed` | `0x9Ddb345821c0e0cE4dF7C80EF34A98CeE0c0d51b` |
| `InjectTokenOwnerEthBalance` | `0x8D9A5b1BBAe4Eb97f01F9e15A1b0a9cbCE61bD8f` |
| `InjectBlockHeightAndArtistProjectOverrides` | `0x531f0D949F76A75cB865b2C75Dd65bae1Eb7609B` |

---

## Notable Custom Hook Examples

Real-world hook contracts from the artblocks-contracts repo to use as reference:

| Contract | What it does | Source |
|---|---|---|
| `InjectTokenOwner` | Simplest augment hook — one external call, one param appended | [source](https://github.com/ArtBlocks/artblocks-contracts/blob/main/packages/contracts/contracts/web3call/augment-hooks/InjectTokenOwner.sol) |
| `InjectBlockTimestamp` | Augment using `block.timestamp` with `Strings.toString()` | [source](https://github.com/ArtBlocks/artblocks-contracts/blob/main/packages/contracts/contracts/web3call/augment-hooks/InjectBlockTimestamp.sol) |
| `InjectChromieSquiggleFloorPrice` | Oracle-style augment — reads Uniswap V2 reserves to compute floor price | [source](https://github.com/ArtBlocks/artblocks-contracts/blob/main/packages/contracts/contracts/web3call/augment-hooks/InjectChromieSquiggleFloorPrice.sol) |
| `LiftHooks` | Combined hook — configure hook validates Squiggle ownership; augment hook strips param and injects token hash | [source](https://github.com/ArtBlocks/artblocks-contracts/blob/main/packages/contracts/contracts/web3call/combined-hooks/LiftHooks.sol) |
| `SRHooks` | Complex upgradeable augment hook for Send/Receive project — Feistel walk sampling, metadata tracking | [source](https://github.com/ArtBlocks/artblocks-contracts/blob/main/packages/contracts/contracts/web3call/augment-hooks/SRHooks.sol) |

All 16 standard augment hook examples: [augment-hooks/](https://github.com/ArtBlocks/artblocks-contracts/tree/main/packages/contracts/contracts/web3call/augment-hooks)

---

## `supportsInterface` Interface IDs

Your hook must return `true` for its interface ID(s). The cleanest way:

```solidity
function supportsInterface(bytes4 interfaceId) external pure override returns (bool) {
    return interfaceId == type(IPMPAugmentHook).interfaceId   // augment hooks
        || interfaceId == type(IPMPConfigureHook).interfaceId  // configure hooks (add if combined)
        || interfaceId == type(IERC165).interfaceId;
}
```

PMPV0 calls `supportsInterface` during `configureProjectHooks` and reverts if it returns `false` for the expected interface.

---

## `PMPInput.ParamType` enum

Used in configure hooks to identify which type of param was configured:

```solidity
enum ParamType {
    Unconfigured, // default — param not yet set
    Select,       // enum / dropdown
    Bool,
    Uint256Range,
    Int256Range,
    DecimalRange,
    HexColor,
    Timestamp,
    String        // uses configuredValueString; all others use configuredValue (bytes32)
}
```

For `String` type params, read `pmpInput.configuredValueString`. For all other types, decode `pmpInput.configuredValue` as the appropriate numeric type.

---

## Art Script Access Pattern

```javascript
const postParams = tokenData.externalAssetDependencies[0];

// Augmented value from your hook (always a string or undefined)
const myValue = postParams?.data?.["myKey"];

// Configured param value set by collector
const collectorParam = postParams?.data?.["myParam"];
```

Confirm the dependency index in Creator Dashboard under **Scripts → Flex Assets** — it appears as an external asset with text `#web3call-contract#`.

---

## External links

- [PostParams docs](https://docs.artblocks.io/protocol/postparams)
- [artblocks-contracts repo](https://github.com/ArtBlocks/artblocks-contracts)
- [Creator Dashboard](https://create.artblocks.io)
- [Standard hook deployment doc](https://github.com/ArtBlocks/artblocks-contracts/blob/main/packages/contracts/deployments/web3call/hooks/standard-augment-hooks/deployed-standard-augment-hooks.md)
