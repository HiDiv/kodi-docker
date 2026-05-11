# Kodi Docker

[English](README.md) | **Русский**

Универсальный набор Docker-образов и инструментов для запуска Kodi (версии 19, 20, 21) в различных режимах. Предназначен для ручного и автоматического тестирования Kodi addon'ов.

## Возможности

- **Три версии Kodi**: 19 (Matrix), 20 (Nexus), 21 (Omega)
- **Три режима запуска**: headless (для автотестов), GUI (полный экран), windowed (окно)
- **GPU-ускорение**: NVIDIA через Container Toolkit (опционально)
- **Звук**: PulseAudio через socket
- **E2e-тестирование**: готовый образ с vitest + KodiClient (TypeScript)
- **Скриншоты и видео**: запись экрана Kodi при тестировании
- **Config overlay**: сохранение и восстановление настроек Kodi между запусками
- **Docker Compose**: profiles для переключения версий

## Быстрый старт

### Требования

- Docker 23.0+ (с BuildKit)
- Docker Compose v2
- Для GPU: NVIDIA Container Toolkit
- Для GUI: X11 (Linux)

### 1. Настройка хоста (один раз)

```bash
./scripts/setup-host.sh
```

### 2. Запуск Kodi

```bash
# Headless (для автотестов, доступ через VNC/noVNC)
./scripts/start.sh headless

# В окне с GPU и звуком (для ручного тестирования)
./scripts/start.sh windowed

# Полный экран
./scripts/start.sh gui
```

### 3. Запуск тестов

```bash
./scripts/test.sh
```

### 4. Остановка

```bash
./scripts/stop.sh
```

## Использование в своём проекте

Этот проект предназначен для использования как подкаталог (или git submodule) в проекте вашего addon'а:

```
my-addon-project/
├── addon/                    ← ваш addon
├── tests/                    ← ваши e2e-тесты
│   └── my-addon.test.ts
├── kodi-docker/              ← этот проект
│   ├── docker-compose.yml
│   └── ...
└── ...
```

### Написание тестов

Тесты импортируют `KodiClient` из образа `kodi-e2e`:

```typescript
import { KodiClient } from "kodi-e2e/kodi-client.js";
import { describe, it, expect, beforeAll, afterAll } from "vitest";

describe("My Addon", () => {
  let kodi: KodiClient;

  beforeAll(async () => {
    kodi = new KodiClient();
    await kodi.connect();
  });

  afterAll(() => kodi.disconnect());

  it("should be installed", async () => {
    const addons = await kodi.getAddons();
    expect(addons.find(a => a.addonid === "plugin.video.my-addon")).toBeDefined();
  });

  it("should show menu items", async () => {
    const items = await kodi.getDirectoryItems("plugin://plugin.video.my-addon/");
    expect(items.length).toBeGreaterThan(0);
  });
});
```

### Запуск тестов из своего проекта

```bash
# Из каталога kodi-docker:
docker run --rm --network host \
  -v /path/to/my-tests:/tests \
  -v /path/to/results:/results \
  -e KODI_HOST=localhost \
  -e KODI_WS_PORT=19090 \
  kodi-e2e:latest
```

## Настройка Kodi

### Сохранение настроек

После интерактивной настройки Kodi (язык, addon'ы, и т.д.):

```bash
./scripts/save-config.sh kodi20
```

Настройки сохраняются в `config/kodi20/` и автоматически применяются при следующем запуске.

### Что сохраняется

- `guisettings.xml` — основные настройки (язык, видео, аудио, сервисы)
- `advancedsettings.xml` — расширенные настройки
- `sources.xml` — медиа-источники
- `addon_data/*/settings.xml` — настройки addon'ов

## Скрипты

| Скрипт | Описание |
|--------|----------|
| `scripts/setup-host.sh` | Настройка хоста (xhost, проверка PulseAudio, NVIDIA) |
| `scripts/start.sh` | Запуск Kodi (headless/gui/windowed) |
| `scripts/stop.sh` | Остановка Kodi |
| `scripts/test.sh` | Запуск e2e-тестов |
| `scripts/screenshot.sh` | Скриншот экрана Kodi |
| `scripts/record.sh` | Запись/остановка видео |
| `scripts/save-config.sh` | Сохранение настроек Kodi |

## Docker-образы

| Образ | Описание | Размер |
|-------|----------|--------|
| `kodi-docker:kodi19` | Kodi 19 (Matrix), Ubuntu 22.04 | ~826 MB |
| `kodi-docker:kodi20` | Kodi 20 (Nexus), Ubuntu 24.04 | ~1.1 GB |
| `kodi-docker:kodi21` | Kodi 21 (Omega), Ubuntu 24.04 + PPA | ~1.1 GB |
| `kodi-docker:e2e` | Тестовое окружение (node + vitest + KodiClient) | ~731 MB |

## KodiClient API

Основные методы:

```typescript
// Подключение
await kodi.connect();
kodi.disconnect();

// Навигация
await kodi.navigate("up" | "down" | "left" | "right");
await kodi.select();
await kodi.back();

// GUI
await kodi.getCurrentWindow();
await kodi.activateWindow("videos", ["plugin://plugin.video.my-addon/"]);

// Файлы/каталоги
await kodi.getDirectoryItems("plugin://plugin.video.my-addon/");

// Addon'ы
await kodi.getAddons();
await kodi.executeAddon("plugin.video.my-addon");

// Плеер
await kodi.getActivePlayers();
await kodi.getPlayerProperties(playerId);
await kodi.playerPlayPause(playerId);
await kodi.playerStop(playerId);
await kodi.waitForPlayback(timeoutMs);

// Утилиты
await kodi.executeAction("screenshot");
await kodi.takeScreenshot();
```

## Переменные окружения

| Переменная | По умолчанию | Описание |
|-----------|-------------|----------|
| `KODI_MODE` | `headless` | Режим: headless, gui, windowed |
| `KODI_RESOLUTION` | `1280x720` | Разрешение экрана |
| `ENABLE_VNC` | `true` | Включить VNC-доступ |
| `ENABLE_NOVNC` | `true` | Включить noVNC (веб-доступ) |
| `CONFIG_PATH` | `./config/kodi20` | Путь к config overlay |
| `KODI_DATA` | `./kodi_data` | Путь к данным Kodi |
| `HTTP_PORT` | `18080` | Порт HTTP API |
| `WS_PORT` | `19090` | Порт WebSocket |
| `VNC_PORT` | `15900` | Порт VNC |
| `NOVNC_PORT` | `18000` | Порт noVNC |

## Лицензия

MIT — см. [LICENSE](LICENSE).

## Отказ от ответственности

Данное программное обеспечение предоставляется «как есть», без каких-либо гарантий. Авторы не несут ответственности за любой ущерб, возникший в результате использования данного ПО. Используйте на свой страх и риск.

Kodi® является зарегистрированной торговой маркой XBMC Foundation. Данный проект не связан с XBMC Foundation и не одобрен ею.

## Благодарности

Проект создан на основе идей [bpawnzZ/docker-kodi](https://github.com/bpawnzZ/docker-kodi).
