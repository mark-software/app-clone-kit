#!/bin/bash

# ============================================================================
# app-clone-kit remote installer
# Downloads the repo and runs the local installer.
# Usage: curl -fsSL https://raw.githubusercontent.com/mark-software/app-clone-kit/main/bin/remote-install.sh | bash
# Global: curl -fsSL ... | bash -s -- --global
# ============================================================================

set -e

REPO="https://github.com/mark-software/app-clone-kit.git"
TMP_DIR="/tmp/app-clone-kit-$$"

cleanup() {
    rm -rf "$TMP_DIR"
}
trap cleanup EXIT

git clone --depth 1 --quiet "$REPO" "$TMP_DIR"
"$TMP_DIR/bin/install.sh" "$@"
