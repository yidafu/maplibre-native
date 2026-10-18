#!/bin/bash
# apply-patches.sh
# Apply HarmonyOS-specific patches to the maplibre-native core tree and vendor dependencies.
#
# Policy: the harmony branch only commits changes under platform/harmony. Everything
# else is carried as patch files in this directory and applied on demand
# (after a submodule update, or after resetting the tree to origin/main).
# Applied changes are NOT committed.
#
# Usage:
#   ./apply-patches.sh            # apply all patch groups
#   ./apply-patches.sh core       # only core patches (repo root; needs origin/main base)
#   ./apply-patches.sh vendor     # only vendor patches (boost, harfbuzz, maplibre-tile-spec)
#   ./apply-patches.sh revert     # reverse-apply everything, back to the clean origin/main baseline
#
# See README.md in this directory for base commits and known conflicts.

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# this script lives at <repo>/platform/harmony/patches — three levels up to the repo root
ROOT_DIR="${SCRIPT_DIR}/../../.."

if [ ! -f "${ROOT_DIR}/CMakeLists.txt" ]; then
    echo "Error: repo root not found at ${ROOT_DIR} (CMakeLists.txt missing)" >&2
    exit 1
fi

check_target() {
    # git apply silently ignores patched paths outside the cwd; make sure the
    # target is really there before feeding it any patch
    if [ ! -e "$1/.git" ] && [ ! -f "$1/CMakeLists.txt" ]; then
        echo "Error: patch target $1 does not look like a checkout" >&2
        exit 1
    fi
}

apply_group() {
    local patch_dir="$1" target_dir="$2"
    local applied=0 skipped=0
    check_target "${target_dir}"
    for patch in "${patch_dir}"/*.patch; do
        [ -f "$patch" ] || continue
        echo "  Applying: $(basename "$patch")"
        if (cd "${target_dir}" && git apply "$patch"); then
            applied=$((applied + 1))
        else
            echo "  Warning: $(basename "$patch") did not apply (already applied, or conflicts — see README.md)"
            skipped=$((skipped + 1))
        fi
    done
    echo "  -> ${applied} applied, ${skipped} skipped/failed"
}

revert_group() {
    local patch_dir="$1" target_dir="$2"
    local reverted=0 skipped=0
    check_target "${target_dir}"
    for patch in "${patch_dir}"/*.patch; do
        [ -f "$patch" ] || continue
        if (cd "${target_dir}" && git apply --reverse --check "$patch" 2>/dev/null && git apply --reverse "$patch"); then
            echo "  Reverted: $(basename "$patch")"
            reverted=$((reverted + 1))
        else
            echo "  Skipping: $(basename "$patch") (not currently applied)"
            skipped=$((skipped + 1))
        fi
    done
    echo "  -> ${reverted} reverted, ${skipped} skipped"
}

prune_upstream_ohos() {
    # upstream #4315 ships its own OHOS platform (platform/ohos + CI workflow);
    # it is redundant next to platform/harmony and core/0003 folds away the
    # CMake branch that included it. Policy (2026-09-19): keep it out of the
    # working tree.
    if [ -e "${ROOT_DIR}/platform/ohos" ] || [ -e "${ROOT_DIR}/.github/workflows/ohos-ci.yml" ]; then
        git -C "${ROOT_DIR}" rm -rf --quiet platform/ohos .github/workflows/ohos-ci.yml 2>/dev/null || true
        rm -rf "${ROOT_DIR}/platform/ohos" "${ROOT_DIR}/.github/workflows/ohos-ci.yml"
        echo "Pruned upstream platform/ohos + ohos-ci.yml (superseded by platform/harmony)"
    fi
}

do_core() {
    if [ -d "${SCRIPT_DIR}/core" ]; then
        prune_upstream_ohos
        echo "Applying core patches (against ${ROOT_DIR})..."
        echo "  NOTE: base must be the origin/main tree, NOT the harmony branch tree."
        apply_group "${SCRIPT_DIR}/core" "${ROOT_DIR}"
    fi
}

do_revert() {
    if [ -d "${SCRIPT_DIR}/core" ]; then
        echo "Reverting core patches (against ${ROOT_DIR})..."
        apply_group_revert_core
    fi
    do_revert_vendor
}

apply_group_revert_core() {
    # core patches are file-disjoint, so reverse order is not required
    revert_group "${SCRIPT_DIR}/core" "${ROOT_DIR}"
}

do_vendor() {
    if [ -d "${SCRIPT_DIR}/boost" ]; then
        echo "Applying Boost patches..."
        apply_group "${SCRIPT_DIR}/boost" "${ROOT_DIR}/vendor/boost"
    fi

    if [ -d "${SCRIPT_DIR}/harfbuzz" ]; then
        echo "Applying harfbuzz patches..."
        apply_group "${SCRIPT_DIR}/harfbuzz" "${ROOT_DIR}/vendor/harfbuzz"
    fi

    if [ -d "${SCRIPT_DIR}/maplibre-tile-spec" ]; then
        echo "Applying maplibre-tile-spec patches..."
        apply_group "${SCRIPT_DIR}/maplibre-tile-spec" "${ROOT_DIR}/vendor/maplibre-tile-spec"
    fi

    # Apply other vendor patches here as needed...
}

do_revert_vendor() {
    for sub in boost harfbuzz maplibre-tile-spec; do
        if [ -d "${SCRIPT_DIR}/$sub" ]; then
            echo "Reverting ${sub} patches..."
            revert_group "${SCRIPT_DIR}/$sub" "${ROOT_DIR}/vendor/$sub"
        fi
    done
}

case "${1:-all}" in
    core)   do_core ;;
    vendor) do_vendor ;;
    all)    do_core; do_vendor ;;
    revert) do_revert ;;
    *)      echo "Unknown group: $1 (use: core | vendor | all | revert)"; exit 1 ;;
esac

echo "Done applying patches."
