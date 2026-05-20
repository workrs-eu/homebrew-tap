# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [0.1.10] - 2026-05-20

Re-release of 0.1.9. The 0.1.9 pipeline failed in the release/publish
stage on CI bugs, so no binaries were published. This tag ships the
identical dependency set and source with the pipeline fixes in place.

### Fixed
- CI `homebrew:publish` now captures the HTTP status on the GitHub release API calls and fails with the response body instead of POSTing artifacts to a null upload URL.
- CI `lint:audit` checks the real `cargo-audit` binary path rather than `PATH`, so a populated `cargo-audit-bin` cache no longer makes `cargo install` abort with "binary already exists".

## [0.1.9] - 2026-05-19

### Security
- Bumped wasmtime from 36.0.7 to 36.0.9 to resolve RUSTSEC-2026-0114 (panic on oversized table allocation). Stays on the 36.x LTS line; `wasmtime` and `wasmtime-wasi` are kept aligned.
- Removed the unused workspace-level `rand = "0.8"` declaration (no source file in this workspace imports `rand`; the transitive 0.8 tree arrives via `sqlx-mysql`, `tungstenite`, `cap-rand`, `quinn-proto`, and `num-bigint-dig`). Documented an ignore for RUSTSEC-2026-0097 in `.cargo/audit.toml` with the reachability rationale; revisit when sqlx 0.9 and a tungstenite release on rand 0.9 land.
- Disabled HTTP redirect follow on the gateway's worker fetch client and both webhook delivery clients (`gateway/src/worker/executor.rs`, `gateway/src/webhooks/dispatcher.rs`, `gateway/src/webhooks/queue_consumer.rs`). Previously a remote endpoint could redirect to `http://127.0.0.1` / `http://169.254.169.254` and bypass the SSRF validator, which only inspected the initial URL.
- Extended `validate_webhook_url` to call the full SSRF validator (private IPs, cloud metadata endpoints, IPv6 loopback, obfuscated IP encodings, userinfo bypasses) instead of only checking the HTTPS scheme. The SSRF module moved from `gateway/src/worker/ssrf.rs` to `gateway/src/ssrf.rs` so webhook and worker paths share one implementation.
- Hardened the worker-sdk proc-macro generated `__alloc` / `__dealloc` exports so they no longer panic on zero-size or misaligned allocations (uses the Rust 1.95 `Layout::dangling_ptr` API). Replaced the nested `serde_json::to_vec(...).unwrap()` fallback in `encode_response` / `encode_scheduled_result` with a static hand-rolled JSON byte constant so a serialization failure cannot crash the worker mid-request.
- Added `X-Webhook-Id` header to every webhook delivery (`gateway/src/webhooks/dispatcher.rs`, `gateway/src/webhooks/queue_consumer.rs`). The dispatcher path derives a deterministic UUID from the DB row id so retries of the same delivery share an id, letting receivers de-duplicate. Documented the receiver validation contract (timestamp freshness window, constant-time signature compare, id-based idempotency) in `docs/webhooks.md` with a minimal Rust example.
- Bumped wasmtime from 27 to 36.0.7 to resolve RUSTSEC-2026-0096 (Cranelift aarch64 sandbox escape), RUSTSEC-2026-0088 (pooling allocator data leak), RUSTSEC-2026-0020 (WASI resource exhaustion).
- Bumped aws-lc-sys to 0.40.0 (via aws-lc-rs 1.16.3) to resolve RUSTSEC-2026-0045 (AES-CCM timing side-channel), RUSTSEC-2026-0044 (X.509 name constraints bypass via wildcard/Unicode CN), RUSTSEC-2026-0048 (CRL distribution point scope check logic error), RUSTSEC-2026-0047 (PKCS7_verify signature validation bypass), RUSTSEC-2026-0046 (PKCS7_verify certificate chain validation bypass).
- Bumped rustls-webpki to 0.103.13 to resolve RUSTSEC-2026-0104 (reachable panic in CRL parsing), RUSTSEC-2026-0098 (URI name constraints incorrectly accepted), RUSTSEC-2026-0099 (name constraints accepted for wildcard certificates), RUSTSEC-2026-0049 (CRLs not considered authoritative by distribution point due to faulty matching).
- Bumped rustls to 0.23.39 (from 0.23.36) alongside the TLS stack refresh; patch-level only, no API changes.
- Added `.cargo/audit.toml` with documented ignores for five residual advisories that cannot currently be patched on stable dependency releases (`bytes`, `maxminddb`, `protobuf`, `quinn-proto`, `rsa`). Each entry includes a justification and the reason the vulnerable code path is not reachable or not mitigated yet. CI's `lint:audit` job now blocks only on NEW vulnerabilities; maintenance warnings (unmaintained / unsound-feature / yanked) surface in job logs for release triage.

