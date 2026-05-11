#!/usr/bin/env bash
# Запуск e2e-тестов для Kodi addon.
# Тесты выполняются в Docker-образе kodi-e2e:latest.
# Kodi должен быть запущен (./scripts/start.sh headless).
#
# Использование:
#   ./scripts/test.sh                     — запустить все тесты из e2e/tests/
#   ./scripts/test.sh /path/to/tests      — запустить тесты из указанной директории
#   ./scripts/test.sh --install           — (deprecated) зависимости уже в образе

set -e
cd "$(dirname "$0")/.."

TEST_DIR="${1:-$(pwd)/e2e/tests}"
HTTP_PORT="${HTTP_PORT:-18080}"
WS_PORT="${WS_PORT:-19090}"

if [ "$1" = "--install" ]; then
    echo "Зависимости уже встроены в образ kodi-e2e:latest."
    echo "Пересоберите образ: docker build -t kodi-e2e:latest -f docker/Dockerfile.e2e ."
    exit 0
fi

# Проверить что Kodi запущен
if ! curl -sf -X POST -H "Content-Type: application/json" \
    -d '{"jsonrpc":"2.0","method":"JSONRPC.Ping","id":1}' \
    "http://localhost:${HTTP_PORT}/jsonrpc" | grep -q pong; then
    echo "ОШИБКА: Kodi не запущен или не отвечает на порту ${HTTP_PORT}."
    echo "Запустите: ./scripts/start.sh headless"
    exit 1
fi

echo "=== Запуск e2e-тестов ==="
mkdir -p ./test-results

docker run --rm --network host \
    -v "${TEST_DIR}:/tests" \
    -v "$(pwd)/test-results:/results" \
    -e KODI_HOST=localhost \
    -e KODI_HTTP_PORT="${HTTP_PORT}" \
    -e KODI_WS_PORT="${WS_PORT}" \
    -e TEST_FILTER="${TEST_FILTER:-}" \
    kodi-e2e:latest

echo ""
echo "=== Результаты: ./test-results/ ==="
ls -la ./test-results/ 2>/dev/null || true
