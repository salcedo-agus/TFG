# Phase 3: Bridge & Correctness Fixes - Research

**Researched:** 2026-09-06
**Domain:** Fortran 2008 / Python ctypes bridge consolidation, Windows build tooling
**Confidence:** HIGH

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

### rm_L authority (FIX-01)
- **D-01:** `Rocket%rm_L` is computed ONLY by `Payload_Mass_calculator` (`Payload_Mass_calc.f90`, eq. 11: `rm_L = payload_mass + 0.0755*payload_mass + 50`). Every remaining bridge entry calls it. The inline formula copy in `run_staging` (`C_Interface.f90:54-59`) dies with that entry (D-04) — no second copy is ever created.
- **D-02:** Regression guard — conservative bounds added to `SRC/test/test_rocket_lib.py`: stage-1 mass `m0` finite AND `> payload+PAF`, and `k_L ∈ (0,1)`. Catches uninitialized/garbage masses cheaply without pinning exact physics.
- **D-03:** rm_L consolidation is FOLDED into the bridge-dedup change, not a standalone fix. Planner rescopes 03-01 vs 03-02 accordingly (03-01 may reduce to verification + the bounds test if dedup absorbs the formula removal).

### Bridge consolidation (FIX-02)
- **D-04:** SINGLE-ENTRY consolidation — remove `run_staging` at every layer:
  - Fortran `run_staging` subroutine (`C_Interface.f90:10-102`)
  - Python wrapper + argtypes (`rocket_lib.py:26-27,72-91`)
  - gui.py dead inline twin + private `_lib` DLL handle (`gui.py:30,58-111` — unreferenced dead code, IN-01)
  - `test_call.py` run_staging segment (`test_call.py:5,7`)
  - `RunStagingWrapperContract` test class (`test_rocket_lib.py:148+`)
  - `run_full_pipeline` becomes the ONLY bridge entry. Fortran `STAGING` itself STAYS (still called by `STAGING_LOOP` at `Stage_Optimization_Loop.f90:34` and the console path).
- **D-05:** Test suite reworked INSIDE the phase so it stays green at every commit: remove `RunStagingWrapperContract`, add the D-02 bounds test. No red-commit states.
- **D-06:** Codebase-map/docs refreshed in-phase, same commit set: `CONCERNS.md` dup-bridge (line 20) and rm_L (line 45) rows → resolved; `INTEGRATIONS.md` `run_staging` entry (line 63) + the "MINGW_BIN optional override" note removed; `STRUCTURE.md`/`TESTING.md` `run_staging` references updated; `PROJECT.md` (line 31 pending FIX-02) + `REQUIREMENTS.md` (FIX-01/02/03 ticked) + `AGENTS.md` priorities amended.
- **D-07:** `SRC/test_call.py` CONVERTED to a `run_full_pipeline` smoke (stays a standalone CLI smoke hook against the real DLL; needs the config-driven args incl. `diameter_mode`/`diameter`/`propellant_list`).

### Path resolution (FIX-03)
- **D-08:** Python side is **build/-only** — `rocket_lib.py` loads `build/librocket.dll` via `add_dll_directory(BUILD_DIR)`; the `MINGW_BIN` env lookup (`rocket_lib.py:19`) and the candidate-list block (gui.py:36, removed by D-04) are dropped. This depends on the Makefile continuing to copy the MinGW runtime DLLs into `build/` (`Makefile:168-174`) — that copy STAYS.
- **D-09:** Makefile `MINGW_BIN` (`SRC/Makefile:52`) resolves by DISCOVERY at build time — derive the dir from `where gfortran`/`which gfortran`, overridable via env/CLI `MINGW_BIN`, and fail with a clear hint when MinGW is not found. No drive-letter literal (`C:/TDM-GCC-64/bin`) remains anywhere.

### the agent's Discretion
- 03-01 vs 03-02 rescoping mechanics after the D-03 fold-in (which plan owns which file; execution order).
- Exact bounds-test assertion shape/message wording beyond the D-02 stated bounds.
- Whether to clean up now-orphaned Fortran bits post-removal (module globals seeded only by `run_staging`, unused exports) — permitted only if zero behavior change; skip if any doubt.
- Exact `where gfortran` output-parsing for the D-09 derivation and the error-line wording.
- Whether CR-01/WR-02/WR-03 robustness gaps (recorded by the Phase-2 verifier with disposition "Phase 3/fix") fit inside this phase's FIX scope — include only if they fit without expanding it; otherwise re-file as future-phase defects.

