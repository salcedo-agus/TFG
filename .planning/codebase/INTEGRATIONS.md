# External Integrations

**Analysis Date:** 2026-08-13

## APIs & External Services

**None detected.** This is a standalone desktop application with no network calls, HTTP clients, REST/SOAP/GraphQL consumption, or third-party SDKs. Grep of all Python imports across `SRC/**/*.py` shows only stdlib (`ctypes`, `os`, `sys`, `re`, `datetime`, `importlib`) plus `PyQt6`. The Fortran code performs no network I/O.

## Internal Native Bridge (Fortran ↔ Python)

This is the codebase's defining "integration" layer and the only inter-process boundary:

- **Export side:** `bind(C, name="run_staging")` subroutine in `SRC/interface/C_Interface.f90:9-16` exposes the staging solver with `iso_c_binding` types (`c_int`, `c_double`, `c_double` arrays). It is compiled into the shared library `build/librocket.dll` (Windows) / `build/librocket.so` (Linux) / `build/librocket.dylib` (macOS) by `SRC/Makefile:153-163`.
- **Import side (primary):** `SRC/interface/rocket_lib.py` — `ctypes.CDLL` wrapper; declares `argtypes` for the 15 `run_staging` parameters and returns a results dict (total mass, per-stage m0/mf/mp/ms/k_m/k_s/k_L/ν_e, minimum-found flag). Must be importable via `sys.path.insert(0, ...)` from callers.
- **Import side (duplicated):** `SRC/gui/gui.py:57-110` re-implements the same ctypes wrapper inline (module-level `_lib`, `run_staging()`); changes to `C_Interface.f90`'s ABI must be mirrored in BOTH `rocket_lib.py` and `gui.py` — there is no shared wrapper module.
- **Windows DLL resolution:** both wrappers call `os.add_dll_directory(BUILD_DIR)` and probe MinGW runtime DLL directories; `rocket_lib.py:17-22` uses `MINGW_BIN` env var or `C:\TDM-GCC-64\bin`, `gui.py:38-45` tries a 6-candidate list. Without the gfortran runtime DLLs copied into `build/` (done by the Makefile link step), `ctypes.CDLL` load fails.

## Data Storage

**Databases:**
- None. No SQL/NoSQL database, ORM, or embedded store (no sqlite imports, no db files).

**File Storage:**
- Local filesystem only.
  - Input: `SRC/config.txt` — INI-like mission config read by the Fortran parser `load_config()` (`SRC/inout/Typical_Data.f90:822-906`). Required by the standalone path; GUI path reads config equivalents from widgets instead.
  - Output: results exported as plain-text files by the user via `QFileDialog.getSaveFileName` (`SRC/gui/gui.py:874-907`), default filename pattern `staging_{n}stage_dv{dv:.1f}_pl{pl}kg.txt`. Written with `encoding="utf-8"`.
  - Generated data: `SRC/gui/typical_data_ranges.py` produced from `SRC/inout/Typical_Data.f90` by `SRC/inout/parse_typical_data.py` (regex-based source parser, stdlib `re` only).

**Caching:**
- None (only `__pycache__/` bytecode caches, gitignored).

## Authentication & Identity

**Auth Provider:**
- None. No user accounts, sessions, tokens, or credential handling anywhere in the codebase.

## Monitoring & Observability

**Error Tracking:**
- None. No Sentry/OpenTelemetry/etc.

**Logs:**
- Console only: Fortran `print*` statements (e.g., iteration dumps in `SRC/staging/Staging.f90:59-66`) and Python `print()` warnings (e.g., `SRC/gui/gui.py:53-55`). No structured logging module.

## CI/CD & Deployment

**Hosting:**
- None (desktop app, no deployment target).

**CI Pipeline:**
- None. No GitHub Actions, Travis, AppVeyor, or other CI config in the repo. Only remote is `https://github.com/salcedo-agus/TFG` (git remote `origin`) with branches `main`, `dev_GUI`, `dev_pre_simulation`.

## Environment Configuration

**Required env vars:**
- None required. `MINGW_BIN` is optional on Windows: overrides the MinGW runtime-DLL search path used by `SRC/interface/rocket_lib.py:19` and is the first candidate in `SRC/gui/gui.py:38` (e.g., `$env:MINGW_BIN = 'C:\msys64\mingw64\bin'`).

**Secrets location:**
- N/A — no secrets, keys, or credentials exist in the project. No `.env` file present.

## Webhooks & Callbacks

**Incoming:**
- None.

**Outgoing:**
- None.

---

*Integration audit: 2026-08-13*