# Example: plugin.video.cbilling.iptv

Пример использования kodi-docker для e2e-тестирования IPTV addon'а.

## Структура

```
examples/cbilling-iptv/
├── tests/
│   ├── connection.test.ts   — базовые тесты подключения к Kodi
│   └── addon.test.ts        — тесты навигации по addon'у
└── README.md
```

## Запуск

```bash
# Из корня kodi-docker:

# 1. Запустить Kodi (addon должен быть в kodi_data/addons/)
./scripts/start.sh headless

# 2. Запустить тесты
./scripts/test.sh $(pwd)/examples/cbilling-iptv/tests

# 3. Остановить
./scripts/stop.sh
```

## Что тестируется

- **connection.test.ts**: ping, версия Kodi, текущее окно, список addon'ов
- **addon.test.ts**: открытие addon'а, получение меню (Прямой эфир, Архив, Любимые каналы, Медиатека), навигация назад

## Импорт KodiClient

Тесты импортируют KodiClient из образа `kodi-e2e`:

```typescript
import { KodiClient } from "kodi-e2e/kodi-client.js";
```

Этот импорт работает автоматически при запуске через `kodi-e2e:latest`.
