---
gsd_state_version: 1.0
milestone: v1.1
milestone_name: GUI Visual Enhancements & Fairing Configuration
status: planning
last_updated: "2026-09-17T23:18:25.950Z"
last_activity: 2026-09-17
progress:
  total_phases: 0
  completed_phases: 0
  total_plans: 0
  completed_plans: 0
  percent: 0
---

# Project State

## Project Reference

See: .planning/PROJECT.md (updated 2026-08-14)

**Core value:** The user can go from mission parameters to a complete, trustworthy vehicle design (stage masses, ΔV, thrust, geometry) entirely from the GUI.
**Current focus:** Phase 03 — Bridge & Correctness Fixes

## Current Position

Phase: Not started (defining requirements)
Plan: —
Status: Defining requirements
Last activity: 2026-09-17 — Milestone v1.1 started

## Performance Metrics

**Velocity:**

- Total plans completed: 4
- Average duration: — min
- Total execution time: 0.0 hours

**By Phase:**

| Phase | Plans | Total | Avg/Plan |
|-------|-------|-------|----------|
| 1. Centralized 3-Tab GUI | 0 | 3 | — |
| 2. Full Pipeline Exposure | 0 | 2 | — |
| 3. Bridge & Correctness Fixes | 0 | 2 | — |
| 02 | 2 | - | - |
| 03 | 2 | - | - |

**Recent Trend:**

- Last 5 plans: —
- Trend: —

*Updated after each plan completion*
**Per-Plan Metrics:**

| Plan | Duration | Tasks | Files |
|------|----------|-------|-------|
| Phase 01-centralized-3-tab-gui P1 | 17min | 3 tasks | 1 files |
| Phase 01-centralized-3-tab-gui P2 | 14min | 2 tasks | 1 files |
| Phase 01-centralized-3-tab-gui P3 | 9min | 2 tasks | 1 files |
| Phase 02 P02-01 | 16 | 2 tasks | 4 files |
| Phase 02 P02-02 | 25 | 3 tasks | 1 files |
| Phase 03-bridge-correctness-fixes P1 | 2min | 2 tasks | 1 files |
| Phase 03-bridge-correctness-fixes P03-02 | 15 min | 2 tasks | 14 files |

## Accumulated Context

### Decisions

Decisions are logged in PROJECT.md Key Decisions table.
Recent decisions affecting current work:

