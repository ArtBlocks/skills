// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity ^0.8.22;

// ─── Imports ────────────────────────────────────────────────────────────────
//
// Option A — Foundry (copy interfaces locally):
//   Copy all four interface files from artblocks-contracts into src/interfaces/.
//
// Option B — Hardhat / npm:
//   npm install @artblocks/contracts @openzeppelin/contracts
//
import {IERC165} from "@openzeppelin/contracts/interfaces/IERC165.sol";
import {IWeb3Call} from "./interfaces/IWeb3Call.sol";
import {IPMPV0} from "./interfaces/IPMPV0.sol";
import {IPMPAugmentHook} from "./interfaces/IPMPAugmentHook.sol";
import {IPMPConfigureHook} from "./interfaces/IPMPConfigureHook.sol";

// ─── Contract ───────────────────────────────────────────────────────────────

/**
 * @title MyCombinedHook
 * @notice Art Blocks PostParam combined hook — implements both
 *   IPMPAugmentHook and IPMPConfigureHook in a single contract.
 *
 *   Use this pattern when you need both:
 *     - Injecting live on-chain data on every read (augment)
 *     - Validating or gating collector param changes (configure)
 *
 *   Real-world example: LiftHooks (Snowfro's LIFT project)
 *     - Configure: validates Squiggle ownership before accepting "featuredSquiggle" param
 *     - Augment: strips the Squiggle ID param, injects the Squiggle's token hash instead
 *
 * @dev Register this contract address for BOTH hook slots in Creator Dashboard,
 *   or pass it for both arguments in configureProjectHooks().
 */
contract MyCombinedHook is IPMPAugmentHook, IPMPConfigureHook {

    // ── ERC165 ───────────────────────────────────────────────────────────────

    /**
     * @inheritdoc IERC165
     * @dev Must return true for BOTH interface IDs.
     *   PMPV0 validates each slot independently when registering hooks.
     */
    function supportsInterface(bytes4 interfaceId)
        external
        pure
        override(IPMPAugmentHook, IPMPConfigureHook)
        returns (bool)
    {
        return interfaceId == type(IPMPAugmentHook).interfaceId
            || interfaceId == type(IPMPConfigureHook).interfaceId
            || interfaceId == type(IERC165).interfaceId;
    }

    // ── Augment hook ─────────────────────────────────────────────────────────

    /**
     * @notice Inject live on-chain data into the token's PostParam data.
     * @dev Called on every getTokenParams() read.
     * @dev Must return ALL desired params (copy originals + append new ones).
     * @dev view function — no state changes allowed.
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
        uint256 originalLength = tokenParams.length;
        augmentedTokenParams = new IWeb3Call.TokenParam[](originalLength + 1);

        for (uint256 i = 0; i < originalLength; i++) {
            augmentedTokenParams[i] = tokenParams[i];
        }

        augmentedTokenParams[originalLength] = IWeb3Call.TokenParam({
            key: "myAugmentedKey",
            value: _computeAugmentedValue(coreContract, tokenId)
        });

        return augmentedTokenParams;
    }

    // ── Configure hook ────────────────────────────────────────────────────────

    /**
     * @notice Validate a collector's param change.
     * @dev Called after each configureTokenParams() write.
     * @dev Revert here to block the collector's entire transaction.
     */
    function onTokenPMPConfigure(
        address coreContract,
        uint256 tokenId,
        IPMPV0.PMPInput calldata pmpInput
    ) external override {
        // TODO: add your validation logic here.
        //
        // Example — gate augment behavior on a configured param:
        //   if (keccak256(bytes(pmpInput.key)) == keccak256(bytes("featuredToken"))) {
        //       uint256 tokenIdToFeature = uint256(pmpInput.configuredValue);
        //       require(
        //           IERC721(someContract).ownerOf(tokenIdToFeature)
        //               == IERC721(coreContract).ownerOf(tokenId),
        //           "Must own the featured token"
        //       );
        //   }
        //
        coreContract;
        tokenId;
        pmpInput;
    }

    // ── Internal helpers ──────────────────────────────────────────────────────

    function _computeAugmentedValue(address coreContract, uint256 tokenId)
        internal
        view
        returns (string memory)
    {
        // TODO: your on-chain read logic here.
        coreContract;
        tokenId;
        return "todo";
    }
}