### Changed
- Bumped worker-sdk `matchit` from 0.8 to 0.9. The `Router` wrapper in `worker-sdk/src/utils/router.rs` keeps its public API source-compatible (`Match { value, params }` was already the shape we exposed).
- Bumped `sysinfo` (gateway health endpoint) from 0.32 to 0.39; the methods we touch (`System::new`, `refresh_memory`, `Disks::new_with_refreshed_list`, `Disk::mount_point`, `total_space`, `available_space`) are unchanged.
- Refreshed transitive deps via `cargo update`: chrono 0.4.43 to 0.4.44, regex 1.10 to 1.12.3, futures-util 0.3.31 to 0.3.32, tokio 1.49 to 1.52, rustls 0.23.39 to 0.23.40, uuid 1.19 to 1.23, tempfile 3.24 to 3.27, sqlx 0.8.x patch. No API-level changes; lockfile diff confined to known crate families.
- Removed the redundant inline `sqlx` declaration from `gateway/Cargo.toml`; gateway now inherits the workspace `sqlx` definition (same features, same version).
- Bumped MSRV to Rust 1.95.0. `rust-toolchain.toml` now pins an exact version (was `stable`) so local developer builds, CI, and release builds are all byte-for-byte reproducible. The CI `build:*` jobs use `rust:1.95`, and a new `lint` stage runs `cargo fmt --check`, `cargo clippy -D warnings`, and `cargo audit` on every push and merge request.
- Hoisted `sqlx = { version = "0.8", features = ["runtime-tokio", "mysql", "chrono", "uuid"] }` to `[workspace.dependencies]` in the root `Cargo.toml`; `gateway/Cargo.toml` now inherits via `sqlx = { workspace = true }`. Feature set and version are unchanged, so `Cargo.lock` is untouched.
- Split gateway `/health` into two endpoints: `/health` now returns a minimal unauthenticated liveness payload (`{"status":"ok"}`) safe for load-balancer and orchestrator probes, while the full diagnostic payload moves to `/health/detailed`. The detailed endpoint requires `Authorization: Bearer <token>` matching `health_detailed_token` (TOML) or the `HEALTH_DETAILED_TOKEN` env var; if unset, the route is not registered (returns 404).

### Added
- CLI `build --release` now auto-runs Binaryen's `wasm-opt -Oz --strip-debug --strip-producers` when the `wasm-opt` binary is on `PATH`, typically shrinking worker WASM by 50-70% for faster cold starts. If `wasm-opt` is missing, the build prints a warning with install instructions and continues. Pass `--no-wasm-opt` to skip the step.
- Add queue bindings support to CLI deploy command (edge.toml `[queue_bindings]`)
- Add 5 missing dev runtime host functions: `__host_fetch`, `__host_cache_get/put/delete`, `__host_webhook_send`
- Add SSRF validation module to edge-cli for dev runtime fetch safety
- Add cron-based worker scheduler with timezone-aware evaluation (`chrono-tz`)
- Add `execute_scheduled()` to gateway executor for `__worker_scheduled` WASM export
- Add token bucket rate limiter with per-team and per-worker buckets
- Add module cache disk tracking with LRU eviction when exceeding `max_disk_size`
- Add cache stats and rate limiter status to health endpoint

### Added (previous)
- Wire WASI preview1 into gateway linker so `wasm32-wasip1` workers can instantiate
- Implement 5 missing host functions: `__host_fetch`, `__host_cache_get/put/delete`, `__host_queue_send`
- Add gateway-side SSRF validation module with DNS resolution check for outbound fetch
- Add `queue_bindings` to Worker state and control plane config deserialization
- Add shared `reqwest::Client` on WorkerExecutor for connection-pooled outbound requests

### Fixed
- Fix deploy CLI→server field mismatch: `module_hash`→`wasm_hash`, `env`→`environment`
- Align deploy response parsing: `worker_id`→`id`, add `name`, remove `url`
- Update deployment status polling URL and response format to match new server endpoint

### Added
- Handle `rotate_key` command for zero-downtime API key rotation
- `Config::update_api_key()` to persist rotated key to TOML config on disk
- Wrap API key in `RwLock` for in-memory hot-swap during rotation

### Fixed
- Fix gateway not shutting down on restart/stop commands — server now listens for cancellation token
- Fix command poll deserialization: parse `{"commands": [...]}` wrapper instead of raw array

### Added
- `--version` flag on gateway binary (reads from `CARGO_PKG_VERSION`)
- Backup current binary before replacing during `update_binary` command

### Changed
- Upgrade gateway operational logging from debug to info level for visibility in Docker/production logs
- Send heartbeat to control plane on every sync cycle, not just on config changes
- Add error backoff to webhook dispatcher to prevent log spam when table is missing

### Added
- KV store migration (`migrations/20250101_create_kv_tables.sql`) for `kv_data` table schema

