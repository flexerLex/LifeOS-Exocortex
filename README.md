# LifeOS Exocortex (.NET 10)

**Deterministic, Privacy-First Personal Information Processing Plant & Local AI Exocortex.**

Built with **C# 14 / .NET 10**, **SQLite (WAL)**, and a **Zero-Trust Verification Architecture**. Designed to run as a lightweight Control Plane on **ARM64 (Raspberry Pi 4B)** or a local workstation alongside **Ollama** (`qwen2.5:3b`).

---

## Why This Project Exists

Most AI knowledge tools fail in production for three reasons:
1. **Probabilistic Corruption:** LLMs are given direct write access to notes or databases, leading to hallucinated links, broken YAML, or path-traversal vulnerabilities via indirect prompt injection.
2. **Fragile In-Memory Pipelines:** Using in-memory queues without durable leases loses captures on process restart or model timeout.
3. **Privacy & Cost Leaks:** Sending every raw thought or receipt to frontier cloud APIs violates data minimization (GDPR) and wastes compute on tasks a deterministic C# regex or a 3B local model can solve in milliseconds.

**LifeOS Exocortex** solves this by treating the LLM strictly as an **untrusted proposing machine** inside a deterministic C# factory pipeline.

---

## Key Architectural Highlights

- **Durable Idempotent Inbox (`SqliteDurableInbox`):** Guarantees at-least-once ingestion with SHA-256 payload conflict detection (`Accepted`, `AlreadyAccepted`, `IdempotencyConflict`), atomic worker leases, exponential backoff retries, and automatic poison-message quarantine.
- **Strict `AiRun` State Machine & Provenance:** Every AI execution follows `Queued -> Running -> AwaitingVerification -> Succeeded | Failed | Cancelled`. A run cannot transition to `Succeeded` without a deterministic verifier report and a canonical SHA-256 hash of the staged output.
- **Deny-by-Default Model Routing (`OllamaModelRouter`):** Enforces at the code level that `Personal` and `Restricted` data can only be routed to loopback (`localhost` / `127.0.0.1`) inference endpoints.
- **Guardian Output Verifier (`DeterministicOutputVerifier`):** Validates candidate notes for path safety (`.` / `..` / rooted path rejection), PARA category allowlists (`Projects`, `Areas`, `Resources`, `Archives`), non-empty YAML frontmatter keys (`title:`, `category:`), and wikilink syntax before a single byte hits the disk.
- **Zero-Trust Staging & Atomic Promotion (`FileSystemVaultStagingStore`):** Writes exclusively to `<vault>/_Staging` using atomic temp-file + move semantics, guards against partial-prefix (`_Staging_Evil`) and symlink/reparse-point escapes, and verifies SHA-256 integrity again upon human approval (`CommitApprovedAsync`).

---

## Solution Structure

```text
LifeOS.sln
├── src/
│   ├── LifeOS.Domain/          # Pure domain entities (InboxMessage, AiRun), events, invariants (0 dependencies)
│   ├── LifeOS.Application/     # Use-case handlers (SubmitCapture, ProcessNextInboxMessage) & strict ports
│   ├── LifeOS.Infrastructure/  # SQLite WAL repositories, OllamaModelRouter, Verifier, Staging store
│   └── LifeOS.Host/            # Executable CLI & background worker host
├── tests/
│   └── LifeOS.Domain.Tests/    # 50+ deterministic unit & SQLite/filesystem integration tests
└── docs/
    ├── ARCHITECTURE.md         # System blueprint & 4-layer compute funnel
    └── adr/                    # Architectural Decision Records (ADR-0001, ADR-0002)