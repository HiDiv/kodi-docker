#!/usr/bin/env bash
# Запуск Kodi в Docker-контейнере.
#
# Использование:
#   ./scripts/start.sh                    — Kodi 20, окно, GPU, звук
#   ./scripts/start.sh headless           — Kodi 20, headless (для тестов)
#   ./scripts/start.sh gui                — Kodi 20, полный экран, GPU, звук
#   ./scripts/start.sh headless kodi19    — Kodi 19, headless
#   ./scripts/start.sh windowed kodi21    — Kodi 21, окно, GPU, звук
#
# Режимы:
#   windowed  — окно на рабочем столе (по умолчанию)
#   gui       — полный экран
#   headless  — без GUI, доступ через VNC/noVNC

set -e
cd "$(dirname "$0")/.."

MODE="${1:-windowed}"
VERSION="${2:-kodi20}"
RESOLUTION="${3:-1280x720}"

# Проверки
if [ "$MODE" != "headless" ]; then
    if ! xhost 2>/dev/null | grep -q "LOCAL"; then
        echo "ОШИБКА: X11 доступ не настроен. Запустите: ./scripts/setup-host.sh"
        exit 1
    fi
fi

echo "=== Запуск Kodi ==="
echo "  Версия:    $VERSION"
echo "  Режим:     $MODE"
echo "  Разрешение: $RESOLUTION"
echo ""

export KODI_MODE="$MODE"
export KODI_RESOLUTION="$RESOLUTION"

# Порты (из .env или значения по умолчанию, избегаем конфликта с searx на 8080)
export HTTP_PORT="${HTTP_PORT:-18080}"
export WS_PORT="${WS_PORT:-19090}"
export VNC_PORT="${VNC_PORT:-15900}"
export NOVNC_PORT="${NOVNC_PORT:-18000}"
export EVENT_PORT="${EVENT_PORT:-19777}"

if [ "$MODE" = "headless" ]; then
    docker compose --profile "$VERSION" up -d
    echo ""
    echo "Kodi запущен в headless-режиме."
    echo "  JSON-RPC: http://localhost:${HTTP_PORT}/jsonrpc"
    echo "  noVNC:    http://localhost:${NOVNC_PORT}/vnc.html"
    echo "  VNC:      localhost:${VNC_PORT}"
else
    docker compose -f docker-compose.yml -f docker-compose.gpu.yml --profile "$VERSION" up -d
    echo ""
    echo "Kodi запущен в режиме $MODE."
    echo "  JSON-RPC: http://localhost:${HTTP_PORT}/jsonrpc"
fi

echo ""
echo "Остановка: ./scripts/stop.sh"
