# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [0.2.1] - 2026-09-14

The `v0.2.0` tag pipeline failed on the CI `lint:audit` gate and published nothing: there is
no GitHub release and no Homebrew formula for 0.2.0. This tag is the first published build of
the 0.2.0 feature set (origin proxy, WAF engine, split listeners), with the audit fix, the
Rust 1.98 toolchain and the dependency refresh below on top.

### Changed
- Rust toolchain moved from 1.95.0 to 1.98.1. `rust-toolchain.toml` pins the exact version, the CI lint and build jobs use `rust:1.98-slim` and `rust:1.98`, and the gateway images build on `rust:1.98-bookworm` (`gateway/Dockerfile` was still on the stale 1.85, the workrs-network gateway builder floated on `rust:1-bookworm` and is now pinned).
- Full lockfile refresh: one `cargo update` moved every dependency to its newest semver-compatible release. This is what clears the eight advisories below; every later dependency change in this release was scoped with `cargo update -p <crate>`.
- Bumped `dirs` from 6 to 7 (CLI login config path).
- Bumped `tokio-tungstenite` from 0.29 to 0.30. No API change at the call sites (config subscriber, `tail`).
- Bumped `prometheus` from 0.13 to 0.14, which moves `protobuf` from 2.x to 3.7.2 and retires the RUSTSEC-2024-0437 ignore. The metric accessor renames (`get_name` to `name` and friends) are applied in `gateway/src/metrics.rs` and `gateway/src/health.rs`.
- Bumped `jsonschema` from 0.46 to 0.56 for the WAF API Shield validator; the code already used the `validator_for`/`Validator`/`iter_errors` API.
- Bumped `maxminddb` from 0.24 to 0.32 and migrated the geo lookup: `lookup()` now returns a result that is decoded with `decode::<geoip2::City>()`, nested structs became non-optional `Default` values, `subdivisions` is a `Vec` and `names` is a struct. Behaviour is unchanged for a missing database and an unknown IP (both yield no geo data).
- Bumped `reqwest` from 0.12 to 0.13: TLS verification now goes through `rustls-platform-verifier` (OS store on Linux, keychain on macOS), crypto provider `ring` to `aws-lc-rs`. Features are pinned explicitly (`json`, `form`, `rustls`) because 0.13 drops `rustls-tls-native-roots` and makes `form` opt-in.
- Bumped `redis` from 0.27 to 1.7 and `deadpool-redis` from 0.18 to 0.23. redis 1.x introduces default async timeouts (500 ms response, 1 s connect); both are explicitly disabled so KV, cache, webhook and dev-runtime behaviour matches 0.27. `ErrorKind::IoError` became `ErrorKind::Io`, and the `connection-manager` feature was dropped as unused.
- Removed the `wit-bindgen` dependency from the workspace and the worker SDK. It was declared for wasm32 targets but imported nowhere: workers are core WASM modules and the CLI template pins no wit-bindgen.
- Pruned `.cargo/audit.toml` to a single ignore, RUSTSEC-2023-0071 (`rsa`, Marvin timing attack, no fixed release exists). The `bytes`, `rand`, `quinn-proto`, `protobuf` and `maxminddb` ignores are gone because the refresh and the bumps patched them.
- Documented minimum Rust for user workers raised from 1.83 to 1.85 in `docs/getting-started.md`, matching the worker SDK's transitive MSRV. The workspace still declares no `rust-version`, so nothing is forced on worker crates.

### Security
All eight advisories below had accumulated on `main` and none originated in the 0.2.0 feature
work. `cargo audit` is back to 0 vulnerabilities; only maintenance warnings remain (`fxhash`,
`rustls-pemfile`).

- Bumped `wasmtime-wasi` from 36.0.10 to 36.0.15 to patch **RUSTSEC-2026-0182**: leak in the WASIp1 `fd_renumber` implementation (fixed upstream in 36.0.11).
- Bumped `wasmtime-wasi` from 36.0.10 to 36.0.15 to patch **RUSTSEC-2026-0188**: WASI hard links and renames bypassed `FilePerms` for the destination path (fixed upstream in 36.0.12).
- Bumped `wasmtime` from 36.0.10 to 36.0.15 to patch **RUSTSEC-2026-0222**: stores could mix up type indices between engines (fixed upstream in 36.0.13).
- Bumped `wasmtime` from 36.0.10 to 36.0.15 to patch **RUSTSEC-2026-0269**: filesystem sandbox escape when paths or symlinks contain trailing slashes (fixed upstream in 36.0.14).
- Bumped `h2` from 0.4.14 to 0.4.19 to patch **RUSTSEC-2026-0258**: unbounded empty DATA frames (fixed upstream in 0.4.16).
- Bumped `quinn-proto` from 0.11.14 to 0.11.18 to patch **RUSTSEC-2026-0185**: remote memory exhaustion from unbounded out-of-order stream reassembly (fixed upstream in 0.11.15).
- Bumped `crossbeam-epoch` from 0.9.18 to 0.9.21 to patch **RUSTSEC-2026-0204**: invalid pointer dereference in the `fmt::Pointer` impl for `Atomic` and `Shared` when the underlying pointer is invalid (fixed upstream in 0.9.20).
- Bumped `webbrowser` from 1.2.1 to 1.2.4 to patch **RUSTSEC-2026-0257**: Unix `BROWSER` handling allowed browser argument injection (fixed upstream in 1.2.2).

