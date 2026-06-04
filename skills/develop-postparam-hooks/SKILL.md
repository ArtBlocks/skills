---
name: develop-postparam-hooks
description: >-
  Design, write, test, deploy, and register custom Art Blocks PostParam hook
  contracts in Solidity. Use when an artist or developer wants to build a
  custom IPMPAugmentHook (inject live on-chain data into tokenData) or
  IPMPConfigureHook (validate/gate collector param changes), or both combined.
  Covers hook type selection, Solidity templates, lightweight testing in Foundry
  or Hardhat, deployment to Sepolia and mainnet, and registration via the
  Creator Dashboard.
---

# Developing PostParam Hooks

PostParam hooks are Solidity contracts that extend Art Blocks' PostParams
system. Two hook types exist:

| Hook type | Interface | Triggered by | Can revert? | Use for |
|---|---|---|---|---|
| **Augment** | `IPMPAugmentHook` | Every `getTokenParams()` read | No (view) | Inject live on-chain data into `tokenData` |
| **Configure** | `IPMPConfigureHook` | Every `configureTokenParams()` write | Yes | Validate or gate collector param changes |
| **Combined** | Both | Both | Augment: no; Configure: yes | Full control (e.g. LiftHooks) |

## Step 1 — Choose your hook type

**Build an augment hook if you want to:**
- Inject dynamic on-chain data (token owner, block height, ETH balance, oracle prices, NFT ownership)
- Keep the art script reactive to real-world state without collector interaction

**Build a configure hook if you want to:**
- Validate that a param change meets custom conditions before it's accepted
- Revert invalid configurations (e.g. "collector must own a specific NFT to set this value")

**Build a combined hook** (implement both interfaces in one contract) when you need both.

Check [reference.md](reference.md) for the full list of standard augment hooks — you may not need to write one at all.

## Step 2 — Set up your project

The interfaces are small and self-contained (only depend on OpenZeppelin `IERC165`).