- [Phase 1]: Centralized 3-tab GUI — Results (index 0) / Setup (sliders + propellant-cycle verbatim) / Vehicle Configuration (diameter modes 1/2/3, user-specified box)
- [Phase 1]: Mission inputs in GUI (orbit height 100–2000 km, payload, stages 1–3); ΔV computed internally, no hand-entered ΔV
- [Phase 1]: UI-SPEC locks tokens (4/8/16/24/32/48 spacing; 12/13/14/16px type; existing STYLE palette), QSS for QTabBar/QRadioButton, English copy, auto-switch to Results after Run
- [Project]: Tests deferred to future sessions (user decision)
- [Project]: config.txt stays a separate input path (user decision)
- [Phase 01-centralized-3-tab-gui]: Tab order contractual: Results(0) active on open / Setup(1) / Vehicle Configuration(2); tabs not movable/closable/renamable
- [Phase 01-centralized-3-tab-gui]: Tab-bar/radio QSS appended to STYLE using only the 12 named palette constants (append-only)
- [Phase 01-centralized-3-tab-gui]: dv_spin relocates verbatim into Setup; removal deferred to 01-02-T1
- [Phase 01-centralized-3-tab-gui]: D-10 completed: no ΔV input of any kind remains in the GUI; orbit height (100.0-2000.0) drives the interim _auto_delta_v() V_circ mirror (g_0=9.80665, Radius=6378.0, cited from Orbit_calc.f90:9-10 / Typical_Data.f90:3-5), documented interim for Phase 2 PIPE-01 removal.
- [Phase 01-centralized-3-tab-gui]: Diameter mode int stored via QButtonGroup.buttonToggled (fires on programmatic setChecked too), not buttonClicked (user-clicks only) — matches the plan's 'updated on radio toggled' contract and keeps Phase 2 handoff state correct under programmatic changes.
- [Phase 01-centralized-3-tab-gui]: Vehicle Configuration tab state (mode int + diameter value) stored on MainWindow for Phase 2; deliberately NOT wired into run_staging (Pitfall 8).
- [Phase 01-centralized-3-tab-gui]: ResultCard add_metric is fmt-aware with two formatting branches (% specs via fmt % value; format-specs via nested braces with lstrip colon): the PATTERNS s5 literal nested-spec pattern raises ValueError for both ':,.1f' (colon in spec) and '%.2f' (% not in the format mini-language); output byte-identical to the plan contract.
- [Phase 01-centralized-3-tab-gui]: Rows 0-3 keep the legacy :,.1f card rendering (k_m shows '2.3', nu_e '3.5 km/s' — byte-identical to pre-phase per plan truth 2); the UI-SPEC %.4f ratio contract governs the export file (unchanged) and the new rows' %.2f contract, not the legacy card rows.
- [Phase 01-centralized-3-tab-gui]: Partial-state hint condition mirrors the card placeholder lookup exactly (any of dv/diameter/length/volume None across stages -> one 11px TEXT_DIM hint); Phase 2 dicts packing all four keys suppress the hint automatically (verified offscreen).
- [Phase 01-centralized-3-tab-gui]: Auto-switch setCurrentIndex(0) placed after print_btn.setEnabled(True) in the _run success path only; _on_inputs_changed remains navigation-free (verified offscreen).
- [Phase 02]: 02-01 full-pipeline-exposure: tracer gate applied in autonomous form — dispatch mandated full-plan completion and T1's verify is fully automated, so the tracer <verify> was re-run end-to-end before expanding to T2 instead of halting for a rubber-stamp human-verify
- [Phase 02]: 02-01 full-pipeline-exposure: stale Phase 1 GUI process (PID 8724) holding build/librocket.dll killed to unblock the mandated make all rebuild (Rule 3); unrelated streamlit process left untouched
- [Phase 02]: 02-01 full-pipeline-exposure: per-stage volume packed as pi/4*D^2*L in C_Interface (constants-module pi) per the Geometry_calc identity; no Stage_t Volume field added
- [Phase 02]: 02-01 full-pipeline-exposure: STATE.md normalized (Plan '1 of ?' placeholder->'1 of 2', current_phase_name fixed to full-pipeline-exposure, milestone plan counts 9/7) so state.advance-plan parses; progress bar still shows Phase 1 view until phase close (orchestrator recomputes)
- [Phase 02]: T3 (gate=blocking human-verify) approved by the user WITH two follow-up changes implemented atomically: (1) diameter-configuration changes (mode radios + user-specified diameter) clear results / disable Save / reset _last_v_circ / restore '— km/s' label; (2) Run button visible on every tab except Results via a shared central row shown/hidden by tabs.currentChanged
- [Phase 02]: Diameter invalidation wired in the post-construction wiring block (mode_buttons.buttonToggled + diameter_spin.valueChanged -> _on_inputs_changed); construction-time setChecked/setValue never retroactively triggers; _on_mode_toggled stored-mode semantics (1/2/3) unchanged
- [Phase 02]: Run button relocated from setup_layout to a shared central row beneath the tabs (_build_ui) — objectName / ready property / stylesheet / clicked->_run unchanged; Save Results stays Results-tab-only; post-run auto-switch to Results unchanged (button hidden there)
- [Phase 02]: Estimate calibration: 02-02 actuals 2651 tokens (chars/4 over realized gui.py diff) vs 28000 estimated — ~10x over-estimate on a single-file GUI-wiring plan; scale down low-confidence estimates on mapped code
- [Phase 03-bridge-correctness-fixes]: D-02 bounds sentinel is a standalone unittest.TestCase calling run_full_pipeline(**N3_CONFIG) directly; conservative guards (m0 > payload+PAF, k_L in (0,1)) cannot false-fail on valid inputs but trip on uninitialized/garbage rm_L; PAF recomputed in-test from Payload_Mass_calc.f90 eq. 11. Task 2 (clean rebuild + baseline) is verification-only — zero source changes, no task commit. Tracer gate applied autonomously on resume: Task-1 tracer verify re-run end-to-end against fresh DLL before Task 2 — all 24 green.
- [Phase ?]: Coordinated single-wave removal of run_staging at every layer (D-04/D-05): Fortran bind(C), Python wrapper + argtypes, gui.py inline twin + _lib handle + _MINGW_CANDIDATES block, test consumers — all in one atomic commit so the suite never sees a red collection-time ImportError
- [Phase ?]: run_full_pipeline is the sole survivor; the inline rm_L formula copy in C_Interface.f90 dies with run_staging — Payload_Mass_calculator is the single formula source (FIX-01/D-01)
- [Phase ?]: Makefile MINGW_BIN uses ?= (not :=) discovery via where gfortran + patsubst + firstword, with  hint — env/CLI override honored (D-09/FIX-03)
- [Phase ?]: Python loads DLL build/-only via add_dll_directory(BUILD_DIR); MINGW_BIN env lookup removed from rocket_lib.py (D-08/FIX-03)
- [Phase ?]: test_call.py converted to run_full_pipeline-only smoke (D-07); keeps sys.path hook and all five assertion groups
- [Phase ?]: Codebase map docs (CONCERNS, INTEGRATIONS, STRUCTURE, TESTING, ARCHITECTURE, STACK, PROJECT, REQUIREMENTS, AGENTS.md) refreshed in one commit marking FIX-01/02/03 resolved

### Pending Todos

None yet.

### Blockers/Concerns

- `build/librocket.dll` present and proven on this machine (02-01 `make all` + `test_call.py` exit 0); GUI/offscreen validation runs run directly against it — no rebuild required unless Fortran sources change

## Deferred Items

Items acknowledged and carried forward:

| Category | Item | Status | Deferred At |
|----------|------|--------|-------------|
| Phase 2 | Full pipeline wiring (ΔV + geometry results populate) | Pending | 2026-08-14 |
| Phase 3 | rm_L init fix, bridge dedup, MinGW path | Pending | 2026-08-14 |
| Future | Automated tests | Pending | 2026-08-14 |

Items acknowledged and deferred at milestone close on 2026-09-17:

| Category | Item | Status |
|----------|------|--------|
| debug | DEBUG-null-masses-on-run | diagnosed |
| debug | DEBUG-test-call-import-error | diagnosed |

## Session Continuity

Last session: 2026-09-17T22:09:24.577Z
Stopped at: Completed 03-02-PLAN.md
Resume file: None

## Operator Next Steps

- Start the next milestone with /gsd-new-milestone