### Deferred Ideas (OUT OF SCOPE)
- **Rocket-diagram in Results** (user-requested this session): draw the launch vehicle with per-stage length/diameter from the selected configuration — the pipeline already returns `Diameter`/`Length`/`Volume` per stage. New visualization capability → own phase (Phase 4 candidate); can build on the single-bridge shape Phase 3 locks down.
- **ISP/k_s authority (tables vs sliders)** — deferred from Phase 2 (`02-CONTEXT.md:94`), blocked by out-of-scope FIX-05 (Soyuz TEST CASE overrides the tables). Dedup must PRESERVE today's slider-passing behavior; do not resolve here.
- **FIX-04** (config parser writes stage-2/3 combustion cycles into `first_stage_combustion_cycle`, `Typical_Data.f90:924-930`) and **FIX-05** (dead TEST CASE override) — out of scope, do not touch.
- **CR-01 / WR-02 / WR-03** — Phase-2 verifier disposition "Phase 3/fix": Constant-mode ghost-stage geometry pollution, NaN/negative geometry from vacant branches, negative-thrust domain. Not ROADMAP criteria; include only if they fit without expanding scope (agent discretion), else re-file.
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| FIX-01 | `Rocket%rm_L` initialized on every bridge path from a single formula source | D-01 analysis: `Payload_Mass_calculator` is the sole authority (`Payload_Mass_calc.f90:12,19`); the inline copy (`C_Interface.f90:54-59`) dies with `run_staging`; D-02 bounds-test design + no-false-fail probe data; rm_L read sites `Staging.f90:86,106` |
| FIX-02 | Duplicated `run_staging` ctypes bridge consolidated into one module; `gui.py` uses it | Full per-layer deletion surface (Fortran 10-102, wrapper 26-43/72-115, gui twin + `_lib` 20/25-26/32-56/58-111, tests 23/148-164, test_call 1-20); orphan analysis (delta_v/globals self-seeded); single-wave coordination to keep suite green (D-05) |
| FIX-03 | Hardcoded MinGW path removed/replaced with a resolvable library path | D-09 `?=` discovery + override + error-hint pattern empirically verified on both installed makes (discovery / failure / env override / CLI override); D-08 build/-only DLL load documented with official `os.add_dll_directory` API; runtime-DLL copy (`Makefile:168-174`) confirmed as the dependency |
</phase_requirements>

## Summary

Phase 3 consolidates the Fortran↔Python bridge to a single authoritative entry (`run_full_pipeline`) and removes three correctness shortcuts (FIX-01 rm_L, FIX-02 duplicated `run_staging` bridge, FIX-03 hardcoded MinGW path). The code is **not broken from scratch** — `Rocket%rm_L` is already initialized on both bridge entries, the GUI already calls `rocket_lib.run_full_pipeline` (`gui.py:1143`), and all 23 Phase-2 tests are green. This is deletion + one-path consolidation, so the highest planning risk is **wave coordination**: `unittest` collects `test_rocket_lib.py`, which imports `run_staging` directly — removing the wrapper before the test is updated produces a red suite at collection time, violating D-05.

The removal surface is fully mapped and verified this session: Fortran `run_staging` (`C_Interface.f90:10-102`), its wrapper + argtypes (`rocket_lib.py:26-43,72-115`), the MINGW env block (`rocket_lib.py:19-21`, D-08), the gui.py dead twin + `_lib` + candidates block (`gui.py:20,25-26,32-56,58-111`), and both test consumers. Orphan analysis is clean: `Rocket%delta_v` is self-seeded by `STAGING_LOOP` (`Stage_Optimization_Loop.f90:26`), the only surviving bare-`STAGING` caller after removal is `STAGING_LOOP` itself (`:34`), and `payload_mass`/`number_of_stages` globals are also seeded by `run_full_pipeline` (`C_Interface.f90:146-147`).

The D-09 Makefile discovery pattern was **empirically verified on both installed makes** (chocolatey GNU Make 4.4.1 and TDM mingw32-make 3.82.90): `where gfortran 2>NUL` → `C:\TDM-GCC-64\bin`; failure path fires a clear `$(error ...)` hint; env-var and CLI overrides both work via `?=`. The current line 52 uses `:=`, which silently ignores overrides — D-09's `?=` form fixes that too. D-08's build/-only DLL load is backed by official documentation (`os.add_dll_directory`, Python 3.8+) and proven end-to-end by the green suite.

**Primary recommendation:** Plan this phase as a **single coordinated wave** (Fortran removal + DLL rebuild + Python bridge + both test files + bounds test together), then a docs wave — never split the dedup across waves, or the suite goes red mid-phase.

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| `Rocket%rm_L` computation | Backend (Fortran core) | — | `Payload_Mass_calculator` is the single authority (D-01); `STAGING` only reads it (`Staging.f90:86,106`) |
| Pipeline orchestration entry | Backend (bind(C) + ctypes wrapper) | — | `run_full_pipeline` becomes the ONLY bridge entry (D-04) |
| Bridge contract declaration | Backend (Python ctypes layer) | — | `.argtypes` declared exactly once in `rocket_lib.py:45-70`; gui.py never re-declares (D-04) |
| GUI invocation | Client (PyQt6) | Backend | `gui.py:1143` → `rocket_lib.run_full_pipeline(...)` — survives dedup |
| DLL loading | Client process (Python loader) | Build system | build/-only via `os.add_dll_directory(BUILD_DIR)` (D-08), depends on Makefile runtime-DLL copy (`Makefile:168-174`) |
| MinGW toolchain resolution | Build system (Makefile) | — | Discovery at build time, env/CLI override, clear failure hint (D-09) |
| Regression guarding | Test tier | Backend | stdlib `unittest` against the real rebuilt DLL; D-02 bounds test in `test_rocket_lib.py` |

## Standard Stack

### Core

No new packages. The entire phase runs on the **Python standard library** (`ctypes`, `os`) plus the **existing toolchain**. This is deliberate: ctypes is the established bridge mechanism (no replacement), and `os.add_dll_directory` is the sanctioned Windows DLL-resolution API since Python 3.8.

