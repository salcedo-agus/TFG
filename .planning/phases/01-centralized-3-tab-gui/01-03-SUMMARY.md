---
phase: 01-centralized-3-tab-gui
plan: 3
subsystem: ui
tags: [pyqt6, resultcard, placeholders, export-contract, auto-switch, partial-state]

# Dependency graph
requires:
  - phase: 01-centralized-3-tab-gui
    provides: 3-tab shell + Results render path relocated (01-01), _auto_delta_v + dv_spin removal (01-02)
provides:
  - ResultCard extended to 10 metric slots: rows 4-5 Stage ΔV/Diameter + Length/Volume with fmt-aware add_metric (legacy :,.1f default; %.2f new rows; "—" TEXT_DIM placeholders via .get() defaults)
  - Partial-state hint "ΔV and geometry populate with full pipeline wiring (Phase 2)." (11px TEXT_DIM, once per render, absent pre-run)
  - Auto-switch to Results tab after successful Run (setCurrentIndex(0)); invalidation never navigates
  - Export + minimum-confirmed contracts verified unchanged (auto ΔV line, filename pattern, dialog-per-save idempotency, GREEN/ACCENT2 indicator, blocking single-thread)
affects: [02-full-pipeline-exposure (PIPE-02 packs dv/diameter/length/volume into the bridge dict — cards fill in without signature churn), verify-work]

actuals:
  tokens: 885   # chars/4 over realized diff (3542 chars across the 2 task commits, SRC/gui/gui.py)
  tasks: 2
  commits: 2

tech-stack:
  added: []
  patterns:
    - fmt-aware add_metric: legacy format-spec (",.1f") via nested f-string with lstrip(':') and %-specs ("%.2f") via %-formatting — two-branch because nested f-string specs reject both colon-prefixed and %-style specs
    - placeholder idiom: data.get(key) → None → "—" TEXT_DIM inside the widget; the render path only counts (not formats) missing values for the hint
    - partial-state hint: appended after the cards in the same success path that enables Save; cleared by the standard _clear_results drain

key-files:
  created: []
  modified:
    - SRC/gui/gui.py

key-decisions:
  - "fmt-aware add_metric implemented with two formatting branches (%-style specs and format-specs) — the PATTERNS §5 literal snippet f\"{value:{fmt}}\" raises ValueError for both ':,.1f' (colon in spec) and '%.2f' (% not in format mini-language); output is byte-identical to the plan's stated contract."
  - "Rows 0-3 keep the legacy :,.1f rendering (k_m shows '2.3', ν_e '3.5 km/s' — byte-identical to pre-phase per plan truth #2); the UI-SPEC %.4f ratio contract governs the export file (unchanged since pre-phase) and the new rows' %.2f contract, not the legacy card rows."
  - "Partial-state hint condition mirrors the card lookup exactly: any of dv/diameter/length/volume resolving to None across stages → one hint; Phase 2 dicts with all four keys suppress it (verified offscreen with a full-pipeline fake bridge dict)."
  - "Auto-switch placed after print_btn.setEnabled(True) in the success path only; _on_inputs_changed remains navigation-free (verified: tab stays on Setup after orbit-height invalidation)."

patterns-established:
  - "ResultCard row contract: rows 0-3 add_metric(data[key]) with default fmt; rows 4-5 add_metric(data.get(key)) with explicit fmt — Phase 2 packs dict keys without any caller/signature change."
  - "Hint lifecycle: created in the render block, destroyed by _clear_results — 'once per render' is structural, not counted."

requirements-completed: [GUI-02, GUI-03, GUI-04]

