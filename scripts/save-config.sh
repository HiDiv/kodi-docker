#!/usr/bin/env bash
# Сохранение настроек Kodi из kodi_data в config/.
# Запускать ПОСЛЕ интерактивной сессии (когда Kodi остановлен).
#
# Использование:
#   ./scripts/save-config.sh              — сохранить для Kodi 20
#   ./scripts/save-config.sh kodi21       — сохранить для Kodi 21
#
# Что сохраняется:
#   - guisettings.xml (основные настройки)
#   - advancedsettings.xml (расширенные настройки)
#   - sources.xml (медиа-источники)
#   - addon_data/ (настройки addon'ов)
#
# Что НЕ сохраняется:
#   - Database/ (генерируется автоматически)
#   - Thumbnails/ (кэш)
#   - temp/ (логи)
#   - peripheral_data/

set -e
cd "$(dirname "$0")/.."

VERSION="${1:-kodi20}"
KODI_DATA="${KODI_DATA:-./kodi_data}"
CONFIG_DIR="./config/${VERSION}"
USERDATA="${KODI_DATA}/userdata"

if [ ! -d "$USERDATA" ]; then
    echo "ОШИБКА: каталог $USERDATA не найден."
    echo "Сначала запустите Kodi: ./scripts/start.sh windowed"
    exit 1
fi

echo "=== Сохранение настроек Kodi (${VERSION}) ==="
echo "  Источник: ${USERDATA}"
echo "  Назначение: ${CONFIG_DIR}"
echo ""

mkdir -p "$CONFIG_DIR"

# Список файлов для сохранения
FILES_TO_SAVE=(
    "guisettings.xml"
    "advancedsettings.xml"
    "sources.xml"
)

# Копирование отдельных файлов
for f in "${FILES_TO_SAVE[@]}"; do
    if [ -f "${USERDATA}/${f}" ]; then
        cp "${USERDATA}/${f}" "${CONFIG_DIR}/${f}"
        echo "  ✓ ${f}"
    fi
done

# Копирование addon_data (настройки addon'ов)
if [ -d "${USERDATA}/addon_data" ]; then
    mkdir -p "${CONFIG_DIR}/addon_data"
    # Копируем только settings.xml из каждого addon'а
    find "${USERDATA}/addon_data" -name "settings.xml" | while read -r settings_file; do
        rel_path="${settings_file#${USERDATA}/}"
        mkdir -p "${CONFIG_DIR}/$(dirname "$rel_path")"
        cp "$settings_file" "${CONFIG_DIR}/${rel_path}"
        echo "  ✓ ${rel_path}"
    done
fi

echo ""
echo "=== Готово ==="
echo ""

# Показать diff если git доступен
if git rev-parse --is-inside-work-tree &>/dev/null; then
    echo "Изменения (git diff):"
    git diff --stat -- "$CONFIG_DIR" 2>/dev/null || true
    echo ""
    git status --short -- "$CONFIG_DIR" 2>/dev/null || true
fi

echo ""
echo "Для фиксации: git add ${CONFIG_DIR} && git commit -m 'config: update ${VERSION} settings'"