| Component | Version | Purpose | Why Standard |
|-----------|---------|---------|--------------|
| `ctypes` (stdlib) | Python 3.11.1 | Fortran DLL bridge | Existing Phase-1/2 mechanism; `.argtypes` gives typed, validated calls |
| `os.add_dll_directory` (stdlib) | Python 3.8+ (present 3.11) | DLL dependency resolution | Officially the only supported way to add DLL search dirs post-3.8 [CITED: docs.python.org/3/library/os.html] |
| `unittest` (stdlib) | Python 3.11.1 | Regression suite | Phase-2 suite already runs on it — no framework migration (D-05 keeps green) |
| `gfortran` (TDM-GCC) | 10.3.0 | Fortran compile/link | Existing toolchain at `C:\TDM-GCC-64\bin` |
| GNU Make / mingw32-make | 4.4.1 / 3.82.90 | Build orchestration | Both installed; D-09 pattern verified on both |
| PyQt6 | 6.11.0 | GUI | Already installed (Phase 1); untouched this phase |

### Supporting

| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| `ctypes.POINTER(ctypes.c_double)` arrays | stdlib | Marshalling `REAL(c_double) :: isp_in(n_stages)` | Every bridge call — declared once, reused |
| `($env):MINGW_BIN` env var | — | D-09 build-time override | ONLY in Makefile; removed from Python (D-08) |

### Alternatives Considered

| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| `os.add_dll_directory(BUILD_DIR)` | `os.environ["PATH"] += build` | PATH mutation is the pre-3.8 DLL-hijack vector and order-fragile; rejected |
| Loading `librocket.so` on POSIX in the same block | Keep the `else` branch | Unchanged behavior, zero risk; keep `rocket_lib.py:23-24` |
| `where gfortran` (cmd builtin) | `which` / `shutil.which` | `where` is the native cmd tool and works in both makes' cmd shell; `which` doesn't exist under cmd. sh-only environments fall back to the error hint (fail-safe) |

**Installation:** none — no packages are installed in this phase.

**Version verification:** n/a (no new packages). Existing components verified live: `python --version` → 3.11.1 (last session), `gfortran --version` → GNU Fortran 10.3.0 (TDM), `pip show PyQt6` → 6.11.0 (this session), `make --version` → 4.4.1 / 3.82.90 (both verified live).

## Package Legitimacy Audit

> This phase installs **no external packages** — the Standard Stack is Python stdlib + existing local toolchain. The npm/PyPI/crates legitimacy gate is therefore **not triggered**. The only "packages" in play are already installed and were verified live this session:

| Package | Registry | Age | Downloads | Source Repo | Verdict | Disposition |
|---------|----------|-----|-----------|-------------|---------|-------------|
| PyQt6 6.11.0 | PyPI | mature | — | riverbankcomputing | OK (already installed Phase 1) | Approved — no install action |
| gfortran 10.3.0 (TDM-GCC) | — | mature | — | TDM-GCC | OK (on PATH) | Approved — no install action |
| GNU Make 4.4.1 / mingw32-make 3.82.90 | — | mature | — | FSF / TDM | OK (on PATH) | Approved — no install action |

**Packages removed due to [SLOP] verdict:** none (no new packages proposed).
**Packages flagged as suspicious [SUS]:** none.
**Packages tagged [ASSUMED]:** none.

## Architecture Patterns

### System Architecture Diagram

```
                        ┌────────────────────────────────────────────┐
                        │                GUI (PyQt6)                 │
                        │  gui.py:1143  _run()                       │
                        │      │                                     │
                        │      ▼                                     │
                        │  rocket_lib.run_full_pipeline(...)         │
                        └──────┬─────────────────────────────────────┘
                               │  pure Python, no ctypes in GUI
                               ▼
               ┌───────────────────────────────┐
               │   rocket_lib.py (bridge)      │   .argtypes declared ONCE (45-70)
               │   win32 block (17-24):        │   BUILD_DIR = <repo>/build
               │   add_dll_directory(BUILD_DIR)│   (MINGW env block DELETED, D-08)
               │   lib = ctypes.CDLL(build\librocket.dll)
               └──────────────┬────────────────┘
                              ▼
               ┌───────────────────────────────┐
               │   librocket.dll (built, libgfortran + 3 runtime DLLs copied in build/)
               │   run_full_pipeline (ONLY entry after D-04)
               │     Payload_Mass_calculator   → sets Rocket%rm_L  (D-01 authority)
               │     orbit_speed_calculator    → sets V_circ
               │     STAGING_LOOP              → self-seeds delta_v (:26), calls STAGING (:34)
               │     rocket_geometry_calculation
               │     eq-26 minimum-found pack + flat arrays → dict
               └──────────────┬────────────────┘
                              │
               ┌──────────────▼────────────────┐
               │  Makefile (build-time only)   │
               │  MINGW_BIN ?= discovery (D-09)│
               │  copy 4 runtime DLLs → build/ │  (168-174, STAYS — D-08 depends on it)
               └───────────────────────────────┘

   Removed entirely (D-04): C_Interface.f90 run_staging (10-102),
   rocket_lib.run_staging wrapper + argtypes (26-43, 72-115),
   gui.py dead twin + _lib + candidates (20,25-26,32-56,58-111),
   STAGING bare-callers except Stage_Optimization_Loop.f90:34.
```

