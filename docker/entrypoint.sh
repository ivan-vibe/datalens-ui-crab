#!/bin/sh
# Entrypoint for the DataLens Theme Fork runtime image.
#
# It prepares the writable theme store and checks that the built UI is present,
# then hands over to the image's normal supervisord (nginx + node).
set -eu

THEMES_DATA_DIR="${THEMES_DATA_DIR:-/opt/app/theme-data}"
THEMES_DATA_PATH="${THEMES_DATA_PATH:-${THEMES_DATA_DIR}/themes.json}"
THEMES_SEED="${THEMES_SEED:-/opt/app/theme-data.seed/themes.json}"

if [ ! -d "${THEMES_DATA_DIR}" ]; then
    mkdir -p "${THEMES_DATA_DIR}" 2>/dev/null || true
fi

if [ ! -f "${THEMES_DATA_PATH}" ]; then
    if [ -f "${THEMES_SEED}" ] && [ -w "${THEMES_DATA_DIR}" ]; then
        cp "${THEMES_SEED}" "${THEMES_DATA_PATH}"
        chmod 0600 "${THEMES_DATA_PATH}" 2>/dev/null || true
        echo "theme-fork: seeded ${THEMES_DATA_PATH}"
    else
        echo "theme-fork: WARNING: ${THEMES_DATA_PATH} is missing and cannot be seeded;" >&2
        echo "theme-fork: mount a writable theme store (see README.md)." >&2
    fi
fi

if [ ! -f "${THEMES_DATA_PATH}" ] || [ ! -w "${THEMES_DATA_PATH}" ]; then
    echo "theme-fork: WARNING: theme store is not writable; theme changes will fail." >&2
fi

if [ ! -f /opt/app/dist/public/build/manifest.json ]; then
    echo "theme-fork: ERROR: built UI assets are missing from /opt/app/dist." >&2
    echo "theme-fork: run ./scripts/fetch-dist.sh <tag> or mount ./dist at /opt/app/dist:ro." >&2
    exit 1
fi

exec /usr/bin/supervisord -c /etc/supervisor/supervisord.conf
