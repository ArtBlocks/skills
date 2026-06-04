// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity ^0.8.22;

// ─── Imports ────────────────────────────────────────────────────────────────
//
// Option A — Foundry (copy interfaces locally):
//   Copy IPMPConfigureHook.sol and IPMPV0.sol from artblocks-contracts into
//   your src/interfaces/ directory.
//
// Option B — Hardhat / npm:
//   npm install @artblocks/contracts @openzeppelin/contracts
//
import {IERC165} from "@openzeppelin/contracts/interfaces/IERC165.sol";
import {IPMPV0} from "./interfaces/IPMPV0.sol";
import {IPMPConfigureHook} from "./interfaces/IPMPConfigureHook.sol";

// ─── Contract ───────────────────────────────────────────────────────────────

/**
 * @title MyConfigureHook
 * @notice Art Blocks PostParam post-configuration hook.
 *
 *   Called after every configureTokenParams() write. Use this hook to
 *   validate or gate collector parameter changes — for example, requiring
 *   the collector to own a specific NFT before setting a param value.
 *
 * @dev WARNING: A revert in onTokenPMPConfigure rolls back the collector's
 *   ENTIRE configureTokenParams transaction. Be careful with access control
 *   and validation logic — a bug can permanently prevent collectors from
 *   configuring their tokens.
 *
 * @dev This function is NOT view — it can read state and emit events, but
 *   the primary use case is validation via revert.
 */
contract MyConfigureHook is IPMPConfigureHook {

    // ── Custom errors ─────────────────────────────────────────────────────────
    //
    // Prefer custom errors over require strings for gas efficiency.
    //
    // error NotTokenOwner();
    // error RequiredNFTNotOwned(address required, address collector);
    // error ParamLocked();

    // ── Constructor ──────────────────────────────────────────────────────────
    //
    // Add constructor args if your hook needs config (e.g. an NFT contract
    // address to check ownership against).
    //
    // address public immutable requiredNFT;
    // constructor(address _requiredNFT) {
    //     requiredNFT = _requiredNFT;
    // }

    // ── ERC165 ───────────────────────────────────────────────────────────────

    /**
     * @inheritdoc IERC165
     * @dev Must return true for IPMPConfigureHook.interfaceId.
     *   PMPV0 validates this on-chain during configureProjectHooks().
     */
    function supportsInterface(bytes4 interfaceId)
        external
        pure
        override
        returns (bool)
    {
        return interfaceId == type(IPMPConfigureHook).interfaceId
            || interfaceId == type(IERC165).interfaceId;
    }

    // ── Hook implementation ───────────────────────────────────────────────────

    /**
     * @notice Called after a token's param is successfully stored in PMPV0.
     * @dev Revert here to block the collector's configureTokenParams transaction.
     * @param coreContract The Art Blocks core NFT contract address.
     * @param tokenId      The token whose param was configured.
     * @param pmpInput     The param that was just stored.
     */
    function onTokenPMPConfigure(
        address coreContract,
        uint256 tokenId,
        IPMPV0.PMPInput calldata pmpInput
    ) external override {
        // TODO: add your validation logic here.
        //
        // Common patterns:
        //
        // 1. Gate on NFT ownership:
        //    address owner = IERC721(coreContract).ownerOf(tokenId);
        //    require(
        //        IERC721(requiredNFT).balanceOf(owner) > 0,
        //        "Must own required NFT"
        //    );
        //
        // 2. Gate on a specific param key:
        //    if (keccak256(bytes(pmpInput.key)) == keccak256(bytes("lockedParam"))) {
        //        revert("This param cannot be changed");
        //    }
        //
        // 3. Validate a numeric range beyond PMPV0's built-in constraints:
        //    uint256 val = uint256(pmpInput.configuredValue);
        //    require(val % 2 == 0, "Value must be even");
        //
        // 4. Emit an event for off-chain indexing:
        //    emit TokenConfigured(coreContract, tokenId, pmpInput.key);
        //
        // Suppress unused-variable warnings during development:
        coreContract;
        tokenId;
        pmpInput;
    }
}
