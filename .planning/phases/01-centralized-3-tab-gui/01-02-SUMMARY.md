---
phase: 01-centralized-3-tab-gui
plan: 2
subsystem: ui
tags: [pyqt6, qspinbox, qradiobutton, qbuttongroup, mission-inputs, delta-v-removal]

# Dependency graph
requires:
  - phase: 01-centralized-3-tab-gui
    provides: 3-tab shell + Setup tab with relocated mission group incl. dv_spin (01-01-T2/T3)
provides:
  - Mission grid rework: orbit height spinbox (100-2000 km) + read-only "ΔV (auto)" label; dv_spin fully removed (D-10)
  - Interim _auto_delta_v() V_circ mirror (Orbit_calc.f90:9-10) feeding run_staging delta_v + export header/filename
  - Vehicle Configuration tab: DIAMETER MODE radios 1/2/3 with helper lines + user-specified diameter box (visibility contract)
affects: [01-03-results-surface-extension, 02-full-pipeline-exposure (PIPE-01 replaces _auto_delta_v), verify-work]

actuals:
  tokens: 2478   # chars/4 over realized diff (9915 chars across the 2 task commits)
  tasks: 2
  commits: 2

tech-stack:
  added: [QButtonGroup (new widget type used for radio exclusivity + mode ids)]
  patterns:
    - mission-grid idiom: bounded QDoubleSpinBox + read-only QLabel row; fan-out valueChanged -> _on_inputs_changed AND _update_auto_dv_label
    - radio group: QButtonGroup ids 1/2/3 + buttonToggled (checked-guard) stores diameter_mode int; mode_user.toggled -> diameter_spin.setVisible

key-files:
  created: []
  modified:
    - SRC/gui/gui.py

key-decisions:
  - "D-10 completed: no ΔV input of any kind remains in the GUI; orbit height (100.0-2000.0) drives the interim _auto_delta_v() V_circ mirror (g_0=9.80665, Radius=6378.0, cited from Orbit_calc.f90:9-10 / Typical_Data.f90:3-5), documented interim for Phase 2 PIPE-01 removal."
  - "Diameter mode int stored via QButtonGroup.buttonToggled (fires on programmatic setChecked too), not buttonClicked (user-clicks only) — matches the plan's 'updated on radio toggled' contract and keeps Phase 2 handoff state correct under programmatic changes."
  - "Vehicle Configuration tab state (mode int + diameter value) stored on MainWindow for Phase 2; deliberately NOT wired into run_staging (Pitfall 8)."

patterns-established:
  - "Mission grid: Orbit Height row 0 -> Payload row 1 -> Stages row 2 -> read-only ΔV (auto) row 3; orbit-height change fans out to cross-tab invalidation AND the label refresh."
  - "Radio-mode state: QButtonGroup with ids 1/2/3, buttonToggled slot guarded on `checked` writes self.diameter_mode; visibility wired declaratively via toggled -> setVisible."

requirements-completed: [GUI-05, GUI-06, GUI-07]

coverage:
  - id: D1
    description: "Setup tab mission grid: row 0 Orbit Height QDoubleSpinBox 100.0-2000.0 (decimals 1, step 10.0, default 500.0); rows 1-2 pl_spin/n_stages_spin verbatim; row 3 read-only ΔV (auto) label {:.2f} km/s TEXT_SEC 12px that updates on orbit-height change and feeds run_staging + export"
    requirement: GUI-05
    verification:
      - kind: integration
        ref: "offscreen smoke smoke_0102_t1.py (17 checks: widget contract, label math 7.62 km/s @500km, label update, run_staging delta_v capture, export Delta-V line + filename pattern)"
        status: pass
    human_judgment: false
  - id: D2
    description: "dv_spin fully removed — no ΔV input exists anywhere in the GUI (D-10, GUI-05); the removed widget is not re-added and no editable ΔV control exists"
    requirement: GUI-05
    verification:
      - kind: integration
        ref: "Select-String dv_spin SRC/gui/gui.py -> zero matches (exit 1); offscreen smoke 'no dv_spin attribute on window' PASS"
        status: pass
    human_judgment: false
  - id: D3
    description: "Vehicle Configuration tab: header + subtitle + divider; DIAMETER MODE group with exactly 3 mutually-exclusive radios (QButtonGroup ids 1/2/3, mode 1 default checked) each with its 11px TEXT_SEC helper line (UI-SPEC copy)"
    requirement: GUI-06
    verification:
      - kind: integration
        ref: "offscreen smoke smoke_0102_t2.py (26 checks: labels exact, ids, default state, helper copy, exclusivity)"
        status: pass
    human_judgment: false
  - id: D4
    description: "User-Specified Diameter box (0.5-20.0, decimals 2, step 0.1, default 2.00) visible only in mode 3, hidden in modes 1/2; value persists across mode toggles and tab switches (widgets never rebuilt); diameter_mode int + value stored as MainWindow state for Phase 2, NOT wired into run_staging"
    requirement: GUI-07
    verification:
      - kind: integration
        ref: "offscreen smoke smoke_0102_t2.py (visibility contract, persistence 5.55/6.66 across toggles + tab switches, run_staging untouched via inspect.getsource)"
        status: pass
    human_judgment: false
  - id: D5
    description: "Full GUI smoke (`make gui` in SRC/: DLL build + launch; Setup shows Orbit Height 500.0 / Payload / Stages / read-only ΔV (auto); orbit change updates label + clears Results + disables Save; Run + Save work; export Delta-V line equals label; filename staging_{n}stage_dv{dv:.1f}_pl{pl}kg.txt)"
    verification: []
    human_judgment: true
    rationale: "Requires building librocket.dll (MinGW/TDM-GCC) and an interactive display; build/librocket.dll is absent on this machine (STATE.md blocker). User must run `make gui` and confirm visually. WINDOWS.md entries 1-2 already track this unrun verify."
  - id: D6
    description: "Phase gate `python SRC/test_call.py` (bridge unchanged — gui.py:80-110 zero-diff per diff guard c2a2751..HEAD)"
    verification: []
    human_judgment: true
    rationale: "test_call.py requires build/librocket.dll which is missing on this machine (documented in STATE.md / WINDOWS.md entry 1). Bridge code has zero diff per the diff guard, so behavior is unchanged by construction."

