# Harmony patches

Harmony branch policy: **only `platform/harmony/**` is committed directly on the
`harmony` branch.** All other code (core `src/`, `include/`, `cmake/`, root files,
vendor submodules) is carried as git patch files in this directory and applied on
demand — applied changes are **not** committed.

## Layout

| Directory | Target | Content |
|---|---|---|
| `core/` | repository root | Harmony branch changes to non-`platform/harmony` paths, split by theme |
| `boost/` | `vendor/boost` | HarmonyOS compile fix (pthread_setcancelstate) |
| `harfbuzz/` | `vendor/harfbuzz` | CMake: replace obsolete `FindPythonInterp` |
| `maplibre-tile-spec/` | `vendor/maplibre-tile-spec` | C++20/OHOS compiler compat fixes |

`core/` patches, in application order:

1. `0001-cpp20-ranges-iterator-compat.patch` — replaces `std::ranges::*` algorithms
   with iterator-pair equivalents (OHOS clang++ lacks full `<ranges>` support).
2. `0002-restore-custom-drawable-layer.patch` — restores the CustomDrawableLayer
   feature (style/renderer layers, layermanager factory, custom geometry /
   symbol-icon shaders for gl/mtl/vulkan/webgpu, shader registry hooks).
3. `0003-harmony-build-platform-fixes.patch` — OHOS cmake dispatch in root
   `CMakeLists.txt`, `VK_USE_PLATFORM_OHOS_KHR`, `Backend::GetTypeName` helper,
   `glMapBufferRange`→`glBufferSubData` fallback in the GL buffer allocator.

Not carried in patches (intentionally excluded build artifacts that are tracked on
the branch): `.hvigor/outputs/build-logs/build.log`,
`render-test/android/build/reports/problems/problems-report.html`.

## Base commits

- Patch base (what `core/*` diffs against): merge-base with origin/main
  `d5df4d12eaec` ("perf(core): Convert available images to copy-on-write").
- origin/main at generation time: `b7242e43a7ef`
  (includes upstream `core: Add HarmonyOS platform (#4315)` and
  `fix(core): pick raster-dem tiles (#4650)`).
- Generated from harmony branch: `bccc3ac44a84`.

## Usage

The tree outside `platform/harmony` is kept at a clean **origin/main baseline**
(index + working tree); the patches are **not** applied permanently. Apply them
only when a core / vendor build needs them, and revert afterwards if desired.

```bash
./platform/harmony/patches/apply-patches.sh core     # before building core for OHOS (needs origin/main base)
./platform/harmony/patches/apply-patches.sh vendor   # before building vendor deps
./platform/harmony/patches/apply-patches.sh          # everything
./platform/harmony/patches/apply-patches.sh revert   # un-apply everything, back to the clean baseline
```

State as of 2026-09-19: baseline restored (outside of `platform/harmony` the
tree is byte-identical to origin/main `b7242e43a7ef`), no patches applied, all
patches verified to apply cleanly in that state.

### Root `CMakeLists.txt`: upstream OHOS branch is folded away

Applying `core/0003` to origin/main yields a `CMakeLists.txt` with a **single**
OHOS branch: upstream #4315's
`elseif(OHOS) include(platform/ohos/ohos.cmake)` is removed, and harmony's
branch (default renderer + `include(platform/harmony/harmony.cmake)`) is the
only OHOS target. Reason: in the unpatched upstream tree both branches exist,
and CMake's first-match rule would silently dead-code harmony's branch —
`harmony.cmake` would never be included, breaking the build. Consequently the
`CMakeLists.txt` hunk in `0003` is generated against **origin/main**, not the
merge-base (every other hunk in `core/*` is a merge-base diff).

`platform/ohos/` and `.github/workflows/ohos-ci.yml` — upstream #4315's own
OHOS platform, redundant next to `platform/harmony` — are **deleted** from the
working tree; `apply-patches.sh core` prunes them automatically on every run.
To consult them for reference:
`git restore --source=origin/main -- platform/ohos .github/workflows/ohos-ci.yml`.

## Vendor submodule state (working tree, uncommitted by policy)

| Submodule | Pinned (HEAD == origin/main) | Checked out | Patch file |
|---|---|---|---|
| `vendor/boost` | `c6eb4cbc` | `bda61999` (Boost 1.86 bump) — `boost/0001` assumes this checkout | `boost/0001` |
| `vendor/harfbuzz` | `c1eb66d4` | same | `harfbuzz/0001` |
| `vendor/maplibre-tile-spec` | `751ebb18` | same | `maplibre-tile-spec/0001` |
| `vendor/wgpu-native` | `d2e3330a` | `74f8c24c` (older than pinned) | none (checkout drift only, no content diff) |

As of 2026-09-19 the vendor working trees carry **no** patch content (reverted
to their checked-out HEAD); run `apply-patches.sh vendor` before building.
`boost/0001` only applies on top of the `bda61999` checkout — keep that drift.

To restore the recorded pointer of a submodule:
`git -C vendor/<name> checkout <pinned-sha>`; re-run `apply-patches.sh vendor` after.

## Regenerating patches

```bash
BASE=d5df4d12eaec   # merge-base(harmony, origin/main); bump after the next sync
git diff --binary $BASE HEAD -- <paths outside platform/harmony> > platform/harmony/patches/core/NNNN-<name>.patch
git -C vendor/harfbuzz diff          > platform/harmony/patches/harfbuzz/NNNN-<name>.patch
git -C vendor/maplibre-tile-spec diff > platform/harmony/patches/maplibre-tile-spec/NNNN-<name>.patch
```

After regenerating, verify before relying on them (expect **no** conflicts —
the CMakeLists merge is already baked into `0003`):

```bash
git worktree add --detach /tmp/mn-verify origin/main
for p in platform/harmony/patches/core/*.patch; do
  git -C /tmp/mn-verify apply "$p" || echo "CONFLICT: $p"
done
git -C vendor/<sub> apply --reverse --check <patch>   # while the patch content is applied
git worktree remove --force /tmp/mn-verify
```
