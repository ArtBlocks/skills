// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity ^0.8.22;

// ─── Imports ────────────────────────────────────────────────────────────────
//
// See ObserverTransferHook.sol for the two setup options.
//
import {AbstractTransferHook} from "./AbstractTransferHook.sol";
import {IGenArt721CoreContractV3_Engine} from "./interfaces/IGenArt721CoreContractV3_Engine.sol";

// ─── Contract ───────────────────────────────────────────────────────────────

/**
 * @title RestrictiveTransferHook
 * @notice Art Blocks transfer hook that can refuse a transfer.
 *
 *   This example holds tokens non-transferable until a per-project unlock
 *   timestamp, then gets out of the way. Mints always pass — a hook that
 *   blocks mints blocks the project from selling.
 *
 * @dev WARNING: a revert here aborts the whole mint or transfer. That is the
 *   point of a restrictive hook, and it is also how you brick a collection.
 *   Before configuring one on mainnet:
 *
 *     - Test the MINT path, not just secondary transfers.
 *     - Make sure no reachable state leaves a token permanently stuck unless
 *       that is genuinely the intent.
 *     - Remember an artist can clear the hook with configureProjectTransferHook
 *       (address(0)) — unless the project's hook configuration has been locked,
 *       after which there is no escape hatch at all.
 *
 * @dev Collectors will meet this as a failed transfer in whatever marketplace
 *   they are using, which usually reports it poorly. Communicate the rule.
 */
contract RestrictiveTransferHook is AbstractTransferHook {
    /// @dev Art Blocks packs projectId and token index into the token ID.
    uint256 private constant ONE_MILLION = 1_000_000;

    // ── Custom errors ────────────────────────────────────────────────────────

    error HookNotConfiguredForProject(
        address coreContract,
        uint256 projectId,
        address configuredHook
    );

    /// @notice Thrown when a transfer is attempted before the project unlocks.
    error TransfersLockedUntil(
        address coreContract,
        uint256 projectId,
        uint256 unlockTimestamp
    );

    /// @notice Thrown when a non-artist tries to set a project's unlock time.
    error OnlyArtist(address coreContract, uint256 projectId, address caller);

    /// @notice Thrown when an unlock time is set more than once.
    error UnlockAlreadySet(address coreContract, uint256 projectId);

    // ── Storage ──────────────────────────────────────────────────────────────

    mapping(address coreContract => mapping(uint256 projectId => uint256))
        public unlockTimestamp;

    // ── Events ───────────────────────────────────────────────────────────────

    event UnlockTimestampSet(
        address indexed coreContract,
        uint256 indexed projectId,
        uint256 unlockTimestamp
    );

    // ── Configuration ────────────────────────────────────────────────────────

    /**
     * @notice Set the unlock time for a project. Artist only, once.
     * @dev Write-once on purpose: a mutable restriction is one the artist can
     *   tighten after collectors have bought in. Decide deliberately which one
     *   your project wants.
     */
    function setUnlockTimestamp(
        address coreContract,
        uint256 projectId,
        uint256 timestamp
    ) external {
        address artist = IGenArt721CoreContractV3_Engine(coreContract)
            .projectIdToArtistAddress(projectId);
        if (msg.sender != artist) {
            revert OnlyArtist({
                coreContract: coreContract,
                projectId: projectId,
                caller: msg.sender
            });
        }
        if (unlockTimestamp[coreContract][projectId] != 0) {
            revert UnlockAlreadySet({
                coreContract: coreContract,
                projectId: projectId
            });
        }

        unlockTimestamp[coreContract][projectId] = timestamp;
        emit UnlockTimestampSet({
            coreContract: coreContract,
            projectId: projectId,
            unlockTimestamp: timestamp
        });
    }

    // ── Hook logic ───────────────────────────────────────────────────────────

    /// @dev `view` because this hook only reads. Solidity permits an override
    /// to tighten mutability; drop it as soon as you write state or emit.
    function _onTokenTransfer(
        address coreContract,
        uint256 tokenId,
        address from,
        address /* to */,
        address /* operator */
    ) internal view override {
        uint256 projectId = tokenId / ONE_MILLION;

        _onlyConfiguredForProject({
            coreContract: coreContract,
            projectId: projectId
        });

        // Never block a mint. from == address(0) identifies one.
        if (from == address(0)) {
            return;
        }

        uint256 unlocksAt = unlockTimestamp[coreContract][projectId];
        if (block.timestamp < unlocksAt) {
            revert TransfersLockedUntil({
                coreContract: coreContract,
                projectId: projectId,
                unlockTimestamp: unlocksAt
            });
        }
    }

    // ── Internal ─────────────────────────────────────────────────────────────

    function _onlyConfiguredForProject(
        address coreContract,
        uint256 projectId
    ) private view {
        (address configuredHook, ) = IGenArt721CoreContractV3_Engine(
            coreContract
        ).projectTransferHookConfig(projectId);
        if (configuredHook != address(this)) {
            revert HookNotConfiguredForProject({
                coreContract: coreContract,
                projectId: projectId,
                configuredHook: configuredHook
            });
        }
    }
}
