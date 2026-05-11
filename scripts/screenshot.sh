#!/usr/bin/env bash
# Сделать скриншот Kodi из Docker-контейнера.
#
# Использование:
#   ./scripts/screenshot.sh              — скриншот с именем по timestamp
#   ./scripts/screenshot.sh my-screen    — скриншот с заданным именем

set -e
cd "$(dirname "$0")/.."

NAME="${1:-screenshot-$(date +%H%M%S)}"
CONTAINER="${KODI_CONTAINER:-kodi-docker-kodi20-1}"
OUTDIR="./test-results"

mkdir -p "$OUTDIR"

docker exec "$CONTAINER" scrot -D :99 "/tmp/${NAME}.png"
docker cp "$CONTAINER:/tmp/${NAME}.png" "${OUTDIR}/${NAME}.png"

echo "📸 ${OUTDIR}/${NAME}.png"
