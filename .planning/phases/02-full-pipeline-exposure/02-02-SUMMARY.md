---
phase: 02-full-pipeline-exposure
plan: 2
subsystem: ui
tags: [pyqt6, ctypes, rocket_lib, full-pipeline, vcirc, gui, offscreen-harness]

# Dependency graph
requires:
  - phase: 02-full-pipeline-exposure
    provides: run_full_pipeline bind(C) entry + ctypes wrapper + rebuilt librocket.dll (plan 02-01)
provides:
  - "MainWindow._run drives the complete Fortran pipeline (orbit -> payload -> staging solver -> thrust -> geometry) through the single rocket_lib.run_full_pipeline entry"
  - "Fortran V_circ as the single source for the Setup 'ΔV (auto)' label, the export Delta-V line, and the suggested export filename (label == line == filename)"
  - "Input-integrity invalidation extended to the Vehicle Configuration tab: diameter-mode radio toggles and the user-specified diameter value clear results / disable Save / reset the V_circ source"
  - "A shared Run button reachable from every tab except Results (visible on Setup + Vehicle Configuration, hidden on Results)"
affects: [03-bridge-correctness-fixes (FIX-02 bridge dedup, FIX-03 MinGW path), verify-work UAT]

# Actuals (#2632) — chars/4 over the realized diff (gui.py, commits 70095ec..3e7eab2)
actuals:
  tokens: 2651
  tasks: 3
  commits: 4

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Single ctypes pipeline entry consumed at the GUI call site only (import rocket_lib); the inline _lib/run_staging twin stays byte-untouched for Phase 3 dedup"
    - "Fortran-origin scalar (v_circ) stored on MainWindow, rendered via _update_auto_dv_label with the '— km/s' placeholder for pre-run / post-invalidation state"
    - "Input invalidation funnel: every input signal (sliders, spinboxes, mode radios, user-diameter value) routes through _on_inputs_changed — one clearing path"
    - "Shared action button placed in a central container row, shown/hidden via the tab widget's currentChanged (no per-layout duplication)"

key-files:
  created: []
  modified:
    - SRC/gui/gui.py

key-decisions:
  - "T3 (gate=blocking human-verify) approved by the user on 2026-09-06 WITH two follow-up changes: (1) diameter configuration changes must clear results, (2) the Run button must be visible on every tab except Results — both implemented atomically and offscreen-verified (GATE A/B/C)"
  - "Diameter invalidation wired as two additional signal connections (buttonToggled + diameter_spin.valueChanged -> _on_inputs_changed) placed in the post-construction wiring block so the construction-time setChecked/setValue never retroactively invalidates"
  - "Run button relocated out of setup_layout into a shared row beneath the tabs in _build_ui (single widget, currentChanged show/hide), preserving objectName / ready property / stylesheet / clicked->_run contract; Save Results stays Results-tab-only"
  - "Estimate calibration signal: plan estimated 28000 tokens; actuals 2651 (chars/4 over the realized gui.py diff) — the 02-02 surface was much smaller than feared (single file, no new artifacts)"

patterns-established:
  - "Pattern: an input group's state is invalidated by connecting the group's change signals to _on_inputs_changed AFTER all widgets are constructed — construction-time defaults can never fire invalidation"
  - "Pattern: tab-dependent widget visibility via tabs.currentChanged -> handler, with an explicit initial sync call (Results active on open)"

requirements-completed: [PIPE-01]

