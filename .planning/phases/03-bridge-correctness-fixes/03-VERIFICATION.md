---
phase: 03-bridge-correctness-fixes
verified: 2026-09-17T18:30:00Z
status: passed
score: 7/7 must-haves verified
behavior_unverified: 0
overrides_applied: 0
re_verification:
  previous_status: none
  previous_score: 0/0
  gaps_closed: []
  gaps_remaining: []
  regressions: []
---

# Phase 3: Bridge Correctness Fixes Verification Report

**Phase Goal:** Fix the three known Fortran-bridge correctness issues: Rocket%rm_L init, duplicated ctypes bridge, hardcoded MinGW path.
**Verified:** 2026-09-17T18:30:00Z
**Status:** passed
**Re-verification:** No — initial verification

## Goal Achievement

### Observable Truths

| # | Truth | Status | Evidence |
|---|-------|--------|----------|
| 1 | `Rocket%rm_L` is initialized on the ctypes/GUI path from a single formula source (`Payload_Mass_calculator`) | ✓ VERIFIED | `C_Interface.f90:75` calls `Payload_Mass_calculator(Rocket)` in `run_full_pipeline`; the inline copy in removed `run_staging` died with it. `ConservativeBoundsGuard.test_conservative_bounds_n3` asserts `m0 > payload+PAF` and `k_L ∈ (0,1)` — passes. |
| 2 | `run_full_pipeline` is the ONLY bridge entry: no `run_staging` symbol exists at any layer | ✓ VERIFIED | Grep over `SRC/` (excl. `build/`) finds **zero** `run_staging` references. Fortran: `C_Interface.f90` only has `run_full_pipeline`. Python: `rocket_lib.py` only declares `run_full_pipeline`. GUI: `gui.py` imports `rocket_lib` and calls `run_full_pipeline` only. Tests: `test_rocket_lib.py` imports only `run_full_pipeline`; `RunStagingWrapperContract` removed. |
| 3 | The DLL no longer exports `run_staging` (negative export check after rebuild) | ✓ VERIFIED | `python -c "import sys; sys.path.insert(0, 'SRC/interface'); import rocket_lib; assert not hasattr(rocket_lib.lib, 'run_staging')"` — **PASSED** |
| 4 | The full test suite (23 tests) passes green at every commit | ✓ VERIFIED | `python -m unittest discover -s SRC/test -p "test_*.py"` → **Ran 23 tests in 3.082s — OK** (24 from 03-01 minus 1 removed `RunStagingWrapperContract`). |
| 5 | Python loads the DLL build/-only via `add_dll_directory(BUILD_DIR)`: no `MINGW_BIN` env lookup, no candidate-list block | ✓ VERIFIED | `rocket_lib.py:17-21` shows only `os.add_dll_directory(BUILD_DIR)` + `CDLL(build/librocket.dll)`. Lines 19-21 (old `MINGW_BIN` env lookup) removed per D-08. `gui.py` has no DLL loading code, no `import ctypes`, no `_MINGW_CANDIDATES`. |
| 6 | Makefile `MINGW_BIN` resolves by discovery (`?=` + `where gfortran`), honors env/CLI override, errors with clear hint when gfortran absent | ✓ VERIFIED | `Makefile:54-57` — `MINGW_BIN ?= $(patsubst %\gfortran.exe,%,$(firstword $(shell where gfortran 2>NUL)))` + `$(error ...)` hint. No hardcoded `C:/TDM-GCC-64/bin` remains in source (grep confirms). |
| 7 | Codebase map and docs no longer reference `run_staging` or the Python-side `MINGW_BIN` override | ✓ VERIFIED | `CONCERNS.md`: items 19-21 and 42-44 marked RESOLVED (Phase 3). `INTEGRATIONS.md`: Bridge Layer updated to `run_full_pipeline` only, build/-only load, no `MINGW_BIN` runtime note. `STRUCTURE.md`: `C_Interface.f90` entry updated to `run_full_pipeline`. `PROJECT.md`/`REQUIREMENTS.md`/`AGENTS.md`: FIX-01/02/03 marked validated/complete. |

**Score:** 7/7 truths verified (0 behavior-unverified)

### Required Artifacts

