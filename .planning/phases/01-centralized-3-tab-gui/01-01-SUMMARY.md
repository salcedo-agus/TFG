---
phase: 01-centralized-3-tab-gui
plan: 1
subsystem: ui
tags: [pyqt6, qtabwidget, qss, gui-restructure, shell, relocation]

# Dependency graph
requires:
  - phase: 0-foundation
    provides: existing PyQt6 MainWindow split layout (gui.py), STYLE palette, SplashScreen/AppWindow
provides:
  - 3-tab QTabWidget workbench (Results/Setup/Vehicle Configuration) as MainWindow central widget
  - Setup tab verbatim relocation of the input panel (D-08) incl. mission group + stage widgets + Run
  - Results tab verbatim relocation of the render surface (D-07) incl. empty state, summary, minimum indicator, cards, Save Results
  - tab-bar + radio QSS appended to STYLE using only the 12 named palette constants
affects: [01-02-mission-input-rework, 01-03-results-surface-extension, verify-work]

actuals:
  tokens: 5836
  tasks: 3
  commits: 3

tech-stack:
  added: [PyQt6 QTabWidget, QRadioButton (new widget type used in later plans)]
  patterns:
    - QScrollArea + setWidgetResizable(True) + stretch bookends per tab page
    - verbatim relocation (D-08): move construction code, never instances
    - tab shell is addTab contract (index 0 Results active, 1 Setup, 2 Vehicle Configuration)

key-files:
  created: []
  modified:
    - SRC/gui/gui.py

key-decisions:
  - "Tab order is contractual and fixed: Results(0) active on open / Setup(1) / Vehicle Configuration(2); tabs left non-movable/closable/renamable (QTabWidget defaults)."
  - "Tab-bar/radio QSS is append-only into STYLE using the 12 named palette constants (BG_DARK/BG_PANEL/BG_CARD/BORDER/TEXT_SEC/TEXT_PRI/ACCENT); no new palette tokens."
  - "dv_spin relocates verbatim into Setup this plan (removal is deferred to 01-02-T1); _print_results keeps reading self.dv_spin."
  - "print_btn (Save Results) relocated into the Results tab and preserved by reference across _clear_results; _show_empty_state re-pins it above a trailing stretch so it stays visible-but-disabled before a run."
  - "Solver stays a blocking UI-thread call; QThread remains a dead import (A6)."

patterns-established:
  - "Tab shell: QTabWidget setCentralWidget + _build_{results,setup,vehicle}_tab builders, each a QScrollArea (margins 24/24/24/24 Results, 16/20/16/20 Setup) with stretch bookends."
  - "Cross-tab invalidation (Pitfall 3): signals are layout-agnostic; _on_inputs_changed clears results_layout and disables Save from the Setup tab."
  - "Ready-property run_btn state via setProperty('ready') + unpolish/polish, relocated verbatim."

requirements-completed: [GUI-01, GUI-04, GUI-08]

coverage:
  - id: D1
    description: "3-tab QTabWidget shell in contractual order (Results index 0 active on open, Setup, Vehicle Configuration); tabs not movable/closable/renamable; setMinimumSize(960,700) preserved on MainWindow and AppWindow"
    requirement: GUI-01
    verification:
      - kind: integration
        ref: "offscreen smoke test smoke_tabs.py (3 tabs, order, currentIndex 0, isMovable/closable False, min sizes)"
        status: pass
    human_judgment: false
  - id: D2
    description: "Tab-bar + radio QSS appended to STYLE using only the 12 named palette constants; existing STYLE rules untouched (append-only); selected tab ACCENT #58a6ff"
    requirement: GUI-01
    verification:
      - kind: integration
        ref: "git diff acacf1b..HEAD: single append hunk at STYLE tail, palette interpolation only"
        status: pass
    human_judgment: false
  - id: D3
    description: "Setup tab is a verbatim relocation of the input panel (header, mission group with dv_spin/pl_spin/n_stages_spin, stage widgets, Run button) — no widget redesign; stage rebuild 1-3 without layout break; combos >=220px"
    requirement: GUI-04
    verification:
      - kind: integration
        ref: "offscreen smoke test (mission group present, dv_spin alive, run_btn in setup_layout, 3->1->3 rebuild)"
        status: pass
    human_judgment: false
  - id: D4
    description: "Results tab empty state 'Run the analysis to see results here.' at layout index 0; after Run: summary -> minimum indicator -> divider -> n ResultCards -> Save -> stretch; Save disabled until first successful run; _last_configs/_last_results captured"
    requirement: GUI-04
    verification:
      - kind: integration
        ref: "offscreen smoke test (render order + ResultCard count 3 + Save enabled after run + capture + post-invalidation empty state)"
        status: pass
    human_judgment: false
  - id: D5
    description: "Splash preserved (GUI-08): AppWindow QStackedWidget + 600ms InOutQuad fade untouched; splash still shows first on launch"
    requirement: GUI-08
    verification:
      - kind: integration
        ref: "git diff acacf1b..HEAD: zero hunks in original ranges 582-700 and 990-1019; offscreen smoke: AppWindow._stack.currentIndex()==0"
        status: pass
    human_judgment: false
  - id: D6
    description: "'Missing Data' and 'Fortran Error' error modals preserved"
    requirement: GUI-04
    verification:
      - kind: other
        ref: "git diff acacf1b..HEAD: no hunks in _run validation/modal block (original 909-943)"
        status: pass
    human_judgment: false
  - id: D7
    description: "Full GUI smoke (`make gui` in SRC/: DLL build + launch; tab visuals, slider/selector interaction, dropdown readability at 960px, tab-bar fit, styled selected-tab ACCENT) — requires build/librocket.dll which is missing on this machine"
    verification: []
    human_judgment: true
    rationale: "Requires building librocket.dll (MinGW/TDM-GCC) and an interactive display; cannot be automated in this environment. Per RESEARCH:304-310 the DLL is absent here. User must run `make gui` and confirm visually. Backstop item (combo readability/tab fit at 960px) is human_needed."

