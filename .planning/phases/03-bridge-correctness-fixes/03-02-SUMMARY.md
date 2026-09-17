---
phase: 03-bridge-correctness-fixes
plan: 2
subsystem: bridge
tags: [ctypes, fortran, makefile, gui, dll, consolidation]

# Dependency graph
requires:
  - phase: 03-01
    provides: ConservativeBoundsGuard regression test for rm_L (FIX-01 sentinel); pre-dedup baseline: 24-test green suite against freshly rebuilt build/librocket.dll
provides:
  - run_full_pipeline as the ONLY bridge entry end-to-end (Fortran → ctypes → GUI → tests → smoke)
  - FIX-01 closed: Rocket%rm_L initialized solely by Payload_Mass_calculator
  - FIX-02 closed: Zero run_staging references in the tree (excluding build/)
  - FIX-03 closed: Makefile discovers MinGW via ?= + where gfortran; Python loads build/-only
  - Codebase map and docs reflect consolidated state (D-06)
affects: [verify-work phase 3]

# Actuals (#2632) — pairs with the plan's `estimate` to calibrate future estimates.
# Same estimateTokens scale (chars/4 over the realized diff), never a harness token count.
actuals:
  tokens: 36750
  tasks: 2
  commits: 4

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Single authoritative ctypes bridge entry (run_full_pipeline) — no duplicate declarations at any layer"
    - "Build-time MinGW discovery via ?= + where gfortran with env/CLI override and clear error hint"
    - "Build/-only DLL load via os.add_dll_directory(BUILD_DIR); no runtime MINGW_BIN env lookup"
    - "Conservative physical-bounds regression testing for ctypes bridge outputs (finitude + strict inequality guards)"

key-files:
  created: []
  modified:
    - "SRC/interface/C_Interface.f90"
    - "SRC/interface/rocket_lib.py"
    - "SRC/gui/gui.py"
    - "SRC/test/test_rocket_lib.py"
    - "SRC/test_call.py"
    - "SRC/Makefile"
    - "AGENTS.md"
    - ".planning/codebase/CONCERNS.md"
    - ".planning/codebase/INTEGRATIONS.md"
    - ".planning/codebase/STRUCTURE.md"
    - ".planning/codebase/TESTING.md"
    - ".planning/codebase/ARCHITECTURE.md"
    - ".planning/codebase/STACK.md"
    - ".planning/PROJECT.md"
    - ".planning/REQUIREMENTS.md"

key-decisions:
  - "Coordinated single-wave removal of run_staging at every layer (D-04/D-05): Fortran bind(C), Python wrapper + argtypes, gui.py inline twin + _lib handle + _MINGW_CANDIDATES block, test consumers — all in one atomic commit so the suite never sees a red collection-time ImportError"
  - "run_full_pipeline is the sole survivor; the inline rm_L formula copy in C_Interface.f90 dies with run_staging — Payload_Mass_calculator is the single formula source (FIX-01/D-01)"
  - "Makefile MINGW_BIN uses ?= (not :=) discovery via where gfortran + patsubst + firstword, with $(error ...) hint — env/CLI override honored (D-09/FIX-03)"
  - "Python loads DLL build/-only via add_dll_directory(BUILD_DIR); MINGW_BIN env lookup removed from rocket_lib.py (D-08/FIX-03)"
  - "test_call.py converted to run_full_pipeline-only smoke (D-07); keeps sys.path hook and all five assertion groups"
  - "Codebase map docs (CONCERNS, INTEGRATIONS, STRUCTURE, TESTING, ARCHITECTURE, STACK, PROJECT, REQUIREMENTS, AGENTS) refreshed in one commit marking FIX-01/02/03 resolved"

patterns-established:
  - "Atomic bridge consolidation: removal + rebuild + negative-export check + suite in one wave — prevents the collection-time ImportError that would occur if wrapper and tests updated in separate commits"
  - "Build-time toolchain discovery with ?= and clear $(error ...) hint — reproducible across machines, no hardcoded paths"
  - "Single ctypes declaration per bridge entry; gui.py imports the authoritative wrapper, never re-declares"

requirements-completed: [FIX-01, FIX-02, FIX-03]

