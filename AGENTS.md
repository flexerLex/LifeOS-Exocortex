# AGENTS.md — Engineering & Security Rules for Coding Agents

Before writing or modifying any code in this repository, read this file and `docs/ARCHITECTURE.md` in full.

## 1. Core Mental Model: Modular Information Processing Plant
We are building a **deterministic, local-first Information Processing Plant (Exocortex)** on **.NET 10** (`ENGINEERING_HANDBOOK.md`).
- **Telegram is a Terminal & Rich UI Hub, NOT the Application Core:** Telegram (Inline Keyboards, Forum Topics per Agent/Domain, Mini Apps, and Push Notifications) is one presentation/ingress adapter. Bureaucracy/Career is one domain module among several (Knowledge Refinery, Finance/Tax ROI, Schedule/Routine Alarm, Language Mentor).
- **LLM Output is an Untrusted Proposal (ADR-0002):** No LLM output can mutate domain state or write to the published vault without passing through `IOutputVerifier` and `_Staging`.
- **4-Tier Compute Funnel:**
  - **Layer 0 (Deterministic C# / Regex):** `PiiScrubber`, slash commands, SHA-256 integrity, deadline math, and YAML/path verification (`0 ms`, `$0.00`).
  - **Layer 1 (Voice & Narrow Models):** iOS Neural Dictation via Shortcuts (`/api/ios-capture`) + Telegram `.ogg` Voice transcription (`IVoiceTranscriberPort` via local Whisper / Groq Whisper API).
  - **Layer 2 (Local SLM Worker via Ollama):** `qwen2.5:3b` on loopback (`127.0.0.1:11434`) for `Personal`/`Restricted` note structuring and bureaucracy extraction.
  - **Layer 3 (External Workspace & Deep Distillers):** Google Workspace adapters (`IGoogleWorkspacePort` for Gmail job alerts/invoices, Google Calendar deadlines, Google Tasks) and bulk YouTube/PDF distillation.

## 2. Strict Architectural Boundaries (Modular Monolith — ADR-0001)
- `LifeOS.Domain`: Pure domain entities (`InboxMessage`, `AiRun`, `BureaucracyRecord`), state machines, and invariants. Zero external NuGet packages.
- `LifeOS.Application`: Use-case handlers (`SubmitCaptureHandler`, `ProcessNextInboxMessageHandler`, `ProactiveBureaucracyAdvisor`, `JobVacancyTriageService`, `NotificationDispatcher`) and ports (`IDurableInbox`, `IAiRunRepository`, `IBureaucracyRepository`, `INotificationPort`, `IGoogleWorkspacePort`, `IVoiceTranscriberPort`).
- `LifeOS.Infrastructure`: SQLite (`WAL`), `OllamaModelRouter`, `DeterministicOutputVerifier`, `FileSystemVaultStagingStore`, Telegram & Google Workspace adapters.
- `LifeOS.Host`: Composition root, CLI, Background workers, Telegram Rich UI polling, and local HTTP Webhook listener (`/api/ios-capture`, `/api/job-email`).

## 3. Non-Negotiable C# / .NET 10 Rules
1. Never use `DateTimeOffset.Now` or `DateTimeOffset.UtcNow` directly in business logic; always inject `TimeProvider`.
2. Enforce canonical path containment (`Path.GetFullPath` + trailing `Path.DirectorySeparatorChar`) and reject `.` / `..` / symlinks.
3. Never print raw `.md` filenames as bare `capture.md` strings in Telegram (Telegram misinterprets `.md` as Moldovan URLs); always format filenames inside backticks `` `Resources/file.md` `` and include note title/preview + inline `[👁 Read Note]` buttons.