coverage:
  - id: D1
    description: "ResultCard 10 metric slots per stage — rows 0-3 byte-identical legacy formats (masses :,.1f, ratios/ν_e legacy), rows 4-5 Stage ΔV (%.2f km/s) / Diameter (%.2f m) / Length (%.2f m) / Volume (%.2f m³) per the locked formatting contract; Phase-2 dicts with dv/diameter/length/volume render TEXT_PRI formatted values"
    requirement: GUI-02
    verification:
      - kind: integration
        ref: "offscreen smoke smoke_0103_t1.py (22 checks: legacy rows byte-identical, placeholders glyph+color, %.2f contract, full _run render no KeyError)"
        status: pass
    human_judgment: false
  - id: D2
    description: "Partial state: missing dv/diameter/length/volume render '—' TEXT_DIM via data.get() defaults (never fabricated numbers, PIPE-02); the 11px TEXT_DIM hint 'ΔV and geometry populate with full pipeline wiring (Phase 2).' appears exactly once below the cards per render, absent in the pre-run empty state, cleared on invalidation, suppressed when Phase 2 data is present"
    requirement: GUI-03
    verification:
      - kind: integration
        ref: "offscreen smoke smoke_0103_t2.py (hint once/2nd-run once/cleared on invalidation/full-data no hint/pre-run absent)"
        status: pass
    human_judgment: false
  - id: D3
    description: "Auto-switch: successful Run lands on Results (self.tabs.setCurrentIndex(0) after Save-enable, UI-SPEC:193); input invalidation clears Results + disables Save without navigating"
    requirement: GUI-04
    verification:
      - kind: integration
        ref: "offscreen smoke smoke_0103_t2.py (currentIndex 0 after run; stays on Setup after invalidation)"
        status: pass
    human_judgment: false
  - id: D4
    description: "Export + indicator contracts verified unchanged (no code change): 'ROCKET STAGING RESULTS' header block, Delta-V line from _auto_delta_v (never hand-entered), filename staging_{n}stage_dv{dv:.1f}_pl{pl}kg.txt, dialog re-opens per Save (2 calls, no append, no silent double-write, idempotent identical content); minimum indicator verbatim GREEN '✔  Minimum confirmed' / ACCENT2 '✘  Minimum not confirmed — check your inputs' from minimum_found; solver stays a blocking UI-thread call (no QThread worker in _run)"
    requirement: GUI-04
    verification:
      - kind: integration
        ref: "offscreen smoke smoke_0103_t2.py (dialog calls==2, filename pattern, header block, auto Delta-V line, c1==c2 idempotency, GREEN/ACCENT2 checks, source scan for threading)"
        status: pass
    human_judgment: false
  - id: D5
    description: "Full GUI smoke (`make gui` in SRC/: DLL build + launch; each card shows 8 original metrics unchanged + 2 new rows all rendering '—' in dim text; hint once below cards; Run auto-switches; Save twice re-opens dialog; exported .txt identical in structure to a pre-phase file except the Delta-V line source; window resizes without layout break; min indicator ✔/✘)"
    verification: []
    human_judgment: true
    rationale: "Requires building librocket.dll (MinGW/TDM-GCC) and an interactive display; build/librocket.dll is absent on this machine (STATE.md blocker; WINDOWS.md entry 3). User must run `make gui` and confirm visually per each task's human-check list."
  - id: D6
    description: "Phase gate `python SRC/test_call.py` (bridge unchanged — gui.py:22-110 zero-diff per diff guard c3ef2f2..HEAD)"
    verification: []
    human_judgment: true
    rationale: "test_call.py requires build/librocket.dll which is missing on this machine (STATE.md blocker; WINDOWS.md entry 1). Bridge code has zero diff per the diff guard, so behavior is unchanged by construction."

# Metrics
duration: 9min
completed: 2026-08-14
status: complete
---

# Phase 1 Plan 3: Results Surface + Export/Indicator Contracts Summary

**ResultCard extended to 10 metric slots (per-stage ΔV + diameter/length/volume rendered as intentional TEXT_DIM "—" placeholders with a one-shot partial-state hint until Phase 2 packs them), auto-switch to Results after a successful Run, and the export/minimum-indicator contracts verified byte-identical (auto ΔV line, filename pattern, dialog-per-save idempotency, blocking single-thread guarantee).**

## Performance

- **Duration:** 9 min
- **Started:** 2026-08-14T20:04:00Z
- **Completed:** 2026-08-14T20:12:56Z
- **Tasks:** 2 completed
- **Files modified:** 1 (SRC/gui/gui.py)
- **Commits:** 2 (plus this metadata commit)

## Accomplishments