# Metrics
duration: 17min
completed: 2026-08-14
status: complete
---

# Phase 1 Plan 1: Centralized 3-Tab GUI — Shell + Verbatim Relocation Summary

**Single-file restructure of `SRC/gui/gui.py` into a QTabWidget workbench: Results (index 0, active on open) / Setup / Vehicle Configuration, with the old input panel moved verbatim into Setup (D-08), the old render surface moved verbatim into Results (D-07), and tab-bar/radio QSS appended to STYLE.**

## Performance

- **Duration:** 17 min
- **Started:** 2026-08-14T16:30Z (approx, -0300 local)
- **Completed:** 2026-08-14T16:47Z (approx, -0300 local)
- **Tasks:** 3 completed
- **Files modified:** 1 (SRC/gui/gui.py)
- **Commits:** 3 (plus this metadata commit)

## Accomplishments

- Replaced the `root_layout` QHBox split with a `QTabWidget` central widget; contractual `addTab` order Results(0)/Setup(1)/Vehicle Configuration(2); tabs left non-movable/closable/renamable.
- Appended the tab-bar + radio QSS block to `STYLE` (append-only, f-string interpolation of the 12 named palette constants only — existing rules byte-identical).
- Relocated the left input panel verbatim into `_build_setup_tab`: header, mission group (`dv_spin` kept for this plan per 01-02 deferral), stages container, Run button with ready-property styling; all signal wiring preserved across the tab boundary.
- Relocated the right results panel verbatim into `_build_results_tab`: empty state, summary rich-text header, minimum indicator, divider, ResultCards, and Save Results pinned above the trailing stretch; export path unchanged.
- `print_btn` survives `_clear_results` by reference (was outside the cleared layout pre-relocation) and is re-pinned by `_show_empty_state`, so the disabled Save stays visible before a run.
- Old split scaffolding fully removed — no ghost panels; Splash/AppWindow/600 ms fade untouched (GUI-08).

## Task Commits

1. **Task 1 (tracer): Add QTabWidget shell and tab-bar/radio QSS** - `d9c3c1c` (feat)
2. **Task 2: Relocate input panel into Setup tab verbatim (D-08)** - `961721a` (refactor)
3. **Task 3: Relocate results panel into Results tab verbatim (D-07, GUI-04)** - `91d7c8d` (refactor)

**Plan metadata:** (see docs commit below)

## Files Created/Modified

- `SRC/gui/gui.py` - Imports (+QTabWidget, +QRadioButton); STYLE tab-bar/radio QSS append; `_build_ui` now builds the 3-tab shell; new `_build_results_tab`/`_build_setup_tab`/`_build_vehicle_tab` builders; `_show_empty_state`/`_clear_results` retargeted to `results_layout`; `_run` render block retargeted with Save pinned above the final stretch; print_btn relocated into the Results tab.

## Decisions Made

- Kept the split-panel construction as an intentionally orphaned intermediate state in Task 1 (per plan), pinned alive via `self._left_scroll`/`self._right_scroll` so no child-widget GC cascade could delete `self.dv_spin`/`self.run_btn` between commits — the T1 commit remains genuinely runnable.
- Relocated `print_btn` by reference and guarded it in `_clear_results` + re-pin in `_show_empty_state` so the disabled Save button remains visible before a run (preserves original left-panel behavior).
- Moved the mission-group signal wiring (`dv/pl/n_stages_spin.valueChanged -> _on_inputs_changed`) into the Setup builder with the panel it wires, keeping `_build_ui` minimal.
- Combos already had `setMinimumWidth(220)` on both `NoScrollComboBox`es (gui.py:336/345 pre-existing) — the long-text backstop was pre-satisfied; no change needed.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 2 - Missing Critical] Kept orphaned panels alive between T1/T2/T3 commits**
- **Found during:** Task 1 (tracer shell commit)
- **Issue:** The plan's T1 "orphaned widgets" state — left/right `QScrollArea` locals constructed but never added to any parent — would be garbage-collected on `_build_ui` return, cascade-deleting `self.dv_spin`, `self.run_btn`, `self.stages_layout`, and `self.stage_widgets` (CPython refcount → sip delete). The T1 commit would crash on first interaction instead of being a launchable intermediate.
- **Fix:** Kept the two scroll areas alive with `self._left_scroll = left_scroll` / `self._right_scroll = right_scroll` attributes (removed in T2/T3 when the panels were relocated). No behavior change in the final state.
- **Files modified:** SRC/gui/gui.py
- **Verification:** Offscreen instantiation of the T1 intermediate state is stable; py_compile passes.
- **Committed in:** d9c3c1c (Task 1 commit)