# Metrics
duration: 14min
completed: 2026-08-14
status: complete
---

# Phase 1 Plan 2: Mission Inputs + Vehicle Configuration Summary

**Mission-input rework in the Setup tab (dv_spin removed per D-10 — orbit height 100-2000 km now drives an interim read-only auto-ΔV computed as the V_circ mirror of Orbit_calc.f90:9-10, feeding the solver call and the export header/filename) plus a fully built Vehicle Configuration tab (3 diameter-mode radios mapped to Fortran 1/2/3 with the user-specified box under a strict visibility contract, state stored for Phase 2 handoff).**

## Performance

- **Duration:** 14 min
- **Started:** 2026-08-14T19:46Z (approx)
- **Completed:** 2026-08-14T20:00Z
- **Tasks:** 2 completed
- **Files modified:** 1 (SRC/gui/gui.py)
- **Commits:** 2 (plus this metadata commit)

## Accomplishments

- Setup tab mission grid reworked: `dv_spin` construction, grid row, and valueChanged connection removed; `orbit_height` QDoubleSpinBox added at row 0 (100.0-2000.0, decimals 1, step 10.0, default 500.0); `pl_spin`/`n_stages_spin` kept verbatim; read-only `auto_dv_label` added at row 3 ("ΔV (auto)", `{:.2f} km/s`, TEXT_SEC 12px).
- New `_auto_delta_v()` helper — interim V_circ mirror of `Orbit_calc.f90:9-10` (g_0=9.80665, Radius=6378.0 from `Typical_Data.f90:3-5`), docstring-marked for Phase 2 PIPE-01 removal — and `_update_auto_dv_label()` refreshing the label.
- D-10 trap closed in a single commit: all three `dv_spin` value reads swapped to `self._auto_delta_v()` — `_run` delta_v argument, `_print_results` local `dv` (covers the filename pattern `staging_{n}stage_dv{dv:.1f}_pl{pl}kg.txt`) and the Delta-V export header line.
- Orbit-height fan-out per UI-SPEC:174-175: `valueChanged` → `_on_inputs_changed` (clears Results + disables Save) AND `_update_auto_dv_label`.
- Vehicle Configuration tab filled: header ("VEHICLE CONFIGURATION" 20px/800 + "Diameter sizing mode" subtitle + divider), DIAMETER MODE QGroupBox with 3 mutually-exclusive radios (QButtonGroup ids 1/2/3; "Statistically determined" default checked mirroring `Diameter_setup = 1`) each with its 11px TEXT_SEC helper line, and the user-specified diameter QDoubleSpinBox (0.5-20.0, decimals 2, step 0.1, default 2.00) hidden by default.
- Visibility contract: `mode_user.toggled → diameter_spin.setVisible`; mode int stored via `QButtonGroup.buttonToggled` (checked-guard) into `self.diameter_mode`; value persists across toggles and tab switches (widgets never rebuilt). State NOT wired into `run_staging` (Pitfall 8).

## Task Commits

1. **Task 1: Mission inputs rework — orbit height + auto ΔV (D-09, D-10, GUI-05)** - `040901c` (feat)
2. **Task 2: Build Vehicle Configuration tab (D-11, D-12, GUI-06, GUI-07)** - `818e49c` (feat)

**Plan metadata:** (see docs commit below)

## Files Created/Modified

- `SRC/gui/gui.py` - Imports (+QButtonGroup); `_build_setup_tab` mission grid rework (orbit_height row 0, auto_dv_label row 3, dv_spin gone); new `_auto_delta_v()`/`_update_auto_dv_label()` methods; `_print_results` + `_run` ΔV source swapped to the auto value; `_build_vehicle_tab` full implementation (header, DIAMETER MODE radios + helpers, diameter_spin, visibility + mode-state wiring); `_vehicle_helper()`/`_on_mode_toggled()` helpers.

## Decisions Made