- `add_metric` closure in `ResultCard` gained a `fmt` parameter defaulting to the legacy `:,.1f`: rows 0-3 render byte-identical to pre-phase (masses `%,.1f`, ratios/ν_e legacy 1-decimal); two new grid rows 4-5 render Stage ΔV (`%.2f km/s`), Diameter (`%.2f m`), Length (`%.2f m`), Volume (`%.2f m³`) per UI-SPEC:144-155.
- Missing values are handled before formatting: `data.get()` defaults (None) render the glyph "—" in TEXT_DIM — never a fabricated number (PIPE-02, T-03-03 mitigation); Phase 2 dict keys (`dv`, `diameter`, `length`, `volume`) fill the same rows with TEXT_PRI and zero signature churn.
- Partial-state hint: one 11px TEXT_DIM label "ΔV and geometry populate with full pipeline wiring (Phase 2)." appended after the cards whenever any placeholder is rendered — structurally once per render (cleared and rebuilt with the layout), absent from the pre-run empty state.
- Auto-switch: `self.tabs.setCurrentIndex(0)` in the `_run` success path right after Save-enable (UI-SPEC:193); `_on_inputs_changed` remains navigation-free — verified offscreen that invalidation from the Setup tab keeps the tab on Setup.
- Export + minimum-indicator contracts verified, not redesigned: `_print_results` header block, Delta-V line from `_auto_delta_v`, filename `staging_{n}stage_dv{dv:.1f}_pl{pl}kg.txt`, dialog re-opens per Save (no append, no silent double-write — two saves produce byte-identical files), GREEN/ACCENT2 indicator driven by `minimum_found`, solver blocking on the UI thread (no threading machinery, A6).

## Task Commits

1. **Task 1: Extend ResultCard with ΔV + geometry rows (D-05, D-06, GUI-02, GUI-03)** - `b3f9736` (feat)
2. **Task 2: Partial-state hint, auto-switch, export/indicator contracts (D-07, GUI-02/03/04)** - `020962e` (feat)

**Plan metadata:** (see docs commit below)

## Files Created/Modified

- `SRC/gui/gui.py` - `ResultCard.add_metric` gains `fmt` (default `:,.1f`) with a None-guard rendering "—" TEXT_DIM and a two-branch formatter (%-specs via `fmt % value`, format-specs via nested `{value:{fmt.lstrip(':')}}`); rows 4-5 call sites added; `_run` success path appends the partial-state hint after the cards and calls `self.tabs.setCurrentIndex(0)` after `print_btn.setEnabled(True)`. Export/min-indicator logic untouched (0 lines changed).

## Decisions Made

- Implemented `fmt` with two formatting branches: `f"{value:{fmt}}"` (the PATTERNS §5 literal snippet) raises `ValueError` for `:,.1f` (a nested spec must not carry the leading colon) and `TypeError`/`ValueError` for `%.2f` (`%` is not part of the format mini-language). `fmt % value` and `{value:{fmt.lstrip(':')}}` produce the exact strings the plan's contract specifies.
- Rows 0-3 keep the legacy `:,.1f` rendering (e.g. `k_m` shows "2.3", ν_e "3.5 km/s") — plan truth #2 mandates byte-identical rows 0-3; the UI-SPEC `%.4f` ratio contract applies to the export file (pre-existing, unchanged) and to the new rows' format contract, not to the legacy card rows.
- The hint's condition mirrors the placeholder lookup exactly (`any(s.get("dv") is None or ...)`), so a Phase 2 bridge dict that packs all four keys suppresses the hint automatically — verified offscreen with a full-pipeline fake dict.
- No changes to `_print_results`, the minimum-indicator block, or the solver call — T2's export/indicator/concurrency items are verify-only per the plan's reversibility gate.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] fmt-aware add_metric: nested f-string format spec rejected both mandated spec styles**
- **Found during:** Task 1 (ResultCard rows 4-5) — offscreen smoke (first run crashed with `ValueError: Invalid format specifier ':,.1f'`)
- **Issue:** The plan's PATTERNS §5 snippet `val = QLabel(f"{value:{fmt}} {unit}".strip())` with `fmt=":,.1f"` default and `%.2f` for the new rows is latently broken: a nested replacement field supplies the ENTIRE format spec, so the colon-prefixed legacy spec becomes an invalid spec (`format(value, ":,.1f")` → ValueError) and `%`-style specs are not part of the format mini-language at all (`f"{1.5:%.2f}"` → ValueError).
- **Fix:** Two-branch formatting in `add_metric`: `%`-style specs via `fmt % value`; format-specs via `f"{value:{fmt.lstrip(':')}}"` (strips the colon so `:,.1f` → `,.1f`, byte-identical to the legacy `f"{value:,.1f}"`). Output strings match the plan's contract exactly for both styles.
- **Files modified:** SRC/gui/gui.py
- **Verification:** py_compile; smoke_0103_t1.py 22/22 PASS (legacy rows byte-identical; `%.2f` rows render "7.62 km/s", "4.12 m", "12.35 m", "150.99 m³").
- **Committed in:** b3f9736 (Task 1 commit)

---

