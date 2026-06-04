// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity ^0.8.22;

// ─── Imports ────────────────────────────────────────────────────────────────
//
// Option A — Foundry (copy interfaces locally):
//   Copy IPMPAugmentHook.sol and IWeb3Call.sol from artblocks-contracts into
//   your src/interfaces/ directory.  They depend only on OpenZeppelin IERC165.
//
// Option B — Hardhat / npm:
//   npm install @artblocks/contracts @openzeppelin/contracts
//   Then use the package paths below.
//
import {IERC165} from "@openzeppelin/contracts/interfaces/IERC165.sol";
import {IWeb3Call} from "./interfaces/IWeb3Call.sol";
import {IPMPAugmentHook} from "./interfaces/IPMPAugmentHook.sol";

// Uncomment if you need address/uint256 → string conversion:
// import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";

// ─── Contract ───────────────────────────────────────────────────────────────

/**
 * @title MyAugmentHook
 * @notice Art Blocks PostParam augmentation hook.
 *
 *   Called on every getTokenParams() read. Injects one or more live on-chain
 *   values into the token's PostParam data that is passed to the art script.
 *
 * @dev IMPORTANT: onTokenPMPReadAugmentation must return ALL desired params
 *   (original params + new ones). Returning only new params will drop all
 *   configured collector params from tokenData.
 *
 * @dev This function is view — no state changes or events are allowed.
 *
 * @dev Gas: called on every read. Keep computation cheap.
 */
contract MyAugmentHook is IPMPAugmentHook {
    // Uncomment if using Strings library:
    // using Strings for uint256;
    // using Strings for address;

    // ── Constructor ──────────────────────────────────────────────────────────
    //
    // Add constructor args if your hook needs config (e.g. an external contract
    // address to read from). Keep it immutable where possible.
    //
    // address public immutable externalContract;
    // constructor(address _externalContract) {
    //     externalContract = _externalContract;
    // }

    // ── ERC165 ───────────────────────────────────────────────────────────────

    /**
     * @inheritdoc IERC165
     * @dev Must return true for IPMPAugmentHook.interfaceId.
     *   PMPV0 validates this on-chain during configureProjectHooks().
     */
    function supportsInterface(bytes4 interfaceId)
        external
        pure
        override
        returns (bool)
    {
        return interfaceId == type(IPMPAugmentHook).interfaceId
            || interfaceId == type(IERC165).interfaceId;
    }

    // ── Hook implementation ───────────────────────────────────────────────────

    /**
     * @notice Augment the token parameters for a given token.
     * @param coreContract The Art Blocks core NFT contract address.
     * @param tokenId      The token being read.
     * @param tokenParams  Existing configured params for this token.
     * @return augmentedTokenParams Full param array (existing + injected).
     */
    function onTokenPMPReadAugmentation(
        address coreContract,
        uint256 tokenId,
        IWeb3Call.TokenParam[] calldata tokenParams
    )
        external
        view
        override
        returns (IWeb3Call.TokenParam[] memory augmentedTokenParams)
    {
        // Allocate output array: original params + however many you're injecting.
        // Change `+ 1` to `+ N` if injecting multiple params.
        uint256 originalLength = tokenParams.length;
        augmentedTokenParams = new IWeb3Call.TokenParam[](originalLength + 1);

        // Copy all existing params — DO NOT skip this step.
        for (uint256 i = 0; i < originalLength; i++) {
            augmentedTokenParams[i] = tokenParams[i];
        }

        // Inject your new param(s).
        augmentedTokenParams[originalLength] = IWeb3Call.TokenParam({
            key: "myKey",             // must match the key used in your art script
            value: _computeValue(coreContract, tokenId)
        });

        // If injecting multiple params:
        // augmentedTokenParams[originalLength + 1] = IWeb3Call.TokenParam({
        //     key: "mySecondKey",
        //     value: _computeSecondValue(coreContract, tokenId)
        // });

        return augmentedTokenParams;
    }

    // ── Internal helpers ──────────────────────────────────────────────────────

    /**
     * @notice Compute the injected value for this token.
     * @dev All values are returned as strings in the art script.
     *   Common conversions:
     *     uint256 → Strings.toString(n)
     *     address → Strings.toHexString(addr)
     *     bool    → condition ? "true" : "false"
     */
    function _computeValue(address coreContract, uint256 tokenId)
        internal
        view
        returns (string memory)
    {
        // TODO: replace with your on-chain read logic.
        //
        // Examples:
        //   return Strings.toString(block.timestamp);
        //   return Strings.toString(block.number);
        //   return IERC721(coreContract).ownerOf(tokenId).toHexString();
        //   return someExternalContract.getValue(tokenId).toString();
        //
        // Suppress unused-variable warnings during development:
        coreContract;
        tokenId;
        return "todo";
    }
}
