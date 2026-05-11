#!/usr/bin/env bash
# Настройка хоста для запуска Kodi в Docker с GPU и звуком.
# Запускать один раз после перезагрузки системы.

set -e
echo "=== Настройка хоста для Kodi Docker ==="

# 1. Разрешить Docker доступ к X11
echo "[1/3] Разрешаю Docker доступ к X11..."
xhost +local:docker

# 2. Проверить PulseAudio socket
PULSE_SOCKET="/run/user/$(id -u)/pulse/native"
if [ -S "$PULSE_SOCKET" ]; then
    echo "[2/3] PulseAudio socket найден: $PULSE_SOCKET"
else
    echo "[2/3] ОШИБКА: PulseAudio socket не найден: $PULSE_SOCKET"
    echo "       Убедитесь что PulseAudio запущен (pulseaudio --check)"
    exit 1
fi

# 3. Проверить NVIDIA Container Toolkit
if command -v nvidia-ctk &>/dev/null; then
    echo "[3/3] NVIDIA Container Toolkit: OK"
    nvidia-smi --query-gpu=name,driver_version --format=csv,noheader 2>/dev/null || true
else
    echo "[3/3] ПРЕДУПРЕЖДЕНИЕ: nvidia-ctk не найден. GPU-ускорение недоступно."
fi

echo ""
echo "=== Готово! Можно запускать Kodi ==="
echo "  ./scripts/start.sh          — запуск Kodi 20 (GUI + GPU + звук)"
echo "  ./scripts/start.sh headless — запуск в headless-режиме"
echo "  ./scripts/stop.sh           — остановка"