**Total deviations:** 1 auto-fixed (1 bug)
**Impact on plan:** The fix makes the plan's stated fmt contract actually executable; no scope creep, no behavior change vs the plan's intent.

## Issues Encountered

- Smoke harness issues (not code bugs): `findChildren` on a `QLayout` does not descend into widget children (cards/hints must be queried on the layout's parent content widget — same lesson as 01-02); `deleteLater()` widgets remain visible to `findChildren` until `QApplication.sendPostedEvents(None, QEvent.Type.DeferredDelete)` flushes them (plain `processEvents()` does not process DeferredDelete). Resolved in the harness; the GUI code itself was correct (second-run hint count and invalidation-clear checks pass once the flush is applied).
- `python SRC/test_call.py` (phase gate) cannot run on this machine: `build/librocket.dll` absent (STATE.md blocker; WINDOWS.md entry 1). Bridge code zero-diff per the diff guard `c3ef2f2..HEAD` (no hunks in original ranges 22-59 or 80-110), so behavior is unchanged by construction.
- `make gui` GUI smoke cannot run here (no DLL build toolchain / interactive display); the T1/T2 human-check items are recorded for the user (coverage D5; WINDOWS.md entry 3).

## User Setup Required

None - no external service configuration required. (For GUI smoke: build the DLL via `make gui` in `SRC/` on a machine with MinGW/TDM-GCC, then run the human checks from each task's verify block.)

## Next Phase Readiness

- Phase 1 (GUI-01..GUI-08) is fully implemented across plans 01-01/01-02/01-03. The Results tab is the complete required surface: 10 metric slots per stage (8 populated, ΔV + 3 geometry placeholders), exact formatting contract, partial-state hint, auto-switch after Run, idempotent Save export with the auto-ΔV line, verbatim minimum indicator, blocking single-thread guarantee.
- Phase 2 (full pipeline exposure, PIPE-01/PIPE-02) replaces `_auto_delta_v()` and packs `dv`/`diameter`/`length`/`volume` into the bridge return dict: `ResultCard` fills the placeholder rows and the hint disappears automatically — no signature or caller changes needed (verified offscreen with a full-pipeline fake dict).
- Phase 2 consumes `self.diameter_mode` + `self.diameter_spin.value()` (Vehicle Configuration state stored on MainWindow in 01-02) for geometry.
- **User action required:** run `make gui` and confirm the 01-03 human-check items: 8 original metrics unchanged + 2 new rows all "—" in dim text; hint appears once below the cards; Run auto-switches to Results; changing an input invalidates without navigating; Save twice opens the dialog each time with a .txt identical in structure to today's export; minimum indicator ✔/✘; window unresponsive mid-run (blocking, expected).

## Known Stubs

None - the "—" placeholders and the partial-state hint are the plan's designed Phase 1 state (user-approved partial population, RESEARCH Open Question 2 resolved), explicitly wired to disappear when Phase 2 packs the values; not stubs blocking this plan's goal.

## Self-Check: PASSED

- SRC/gui/gui.py exists and py_compiles: `python -m py_compile SRC/gui/gui.py` → PY_COMPILE_OK (verified at each task commit and on the final state).
- Offscreen runtime smokes: smoke_0103_t1.py 22/22 PASS (legacy rows byte-identical; "—" TEXT_DIM placeholders; %.2f Phase-2 contract with TEXT_PRI; full _run render 3 cards, no KeyError); smoke_0103_t2.py 21/21 PASS (auto-switch; hint once per render incl. 2nd run; no hint pre-run / post-invalidation / with full data; invalidation no-nav + Save disabled; Save twice → 2 dialog calls, filename pattern, header block, auto Delta-V line, c1==c2 idempotency; min indicator GREEN/ACCENT2; no QThread/threading in _run).
- Commits exist: `b3f9736`, `020962e` (both in `git log`).
- Diff guard `git diff c3ef2f2..HEAD -- SRC/gui/gui.py`: hunks only at ResultCard add_metric/rows (566-602) and the _run success path (1114-1145); zero hunks in DLL-load (22-59), bridge (80-110), or Splash/AppWindow regions — GUI-08 preserved; `_print_results` and the minimum-indicator block untouched (verify-only contract).
- Phase gate `python SRC/test_call.py` and `make gui` human-check unrun (no DLL on this machine) — recorded in coverage D5/D6 and WINDOWS.md entry 3.

---
*Phase: 01-centralized-3-tab-gui*
*Completed: 2026-08-14*