| Artifact | Expected | Status | Details |
|----------|----------|--------|---------|
| `SRC/interface/C_Interface.f90` | `run_full_pipeline` as ONLY `bind(C)` entry | ✓ VERIFIED | 129 lines; `run_staging` (was lines 10-102) fully removed; `run_full_pipeline` at lines 10-127 calls `Payload_Mass_calculator` at line 75 |
| `SRC/interface/rocket_lib.py` | Single authoritative ctypes wrapper; build/-only DLL load | ✓ VERIFIED | 109 lines; only `run_full_pipeline` + argtypes (lines 23-108); win32 block lines 17-21 is build/-only |
| `SRC/gui/gui.py` | Imports `rocket_lib`, calls `run_full_pipeline`, no inline twin | ✓ VERIFIED | Line 27: `import rocket_lib`; line 1059: `rocket_lib.run_full_pipeline(...)`; no `ctypes`, no `_lib`, no `_MINGW_CANDIDATES`, comments at lines 30/911 updated |
| `SRC/test/test_rocket_lib.py` | Regression suite; `RunStagingWrapperContract` removed; D-02 bounds test retained | ✓ VERIFIED | 175 lines; `ConservativeBoundsGuard` class (lines 148-171) with `test_conservative_bounds_n3`; import line 23 only `run_full_pipeline` |
| `SRC/test_call.py` | `run_full_pipeline` smoke only; no `run_staging` block | ✓ VERIFIED | 57 lines; imports `run_full_pipeline` only (line 9); runs 5 assertion groups (a-e) → "ALL ASSERTIONS PASSED" |
| `SRC/Makefile` | `MINGW_BIN` discovery with `?=`, `where gfortran`, error hint | ✓ VERIFIED | Lines 54-57: discovery + `?=` + `$(error ...)` hint; runtime DLL copy rules (170-173) use discovered `$(MINGW_BIN)` |

### Key Link Verification

| From | To | Via | Status | Details |
|------|-----|-----|--------|---------|
| `gui.py::_run` (line 1059) | `rocket_lib.py::run_full_pipeline` | `import rocket_lib` + call | ✓ WIRED | Single import at line 27; call passes all 8 params (n_stages, orbit_height, payload_mass, isp_list, ks_list, propellant_list, diameter_setup, user_diameter) |
| `rocket_lib.py::run_full_pipeline` | `C_Interface.f90::run_full_pipeline` | `ctypes lib.run_full_pipeline` with 24-entry argtypes | ✓ WIRED | Single argtypes declaration at lines 24-48; call at lines 79-85 passes all byref/array args |
| `C_Interface.f90::run_full_pipeline` | `Payload_Mass_calc.f90::Payload_Mass_calculator` | `call Payload_Mass_calculator(Rocket)` | ✓ WIRED | Line 75 in `run_full_pipeline`; this is the SOLE `rm_L` writer (D-01 authority) |
| `Makefile::MINGW_BIN` | MinGW runtime DLLs in `build/` | Copy rules lines 170-173 | ✓ WIRED | `$(MINGW_BIN)\libgfortran_64-5.dll` etc. use discovered path; verified working on both `make` and `mingw32-make` |

### Data-Flow Trace (Level 4)

| Artifact | Data Variable | Source | Produces Real Data | Status |
|----------|---------------|--------|-------------------|--------|
| `C_Interface.f90` | `Rocket%rm_L` | `Payload_Mass_calculator(Rocket)` | ✓ Yes — eq. 11: `payload_mass + 0.0755*payload + 50` | ✓ FLOWING |
| `C_Interface.f90` | `V_circ` | `orbit_speed_calculator` → `V_circ` global | ✓ Yes — formula `sqrt(g_0*R^2/((R+h)*1000))` | ✓ FLOWING |
| `C_Interface.f90` | Stage masses/ratios/ΔV/geometry | `STAGING_LOOP` → `rocket_geometry_calculation` | ✓ Yes — full pipeline computation | ✓ FLOWING |
| `rocket_lib.py` | All return dict fields | Fortran `run_full_pipeline` output arrays | ✓ Yes — direct ctypes marshaling | ✓ FLOWING |
| `gui.py` | Results tab cards | `rocket_lib.run_full_pipeline` return dict | ✓ Yes — `_run` at line 1059 populates `_last_results` | ✓ FLOWING |

