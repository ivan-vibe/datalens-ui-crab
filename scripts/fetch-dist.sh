#!/usr/bin/env bash
# Download a released dist tarball into ./dist.
#
#   ./scripts/fetch-dist.sh [tag]
#
# Defaults:
#   tag        v0.3831.0-themes.1
#   REPO_SLUG  ivan-vibe/datalens-ui-crab  (override for your org)
#
# Uses plain `curl` against the public GitHub release URL, so `gh` is not required.
# Both asset naming schemes are accepted (`datalens-ui-crab-<version>-dist.tar.gz`
# from scripts/release-dist.sh and `datalens-ui-crab-dist.tar.gz` from older
# manual uploads). When the release ships SHA256SUMS it is verified; otherwise a
# warning is printed.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TAG="${1:-v0.3831.0-themes.1}"
VERSION="${TAG#v}"
REPO_SLUG="${REPO_SLUG:-ivan-vibe/datalens-ui-crab}"
BASE_URL="https://github.com/${REPO_SLUG}/releases/download/${TAG}"
# Candidate asset names, most specific first.
CANDIDATES=(
    "datalens-ui-crab-${VERSION}-dist.tar.gz"
    "datalens-ui-crab-dist.tar.gz"
)

if ! command -v curl >/dev/null 2>&1; then
    echo "error: curl is required." >&2
    exit 1
fi

TMP="$(mktemp -d)"
trap 'rm -rf "${TMP}"' EXIT

download() {
    # download <asset> <dest>; returns non-zero on HTTP error
    curl -fsSL --retry 3 --retry-delay 2 -o "$2" "$1"
}

ASSET=""
for candidate in "${CANDIDATES[@]}"; do
    echo "trying ${BASE_URL}/${candidate}"
    if download "${BASE_URL}/${candidate}" "${TMP}/${candidate}"; then
        ASSET="${candidate}"
        break
    fi
done

if [ -z "${ASSET}" ]; then
    echo "error: no dist tarball found in release ${TAG} of ${REPO_SLUG}." >&2
    echo "       looked for: ${CANDIDATES[*]}" >&2
    echo "       check https://github.com/${REPO_SLUG}/releases" >&2
    exit 1
fi
echo "downloaded ${ASSET}"

if download "${BASE_URL}/SHA256SUMS" "${TMP}/SHA256SUMS" 2>/dev/null; then
    if grep -q "  ${ASSET}\$" "${TMP}/SHA256SUMS"; then
        ( cd "${TMP}" && grep "  ${ASSET}\$" SHA256SUMS > CHECKSUM )
        if command -v sha256sum >/dev/null 2>&1; then
            ( cd "${TMP}" && sha256sum -c CHECKSUM )
        else
            ( cd "${TMP}" && shasum -a 256 -c CHECKSUM )
        fi
    else
        echo "warning: ${ASSET} is not listed in SHA256SUMS; skipping verification." >&2
    fi
else
    echo "warning: release has no SHA256SUMS; skipping checksum verification." >&2
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
