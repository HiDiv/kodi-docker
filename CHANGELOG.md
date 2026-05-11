# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- Docker images for Kodi 19 (Matrix), 20 (Nexus), 21 (Omega)
- Headless, GUI, and windowed launch modes
- NVIDIA GPU acceleration support via Container Toolkit
- PulseAudio audio passthrough for GUI mode
- E2e test runner image (node + vitest + KodiClient)
- KodiClient TypeScript library for Kodi JSON-RPC API
- Config overlay mechanism (save/restore Kodi settings)
- Docker Compose with profiles for version switching
- Scripts: start, stop, test, screenshot, record, save-config, setup-host
- GitHub Actions workflow for image publishing
- Example tests for plugin.video.cbilling.iptv