# Coverage metadata (#1602) — one entry per shipped deliverable. Drives DETERMINISTIC UAT routing in verify-work.
coverage:
  - id: D1
    description: "run_full_pipeline is the only bridge entry end-to-end (Fortran bind(C) → ctypes wrapper → GUI import → tests → smoke); run_staging removed at every layer"
    requirement: FIX-02
    verification:
      - kind: integration
        ref: "git grep -rn run_staging SRC/ | grep -v build/ → no output"
        status: pass
      - kind: unit
        ref: "python -c \"import sys; sys.path.insert(0, 'SRC/interface'); import rocket_lib; assert not hasattr(rocket_lib.lib, 'run_staging')\""
        status: pass
      - kind: other
        ref: "python -m unittest discover -s SRC/test -p \"test_*.py\" (23 tests green)"
        status: pass
    human_judgment: false
  - id: D2
    description: "Rocket%rm_L initialized solely by Payload_Mass_calculator on the ctypes/GUI path; the inline formula copy in run_staging removed; bounds test green"
    requirement: FIX-01
    verification:
      - kind: unit
        ref: "SRC/test/test_rocket_lib.py#test_conservative_bounds_n3"
        status: pass
      - kind: other
        ref: "make all -C SRC && python -m unittest discover -s SRC/test -p \"test_*.py\""
        status: pass
    human_judgment: false
  - id: D3
    description: "Makefile discovers MinGW at build time via ?= + where gfortran; env/CLI override honored; clear error hint when gfortran absent; no hardcoded drive-letter literal remains"
    requirement: FIX-03
    verification:
      - kind: other
        ref: "make clean && make all -C SRC (both make and mingw32-make); MINGW_BIN=\"C:\\fake\" make all fails with hint; MINGW_BIN=\"C:/real-mingw\" make all succeeds"
        status: pass
      - kind: other
        ref: "grep -rn \"C:/TDM-GCC-64\" SRC/Makefile → no output"
        status: pass
    human_judgment: false
  - id: D4
    description: "Codebase map and docs (CONCERNS, INTEGRATIONS, STRUCTURE, TESTING, ARCHITECTURE, STACK, PROJECT, REQUIREMENTS, AGENTS.md) reflect consolidated state — FIX-01/02/03 marked resolved"
    requirement: FIX-01, FIX-02, FIX-03
    verification:
      - kind: manual_procedural
        ref: "git diff .planning/codebase/ CONCERNS.md INTEGRATIONS.md STRUCTURE.md TESTING.md ARCHITECTURE.md STACK.md .planning/PROJECT.md .planning/REQUIREMENTS.md AGENTS.md"
        status: pass
    human_judgment: true
    rationale: "Documentation accuracy requires human review; automated checks only verify file modifications, not semantic correctness of prose updates."

# Metrics
duration: 15min
completed: 2026-09-07
status: complete
---

# Phase 3 Plan 2: Bridge Correctness Fixes — Single-Wave Consolidation Summary

**run_full_pipeline is now the sole bridge entry end-to-end; FIX-01/02/03 closed; Makefile discovers MinGW at build time; codebase map refreshed; full suite green at every commit**

## Performance

- **Duration:** 15 min
- **Started:** 2026-09-07T15:42:02Z
- **Completed:** 2026-09-07T15:57:00Z
- **Tasks:** 2
- **Files modified:** 14

## Accomplishments

- **FIX-01 (rm_L single source):** The inline `Rocket%rm_L = payload_mass + 0.0755*payload_mass + 50` formula copy in `C_Interface.f90:54-59` removed with `run_staging`; `Payload_Mass_calculator` is now the sole authority — verified by `ConservativeBoundsGuard.test_conservative_bounds_n3` (finite m0 > payload+PAF, k_L ∈ (0,1))
- **FIX-02 (single bridge entry):** `run_staging` removed at every layer — Fortran `bind(C)` subroutine (94 lines), Python wrapper + argtypes (67 lines), GUI inline twin + `_lib` handle + `_MINGW_CANDIDATES` block + `import ctypes` (90 lines), test import + `RunStagingWrapperContract` class (21 lines) — all in one atomic commit (`8b49b2f`)
- **FIX-03 (resolvable library path):** Makefile `MINGW_BIN` hardcoded path replaced with `?=` discovery via `where gfortran` + `patsubst` + `firstword` + `$(error ...)` hint (D-09); Python `rocket_lib.py` drops `MINGW_BIN` env lookup, loads DLL build/-only via `add_dll_directory(BUILD_DIR)` (D-08) — verified with override probes and `grep C:/TDM-GCC-64`
- **test_call.py converted:** Full-pipeline-only smoke with all five assertion groups (a-e) retained; runs to `ALL ASSERTIONS PASSED` (commit `071a871`)
- **Codebase map refreshed:** 9 files updated marking FIX-01/02/03 resolved (commit `b79f298`)
- **Full suite green at every commit:** 23 tests (24 from 03-01 minus `RunStagingWrapperContract`), negative export check passes, GUI offscreen import verified (no `ctypes`, no `run_staging`, no `_lib`, `rocket_lib` imported)

