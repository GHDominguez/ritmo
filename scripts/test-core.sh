#!/bin/zsh
set -euo pipefail

PROJECT_DIR="${0:A:h:h}"
TEST_DIR="$(mktemp -d)"
trap 'rm -rf "$TEST_DIR"' EXIT

clang \
    -fobjc-arc \
    -fmodules \
    -fmodules-cache-path="$TEST_DIR/ModuleCache" \
    -fblocks \
    -mmacosx-version-min=14.0 \
    -I "$PROJECT_DIR/Native" \
    "$PROJECT_DIR"/Native/RitmoCore.m \
    "$PROJECT_DIR"/Native/RitmoCoreTests.m \
    -framework Foundation \
    -o "$TEST_DIR/RitmoCoreTests"

"$TEST_DIR/RitmoCoreTests"
