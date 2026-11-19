#!/usr/bin/env bash
# Download a released dist tarball into ./dist.
#
#   ./scripts/fetch-dist.sh [tag]
#
# Defaults:
#   tag       v0.3831.0-themes.1
#   REPO_SLUG ivan-vibe/datalens-ui-crab  (override for your org)
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TAG="${1:-v0.3831.0-themes.1}"
VERSION="${TAG#v}"
REPO_SLUG="${REPO_SLUG:-ivan-vibe/datalens-ui-crab}"
ASSET="datalens-ui-crab-${VERSION}-dist.tar.gz"

if [ "${REPO_SLUG%%/*}" = "ivan-vibe" ]; then
    echo "error: set REPO_SLUG=owner/repo (or edit this script) before downloading." >&2
    exit 1
fi

if ! command -v gh >/dev/null 2>&1; then
    echo "error: gh (GitHub CLI) is required." >&2
    exit 1
fi

TMP="$(mktemp -d)"
trap 'rm -rf "${TMP}"' EXIT

echo "downloading ${ASSET} from ${REPO_SLUG}@${TAG}"
gh release download "${TAG}" \
    --repo "${REPO_SLUG}" \
    --pattern "${ASSET}" \
    --pattern "SHA256SUMS" \
    --dir "${TMP}"

if [ -f "${TMP}/SHA256SUMS" ]; then
    ( cd "${TMP}" && grep "  ${ASSET}\$" SHA256SUMS > CHECKSUM )
    if command -v sha256sum >/dev/null 2>&1; then
        ( cd "${TMP}" && sha256sum -c CHECKSUM )
    else
        ( cd "${TMP}" && shasum -a 256 -c CHECKSUM )
    fi
else
    echo "warning: SHA256SUMS not found in release; skipping checksum verification." >&2
fi

mkdir -p "${ROOT}/dist"
find "${ROOT}/dist" -mindepth 1 -maxdepth 1 ! -name '.gitkeep' -exec rm -rf {} +

tar -xzf "${TMP}/${ASSET}" -C "${ROOT}/dist"
test -f "${ROOT}/dist/public/build/manifest.json" || {
    echo "error: archive does not contain public/build/manifest.json" >&2
    exit 1
}

echo "dist ready: ${ROOT}/dist"
du -sh "${ROOT}/dist"
