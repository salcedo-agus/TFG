# External Integrations

**Analysis Date:** 2026-08-14

## APIs & External Services

**None.** This is a fully standalone desktop application. No HTTP calls, no third-party APIs, no SDKs.

## Data Storage

**Databases:**
- None

**File Storage:**
- Local filesystem only
- Input: `SRC/config.txt` (mission parameters, parsed at runtime)
- Output: results saved to user-chosen `.txt` via the GUI "Save Results" button (`SRC/gui/gui.py:864`), or console prints in the Fortran executable

**Caching:**
- None

## Authentication & Identity

**Auth Provider:**
- None — no authentication, no user accounts

## Monitoring & Observability

**Error Tracking:**
- None

**Logs:**
- Fortran `print*` statements to stdout (very verbose in `SRC/staging/Staging.f90` and `SRC/staging/Root_Finding.f90`)
- Python `print()` warnings (e.g. GUI MinGW detection warnings in `SRC/gui/gui.py:53-55`)

## CI/CD & Deployment

**Hosting:**
- None — desktop app, no deployment pipeline

**CI Pipeline:**
- None

## Environment Configuration

**Required env vars:**
- `MINGW_BIN` (optional) — MinGW bin directory override for runtime DLL loading (`SRC/gui/gui.py:36`, `SRC/interface/rocket_lib.py:19`)
- All other configuration via `SRC/config.txt`

**Secrets location:**
- N/A — no secrets exist in this codebase (no .env files present)

## Webhooks & Callbacks

**Incoming:**
- None

**Outgoing:**
- None

## Bridge Layer (Fortran ↔ Python)

- `SRC/interface/C_Interface.f90` exposes `run_staging` with `bind(C)` for 15 pointer arguments (scalars + arrays)
- `SRC/interface/rocket_lib.py` wraps it with ctypes; `SRC/gui/gui.py` duplicates the same ctypes wrapper inline (see CONCERNS.md — duplicated bridge)
- Loads `build/librocket.dll` (Windows) or `build/librocket.so` (Linux)

---

*Integration audit: 2026-08-14*