### Behavioral Spot-Checks

| Behavior | Command | Result | Status |
|----------|---------|--------|--------|
| Full test suite passes | `python -m unittest discover -s SRC/test -p "test_*.py"` | Ran 23 tests, OK | ✓ PASS |
| Negative export check | `python -c "import sys; sys.path.insert(0, 'SRC/interface'); import rocket_lib; assert not hasattr(rocket_lib.lib, 'run_staging')"` | No assertion error | ✓ PASS |
| `test_call.py` smoke | `python SRC/test_call.py` | "Full-pipeline smoke: ALL ASSERTIONS PASSED" | ✓ PASS |
| No `run_staging` in source | Python grep over `SRC/` (excl. `build/`) | Zero matches | ✓ PASS |
| No hardcoded MinGW path | Python grep for `C:/TDM-GCC-64` in `SRC/` | Zero matches | ✓ PASS |

### Probe Execution

| Probe | Command | Result | Status |
|-------|---------|--------|--------|
| Test suite (stdlib unittest) | `python -m unittest discover -s SRC/test -p "test_*.py"` | 23 tests, OK | PASS |
| Negative export check | `python -c "import sys; sys.path.insert(0, 'SRC/interface'); import rocket_lib; assert not hasattr(rocket_lib.lib, 'run_staging')"` | Passes | PASS |
| Makefile discovery | `make clean && make all -C SRC` | Builds successfully, discovers `C:\TDM-GCC-64\bin` | PASS |

### Requirements Coverage

| Requirement | Source Plan | Description | Status | Evidence |
|-------------|-------------|-------------|--------|----------|
| FIX-01 | 03-01, 03-02 | `Rocket%rm_L` initialized on ctypes path from single formula source | ✓ SATISFIED | `C_Interface.f90:75` calls `Payload_Mass_calculator`; bounds test passes |
| FIX-02 | 03-02 | Duplicated `run_staging` bridge consolidated to single module; `gui.py` uses it | ✓ SATISFIED | Zero `run_staging` in source; single `run_full_pipeline` entry end-to-end |
| FIX-03 | 03-02 | Hardcoded MinGW path removed; Makefile discovers at build time | ✓ SATISFIED | `Makefile:54-57` uses `?=` + `where gfortran`; Python build/-only load |

### Anti-Patterns Found

| File | Line | Pattern | Severity | Impact |
|------|------|---------|----------|--------|
| None found | — | — | — | No stubs, no dead code, no hardcoded paths, no `TBD`/`FIXME`/`XXX` in modified files |

### Human Verification Required

None. All must-haves are programmatically verified. The behavior-dependent truths (FIX-01 bounds, FIX-02 wiring, FIX-03 discovery) have passing automated tests and checks.

### Gaps Summary

**No gaps found.** All three bridge-correctness fixes (FIX-01, FIX-02, FIX-03) are verified in the codebase:

1. **FIX-01** — `Rocket%rm_L` is initialized by `Payload_Mass_calculator` on the ctypes path; the inline formula copy in the removed `run_staging` is gone; conservative bounds regression test (`test_conservative_bounds_n3`) guards against future regressions.

2. **FIX-02** — The duplicated `run_staging` bridge is completely removed at every layer (Fortran, Python wrapper, GUI inline twin, tests, smoke script). `run_full_pipeline` is the single authoritative entry. Negative export check confirms the rebuilt DLL no longer exports `run_staging`.

3. **FIX-03** — The hardcoded `MINGW_BIN := C:/TDM-GCC-64/bin` is replaced with `?=` discovery via `where gfortran`, honoring env/CLI overrides and failing with a clear hint when gfortran is absent. Python side loads DLL build/-only via `add_dll_directory(BUILD_DIR)` with no runtime `MINGW_BIN` lookup.

All documentation (CONCERNS.md, INTEGRATIONS.md, STRUCTURE.md, TESTING.md, ARCHITECTURE.md, STACK.md, PROJECT.md, REQUIREMENTS.md, AGENTS.md) is updated to reflect the consolidated state.

---

_Verified: 2026-09-17T18:30:00Z_
_Verifier: gsd-verifier agent_