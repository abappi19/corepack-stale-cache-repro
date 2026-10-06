#!/usr/bin/env bash
# corepack@0.34.0 caches pnpm 12.2.1 with bin ./bin/pnpm.cjs, a file pnpm 12 doesn't ship.
# corepack@0.36.0 reuses that cached record and crashes. Exits 1 when the bug reproduces.
set -u
cd "$(dirname "$0")"
export COREPACK_HOME="$PWD/.corepack-home" COREPACK_ENABLE_DOWNLOAD_PROMPT=0
rm -rf "$COREPACK_HOME"

echo "### npx corepack@0.34.0 install"
npx -y corepack@0.34.0 install
echo "### cached record vs files on disk"
cat "$COREPACK_HOME/v1/pnpm/12.2.1/.corepack"; echo
ls "$COREPACK_HOME/v1/pnpm/12.2.1/bin"

echo "### npx corepack@0.36.0 pnpm --version"
out="$(npx -y corepack@0.36.0 pnpm --version 2>&1)"; echo "$out"

if grep -q "Cannot find module '.*/v1/pnpm/12.2.1/bin/pnpm.cjs'" <<<"$out"; then echo "BUG REPRODUCED"; exit 1; fi
echo "not reproduced"
