---
phase: 01-centralized-3-tab-gui
plan: 5
subsystem: bridge, testing
tags: [ctypes, rocket_lib, sys.path, smoke-test, gap-closure]

# Dependency graph
requires:
  - phase: 01-centralized-3-tab-gui
    provides: gui.py:29 sys.path pattern (surviving in-repo pattern after 72c468f reorg)
provides:
  - Restored `SRC/test_call.py` bridge-smoke import (G-01-4 closed) — resolves from any CWD
  - Accurate TESTING.md run instruction for the interface/ layout
affects: [Phase 3 FIX-02 bridge consolidation, verify-work UAT Test 4]

# Actuals (#2632) — pairs with the plan's `estimate` (12000 tokens) to calibrate future estimates.
# Same estimateTokens scale (chars/4 over the realized diff), never a harness token count.
actuals:
  tokens: 65
  tasks: 2
  commits: 2

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "script/bootstrap import pattern: sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), 'interface')) before a bare `from rocket_lib import ...` (gui.py:29 mirror)"

key-files:
  created: []
  modified:
    - SRC/test_call.py
    - .planning/codebase/TESTING.md

key-decisions:
  - "Keep the bare `from rocket_lib import run_staging` in test_call.py and fix the import path (gui.py:29 mirror) rather than rewriting to `interface.rocket_lib` — preserves the module's __file__-based DLL path resolution (rocket_lib.py:12-15)."

patterns-established:
  - "Bridge-consumer scripts derive the interface/ path from __file__ before the bare import, so the smoke test runs from any CWD."

requirements-completed: []

# Coverage metadata (#1602) — one entry per shipped deliverable.
coverage:
  - id: D1
    description: "SRC/test_call.py bridge-smoke import restored — `from rocket_lib import run_staging` resolves from any CWD (G-01-4 ModuleNotFoundError closed)"
    verification:
      - kind: e2e
        ref: "python -m py_compile SRC/test_call.py && python SRC/test_call.py (repo root AND SRC/ CWDs) — no ModuleNotFoundError; DLL loaded, full run completed"
        status: pass
    human_judgment: false
  - id: D2
    description: "TESTING.md:17 run command corrected for the post-reorg layout (interface/ import, any-CWD, build/librocket.dll prerequisite)"
    verification:
      - kind: other
        ref: "Select-String gate: 'must be run from SRC/' count 0; 'interface/' count > 0; 'build/librocket.dll' count > 0"
        status: pass
    human_judgment: false

# Metrics
duration: 4min
completed: 2026-09-06
status: complete
---

# Phase 01 Plan 5: Gap-Closure — Restore test_call.py Bridge-Smoke Import Summary

**G-01-4 (blocker) closed: `SRC/test_call.py` bridges SRC/interface/rocket_lib.py via the gui.py:29 `sys.path.insert` pattern, and TESTING.md documents the post-reorg run contract — the ModuleNotFoundError is eliminated from any CWD.**

## Performance

- **Duration:** 4 min
- **Started:** 2026-09-06
- **Completed:** 2026-09-06
- **Tasks:** 2 (both `type="auto"`)
- **Files modified:** 2

## Accomplishments
- Restored the bridge-smoke import in `SRC/test_call.py` by inserting `sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), "interface"))` before the bare `from rocket_lib import run_staging` — the exact gui.py:29 pattern; import now resolves deterministically from repo root and from `SRC/`.
- Verified end-to-end from **both CWDs** (repo root and SRC/): no ModuleNotFoundError; `librocket.dll` loaded and the 3-stage smoke case ran to completion with finite per-stage results printed.
- Corrected the stale TESTING.md run command ("must be run from SRC/") to describe the current layout: `interface/` import, any-CWD execution, `build/librocket.dll` prerequisite (built via `make all` in SRC/).
- Zero diff in the bridge (SRC/gui/gui.py and SRC/interface/rocket_lib.py untouched) — bridge behavior unchanged by construction.

## Task Commits

Each task was committed atomically:

1. **Task 1: Add interface/ to sys.path in test_call.py before the import** - `4efd8f4` (fix)
2. **Task 2: Correct the stale TESTING.md run instruction** - `efd6eec` (docs)

**Plan metadata:** committed via per-task commits; SUMMARY committed separately (`docs`).

## Files Created/Modified
- `SRC/test_call.py` - Added 3 lines (stdlib `import os`/`import sys` + `sys.path.insert(0, ...interface)`) before the bare import; smoke case and prints untouched.
- `.planning/codebase/TESTING.md` - Line 17 run command rewritten for the interface/ layout + DLL prerequisite; no other lines touched.

## Decisions Made
- **Keep the bare import, fix the path** (per plan prohibition): `from rocket_lib import run_staging` stays; only path setup added, mirroring gui.py:29 exactly. Preserves `rocket_lib.py`'s `__file__`-based DLL path resolution.

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered
- **Gate C note (not a deviation):** `build/librocket.dll` was present on this machine, so the smoke test ran to full completion (not just the machine-blocked DLL-load failure). Per-stage masses print as `0.0 kg` — this is the pre-existing `Rocket%rm_L` uninitialized ctypes-path bug documented in CONCERNS.md (FIX-01, Phase 3), out of scope for this plan. The import defect (G-01-4) is closed regardless.

## User Setup Required

None - no external service configuration required. DLL rebuild belongs to 01-04's verification.

## Next Phase Readiness
- UAT Test 4 truth restored: bridge smoke import resolves from any CWD; zero diff in `gui.py:22-110` / `rocket_lib.py`.
- TESTING.md now describes the current layout; documentation is accurate for Phase 2/3 planning (FIX-02 bridge consolidation builds on this groundwork).
- Full gate pass confirmed on machines with `build/librocket.dll` present (01-04's `make all` supplies it where absent).

---
*Phase: 01-centralized-3-tab-gui*
*Completed: 2026-09-06*

## Self-Check: PASSED

- Files verified on disk: `SRC/test_call.py`, `.planning/codebase/TESTING.md`, `01-05-SUMMARY.md` — all FOUND.
- Commits verified in git history: `4efd8f4` (Task 1 fix), `efd6eec` (Task 2 docs).
- Gate A (py_compile): PASS. Gate B (import from repo root AND SRC/ CWDs): PASS — no ModuleNotFoundError. Gate C (full run): PASS — DLL loaded, run completed (0.0 kg masses reflect pre-existing rm_L bug, FIX-01 scope). Gate D (Select-String): PASS. Diff guard (gui.py/rocket_lib.py): PASS — zero diff.