- `QButtonGroup.buttonToggled` (not `buttonClicked`) drives `self.diameter_mode`: it fires on programmatic `setChecked` as well as user clicks, so the stored int stays correct even if Phase 2 code changes the radio state programmatically — matches the plan's "updated on radio toggled" wording.
- Label/helper copy taken verbatim from UI-SPEC:121/166-169 (incl. the two-space column alignment of existing mission labels where the spec string omits it — orbit label uses the exact UI-SPEC string "Orbit Height (km)").
- No changes to `_print_results` beyond the two ΔV-source swaps — export format otherwise byte-identical (reversibility gate: only the Delta-V line reads the computed value).

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Mode int not updated on programmatic radio changes**
- **Found during:** Task 2 (Vehicle Configuration tab) — offscreen smoke
- **Issue:** Initial wiring used `QButtonGroup.buttonClicked`, which only fires on real user clicks; the offscreen smoke's programmatic `setChecked(True)` left `self.diameter_mode` stale (visible in smoke checks "diameter_mode -> 3" failing while the radio itself was checked). The plan explicitly requires the int "updated on radio toggled".
- **Fix:** Switched to `QButtonGroup.buttonToggled` with a `checked`-guarded slot (`if checked: self.diameter_mode = self.mode_buttons.id(btn)`), which fires for both user clicks and programmatic changes.
- **Files modified:** SRC/gui/gui.py
- **Verification:** py_compile; offscreen smoke 26/26 PASS (incl. diameter_mode 3/2/1 transitions and persistence).
- **Committed in:** 818e49c (Task 2 commit)

---

**Total deviations:** 1 auto-fixed (1 bug)
**Impact on plan:** The fix aligns the implementation with the plan's stated toggled-signal contract and makes the Phase 2 handoff state robust; no scope creep.

## Issues Encountered

- Smoke harness issues (not code bugs): `isVisible()` checks required `w.show()` + switching to tab index 2 (QTabWidget hides non-current pages); `findChildren` on a QLayout does not descend into widget children (must query `mode_group.findChildren`). Resolved in the harness; the GUI code itself was correct.
- `python SRC/test_call.py` (phase gate) cannot run on this machine: `build/librocket.dll` absent (STATE.md blocker); bridge code zero-diff per the diff guard `c2a2751..HEAD` (no hunks in original ranges 22-59 or 80-110), so behavior is unchanged by construction.
- `make gui` GUI smoke cannot run here (no DLL build toolchain / interactive display); the T1/T2 human-check items are recorded for the user (coverage D5).

## User Setup Required

None - no external service configuration required. (For GUI smoke: build the DLL via `make gui` in `SRC/` on a machine with MinGW/TDM-GCC, then run the human checks from each task's verify block.)

## Next Phase Readiness

- Ready for plan 01-03 (ResultCard +2 rows, partial-state hint, auto-switch to Results after Run) — Results render path and print_btn untouched by this plan.
- Phase 2 (PIPE-01) replaces `_auto_delta_v()` with the pipeline ΔV and consumes `self.diameter_mode` + `diameter_spin.value()` for geometry — handoff state is stored on MainWindow as designed.
- **User action required:** run `make gui` and confirm the 01-02 human-check items: Setup shows Orbit Height (500.0) / Payload / Stages / read-only ΔV (auto); orbit change updates the label, clears Results, disables Save; Run + Save work; exported .txt Delta-V line equals the label and the filename follows `staging_{n}stage_dv{dv:.1f}_pl{pl}kg.txt`; Vehicle tab modes reveal/hide the diameter box with persistence.

## Known Stubs

None - `_auto_delta_v()` and the read-only ΔV label are the plan's designed interim behavior (documented for Phase 2 PIPE-01 removal), not placeholders; the vehicle tab is fully wired for its phase scope.

## Self-Check: PASSED

- SRC/gui/gui.py exists and py_compiles: `python -m py_compile SRC/gui/gui.py` → PY_COMPILE_OK (verified at each task commit and on the final state).
- `dv_spin` fully removed: Select-String on SRC/gui/gui.py → zero matches (truth #2).
- Offscreen runtime smokes: smoke_0102_t1.py 17/17 PASS (orbit widget contract, V_circ math 7.62 km/s @500 km, label update, invalidation, run_staging delta_v capture, export Delta-V line + filename pattern); smoke_0102_t2.py 26/26 PASS (radio labels/ids/default, helper copy, visibility contract, persistence across toggles + tab switches, run_staging untouched).
- Commits exist: `040901c`, `818e49c` (both in `git log`).
- Diff guard `git diff c2a2751..HEAD -- SRC/gui/gui.py`: hunks only at imports (14), mission grid/vehicle tab (781-923), new helpers (983-1012), and the three ΔV read sites (1000/1016/1067); zero hunks in DLL-load (22-59), bridge (80-110), or Splash/AppWindow regions — GUI-08 preserved.
- Phase gate `python SRC/test_call.py` and `make gui` human-check unrun (no DLL on this machine) — recorded in coverage D5/D6 and WINDOWS.md entries 1-2.

---
*Phase: 01-centralized-3-tab-gui*
*Completed: 2026-08-14*