**Deletion model:** the phase is a *path removal*, so the diagram's "processing stages" are the surviving pipeline stages; the removed entry is shown only as annotations. The primary use case (GUI run → dict of masses/geometry) is unchanged and flows through the surviving path.

### Recommended Project Structure

Unchanged — this phase edits in place:

```
TFG/
├── SRC/
│   ├── interface/
│   │   ├── C_Interface.f90      # run_staging DELETED (10-102); run_full_pipeline stays
│   │   └── rocket_lib.py        # win32 block (19-21) trimmed; run_staging block (26-43,72-115) DELETED
│   ├── gui/
│   │   └── gui.py               # twin (20,25-26,32-56,58-111) DELETED; import rocket_lib stays (30); comments 30/911 updated
│   ├── test/
│   │   └── test_rocket_lib.py   # import (23) trimmed; RunStagingWrapperContract (148-164) DELETED; D-02 bounds test ADDED
│   ├── test_call.py             # run_staging block (1-20) DELETED; full-pipeline smoke (22-73) stays
│   ├── staging/                 # BYTE-IDENTICAL (hard boundary)
│   └── Makefile                 # line 52 discovery; error-hint guard; runtime-DLL copy (168-174) STAYS
├── build/                       # regenerated DLL + .mod/.o (rebuild is part of the wave)
└── .planning/codebase/          # D-06 refresh targets (CONCERNS/INTEGRATIONS/STRUCTURE/TESTING)
```

### Pattern 1: Single authoritative bridge entry (bind(C) + one argtypes declaration)

**What:** Every Fortran entry point exported with `bind(C, name=...)` and wrapped by exactly one Python function with a single `.argtypes` block; every other Python module imports that wrapper rather than touching `ctypes` or the DLL handle.
**When to use:** Any multi-module ctypes project (this is the FIX-02 dedup).
**Evidence this phase:** `gui.py` currently re-declares argtypes (62-79) and holds a private `_lib` (58-60) — both unreferenced dead code (IN-01). After deletion, `rocket_lib.py:45-70` is the only declaration; `gui.py` calls `rocket_lib.run_full_pipeline` (1143).
**Example (target state, `rocket_lib.py` win32 block after D-08):**

```python
# SRC/interface/rocket_lib.py — target load block (D-08: build/-only)
if sys.platform == "win32":
    os.add_dll_directory(BUILD_DIR)                       # line 18 STAYS (removed lines 19-21: MINGW env lookup)
    lib = ctypes.CDLL(os.path.join(BUILD_DIR, "librocket.dll"))   # line 22 STAYS
else:
    lib = ctypes.CDLL(os.path.join(BUILD_DIR, "librocket.so"))    # line 24 STAYS
```

### Pattern 2: Makefile tool discovery + fail-hint (D-09)

**What:** Replace a hardcoded machine path with discovery at build time, keep env/CLI override semantics, and fail loudly (not cryptically) when the toolchain is absent.
**When to use:** Any machine-specific path in a checked-in build file.

```make
# SRC/Makefile:52 replacement — VERIFIED on GNU Make 4.4.1 AND mingw32-make 3.82.90
ifeq ($(OS), Windows_NT)
    ...
    MINGW_BIN ?= $(patsubst %\gfortran.exe,%,$(firstword $(shell where gfortran 2>NUL)))
    ifeq ($(strip $(MINGW_BIN)),)
        $(error gfortran not found in PATH. Install TDM-GCC/MinGW-w64 or set MINGW_BIN=<dir> explicitly.)
    endif
    ...
endif
```

Empirically confirmed this session (temp makefiles, both makes): discovery → `C:\TDM-GCC-64\bin`; bogus tool name → error hint fires; `MINGW_BIN=C:\fake\env-path` env var → override honoured; `MINGW_BIN="C:\cli\path"` CLI → override honoured. Note the current line 52 uses `:=` which would NOT honour overrides — `?=` is required.

### Anti-Patterns to Avoid

- **Split the dedup across waves**: `unittest discover` imports `test_rocket_lib.py:23` (`from rocket_lib import ... run_staging`) — if `rocket_lib.py` drops the wrapper first, collection raises `ImportError` and the whole suite reads RED (violates D-05). Fortran + DLL rebuild + Python + tests must land as one wave/commit.
- **Rebuild the DLL after the Fortran edit but skip the negative export check**: a stale DLL silently keeps exporting `run_staging`. Verification should assert `not hasattr(rocket_lib.lib, "run_staging")` after the rebuild.
- **Leave the gui.py comments stale**: line 30 ("...twin stays for Phase 3 dedup") and line 911 ("NOT wired into run_staging") must be rewritten in the same commit as the deletion.
- **Keep `:=` on MINGW_BIN**: silently ignores `$env:MINGW_BIN`; the whole point of D-09's override path requires `?=`.
- **Touch algorithm files**: `Staging.f90`, `Stage_Optimization_Loop.f90`, `Payload_Mass_calc.f90`, `Geometry_calc.f90`, `Thrust_calc.f90` must stay byte-identical (hard boundary) — even "obvious" cleanups there are out of scope.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| DLL dependency resolution on Windows | Manual PATH manipulation, copying DLLs next to python.exe | `os.add_dll_directory(BUILD_DIR)` | Pre-3.8 PATH search was the DLL-hijack vector; the stdlib API is the sanctioned mechanism [CITED: docs.python.org] |
| Finding gfortran at build time | Hardcoded `C:/TDM-GCC-64/bin` (the current bug) | `where gfortran` via make `$(shell)` + `?=` override | `where` is a cmd builtin; pattern verified on both installed makes, fails with a clear hint |
| Declaring ctypes argtypes per module | gui.py's duplicated `.argtypes` block | Single declaration in `rocket_lib.py:45-70` | Duplicated declarations drift; the GUI already delegates to `rocket_lib` |
| Restarting the DLL-loading mechanism | New loader, `load_library` wrappers | Keep `ctypes.CDLL` + `add_dll_directory` | Proven green across 23 tests; zero behavior-change mandate from CONTEXT |

