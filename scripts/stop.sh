#!/usr/bin/env bash
# Остановка Kodi Docker-контейнера.
#
# Использование:
#   ./scripts/stop.sh         — остановить (любой запущенный профиль)

set -e
cd "$(dirname "$0")/.."

echo "=== Остановка Kodi ==="

# Определить какой профиль запущен
RUNNING=$(docker compose ps --format "{{.Name}}" 2>/dev/null | head -1)

if [ -z "$RUNNING" ]; then
    # Попробовать с gpu override
    RUNNING=$(docker compose -f docker-compose.yml -f docker-compose.gpu.yml ps --format "{{.Name}}" 2>/dev/null | head -1)
fi

if [ -z "$RUNNING" ]; then
    echo "Нет запущенных контейнеров Kodi."
    exit 0
fi

echo "Останавливаю: $RUNNING"

# Остановить все возможные комбинации
docker compose -f docker-compose.yml -f docker-compose.gpu.yml \
    --profile kodi19 --profile kodi20 --profile kodi21 down 2>/dev/null || \
docker compose --profile kodi19 --profile kodi20 --profile kodi21 down 2>/dev/null || true

echo "Готово."