**2. [Rule 1 - Bug] print_btn would be destroyed by `_clear_results` after relocation**
- **Found during:** Task 3 (Results relocation)
- **Issue:** Blindly retargeting `_clear_results` from `right_layout` to `results_layout` makes its `takeAt(0) → deleteLater()` loop delete `print_btn`, which previously lived in the *left* panel outside the cleared layout. Any input change after a run would then dereference a destroyed `self.print_btn` (RuntimeError) and the Save button would vanish from the empty state.
- **Fix:** `_clear_results` now skips `print_btn` (`if item.widget() and item.widget() is not self.print_btn: item.widget().deleteLater()`); `_show_empty_state` re-pins Save above a trailing stretch when it is not already in the Results layout.
- **Files modified:** SRC/gui/gui.py
- **Verification:** Offscreen smoke: after `_on_inputs_changed`, print_btn is alive, disabled, and re-pinned in the results layout; a second `_run` renders again and re-enables Save.
- **Committed in:** 91d7c8d (Task 3 commit)

---

**Total deviations:** 2 auto-fixed (1 missing-critical, 1 bug)
**Impact on plan:** Both fixes are necessary for the intermediate commits to stay runnable and for cross-tab invalidation to work at runtime (the plan's literal verbatim-retarget of `_clear_results` would crash). No scope creep; final layout unchanged from the plan's intent.

## Issues Encountered

- `python SRC/test_call.py` (phase gate) cannot run on this machine: `build/librocket.dll` is absent (documented blocker in STATE.md / RESEARCH:304-310) and `rocket_lib` is not importable standalone. The bridge code itself (gui.py:80-110) has zero diff per the guard, so behavior is unchanged by construction.
- `make gui` GUI smoke cannot run here (no DLL build toolchain / interactive display in this session); recorded as a human_judgment coverage item D7 and flagged for the user.
- T1/T2/T3 automated verify is `python -m py_compile` (all PASS); I additionally ran an offscreen runtime smoke (38/38 PASS) since the DLL is unavailable.

## User Setup Required

None - no external service configuration required. (For GUI smoke: build the DLL via `make gui` in `SRC/` on a machine with MinGW/TDM-GCC, per existing project workflow.)

## Next Phase Readiness

- Ready for plan 01-02 (mission-input rework: `dv_spin` removal + orbit-height spinbox + ΔV auto label) — `dv_spin` is still present and functional in the Setup tab as required for this plan's contract.
- Ready for plan 01-03 (results-surface extension: ResultCard +2 rows, auto-switch to tab 0, partial-state hint) — Results render path is intact in `results_layout`.
- The Vehicle Configuration tab exists as an empty container (index 2) awaiting its radio-group UI in a later plan.
- **User action required:** run `make gui` (or `make all` + `python SRC/gui/gui.py`) to visually confirm the 3-tab workbench, styled tab bar (selected = ACCENT), setup/result parity, and the combo/tab-bar fit at 960px (backstop D7).

## Known Stubs

None - the Vehicle Configuration tab is intentionally an empty container this plan (its content is a later plan's deliverable, not a placeholder for this plan's goal).

## Self-Check: PASSED

- SRC/gui/gui.py exists and py_compiles: `python -m py_compile SRC/gui/gui.py` → PY_COMPILE_OK (verified at each task commit).
- Offscreen runtime smoke `smoke_tabs.py`: 38/38 PASS (tab shell, setup parity, stage rebuild, empty state, render order, Save enable/disable, invalidation, print_btn survival, splash-first).
- Commits exist: `d9c3c1c`, `961721a`, `91d7c8d` (all present in `git log`).
- Diff guard: `git diff acacf1b..HEAD -- SRC/gui/gui.py` shows zero hunks in original ranges 22-59, 80-110, 114-130, 582-700, 990-1019, 1023-1028.
- `_print_results` (export format) and `_run` validation/modal blocks untouched — export is byte-identical to pre-refactor by construction.

---
*Phase: 01-centralized-3-tab-gui*
*Completed: 2026-08-14*