**Key insight:** every problem this phase touches already has a sanctioned solution in the codebase or stdlib. The phase's risk isn't "build something" — it's "delete the right things without breaking the green suite."

## Runtime State Inventory

> Refactor phase — every category answered explicitly.

| Category | Items Found | Action Required |
|----------|-------------|------------------|
| Stored data | **None** — standalone desktop app, no databases, no data stores (AGENTS.md:8-9). No string being renamed; this is symbol-level removal. | none |
| Live service config | **None** — no external services, APIs, or remote configs. | none |
| OS-registered state | **None** — no scheduled tasks, services, or OS registrations reference `run_staging` or `MINGW_BIN`. | none |
| Secrets/env vars | `MINGW_BIN` env var — read by `rocket_lib.py:19` (Python, D-08 removes) and `gui.py:40` (dead twin, D-04 removes). Makefile keeps it as an optional `?=` build-time override (D-09). No secrets involved. | **code edits** (removal of the Python reads); env var itself stays available for build overrides — no data migration |
| Build artifacts | `build/librocket.dll` (156,614 B, built 6/9/2026) currently **exports `run_staging`**. The DLL is not in git; it is regenerated by `make all`/`make gui` after editing `C_Interface.f90`. Runtime DLLs (`libgfortran_64-5.dll`, `libgcc_s_seh_64-1.dll`, `libquadmath_64-0.dll`, `libwinpthread_64-1.dll`) are copied by `Makefile:168-174` and stay. `rocket_lib.py` is imported via `sys.path` (not pip-installed) → no egg-info/pycache staleness beyond auto-recompiled `__pycache__`. | **rebuild** — `make all` in the same wave as the Fortran edit; negative export check afterwards |

**Canonical question answered:** after every file is updated, the only runtime system still holding a removed symbol is the compiled DLL (and only until rebuild) — the Python process re-imports fresh code on next launch; there is no persistent runtime state to migrate.

## Common Pitfalls

### Pitfall 1: Red suite at collection after removing the wrapper
**What goes wrong:** `python -m unittest discover -s SRC/test` fails with `ImportError: cannot import name 'run_staging'` even though no test *body* uses it.
**Why it happens:** `test_rocket_lib.py:23` imports `run_staging` at module scope; unittest imports the module during discovery.
**How to avoid:** single-wave commit: `rocket_lib.py` removal + `test_rocket_lib.py` import trim (+ class removal) + `test_call.py` conversion together. Never leave the wrapper removal and the test edit in separate commits.
**Warning signs:** any plan with "remove run_staging from rocket_lib.py" in an earlier wave than the test updates.

### Pitfall 2: Stale DLL still exporting the removed symbol
**What goes wrong:** tests pass against an old DLL; the dedup is "green" while the source and binary disagree.
**Why it happens:** `build/` is not in git; `unittest` doesn't trigger a rebuild.
**How to avoid:** verification order = rebuild (`make all` / `make gui`) → negative check `assert not hasattr(rocket_lib.lib, "run_staging")` → run suite. This is an explicit verification task, not an implicit one.
**Warning signs:** no build/regeneration step in the wave plan.

### Pitfall 3: D-09 discovery breaks under a future sh.exe on PATH
**What goes wrong:** GNU make prefers `sh.exe` when present (Git-for-Windows users); `where` doesn't exist under sh → `$(shell where gfortran)` yields empty → build errors.
**Why it happens:** make's Windows default-shell selection is hardcoded sh-first [CITED: GNU make manual].
**How to avoid:** the `$(error ...)` hint IS the designed failure mode (D-09 asks for a clear hint + override). The hint text should mention `MINGW_BIN=<dir>` as the escape hatch. On THIS machine no sh.exe is on PATH (verified), so normal builds are unaffected.
**Warning signs:** builds that worked locally fail on a co-worker's machine with the hint message — expected, actionable, not a regression.

### Pitfall 4: Deleting `import ctypes` from gui.py while ctypes is still used
**What goes wrong:** `NameError` or `AttributeError` at runtime if any surviving line uses `ctypes`.
**How to avoid:** this session's grep proves every `ctypes` use in gui.py sits in lines 20 and 58-111 (the removed twin); line 911 is a comment only. Executor should re-grep (`grep -n ctypes gui.py`) before removing the import as a last sanity check.
**Warning signs:** a leftover `ctypes.` reference after the block deletion.