### Added
- **Health Endpoint** - Comprehensive `/health` endpoint for control plane monitoring
  - Returns JSON (default) or MessagePack (`Accept: application/msgpack`)
  - System: load average, memory usage, disk usage
  - Connectivity: MariaDB/Valkey ping latency, pool stats, control plane sync status
  - Runtime: module cache stats (memory/disk counts)
  - Metrics: requests total, requests/sec, active requests, error rate, active teams/workers
  - Health status: `healthy`, `degraded` (cache down, high error rate, stale sync, high load, disk full), `unhealthy` (DB unreachable → HTTP 503)
  - Includes edge_id, uptime, version for node identification
- **Metrics Endpoint** - Detailed `/metrics` endpoint with per-worker/per-host stats
  - Prometheus text format (default, backward compatible)
  - JSON (`Accept: application/json`) or MessagePack (`Accept: application/msgpack`)
  - Per-worker: execution count, avg latency, cold starts, errors by type
  - Per-host: request count, avg latency
  - KV operations: counts and latencies by operation type (get/put/delete/list)
  - Connection pools: MariaDB and Valkey pool size/idle stats
- **Webhook API** - Fire-and-forget webhook delivery system for workers
  - Simple SDK API: `env.webhook(url).header("X-Key", "val").send(payload)`
  - JSON helper: `env.webhook(url).send_json(&data)` with automatic Content-Type
  - Durable delivery: Valkey buffer → MariaDB persistence → HTTP delivery
  - Automatic retries with exponential backoff (0s, 1m, 5m, 30m, 2h)
  - Usage tracking with monthly tier limits (Free: 10K, Pro: 100K, Business: 1M)
  - Size limits: URL 2KB, headers 8KB, payload 1MB
- **SNI-Based Certificate Routing** - Dynamic TLS certificate selection based on Server Name Indication
  - Custom domain support with automatic certificate selection per hostname
  - Wildcard certificate matching (`*.example.com`)
  - Fallback certificate for unmatched domains
  - Certificate sync from control plane with hot-reload (no restart required)
- **Team Slug Path Routing** - Path-based routing for shared edge domains
  - Access workers via `edge-1.workrs.eu/<team-slug>/api/users`
  - Automatic path prefix stripping (worker receives `/api/users`)
  - Configurable edge domains in gateway config
- **Geolocation API** - Structured `Geo` struct with `req.geo()` access, includes `is_eu()` helper
- **Fetch API** - Make outbound HTTP requests from workers with `fetch(url, options)`
- **Cache API** - Edge cache with `env.cache()` for fast read/write caching
- **Scheduled Events** - `#[event(scheduled)]` macro for cron/scheduled job handlers
- **KV Store Trait** - `KvStore` trait for abstracting KV operations, `MockKvStore` for testing
- **Cookie Utilities**:
  - `parse_cookies()` - Parse HTTP Cookie header into key-value pairs
  - `CookieBuilder` - Build Set-Cookie headers with all attributes (Path, Domain, Max-Age, Secure, HttpOnly, SameSite)
  - `delete_cookie()` - Create a cookie that expires immediately
- **CORS Helpers**:
  - `CorsBuilder` - Configure allowed origins, methods, headers, and credentials
  - Preflight response handling for OPTIONS requests
  - Support for single origin, multiple origins, and wildcard origins
- **Form Parsing**:
  - `parse_form()` - Parse URL-encoded form data (application/x-www-form-urlencoded)
  - Support for multiple values per field, URL encoding/decoding
- **Input Validation**:
  - `is_email()`, `is_url()`, `is_uuid()` - Format validators
  - `is_alphanumeric()`, `is_identifier()`, `is_slug()` - String pattern validators
  - `validate_length()`, `validate_range()` - Range validators
  - `validate_one_of()`, `validate_with()` - Custom validation helpers
- **Rate Limiting**:
  - `RateLimiter` - Fixed window rate limiter with KV storage
  - `SlidingWindowRateLimiter` - Smoother rate limiting across window boundaries
  - `TokenBucket` - Token bucket for burst traffic handling
- **URL Routing**:
  - `Router` - Efficient trie-based URL matching with path parameters
  - `MethodRouter` - HTTP method-aware routing (GET, POST, PUT, etc.)
  - Support for wildcards (`{*path}`) and named parameters (`{id}`)
- **JWT Validation**:
  - `validate_jwt()` - Verify JWTs signed with HS256/HS384/HS512
  - `create_jwt()` - Create signed JWTs
  - Time validation (exp, nbf claims) with configurable leeway
  - Constant-time signature comparison for security
- **Utility Functions**:
  - HMAC: `hmac_sha256`, `hmac_sha384`, `hmac_sha512`, `hmac_sha256_verify`
  - Encoding: `base64_encode`, `base64_decode`, `base64_url_encode`, `base64_url_decode`
  - Encoding: `hex_encode`, `hex_decode`
  - UUID: `uuid_v4` (random), `uuid_v7` (time-sortable)
  - Security: `constant_time_compare` for timing-safe comparisons

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
