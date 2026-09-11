// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity ^0.8.22;

// ─── Imports ────────────────────────────────────────────────────────────────
//
// Option A — Foundry (copy sources locally, recommended):
//   Copy ITransferHook.sol and AbstractTransferHook.sol from artblocks-contracts
//   into your src/ directory, and change their "@openzeppelin-5.0/contracts/..."
//   imports to "@openzeppelin/contracts/...".
//     forge install OpenZeppelin/openzeppelin-contracts
//
// Option B — Hardhat / npm (the package ships sources, but they import through
//   an aliased OpenZeppelin path, so install the alias too):
//     npm install @artblocks/contracts \
//       "@openzeppelin-5.0/contracts@npm:@openzeppelin/contracts@5.0.1"
//
import {AbstractTransferHook} from "./AbstractTransferHook.sol";
import {IGenArt721CoreContractV3_Engine} from "./interfaces/IGenArt721CoreContractV3_Engine.sol";

// ─── Contract ───────────────────────────────────────────────────────────────

/**
 * @title ObserverTransferHook
 * @notice Art Blocks transfer hook that records something on every ownership
 *   change without ever blocking one.
 *
 *   The core calls onTokenTransfer after the ERC-721 ownership write, on both
 *   mints and transfers. AbstractTransferHook checks that msg.sender is the
 *   coreContract it was handed, then calls _onTokenTransfer below.
 *
 * @dev This is the safe shape to start from: it cannot brick a project,
 *   because it never reverts on a legitimate call. Every transfer of every
 *   token in an opted-in project pays for the storage writes here, so keep
 *   them few.
 */
contract ObserverTransferHook is AbstractTransferHook {
    /// @dev Art Blocks packs projectId and token index into the token ID.
    uint256 private constant ONE_MILLION = 1_000_000;

    // ── Custom errors ────────────────────────────────────────────────────────
    //
    // Prefer custom errors over require strings for gas efficiency.
    //

    /// @notice Thrown when a core calls this hook for a project that has not
    /// configured it.
    error HookNotConfiguredForProject(
        address coreContract,
        uint256 projectId,
        address configuredHook
    );

    // ── Storage ──────────────────────────────────────────────────────────────
    //
    // Key by (coreContract, tokenId). One hook can serve many cores and many
    // projects, and token IDs are only unique within a single core.
    //
    mapping(address coreContract => mapping(uint256 tokenId => uint256))
        public transferCount;

    // ── Events ───────────────────────────────────────────────────────────────

    event TransferObserved(
        address indexed coreContract,
        uint256 indexed tokenId,
        address indexed to,
        uint256 count
    );

    // ── Hook logic ───────────────────────────────────────────────────────────

    /**
     * @dev Called by the core after the ownership write. On mint this runs
     *   after the token hash seed is assigned, so reading tokenIdToHash here
     *   returns the final value.
     * @param coreContract Guaranteed by AbstractTransferHook to equal msg.sender.
     * @param from Previous owner; address(0) on mint.
     */
    function _onTokenTransfer(
        address coreContract,
        uint256 tokenId,
        address from,
        address to,
        address /* operator */
    ) internal override {
        // REQUIRED. AbstractTransferHook proves the caller is not impersonating
        // another contract; it cannot know which cores you serve. Without this,
        // anyone can deploy a contract that calls your hook from its own address
        // with any tokenId, from, to and operator it likes.
        _onlyConfiguredForProject({
            coreContract: coreContract,
            projectId: tokenId / ONE_MILLION
        });

        // ERC-721 permits transferFrom(a, a, id). Ownership did not actually
        // change, so most hooks should ignore it.
        if (from == to) {
            return;
        }

        uint256 count = transferCount[coreContract][tokenId] + 1;
        transferCount[coreContract][tokenId] = count;

        emit TransferObserved({
            coreContract: coreContract,
            tokenId: tokenId,
            to: to,
            count: count
        });
    }

    // ── Internal ─────────────────────────────────────────────────────────────

    /**
     * @dev Reverts unless `coreContract` has this contract configured as the
     *   transfer hook for `projectId`.
     */
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