### Pitfall 5: Turning override off by keeping `:=`
**What goes wrong:** `MINGW_BIN=C:\custom make all` silently falls back to discovery/hardcoded value.
**Why it happens:** `:=` assigns immediately; environment/CLI values are already "defined" so `:=` overwrites them.
**How to avoid:** use `?=` exactly as verified (both makes honour env and CLI overrides).
**Warning signs:** overspecifying the Makefile edit as a plain find-replace of line 52's operator.

## Code Examples

### Common Operation 1: D-09 Makefile discovery (verified full pattern)

```make
# SRC/Makefile, Windows branch — replace line 52 `MINGW_BIN := C:/TDM-GCC-64/bin` with:
MINGW_BIN ?= $(patsubst %\gfortran.exe,%,$(firstword $(shell where gfortran 2>NUL)))
ifeq ($(strip $(MINGW_BIN)),)
    $(error gfortran not found in PATH. Install TDM-GCC/MinGW-w64 or set MINGW_BIN=<dir> explicitly.)
endif
```

- `where gfortran 2>NUL` → `C:\TDM-GCC-64\bin\gfortran.exe` (2>NUL suppresses the localized stderr INFO line)
- `patsubst %\gfortran.exe,%` strips the executable → `C:\TDM-GCC-64\bin`
- `firstword` guards multiple PATH matches
- The runtime-DLL copy rules (`Makefile:170-173`, `$(MINGW_BIN)\libgfortran_64-5.dll` backslash joins) work unchanged with the discovered backslash path
- Optional cleanup (discretion): `RUNTIME_DLLS` (53-57) is a dead variable — the copy rules hardcode the four names

### Common Operation 2: D-04 Fortran deletion surface

```fortran
! SRC/interface/C_Interface.f90 — DELETE lines 10-102 (subroutine run_staging).
! Orphan check — nothing else needs run_staging's seeds, VERIFIED this session:
!   - Rocket%delta_v   : also set by STAGING_LOOP (Stage_Optimization_Loop.f90:26 `Rocket%delta_v = DV_old`)
!   - payload_mass     : also set by run_full_pipeline (C_Interface.f90:146)
!   - number_of_stages : also set by run_full_pipeline (C_Interface.f90:147)
! Remaining bare-STAGING callers after deletion: Stage_Optimization_Loop.f90:34 only (STAGING stays).
! The inline rm_L copy at lines 54-59 (`Rocket%rm_L = payload_mass + 0.0755d0 * payload_mass + 50.d0`)
! dies with the subroutine — Payload_Mass_calculator (Payload_Mass_calc.f90:12-19) is the sole authority (D-01).
```

### Common Operation 3: D-02 conservative bounds test (shape)

```python
# SRC/test/test_rocket_lib.py — add inside an existing suite class (or a new class):
def test_conservative_bounds_n3(self):
    """D-02: catches uninitialized/garbage masses without pinning physics."""
    r = self._baseline()                      # N3_CONFIG defaults (already in the file, lines 30-39)
    paf = 0.0755 * self.payload_mass + 50.0   # PAF eq. 11 — mirrors Payload_Mass_calc.f90:12
    m0 = r["stages"][0]["m0"]
    self.assertTrue(math.isfinite(m0))
    self.assertGreater(m0, self.payload_mass + paf)   # m0 must exceed payload + PAF
    for s in r["stages"]:
        self.assertGreater(s["k_L"], 0.0)
        self.assertLess(s["k_L"], 1.0)               # k_L ∈ (0,1)
```

Bounds probe run this session (n=1/2/3 × payload 1000–1,000,000 kg × orbit 100–2000 km): `m0 > payload+PAF` and `k_L ∈ (0,1)` **always** true — the bounds cannot false-fail on valid inputs. Sample: N3 smoke `m0=120771.89`, `paf=427.50`, `k_L=[0.355531]*3`.

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Dual bridge entries (`run_staging` + `run_full_pipeline`) | Single `run_full_pipeline` entry | This phase (D-04) | One argtypes contract, one pack pattern, no dead twin |
| Inline `Rocket%rm_L` copy in `run_staging` (`C_Interface.f90:59`) | `Payload_Mass_calculator` only (D-01) | This phase | Single formula source — PAF eq. 11 |
| Hardcoded `MINGW_BIN := C:/TDM-GCC-64/bin` | `?=` discovery + override + error hint (D-09) | This phase | Portable Makefile; no drive-letter literals |
| Python reads `$env:MINGW_BIN` + candidate list for DLL search | build/-only via `add_dll_directory(BUILD_DIR)` (D-08) | This phase | Smaller attack surface; single source of DLL location |
| `run_staging`-based smoke + regression guidance | `run_full_pipeline`-based (D-06/D-07) | This phase | Docs and hooks match the surviving bridge |

**Deprecated/outdated:**
- `run_staging` symbol (all layers): the legacy single-solver entry. Superfluous since Phase 2 exposed the full pipeline; removing it elides the delta_v seeding mismatch (`C_Interface.f90:41` vs `STAGING_LOOP` convergence) permanently.

## Assumptions Log

