# Kodi Docker

**English** | [Русский](README.ru.md)

Universal Docker images and tools for running Kodi (versions 19, 20, 21) in various modes. Designed for manual and automated testing of Kodi addons.

## Features

- **Three Kodi versions**: 19 (Matrix), 20 (Nexus), 21 (Omega)
- **Three launch modes**: headless (for CI/tests), GUI (fullscreen), windowed
- **GPU acceleration**: NVIDIA via Container Toolkit (optional)
- **Audio**: PulseAudio via socket
- **E2e testing**: ready-to-use image with vitest + KodiClient (TypeScript)
- **Screenshots & video**: screen capture during testing
- **Config overlay**: save/restore Kodi settings between runs
- **Docker Compose**: profiles for version switching

## Quick Start

### Requirements

- Docker 23.0+ (with BuildKit)
- Docker Compose v2
- For GPU: NVIDIA Container Toolkit
- For GUI: X11 (Linux)

### 1. Host setup (once)

```bash
./scripts/setup-host.sh
```

### 2. Start Kodi

```bash
# Headless (for automated tests, access via VNC/noVNC)
./scripts/start.sh headless

# Windowed with GPU and audio (for manual testing)
./scripts/start.sh windowed

# Fullscreen
./scripts/start.sh gui
```

### 3. Run tests

```bash
./scripts/test.sh
```

### 4. Stop

```bash
./scripts/stop.sh
```

## Using in Your Project

This project is intended to be used as a subdirectory (or git submodule) in your addon project:

```
my-addon-project/
├── addon/                    ← your addon source
├── tests/                    ← your e2e tests
│   └── my-addon.test.ts
├── kodi-docker/              ← this project
│   ├── docker-compose.yml
│   └── ...
└── ...
```

### Writing Tests

Tests import `KodiClient` from the `kodi-e2e` image:

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
});
```

### Running Tests

```bash
docker run --rm --network host \
  -v /path/to/my-tests:/tests \
  -v /path/to/results:/results \
  -e KODI_HOST=localhost \
  -e KODI_WS_PORT=19090 \
  ghcr.io/hidiv/kodi-docker:e2e-latest
```

## Docker Images

| Image | Description | Size |
|-------|-------------|------|
| `kodi-docker:kodi19` | Kodi 19 (Matrix), Ubuntu 22.04 | ~826 MB |
| `kodi-docker:kodi20` | Kodi 20 (Nexus), Ubuntu 24.04 | ~1.1 GB |
| `kodi-docker:kodi21` | Kodi 21 (Omega), Ubuntu 24.04 + PPA | ~1.1 GB |
| `kodi-docker:e2e` | Test runner (node + vitest + KodiClient) | ~731 MB |

## Configuration

See [README.ru.md](README.ru.md) for detailed configuration documentation.

## License

MIT — see [LICENSE](LICENSE).

## Disclaimer

This software is provided "as is", without warranty of any kind. The authors are not liable for any damages arising from the use of this software. Use at your own risk.

Kodi® is a registered trademark of the XBMC Foundation. This project is not affiliated with or endorsed by the XBMC Foundation.

## Credits

Inspired by [bpawnzZ/docker-kodi](https://github.com/bpawnzZ/docker-kodi).
