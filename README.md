# Workrs Edge

**Deploy WebAssembly workers to the edge in seconds.**

Workrs Edge is a high-performance edge computing platform for Europe. Write your workers in Rust, compile to WebAssembly, and deploy globally with sub-millisecond cold starts.

**Website:** [workrs.eu](https://workrs.eu)

---

## Features

- **WebAssembly Runtime** - Secure, sandboxed execution with Wasmtime
- **Sub-millisecond Cold Starts** - Pre-compiled modules with pooled instances
- **Built-in KV Storage** - Distributed key-value store with automatic multi-region sync
- **CRDT Replication** - Eventual consistency across edge locations
- **Developer CLI** - Build, test, and deploy from your terminal

---

## Installation

### Homebrew (macOS/Linux)

```bash
brew tap workrs-eu/tap
brew install workrs-edge
```

### Install Script

```bash
curl -fsSL https://get.workrs.eu/edge | sh
```

### From Source

```bash
cargo install --git https://gitlab.com/workrs-eu/edge-rust edge-cli
```

---

## Quick Start

```bash
# Create a new worker project
workrs-edge init my-worker
cd my-worker

# Build to WebAssembly
workrs-edge build

# Run locally with hot reload
workrs-edge dev

# Deploy to the edge
workrs-edge login
workrs-edge deploy
```

---

## Write a Worker

```rust
use worker_sdk::prelude::*;

#[event(fetch)]
async fn handle(req: Request, env: Env) -> Result<Response> {
    let kv = env.kv("CACHE")?;

    match req.path() {
        "/" => Response::text("Hello from the edge!"),
        "/visits" => {
            let count: u64 = kv.get_json("visits")?.unwrap_or(0);
            kv.put_json("visits", &(count + 1), None)?;
            Response::text(format!("Visits: {}", count + 1))
        }
        _ => Response::not_found(),
    }
}
```

---

## Documentation

| Guide | Description |
|-------|-------------|
| [Getting Started](https://workrs.eu/docs/getting-started) | Installation and first worker |
| [CLI Reference](https://workrs.eu/docs/cli) | All CLI commands |
| [Worker SDK](https://workrs.eu/docs/worker-sdk) | SDK API reference |
| [KV Storage](https://workrs.eu/docs/kv-store) | Key-value storage guide |

---

## Requirements

- Rust 1.83+ with `wasm32-wasip1` target
- macOS, Linux, or WSL

```bash
rustup target add wasm32-wasip1
```

---

## License

MIT License - see [LICENSE](LICENSE) for details.

---

**Built with Rust for the European edge.**
