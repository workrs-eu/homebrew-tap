# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [0.1.8] - 2025-01-20

### Added
- **Queue Bindings** - Send events to message queues for async processing (`env.queue("analytics")`)
- **Geo Headers** - Automatic `X-Edge-Country`, `X-Edge-Region`, `X-Edge-City` headers on requests
- **SDK Utilities** - Added `regex`, `rand`, `sha2`, `chrono` crates to SDK
- **Claude Code Support** - `workrs-edge init` now optionally generates AI assistant configs

### Fixed
- KV storage now works correctly in deployed workers

## [0.1.6] - 2025-01-19

### Fixed
- Fixed Rust edition compatibility
- Removed unused imports and dead code warnings
- Applied clippy lints and code quality improvements

### Added
- Metrics collection and aggregation for gateway heartbeat

## [0.1.5] - 2025-01-19

### Added
- Initial release
- `workrs-edge` CLI with `init`, `build`, `dev`, `deploy`, `login` commands
- Worker SDK with `#[event(fetch)]` macro and KV storage bindings
- Homebrew installation (`brew install workrs-eu/tap/workrs-edge`)
- Binaries for macOS (Intel/Apple Silicon) and Linux (x64/ARM64)