> All structural claims in this research were verified by direct file reads or empirical tests this session. The following are CITED (documented upstream) rather than ASSUMED, listed because they carry the residual uncertainty:

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | On Windows, `ctypes.CDLL` with a full path includes the DLL's own directory in the dependency search [CITED: stackoverflow answer by Eryk Sun (CPython core dev), consistent with ctypes docs] | Standard Stack / D-08 | **None** — `os.add_dll_directory(BUILD_DIR)` is already called before `CDLL` (rocket_lib.py:18), so dependencies are covered under either search model. 23 green tests corroborate. |
| A2 | GNU make prefers `sh.exe` when present on PATH [CITED: GNU make manual] | D-09 pitfall | Low — this machine has no sh.exe on PATH (verified); worst case the error hint fires and `MINGW_BIN=` unblocks |
| A3 | `MINGW_BIN ?=` honours environment and CLI values [Verified empirically on BOTH installed makes this session; make-manual semantics] | Code Examples | None — tested directly |

**If this table is empty:** n/a — it is not empty, but no user confirmation is required: all three items are verified or cited, and A1/A2 have safe fallbacks by design.

## Open Questions (RESOLVED)

1. **03-01 vs 03-02 rescoping after the D-03 fold-in** — **[RESOLVED]** in the plans: 03-01 = D-02 bounds test + clean-rebuild verification; 03-02 = the single coordinated dedup wave (Fortran + bridge + GUI + tests + DLL rebuild) + docs refresh.
   - What we know: rm_L consolidation folds into the dedup change; 03-01 may reduce to verification + bounds test (CONTEXT D-03, discretion item).
   - What's unclear: which plan owns which file and the execution order.
   - Recommendation: 03-01 = verification + D-02 bounds test + docs refresh (D-06); 03-02 = the single coordinated dedup wave (Fortran + bridge + GUI + tests + DLL rebuild). Exact split is the planner's discretion. **[RESOLVED by plans 03-01/03-02]**

2. **`RUNTIME_DLLS` dead variable** (Makefile:53-57) — **[RESOLVED]** optional cleanup granted as agent discretion in 03-02 Task 2 Group B; permitted only if zero behavior change, skip if any doubt.
   - What we know: defined, never referenced; the copy rules hardcode the four names (170-173).
   - What's unclear: whether to fold the copy rules onto the variable as cleanup.
   - Recommendation: permitted as optional cleanup (discretion); must not change behaviour. Skipping is also fine — the copy rules work as-is with the discovered path. **[RESOLVED: optional, discretion-gated]**

3. **Manual GUI smoke after dedup** — **[RESOLVED]** landed in 03-02 Task 2 Group D with an offscreen-QT fallback (`QT_QPA_PLATFORM=offscreen` on `test_gui_full_pipeline.py`) when a windowed launch is not possible.
   - What we know: `test_gui_full_pipeline.py` (13 tests) exercises the GUI's pipeline invocation without launching the window.
   - What's unclear: whether a launched-window smoke (`make gui`) is required by the verifier.
   - Recommendation: include `python SRC/gui/gui.py` launch + one run as a verification step (D-05's "green at every commit" covers tests; the launch smoke covers the removed twin's import-time effect). **[RESOLVED: windowed launch + offscreen fallback]**

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| `gfortran` (TDM-GCC) | Rebuild DLL after Fortran edit | ✓ | GNU Fortran 10.3.0 (`C:\TDM-GCC-64\bin\gfortran.exe`) | — |
| GNU Make (chocolatey) | `make all` / `make gui` | ✓ | 4.4.1 (`C:\ProgramData\chocolatey\bin\make.exe`, first on PATH) | mingw32-make |
| mingw32-make (TDM) | Alternate make | ✓ | 3.82.90 (`C:\TDM-GCC-64\bin\mingw32-make.exe`) | GNU Make |
| Python | ctypes bridge, tests, GUI | ✓ | 3.11.1 | — |
| PyQt6 | GUI launch smoke | ✓ | 6.11.0 (pip) | — |
| node | gsd-tools shim only | ✓ | v24.19.0 (not on PATH — prepend `$env:ProgramFiles\nodejs`) | — |
| `build/librocket.dll` + 4 runtime DLLs | Tests and GUI load | ✓ | built 6/9/2026, 156,614 B | rebuild via `make all` |

**Missing dependencies with no fallback:** none.
**Missing dependencies with fallback:** none.
**Step 2.6 note:** no `sh.exe`/`bash.exe` on PATH (verified) — both makes run with the cmd.exe shell, which is what makes the `where`-based discovery work. If the PATH changes later, the D-09 hint fires (documented).

## Validation Architecture

> `.planning/config.json` has no `nyquist_validation` key → treated as enabled.

### Test Framework

| Property | Value |
|----------|-------|
| Framework | Python stdlib `unittest` (Python 3.11.1); no pytest dependency |
| Config file | none — discovery-based (`-p "test_*.py"`) |
| Quick run command | `python -m unittest discover -s SRC/test -p "test_rocket_lib.py"` (from repo root) |
| Full suite command | `python -m unittest discover -s SRC/test -p "test_*.py"` |

Baseline this session: `test_rocket_lib.py` → Ran 10 tests, OK (0.029s); `test_gui_full_pipeline.py` → Ran 13 tests, OK (0.641s). 23 green.