# Coverage metadata (#1602)
coverage:
  - id: D1
    description: "MainWindow._run calls rocket_lib.run_full_pipeline (orbit/payload/ISP/k_s/propellant indices/diameter mode/value); per-stage dv/diameter/length/volume render as real %.2f values on every ResultCard; the partial-state hint is absent after a run; _last_v_circ stores the Fortran V_circ (> 7.0 km/s for 500 km)"
    requirement: PIPE-01
    verification:
      - kind: e2e
        ref: "temp throwaway harness phase02_t3_harness.py (T1/T2(b) gate: 3 cards, v_circ=7.6158, hint absent, all keys finite/>0) — exit 0"
        status: pass
    human_judgment: false
  - id: D2
    description: "V_circ label/export chain: pre-run label '— km/s'; post-run label == f'{_last_v_circ:.2f} km/s' == results['v_circ']; input changes reset _last_v_circ, refresh the label to '— km/s', disable Save; _print_results guard warns (no file dialog) when _last_v_circ is None; _auto_delta_v deleted (zero matches)"
    requirement: PIPE-01
    verification:
      - kind: e2e
        ref: "temp throwaway harness phase02_t3_harness.py (T2 gates + static greps: 1 import rocket_lib, 0 _auto_delta_v, 5 _last_v_circ) — exit 0"
        status: pass
    human_judgment: false
  - id: D3
    description: "Diameter-configuration invalidation (user follow-up 1): toggling a diameter-mode radio (Constant) and changing the user-specified diameter (3.5 m in mode 3) both clear results, disable Save, reset _last_v_circ to None, and restore the '— km/s' label"
    requirement: PIPE-01
    verification:
      - kind: automated_ui
        ref: "temp throwaway harness phase02_t3_harness.py (GATE A: mode toggle; GATE B: mode-3 diameter value) — exit 0"
        status: pass
    human_judgment: false
  - id: D4
    description: "Run button visibility per tab (user follow-up 2): on a shown window, run_btn.isVisible() is False on Results (index 0), True on Setup (1) and Vehicle Configuration (2); a successful run still auto-switches to Results with the button hidden"
    requirement: PIPE-01
    verification:
      - kind: automated_ui
        ref: "temp throwaway harness phase02_t3_harness.py (GATE C tab-visibility asserts) — exit 0"
        status: pass
    human_judgment: false
  - id: D5
    description: "Interactive GUI walkthrough (plan T3, gate=blocking human-verify): full-pipeline results, V_circ label chain, export file consistency, and diameter-mode geometry — approved by the user, who requested and received the two follow-up changes (D3/D4)"
    requirement: PIPE-01
    verification:
      - kind: manual_procedural
        ref: "T3 interactive walkthrough (how-to-verify checklist, PLAN 02-02) — user approved 2026-09-06"
        status: pass
    human_judgment: true
    rationale: "T3 is a gate=blocking human-verify by plan design: mode 1/2/3 geometry sanity, label==export-line==filename consistency and general UI feel require human judgment. The user approved it interactively on 2026-09-06, conditioning approval on the two follow-up changes (D3/D4) which were then implemented and offscreen-verified."

# Metrics
duration: 25min
completed: 2026-09-06
status: complete
---

# Phase 2 Plan 2: Full-Pipeline Exposure Summary

**The GUI now runs the complete Fortran pipeline (orbit → payload → staging → thrust → geometry) through the single `rocket_lib.run_full_pipeline` entry: the Setup "ΔV (auto)" label, the export Delta-V line and the suggested filename all source from the Fortran V_circ, diameter-configuration changes invalidate results like every other input, and a shared Run button is reachable from every tab except Results — T3 interactively approved, both follow-ups implemented and offscreen-verified.**

## Performance

- **Duration:** 25 min (19:06–19:31 local; includes the T3 interactive approval pause between T2 and the follow-ups)
- **Started:** 2026-09-06T19:06:18-03:00
- **Completed:** 2026-09-06T19:30:21-03:00
- **Tasks:** 3 (T1, T2 auto; T3 checkpoint approved with follow-ups)
- **Files modified:** 1 (SRC/gui/gui.py)
- **Actuals:** 2651 tokens (chars/4 over the realized gui.py diff) vs plan estimate 28000 — calibration signal: the 02-02 surface (one file, no artifacts) cost far less than estimated.

## Accomplishments

