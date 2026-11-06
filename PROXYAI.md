# AI Coding Agent Rules (SWE-1.6 / Grok / Cursor / ProxyAI)

## Token & Execution Discipline (CRITICAL)
1. **Do NOT scan the entire repository.** Read ONLY `AGENTS.md` and the specific files mentioned in the user prompt.
2. **Do NOT run `dotnet format` or multiple `dotnet build` loops** unless explicitly asked. The developer runs builds/tests in JetBrains Rider.
3. **Keep `LifeOS.Domain` 100% dependency-free** and keep SQLite/HTTP/Filesystem implementations strictly inside `LifeOS.Infrastructure`.

## Architecture Invariants
- All external/LLM outputs are untrusted proposals (`CandidateNote`, `NoteMetadataPatch`) that must pass `DeterministicOutputVerifier` and write only to `<vaultRoot>/_Staging`.
- Always inject `TimeProvider` (never call `DateTimeOffset.UtcNow` directly in business logic).
- Always scrub PII via `PiiScrubber.Scrub` or `ReversiblePiiSession` before invoking `IModelRouter`.
- For Legacy Vault Migration (`vault_audit.py` -> `audit.json`), NEVER ask the LLM to rewrite the full Markdown body of an existing note. Use lossless metadata patching (generate YAML frontmatter + tags + links, and preserve original body bytes).