### Phase Requirements → Test Map

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| FIX-01 | `rm_L` initialized from single formula source on the only surviving entry | integration (against rebuilt DLL) | existing RunFullPipelineContract tests + D-02 bounds test (`test_rocket_lib.py`) | ✅ `test_rocket_lib.py` (bounds test added in-phase) |
| FIX-02 | `run_staging` gone everywhere; suite green every commit | integration | same suite + negative export check `not hasattr(rocket_lib.lib, "run_staging")` | ✅ (RunStagingWrapperContract removed in-phase) |
| FIX-03 | No drive-letter literal in Makefile; discovery + override + hint | manual build check | `make clean && make all` on both makes; `MINGW_BIN=` env/CLI override probe | n/a — build-time behaviour, verified by execution |

### Sampling Rate
- **Per task commit:** `python -m unittest discover -s SRC/test -p "test_rocket_lib.py"`
- **Per wave merge:** full suite `-p "test_*.py"`
- **Phase gate:** full suite green + `make all` clean build + negative export check + `make gui` launch smoke before `/gsd-verify-work`

### Wave 0 Gaps
- [ ] `test_rocket_lib.py` — D-02 conservative-bounds test added in-phase (covers FIX-01 behavioral guard)
- [ ] None external: framework (stdlib unittest) and both test files already exist; no new fixtures needed.

## Security Domain

> `.planning/config.json` has no `security_enforcement` key → treated as enabled.

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | no | standalone single-user desktop app; no auth surface |
| V3 Session Management | no | no sessions |
| V4 Access Control | no | single-user local app |
| V5 Input Validation | yes | ctypes `.argtypes` declarations — the typed contract layer; after D-04 they exist exactly once (`rocket_lib.py:45-70`). GUI passes Python scalars/lists; Fortran reads typed `c_double`/`c_int` arrays |
| V6 Cryptography | no | no crypto |

### Known Threat Patterns for Fortran/ctypes stack

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| DLL hijacking via PATH search (pre-3.8 behavior) | Tampering | `os.add_dll_directory(BUILD_DIR)` — app dir/System32/DLL-dir only; PATH no longer consulted (D-08) |
| Arbitrary DLL-dir injection via env var | Tampering | Removal of the `MINGW_BIN` env lookup in Python (`rocket_lib.py:19-21`, D-08) — the env var survives only as a Makefile build-time override (D-09), never as a runtime DLL-search input |
| `build/` directory is user-writable | Tampering | Accepted residual for a local dev toolchain; DLL is loaded via absolute path from the repo, never from cwd or PATH |

## Sources

### Primary (HIGH confidence — read/verified this session)
- `SRC/interface/C_Interface.f90` (full read, 223 lines) — removal surface 10-102; seeds 41-43, 146-157; pipeline call order 169-175; eq-26 packing 178-217
- `SRC/interface/rocket_lib.py` (full read, 176 lines) — win32 load block 17-24; run_staging argtypes 26-43 + wrapper 72-115; run_full_pipeline argtypes 45-70 + wrapper 117-176
- `SRC/gui/gui.py` (lines 15-134 + targeted grep) — twin surface 20, 25-26, 32-56, 58-111; keeper 1143; stale comments 30, 911
- `SRC/pre-staging-calcs/Payload_Mass_calc.f90` (full read) — PAF eq. 11 verbatim, lines 12/19
- `SRC/staging/Stage_Optimization_Loop.f90` (lines 1-45) — delta_v self-seed line 26; sole remaining STAGING caller 34
- `SRC/staging/Staging.f90` (lines 70-114) — rm_L reads 86, 106
- `SRC/Makefile` (full read, 220 lines) — hardcoded MINGW_BIN line 52; dead RUNTIME_DLLS 53-57; copy rules 168-174
- `SRC/test_call.py`, `SRC/test/test_rocket_lib.py` (full reads) — consumer/removal surfaces
- `03-CONTEXT.md` (full read) — locked decisions quoted verbatim below
- `AGENTS.md` (full read) — project constraints quoted in full
- Empirical: D-09 pattern on both makes (discovery / failure / env override / CLI override); test baseline 10+13 OK; bounds probe data

### Secondary (MEDIUM confidence — official docs via web, cross-checked)
- [CITED: docs.python.org/3/library/os.html] — `os.add_dll_directory`: adds path for dependency resolution of imported extension modules and ctypes; 3.8+ / Windows-only
- [CITED: docs.python.org/3/library/ctypes.html] — CDLL failure mode when a dependent DLL is not found
- [CITED: stackoverflow.com (Eryk Sun, CPython)] — Python 3.8+ DLL search: application dir, System32, DLL's own dir searched automatically; everything else needs `add_dll_directory`
- [CITED: GNU make manual — "Choosing the Shell"] — sh.exe preferred when present on Windows; fallback to default shell otherwise

### Tertiary (LOW confidence)
- None — every claim is either [VERIFIED] by this-session reads/tests or [CITED] from the sources above. WebSearch was used only to confirm the two documentation claims above (both confirmed).

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH — no new packages; all existing components verified live this session (versions above)
- Architecture: HIGH — every line of the removal surface read this session; orphan analysis from direct reads; D-09 pattern empirically proven on both makes
- Pitfalls: HIGH — rooted in direct observation (import-time collection order, stale-DLL export, `:=` vs `?=`, sh.exe fail-safe)

**Research date:** 2026-09-06
**Valid until:** 2026-10-01 — findings are tied to the repo's current source state (stable working tree, no fast-moving dependencies; re-verify line numbers if the tree changes before planning)