## Task Commits

Each task was committed atomically:

1. **Task 1 (tracer): Coordinated run_staging removal at every layer + DLL rebuild + negative export check + full suite** - `8b49b2f` (refactor)
2. **Task 2 Group A: test_call.py conversion to run_full_pipeline smoke (D-07)** - `071a871` (refactor)
3. **Task 2 Group B: Makefile MinGW discovery (D-09) — ?= + where gfortran + error hint** - `d0ea9c0` (fix)
4. **Task 2 Group C: Docs refresh (D-06) — 9 codebase map files + PROJECT.md + REQUIREMENTS.md + AGENTS.md** - `b79f298` (docs)

**Plan metadata:** to be committed with this SUMMARY.md

## Files Created/Modified

- `SRC/interface/C_Interface.f90` - Deleted `run_staging` subroutine (lines 10-102) including inline rm_L formula copy; `run_full_pipeline` (lines 104-221) unchanged, `call Payload_Mass_calculator(Rocket)` at line 169 is sole rm_L writer
- `SRC/interface/rocket_lib.py` - Deleted `run_staging` wrapper + argtypes; removed MINGW_BIN env lookup; build/-only DLL load via `add_dll_directory(BUILD_DIR)`; `run_full_pipeline` + argtypes retained byte-identical
- `SRC/gui/gui.py` - Deleted `import ctypes`, `BUILD_DIR` compute, win32 `add_dll_directory` + `_MINGW_CANDIDATES` + WARNING print, `_lib = ctypes.CDLL(...)`, `_lib.run_staging.restype/.argtypes`, `def run_staging(...)` twin; rewrote stale comments (line 30, line 911); keeps `import rocket_lib` + call to `rocket_lib.run_full_pipeline` at ~line 1143
- `SRC/test/test_rocket_lib.py` - Module import trimmed to `run_full_pipeline` only; deleted `RunStagingWrapperContract` class; kept `ConservativeBoundsGuard`, `RunFullPipelineContract`, `RunFullPipelineVariantDomains`
- `SRC/test_call.py` - Deleted `run_staging` import + call + print loop; kept sys.path hook + `run_full_pipeline` smoke with all five assertions
- `SRC/Makefile` - `MINGW_BIN ?= $(patsubst %\gfortran.exe,%,$(firstword $(shell where gfortran 2>NUL)))` + `$(error ...)` hint; deleted dead `RUNTIME_DLLS` variable
- `AGENTS.md` - Current priorities updated: Phase 3 fixes done; resolved issues removed from CONCERNS list
- `.planning/codebase/CONCERNS.md` - Duplicated ctypes bridge, Rocket%rm_L uninitialized, Hardcoded MinGW path marked RESOLVED
- `.planning/codebase/INTEGRATIONS.md` - MINGW_BIN runtime env var removed; Bridge Layer updated to run_full_pipeline only, build/-only load
- `.planning/codebase/STRUCTURE.md` - c_interface entry updated to run_full_pipeline; sole ctypes entry point updated
- `.planning/codebase/TESTING.md` - test_call.py example updated to run_full_pipeline; mock guidance and golden-value check updated
- `.planning/codebase/ARCHITECTURE.md` - c_interface module entry updated; GUI/ctypes path description updated; dual entry and duplicated bridge marked resolved
- `.planning/codebase/STACK.md` - gfortran dependency updated to discovered path; MINGW_BIN runtime env var removed
- `.planning/PROJECT.md` - FIX-01/02/03 moved to Validated with phase references; Context updated to consolidated state
- `.planning/REQUIREMENTS.md` - FIX-01/02/03 marked [x] Complete in both v1 and v2 tables

## Decisions Made

- Coordinated single-wave removal (D-04/D-05) — prevents red suite at collection time; atomic commit across 4 source files + DLL rebuild
- `?=` not `:=` for MINGW_BIN — env/CLI override must be honored (Pitfall 5)
- `test_call.py` keeps literal kwargs for diameter_mode/diameter/propellant_list — no config.txt parser added (planner discretion)
- Docs refresh as one commit (Group C) — all codebase map files updated together
- Negative export check after every rebuild — `assert not hasattr(rocket_lib.lib, "run_staging")`

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

None.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- Phase 3 complete: all three bridge-correctness fixes (FIX-01/02/03) validated
- Full pipeline exposed to GUI via single `run_full_pipeline` entry; build/-only DLL load; discovered MinGW path
- Suite green (23 tests) with conservative bounds regression guard in place
- Ready for `/gsd-verify-work` phase 3 or next milestone planning

---

*Phase: 03-bridge-correctness-fixes*
*Completed: 2026-09-07*