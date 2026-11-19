#!/usr/bin/env bash
# Package a built dist/ and publish it as a GitHub Release asset.
#
#   ./scripts/release-dist.sh <path-to-dist> <version>
#   KEEP_MAPS=1 ./scripts/release-dist.sh /path/to/dist 0.3831.0-themes.2
#
# By default source maps are stripped: the .map files are ~78 MB of the
# 102 MB build and contain the fork's source code. Release artifacts are
# written to ./release/ (git-ignored) and uploaded with gh.
set -euo pipefail

SRC="${1:?usage: release-dist.sh <path-to-dist> <version>}"
VERSION="${2:?usage: release-dist.sh <path-to-dist> <version>}"
TAG="v${VERSION}"

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
REPO_SLUG="${REPO_SLUG:-ivan-vibe/datalens-ui-crab}"
OUT_DIR="${OUT_DIR:-${ROOT}/release}"
ASSET="datalens-ui-crab-${VERSION}-dist.tar.gz"

for required in public/build/manifest.json server shared ui i18n; do
    if [ ! -e "${SRC}/${required}" ]; then
        echo "error: ${SRC}/${required} not found; is this a built dist/?" >&2
        exit 1
    fi
done

mkdir -p "${OUT_DIR}"
STAGE="$(mktemp -d)"
trap 'rm -rf "${STAGE}"' EXIT

if [ "${KEEP_MAPS:-0}" = "1" ]; then
    echo "packaging with source maps"
    cp -R "${SRC}/." "${STAGE}/"
else
    echo "packaging without source maps (KEEP_MAPS=1 to keep them)"
    ( cd "${SRC}" && tar -cf - --exclude='*.map' . ) | ( cd "${STAGE}" && tar -xf - )
fi

tar -czf "${OUT_DIR}/${ASSET}" -C "${STAGE}" .
if command -v sha256sum >/dev/null 2>&1; then
    ( cd "${OUT_DIR}" && sha256sum "${ASSET}" > SHA256SUMS )
else
    ( cd "${OUT_DIR}" && shasum -a 256 "${ASSET}" > SHA256SUMS )
fi

echo "artifact: ${OUT_DIR}/${ASSET}"
du -sh "${OUT_DIR}/${ASSET}"
cat "${OUT_DIR}/SHA256SUMS"

if ! command -v gh >/dev/null 2>&1; then
    echo "gh not found: artifact is ready, upload it manually." >&2
    exit 0
fi

if gh release view "${TAG}" --repo "${REPO_SLUG}" >/dev/null 2>&1; then
    gh release upload "${TAG}" "${OUT_DIR}/${ASSET}" "${OUT_DIR}/SHA256SUMS" \
        --repo "${REPO_SLUG}" --clobber
else
    gh release create "${TAG}" "${OUT_DIR}/${ASSET}" "${OUT_DIR}/SHA256SUMS" \
        --repo "${REPO_SLUG}" \
        --title "UI ${VERSION}" \
        --notes "DataLens Theme Fork UI ${VERSION} (distribution build; source not included)."
fi
