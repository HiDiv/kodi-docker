#!/usr/bin/env bash
# Запись видео с экрана Kodi в Docker-контейнере.
#
# Использование:
#   ./scripts/record.sh start [name]   — начать запись
#   ./scripts/record.sh stop           — остановить и сохранить

set -e
cd "$(dirname "$0")/.."

ACTION="${1:-start}"
NAME="${2:-recording-$(date +%H%M%S)}"
CONTAINER="${KODI_CONTAINER:-kodi-docker-kodi20-1}"
OUTDIR="./test-results"

mkdir -p "$OUTDIR"

case "$ACTION" in
    start)
        echo "🎬 Начинаю запись: ${NAME}.mp4"
        docker exec -d "$CONTAINER" ffmpeg -y -f x11grab \
            -video_size 1280x720 -framerate 15 -i :99 \
            -c:v libx264 -preset ultrafast "/tmp/${NAME}.mp4"
        echo "$NAME" > "$OUTDIR/.recording_name"
        ;;
    stop)
        if [ -f "$OUTDIR/.recording_name" ]; then
            NAME=$(cat "$OUTDIR/.recording_name")
            rm -f "$OUTDIR/.recording_name"
        fi
        docker exec "$CONTAINER" pkill -INT ffmpeg 2>/dev/null || true
        sleep 2
        docker cp "$CONTAINER:/tmp/${NAME}.mp4" "${OUTDIR}/${NAME}.mp4" 2>/dev/null && \
            echo "🎬 Сохранено: ${OUTDIR}/${NAME}.mp4" || \
            echo "⚠️  Видео не найдено"
        ;;
    *)
        echo "Использование: $0 start|stop [name]"
        exit 1
        ;;
esac