## [0.2.0] - 2026-09-14

### Added
- **Origin proxy for proxied DNS records.** A domain the control plane sends a `proxy` block for is now reverse-proxied to the customer's origin instead of 404ing when no worker slug matches: the edge terminates TLS for the hostname, runs the WAF, and streams the request and response bodies both ways. An explicit worker slug still wins; everything else reaches the origin with the full path. Includes forwarded headers (`X-Forwarded-For`/`-Proto`/`-Host`, `X-Real-IP`, `Via`, `Workrs-Ray`), hop-by-hop stripping, WebSocket passthrough, a Valkey-backed response cache honouring `Cache-Control`/`ETag` with generation-based purging (`purge_cache` edge command), 502/504 mapping with a `Workrs-Error` header, and an origin policy that refuses link-local, metadata, private and loopback addresses (`ALLOW_PRIVATE_ORIGINS=true` relaxes the last two for local development). See `docs/gateway.md`.
- Gateway `[listen]` may now be a table with separate `https` and `http` addresses; with `[proxy] http_redirect = true` (the default) the plain-HTTP socket answers 301/308 redirects to HTTPS. The legacy `listen = "0.0.0.0:8080"` string and the `--listen` flag keep working unchanged. The HTTPS listener binds at startup even before the control plane has delivered a certificate, and starts completing handshakes as soon as sync does.
- Gateway `[listen]` gained an optional `management` address (`management = "10.88.0.21:8080"`). When set, `/health`, `/metrics` and `/health/detailed` are served on that private socket only and disappear from the public 80/443 routers, so a public edge no longer exposes its metrics to the internet or 301s the control plane's polls. The control plane polls `{management_address}/health/detailed` (bearer token) and `/metrics` over WireGuard. A management address that cannot be bound is fatal at startup. Without the option nothing changes: the operational endpoints stay on the public listeners. See `docs/gateway.md`.
- CI job `build:gateway-linux-x64` builds the edge gateway for `x86_64-unknown-linux-gnu` and publishes `edge-gateway-x86_64-unknown-linux-gnu.tar.gz` plus its `.sha256` (automatic on tags, manual on `main`). `ops/build-gateway.sh <control-plane-url> [version]` does the same locally, natively on a Linux x86_64 host and through the `linux/amd64` builder image everywhere else, then uploads the binary to the control plane with `INTERNAL_API_KEY`.
- CLI `delete` command removes a worker from the control plane (`workrs-edge delete [name]`). The worker is resolved like `env`/`secret` (team from `[project].team` or `--team`, name from the positional argument or the manifest), confirmed with a yes/no prompt, and deleted via `DELETE /api/workers/{id}`. Pass `--yes`/`-y` to skip the prompt in scripts.
- CLI `kv` command group for managing team KV namespaces: `kv list` prints the team's namespaces, `kv create <name>` creates one bound to a domain (`--domain` or `[project].domain`), and `kv delete <name>` resolves the name to its UUID before deleting. Duplicate names across domains must be disambiguated with `--domain`; the 409 "still bound to a worker" response surfaces as a readable error. `kv delete` supports `--yes` to skip confirmation.
- CLI `tail` now auto-configures its Reverb WebSocket connection from the `/api/me` reverb block, so `workrs-edge tail` works with zero flags. `--ws-url` and `--ws-app-key` (and their `WORKRS_WS_URL` / `WORKRS_WS_APP_KEY` env vars) became optional overrides that win when supplied.
- **Edge WAF engine.** The gateway now evaluates the per-domain `firewall` block the control plane syncs (`gateway/src/waf/`): a structured condition matcher with the full operator set (including `in_list` and CIDR), priority ordering, `allow`/`block`/`log`/`skip` actions, enforce versus simulate mode and an open/closed `fail_mode`, plus a bundled managed ruleset (SQLi, XSS, path traversal, RCE, scanners) with sensitivity tiers. Rules run after body buffering and geo injection, before dispatch. Decisions emit Prometheus metrics and are batched to `/api/edge/waf-events`. See `docs/waf.md`.
- WAF rate limiting and sensitive-data detection. The `rate_limit` action is enforced by a per-`(rule_id, key)` token-bucket limiter (keys: `ip`, `ip_path`, `header`) that answers 429 with `Retry-After`, and bundled detectors flag credentials and PII (AWS keys, PEM private keys, JWTs, Luhn-validated card numbers, IBANs) in the request body and, when enabled, the worker response. Matched values are redacted before an event is emitted. The client IP now comes from the real socket peer, so IP, CIDR, country and ASN conditions match.
- WAF JavaScript proof-of-work challenge, self-hosted on the edge. The `challenge`/`js_challenge` action serves an interstitial that solves SHA-256 for 14, 18 or 22 leading zero bits (easy/medium/hard) and posts to `/__waf/challenge`; the gateway verifies the HMAC-signed token, its freshness and the proof, then issues a signed `__waf_clear` cookie. No third-party service and no PII leaves the edge, and the interstitial works over plain HTTP as well as HTTPS.
- WAF computed condition fields `bot_score` and `attack_score` (0 to 100). `bot_score` is an HTTP heuristic (automation or missing user agent, missing browser headers, datacenter ASN); `attack_score` accumulates weighted managed-signature hits. Each is computed at most once per request, only when a rule references it and the per-domain toggle is on, and drives the existing `log`, `challenge` and `block` actions.
- WAF API Shield: per-domain OpenAPI 3.x request validation. An uploaded spec is compiled once and every request is matched by method and templated path, then its JSON body validated against the operation schema. Violations (`unknown_path`, `method_not_allowed`, `missing_param`, `body_schema`) raise an `api_schema` event; report mode proceeds, enforce mode answers 400.

