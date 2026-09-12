#!/usr/bin/env bash
#
# verify-vulkan-backend.sh — Vulkan backend compile gate for the HarmonyOS platform.
#
# The HarmonyOS module ships with -DMLN_WITH_VULKAN=OFF (OpenGL is the default
# render backend), so `harmony_vulkan_renderer_backend.{hpp,cpp}` never
# participate in day-to-day builds and can silently rot (see
# maplibre_harmony/DEPRECATED_CODE_AUDIT.md §5.2). This script configures a
# throwaway CMake build with the Vulkan backend enabled and compiles the
# backend translation unit — no device, no HAP, no full library link.
#
# Requirements on PATH: cmake, ninja.
# Environment:
#   DEVECO_SDK_HOME  DevEco SDK root (default: /Applications/DevEco-Studio.app/Contents/sdk
#                    or <repo>/ohos-sdk if you provide OHOS_NATIVE instead)
#   OHOS_NATIVE      Explicit path to the OpenHarmony `native` directory
#                    (overrides DEVECO_SDK_HOME; used by CI)
#   OHOS_ARCH        Target ABI (default: arm64-v8a)
#
# Usage:
#   ./platform/harmony/scripts/verify-vulkan-backend.sh
#   exit 0 = Vulkan backend compiles, non-zero = broken.

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
MODULE_DIR="${REPO_ROOT}/platform/harmony/maplibre_harmony"
BUILD_DIR="${MODULE_DIR}/.cxx/vulkan-gate"
OHOS_ARCH="${OHOS_ARCH:-arm64-v8a}"

VULKAN_OBJ="CMakeFiles/maplibre.dir/rendering/backends/harmony_vulkan_renderer_backend.cpp.o"

# ---------------------------------------------------------------------------
# Resolve the OpenHarmony native toolchain directory
# ---------------------------------------------------------------------------
if [[ -n "${OHOS_NATIVE:-}" ]]; then
    NATIVE_DIR="${OHOS_NATIVE}"
elif [[ -n "${DEVECO_SDK_HOME:-}" ]]; then
    NATIVE_DIR="${DEVECO_SDK_HOME}/default/openharmony/native"
elif [[ "$(uname -s)" == "Darwin" && -d "/Applications/DevEco-Studio.app/Contents/sdk" ]]; then
    DEVECO_SDK_HOME="/Applications/DevEco-Studio.app/Contents/sdk"
    NATIVE_DIR="${DEVECO_SDK_HOME}/default/openharmony/native"
else
    echo "ERROR: set OHOS_NATIVE (OpenHarmony native dir) or DEVECO_SDK_HOME" >&2
    exit 2
fi

TOOLCHAIN_FILE="${NATIVE_DIR}/build/cmake/ohos.toolchain.cmake"
if [[ ! -f "${TOOLCHAIN_FILE}" ]]; then
    echo "ERROR: toolchain file not found: ${TOOLCHAIN_FILE}" >&2
    exit 2
fi

CMAKE_BIN="${NATIVE_DIR}/build-tools/cmake/bin/cmake"
if [[ ! -x "${CMAKE_BIN}" ]]; then
    CMAKE_BIN="$(command -v cmake)"
fi
NINJA_BIN="${NATIVE_DIR}/build-tools/cmake/bin/ninja"
if [[ ! -x "${NINJA_BIN}" ]]; then
    NINJA_BIN="$(command -v ninja)"
fi

echo "== Vulkan backend compile gate =="
echo "   repo:       ${REPO_ROOT}"
echo "   native sdk: ${NATIVE_DIR}"
echo "   arch:       ${OHOS_ARCH}"
echo "   build dir:  ${BUILD_DIR}"
echo

# ---------------------------------------------------------------------------
# Configure the module CMake with the Vulkan backend enabled
# ---------------------------------------------------------------------------
if [[ -n "${DEVECO_SDK_HOME:-}" ]]; then
    export DEVECO_SDK_HOME
else
    export DEVECO_SDK_HOME="$(dirname "$(dirname "$(dirname "${NATIVE_DIR}")")")"
fi

mkdir -p "${BUILD_DIR}"
"${CMAKE_BIN}" -G Ninja \
    -S "${MODULE_DIR}/src/main/cpp" \
    -B "${BUILD_DIR}" \
    -DCMAKE_TOOLCHAIN_FILE="${TOOLCHAIN_FILE}" \
    -DCMAKE_MAKE_PROGRAM="${NINJA_BIN}" \
    -DCMAKE_BUILD_TYPE=Debug \
    -DCMAKE_OHOS_ARCH_ABI="${OHOS_ARCH}" \
    -DOHOS_ARCH="${OHOS_ARCH}" \
    -DMLN_WITH_VULKAN=ON \
    -DMLN_WITH_OPENGL=OFF \
    >"${BUILD_DIR}/configure.log" 2>&1 || {
        echo "CMake configure FAILED — last 40 log lines:" >&2
        tail -40 "${BUILD_DIR}/configure.log" >&2
        exit 1
    }
echo "   configure:  OK"

# ---------------------------------------------------------------------------
# Compile only the Vulkan backend translation unit
# ---------------------------------------------------------------------------
if (cd "${BUILD_DIR}" && "${NINJA_BIN}" "${VULKAN_OBJ}"); then
    echo
    echo "PASS: harmony_vulkan_renderer_backend.cpp compiles with MLN_WITH_VULKAN=ON"
else
    echo
    echo "FAIL: harmony_vulkan_renderer_backend.cpp does not compile" >&2
    echo "      (run 'ninja -C ${BUILD_DIR} ${VULKAN_OBJ}' for details)" >&2
    exit 1
fi