**Foundry** — copy the three interface files into `src/interfaces/`:
- [`IPMPAugmentHook.sol`](https://github.com/ArtBlocks/artblocks-contracts/blob/main/packages/contracts/contracts/interfaces/v0.8.x/IPMPAugmentHook.sol)
- [`IPMPConfigureHook.sol`](https://github.com/ArtBlocks/artblocks-contracts/blob/main/packages/contracts/contracts/interfaces/v0.8.x/IPMPConfigureHook.sol)
- [`IWeb3Call.sol`](https://github.com/ArtBlocks/artblocks-contracts/blob/main/packages/contracts/contracts/interfaces/v0.8.x/IWeb3Call.sol)

Install OpenZeppelin as your only dependency:
```bash
forge install OpenZeppelin/openzeppelin-contracts
```

**Hardhat / npm** — install the published package for interfaces + ABIs:
```bash
npm install @artblocks/contracts @openzeppelin/contracts
```

## Step 3 — Write your hook

See the ready-to-use templates in [templates/](templates/). Abbreviated versions below.

### Augment hook

```solidity
// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity ^0.8.22;

import {IERC165} from "@openzeppelin/contracts/interfaces/IERC165.sol";
import {IWeb3Call} from "./interfaces/IWeb3Call.sol";
import {IPMPAugmentHook} from "./interfaces/IPMPAugmentHook.sol";

contract MyAugmentHook is IPMPAugmentHook {
    function supportsInterface(bytes4 interfaceId) external pure override returns (bool) {
        return interfaceId == type(IPMPAugmentHook).interfaceId
            || interfaceId == type(IERC165).interfaceId;
    }

    function onTokenPMPReadAugmentation(
        address coreContract,
        uint256 tokenId,
        IWeb3Call.TokenParam[] calldata tokenParams
    ) external view override returns (IWeb3Call.TokenParam[] memory augmentedTokenParams) {
        uint256 n = tokenParams.length;
        augmentedTokenParams = new IWeb3Call.TokenParam[](n + 1);
        for (uint256 i = 0; i < n; i++) {
            augmentedTokenParams[i] = tokenParams[i]; // must copy all existing params
        }
        augmentedTokenParams[n] = IWeb3Call.TokenParam({
            key: "myKey",
            value: _computeValue(coreContract, tokenId)
        });
    }

    function _computeValue(address coreContract, uint256 tokenId)
        internal view returns (string memory)
    {
        // TODO: your on-chain read logic here
    }
}
```

### Configure hook

```solidity
// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity ^0.8.22;

import {IERC165} from "@openzeppelin/contracts/interfaces/IERC165.sol";
import {IPMPConfigureHook} from "./interfaces/IPMPConfigureHook.sol";
import {IPMPV0} from "./interfaces/IPMPV0.sol";

contract MyConfigureHook is IPMPConfigureHook {
    function supportsInterface(bytes4 interfaceId) external pure override returns (bool) {
        return interfaceId == type(IPMPConfigureHook).interfaceId
            || interfaceId == type(IERC165).interfaceId;
    }

    function onTokenPMPConfigure(
        address coreContract,
        uint256 tokenId,
        IPMPV0.PMPInput calldata pmpInput
    ) external override {
        // Revert to block invalid configuration. Reverts here roll back
        // the collector's entire configureTokenParams transaction.
        require(/* your validation logic */, "Invalid configuration");
    }
}
```

### Combined hook (both interfaces)

Implement both `onTokenPMPReadAugmentation` and `onTokenPMPConfigure` in one
contract and return `true` for both interface IDs in `supportsInterface`. See
[templates/CombinedHook.sol](templates/CombinedHook.sol) for the full pattern.

## Step 4 — Test your hook

No fork or full repo clone required for unit tests.

**Unit test (Foundry)** — call the hook directly:
```solidity
function test_augmentation_appends_key() public {
    MyAugmentHook hook = new MyAugmentHook();

    IWeb3Call.TokenParam[] memory input = new IWeb3Call.TokenParam[](1);
    input[0] = IWeb3Call.TokenParam({key: "existingKey", value: "existingValue"});

    IWeb3Call.TokenParam[] memory result =
        hook.onTokenPMPReadAugmentation(address(0), 0, input);

    assertEq(result.length, 2);
    assertEq(result[0].key, "existingKey"); // original param preserved
    assertEq(result[1].key, "myKey");       // new param appended
}

function test_supportsInterface() public {
    MyAugmentHook hook = new MyAugmentHook();
    assertTrue(hook.supportsInterface(type(IPMPAugmentHook).interfaceId));
    assertTrue(hook.supportsInterface(type(IERC165).interfaceId));
}
```

**Integration test against real PMPV0** — fork Sepolia:
```bash
forge test --fork-url $SEPOLIA_RPC_URL
```

```solidity
// Uses live PMPV0 at 0x00000000A78E278b2d2e2935FaeBe19ee9F1FF14
IPMPV0 pmpV0 = IPMPV0(0x00000000A78E278b2d2e2935FaeBe19ee9F1FF14);
IWeb3Call.TokenParam[] memory params = pmpV0.getTokenParams(coreContract, tokenId);
// assert your hook's injected key appears in params
```

## Step 5 — Deploy

Deploy to **Sepolia staging** first, then repeat for mainnet.

```bash
# Foundry
forge create src/MyAugmentHook.sol:MyAugmentHook \
  --rpc-url $SEPOLIA_RPC_URL \
  --private-key $PRIVATE_KEY

# Verify on Etherscan
forge verify-contract <deployed-address> src/MyAugmentHook.sol:MyAugmentHook \
  --chain sepolia --etherscan-api-key $ETHERSCAN_API_KEY
```

```bash
# Hardhat
npx hardhat run scripts/deploy.js --network sepolia
npx hardhat verify <deployed-address> --network sepolia
```

## Step 6 — Register via Creator Dashboard

The Creator Dashboard is the recommended way to attach your hook:

1. Go to [create.artblocks.io](https://create.artblocks.io) → your project → **PostParams**
2. Find the **Augmentation Hooks** (or **Configure Hooks**) section
3. Paste your deployed contract address
4. The dashboard validates ERC165 compatibility on-chain before saving

To register programmatically instead, call PMPV0 directly (artist wallet required):
```solidity
IPMPV0(0x00000000A78E278b2d2e2935FaeBe19ee9F1FF14).configureProjectHooks(
    coreContract,
    projectId,
    IPMPConfigureHook(address(0)),    // pass address(0) if not using configure hook
    IPMPAugmentHook(myAugmentHook)    // pass address(0) if not using augment hook
);
```

PMPV0 is deployed at the same address on all chains (mainnet, Sepolia, Arbitrum, Base).

## Step 7 — Access injected data in your art script

```javascript
const postParams = tokenData.externalAssetDependencies[0];
const myValue = postParams?.data?.["myKey"]; // string or undefined
```

Verify the correct dependency index in Creator Dashboard under **Scripts → Flex Assets**.

## Critical gotchas

- **Augment hook must return ALL params** — copy the input array in full, then append. Returning only new params drops all configured PostParams from `tokenData`.
- **Configure hook reverts block the collector's entire transaction** — validate carefully and keep access control tight.
- **`supportsInterface` is validated on-chain at registration time** — if it returns false for the correct interface ID, `configureProjectHooks` reverts.
- **Augment hooks are `view`** — no state changes, no events.
- **Gas cost** — augment hooks are called on every read of `getTokenParams()`. Keep computation cheap; avoid unbounded loops or heavy storage reads.
- **No standard hook needed?** — check [reference.md](reference.md) for the full list of pre-deployed standard hooks (block height, token owner, ETH balance, etc.) that require zero Solidity.

## Additional resources

- [reference.md](reference.md) — full interface specs, deployed addresses, standard hook catalog
- [templates/AugmentHook.sol](templates/AugmentHook.sol) — complete augment hook template
- [templates/ConfigureHook.sol](templates/ConfigureHook.sol) — complete configure hook template
- [templates/CombinedHook.sol](templates/CombinedHook.sol) — combined hook template
- [artblocks-contracts repo](https://github.com/ArtBlocks/artblocks-contracts/tree/main/packages/contracts/contracts/web3call) — 16 real augment hook examples
- [PostParams docs](https://docs.artblocks.io/protocol/postparams) — full PostParams reference