### Changed
- The gateway's and CLI's HTTP client (reqwest) now trusts the operating system's CA store (`rustls-tls-native-roots`, matching the WebSocket client) instead of the bundled webpki roots. Edges read `/etc/ssl/certs`, so a locally trusted CA (for example Laravel Valet's, for webhooks to a `*.test` site) works without code changes; the CLI on macOS uses the keychain.
- Deployment docs describe the production install as the control plane renders it: `/etc/workrs/gateway.toml` with the split listen table and a management address, `/etc/workrs/gateway.env` with `HEALTH_DETAILED_TOKEN`, and a unit ordered after `network-online.target` and `wg-quick@wg0.service`. The certbot/ACME instructions are gone (certificates come from the control plane), and `provisioning/bootstrap.sh` is marked retired: it writes a config without a `[kv]` section, which the current gateway refuses to start with.
- WAF rate limiter now bounds its memory: once the per-`(rule_id, key)` token-bucket map crosses a soft cap, fully-refilled (idle) buckets are evicted. This is lossless (a refilled bucket equals a fresh one), so high-cardinality keys (`ip`/`ip_path`) no longer grow the map unbounded until restart.
- The origin proxy now speaks HTTP/1.1 to origins. Over HTTP/2 hyper sends both `:authority` and the forwarded `Host` header, which nginx rejects as a duplicate `Host` header with a 400.
- `ops/build-gateway.sh` now supports both the `--checkout DIR` / `--ref REF` control-plane style and the positional `<control-plane-url> [version]` style, resolves the version from the tag or the binary, and refuses to upload a `0.0.0-dev` build without `--allow-dev`; the copy in workrs-network/ops is byte-identical.

### Fixed
- Gateway no longer loses the file-based fallback certificate (`[tls] cert_path`/`key_path`) when the control plane sends a certificate payload without a default certificate. The file certificate is now remembered separately and reinstated on every such sync, so handshakes without SNI keep working.
- Gateway module cache no longer serves stale pre-compiled modules. Entries now live in `/var/cache/edge-gateway/wasmtime-<tag>/`, where the tag combines a cache format version with Wasmtime's `Engine::precompile_compatibility_hash()`, so artifacts from an older engine (for example the Wasmtime 27 `.cwasm` files left behind by the 36.x upgrade) are ignored and cleaned up on startup along with legacy unversioned files. `is_cached()` now deserializes the entry instead of only checking that the file exists, and invalidates it on failure; `get_or_compile()` rejects an empty WASM slice with a typed `ModuleCacheError::MissingSource` rather than compiling nothing. Previously a stale entry made the gateway answer every request with `HTTP 500 "expected at least one module field"` until the cache directory was cleared by hand. A module that goes missing between the cache probe and execution now returns `503` with `Retry-After: 1`.
- Deploy now posts to the worker deploy routes the control plane actually exposes, and sends `kv_namespaces` and `queue_bindings` as arrays of `{id, binding_name}` / `{queue_id, binding_name}` objects matching the `DeployWorkerRequest` validation, instead of the previous map shape.

### Security
- Bump Wasmtime `36.0.9` to `36.0.10` to patch **RUSTSEC-2026-0149**: WASI `path_open(TRUNCATE)` bypassed the host `FilePerms::WRITE` restriction (CVSS 7.5, high). Same-minor patch, no API change. This was failing the CI `lint:audit` gate.

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
- Fix gateway not shutting down on restart/stop commands: server now listens for cancellation token
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