- **Full-pipeline Run (PIPE-01, T1):** `_run` calls `rocket_lib.run_full_pipeline(n_stages, orbit_height, payload_mass, isp_list, ks_list, propellant_list, diameter_setup, user_diameter)` — the `delta_v=` argument and the interim single-solver call are gone; every ResultCard populates per-stage **ΔV / Diameter / Length / Volume** as real %.2f numbers, the partial-state hint self-disables, and `_last_v_circ = results["v_circ"]` stores the Fortran orbital speed.
- **V_circ label/export chain (D-01/D-04/D-05, T2):** `_auto_delta_v` is deleted (grep: zero matches); the label renders `'— km/s'` pre-run and after any input change, and `f"{_last_v_circ:.2f} km/s"` after a run; `_print_results` guards on a stored V_circ and uses it for the `Delta-V:` line and the `staging_{n}stage_dv{dv:.1f}_pl{pl}kg.txt` filename — label == line == filename, single source.
- **Diameter-configuration invalidation (user follow-up 1):** `mode_buttons.buttonToggled` and `diameter_spin.valueChanged` both route through `_on_inputs_changed` — changing the diameter mode radio or the user-specified diameter clears results, disables Save, resets `_last_v_circ` and restores the `'— km/s'` label; wiring sits in the post-construction block so `mode_stat.setChecked(True)` at build time never retroactively invalidates.
- **Run button on every tab except Results (user follow-up 2):** `run_btn` moved out of `setup_layout` into a shared row beneath the tabs in `_build_ui`; `tabs.currentChanged → _on_tab_changed` shows it on Setup and Vehicle Configuration, hides it on Results (index 0); objectName / `ready` property / stylesheet / `clicked → _run` all unchanged, `_update_run_button` untouched, and the post-run auto-switch still lands on Results (button hidden there). Save Results stays Results-tab-only.
- **Verification:** `python -m py_compile` clean; extended offscreen harness (static greps + T1/T2 regression + GATE A/B/C) exits 0; cross-plan gate `python SRC/test_call.py` exits 0 with all bridge assertions passing.

## Task Commits

Each task was committed atomically:

1. **Task 1: Switch _run to the full pipeline** — `70095ec` (feat(gui))
2. **Task 2: V_circ label/export chain, remove _auto_delta_v** — `6cd13b3` (feat(gui))
3. **Task 3 (follow-up 1): Invalidate results when diameter configuration changes** — `51a5695` (feat(gui))
4. **Task 3 (follow-up 2): Show run button on all tabs except results** — `3e7eab2` (feat(gui))

**Plan metadata:** `5431e8f` (docs(02-02): complete full-pipeline-exposure plan)

## Files Created/Modified

- `SRC/gui/gui.py` — `import rocket_lib` after the sys.path hook (T1); `StageInputWidget.get_propellant_index()` returning the 1-based Fortran propellant code (T1); `_run` switched to `rocket_lib.run_full_pipeline` + `_last_v_circ = results["v_circ"]` (T1); `_auto_delta_v` deleted, `'— km/s'` construction label, rewritten `_update_auto_dv_label`, `_on_inputs_changed` reset, `_print_results` V_circ guard + source (T2); diameter-mode/radio + diameter-spin invalidation wiring (follow-up 1); run button relocated to the central container + `_on_tab_changed` visibility handler (follow-up 2).

## Decisions Made

- **T3 approval with follow-ups:** the user approved the interactive walkthrough and requested two additional behaviors — diameter-config changes must clear results, and the Run button must appear on every tab except Results. Both were implemented as their own atomic commits (listed above) and verified offscreen (GATE A/B/C) before this summary.
- **Diameter invalidation placement:** two extra signal connections in the existing post-construction wiring block (`buttonToggled`, `valueChanged` → `_on_inputs_changed`). This funnel keeps `_on_mode_toggled`'s stored `diameter_mode` semantics (1/2/3) and the mode→geometry influence intact, and the connection point guarantees the construction-time `setChecked(True)` never fires invalidation.
- **Run button placement:** a shared central row under the tabs (single widget shown/hidden by `currentChanged`) rather than per-layout duplication — least-invasive structure change that keeps the `ready` styling contract, keeps Save Results on Results only, and lets the post-run auto-switch land on Results with the button correctly hidden.

## Deviations from Plan

### User-Requested Changes (T3 approval conditions — added after user's interactive approval)

**1. Diameter-configuration changes now invalidate results**
- **Requested by:** user during T3 approval (2026-09-06)
- **Change:** `mode_buttons.buttonToggled` and `diameter_spin.valueChanged` both connect to `_on_inputs_changed` (post-construction wiring block), so mode-radio toggles and the user-specified diameter value clear results / disable Save / reset `_last_v_circ` / refresh the label to `'— km/s'`.
- **Files modified:** SRC/gui/gui.py
- **Verification:** harness GATE A (mode toggle) + GATE B (mode-3 diameter value) — exit 0
- **Committed in:** `51a5695`

**2. Run button visible on every tab except Results**
- **Requested by:** user during T3 approval (2026-09-06)
- **Change:** `run_btn` moved from `setup_layout` to a shared row beneath the tabs (central widget in `_build_ui`); `tabs.currentChanged → _on_tab_changed` shows it for index != 0, hides it on index 0; objectName / `ready` property / stylesheet / `clicked` connection preserved; Save Results unchanged on the Results tab.
- **Files modified:** SRC/gui/gui.py
- **Verification:** harness GATE C (tab 0 hidden / tabs 1,2 visible on a shown window) + auto-switch assertion — exit 0
- **Committed in:** `3e7eab2`

---

**Total deviations:** 2 user-requested additions (both T3 approval conditions, implemented and verified atomically). No Rule 1-4 deviations — the plan executed as written; the follow-ups were the user's stated conditions for approving T3.

**Impact on plan:** Both changes are user-visible GUI behaviors requested at the interactive gate; neither touches the bridge contract, the inline bridge twin, or any Fortran/Python physics.

## Issues Encountered

- Harness-side assertion bug during iteration (not a product defect): the final "no dialogs on visibility run" check compared against a globally empty dialog list, but the deliberate T2(d) guard-test warning had legitimately populated it — fixed in the throwaway script by snapshotting counts before the last `_run()`. All green after the fix.
- Inherited Fortran console prints (`Delta_V = ...`, bisection iteration, `Minimum found`) continue to stream to the console during offscreen runs — acknowledged console-path parity from 02-01, unchanged.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- **PIPE-01 is closed:** the GUI now drives the complete pipeline through the single ctypes entry; label/export/filename are V_circ-sourced with clean invalidation; the two user-requested behaviors (diameter invalidation, run-button reachability) are in place and offscreen-proven.
- **Phase 3 (bridge & correctness fixes) is unblocked and has a cleaner target:** the inline `_lib`/`run_staging` twin (gui.py:19-110) remains byte-identical for FIX-02 dedup, and the hardcoded MinGW path remains for FIX-03 — both verified untouched by this plan.
- **Calibration note for future estimates:** the 02-02 estimate (28000 tokens) over-shot actuals (2651 tokens, chars/4) by ~10× on a single-file GUI-wiring plan; low-confidence estimates on already-mapped code should be scaled down.
- No stubs introduced: the `'— km/s'` label and "Run the analysis to see results here." placeholder are designed partial-state idioms, not un-wired stubs; no skipped tests; no unrun verifies.

---
*Phase: 02-full-pipeline-exposure*
*Completed: 2026-09-06*

## Self-Check: PASSED

- 02-02-SUMMARY.md exists ✓
- Commits present: `70095ec`, `6cd13b3`, `51a5695`, `3e7eab2`, `5431e8f` ✓ (verified via git log)
- py_compile clean ✓; extended offscreen harness exit 0 ✓; `python SRC/test_call.py` exit 0 (cross-plan gate) ✓
- Inline bridge gui.py:19-110 byte-identical to `24a0518` (modulo the single T1 import) ✓ — harness static gate
- Grep gates: 1 `import rocket_lib`, 0 `_auto_delta_v`, 5 `_last_v_circ` ✓
- `.planning/state.json` untracked, never staged ✓