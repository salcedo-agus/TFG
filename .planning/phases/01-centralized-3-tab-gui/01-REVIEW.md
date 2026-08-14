---
phase: 01-centralized-3-tab-gui
reviewed: 2026-08-14T21:30:00Z
depth: deep
files_reviewed: 1
files_reviewed_list:
  - SRC/gui/gui.py
findings:
  critical: 0
  warning: 3
  info: 8
  total: 11
status: issues_found
---

# Phase 1: Code Review Report — Centralized 3-Tab GUI

**Reviewed:** 2026-08-14T21:30:00Z
**Depth:** deep (full-file read + cross-module trace of Fortran mirror, bridge contract, and widget lifecycle)
**Files Reviewed:** 1 (`SRC/gui/gui.py`, phase diff `acacf1b..HEAD`, commits d9c3c1c/961721a/91d7c8d/040901c/818e49c/b3f9736/020962e)
**Status:** issues_found

## Summary

Reviewed the final state of `SRC/gui/gui.py` (1190 lines) against the three phase plans, the UI-SPEC contract, and the Fortran sources it mirrors. The 3-tab shell (Results/Setup/Vehicle Configuration, contractual order, non-movable defaults), the verbatim D-08 relocation, the D-10 auto-ΔV interim (`_auto_delta_v()` is a faithful mirror of `Orbit_calc.f90:9-10` — verified against the Fortran, correct units and values: 7.62 km/s @ 500 km), the GUI-06/07 radio group + visibility contract, and the fmt-aware `add_metric` with "—" placeholders are all implemented correctly. `py_compile` passes; no leftover `dv_spin`/`left_layout`/`right_layout` references; diff guard regions (DLL load 22-59, bridge 80-110, `_load_data`, Splash/AppWindow 990-1019, entry point) are untouched — GUI-08 preserved.

The two dev-time hazards identified in the summaries (print_btn destruction by `_clear_results`; `buttonClicked` vs `buttonToggled` staleness; nested-f-string format spec rejection) were correctly fixed. My adversarial review found no blocker: no crash path under the current bridge contract, no free-text input, no eval/exec, no write outside the QFileDialog-picked path. Findings below are robustness gaps in the render/export paths, plus quality items.

## Warnings

### WR-01: Render block in `_run` sits outside the exception guard

**File:** `SRC/gui/gui.py:1078-1147`
**Issue:** The `try/except` protects only the `run_staging()` call (1078-1088). The entire render path — summary with direct key access `results['total_initial_mass']` (1096), `ResultCard` rows with direct key access `data["m0"]`..`data["nu_e"]` (585-592), the new partial-state hint (1121-1128), `setCurrentIndex(0)` (1141), and the print_btn re-pin (1146-1147) — executes unguarded. If the bridge ever returns a partial dict, or a Phase-2 dict packs `dv`/`diameter`/`length`/`volume` as a non-numeric type (see WR-03), the app dies with a raw traceback instead of the established "Fortran Error" modal. The phase *added* new code to this unguarded region (hint, auto-switch, re-pin).
**Fix:**
```python
        try:
            results = run_staging(...)
            self._clear_results()
            # ... entire render block, hint, capture, print_btn enable, switch ...
        except Exception as e:
            QMessageBox.critical(self, "Fortran Error", str(e))
            return
```

### WR-02: `_print_results` guard asymmetry — unguarded `_last_configs` + silent `zip` truncation

**File:** `SRC/gui/gui.py:1010, 1036`
**Issue:** The entry guard checks only `hasattr(self, '_last_results')` (1010), but the export body reads `self._last_configs` unguarded (1036) and pairs it with `zip(r["stages"], self._last_configs)` — if the two lists ever diverge in length, stages are silently dropped from the export (data-loss adjacent); if `_last_configs` is ever absent while `_last_results` is present, an AttributeError. Unreachable today (both are captured in the same success path and any input change disables Save), but it is a latent contract with no enforcement for Phase 2.
**Fix:** Capture one snapshot object (`self._last_snapshot = (results, configs)`) and guard both, or assert `len(r["stages"]) == len(self._last_configs)` before zipping and surface a modal on mismatch.

### WR-03: `add_metric` None-guard only covers `None` — non-numeric Phase-2 values crash the card render

**File:** `SRC/gui/gui.py:569-583, 1121-1125`
**Issue:** The placeholder branch triggers only on `value is None` (572); the hint condition (1121-1125) mirrors that. The signature-stable handoff contract (`.get()` defaults) means Phase 2 packs `dv`/`diameter`/`length`/`volume` into the same dict — if those arrive as non-numeric (string, `numpy` scalar, NaN from an uninitialized Fortran out-param), `fmt % value` (577) or `{value:{fmt}}` (579) raises TypeError inside card construction, which is unguarded (WR-01). NaN would also render "nan km/s" — a fabricated-looking value that defeats the PIPE-02 "never fabricated numbers" intent.
**Fix:** Validate the value type before formatting:
```python
            try:
                if isinstance(value, (int, float)):
                    text = (f"{fmt % value}" if fmt.startswith("%")
                            else f"{value:{fmt.lstrip(':')}}") + f" {unit}".strip()
                else:
                    text, color = "—", TEXT_DIM
            except (TypeError, ValueError):
                text, color = "—", TEXT_DIM
```

## Info

### IN-01: Duplicated `_last_results` assignment

**File:** `SRC/gui/gui.py:1137, 1143`
**Issue:** `self._last_results = results` is assigned twice in the same success path. Documented as intentional per RESEARCH:338, but it is dead code that invites future confusion (a future phase editing one site will assume the two differ).
**Fix:** Delete line 1143 (or 1137), leaving a single capture next to `_last_configs`.

### IN-02: Dead `QThread` import retained

**File:** `SRC/gui/gui.py:16`
**Issue:** `QThread` is imported and never used. Plan-mandated (A6 keeps the solver blocking, and the plan explicitly says keep the import), so this is intentional — but it trips every unused-import lint and signals a threading path that must never exist.
**Fix:** Leave per plan, or add a comment marking it as deliberately dead (A6).

### IN-03: `print_btn` special-cased in the results-layout drain — fragile ownership coupling

**File:** `SRC/gui/gui.py:980-984, 976-978`
**Issue:** `_clear_results` must remember `is not self.print_btn` (983) or the Save button is destroyed on the first invalidation, and `_show_empty_state` must remember to re-pin it (976-978). Works correctly today (verified by trace: all three layout states — initial, post-run, post-invalidation — are consistent), but any future permanent Results-tab widget inherits this trap silently.
**Fix:** Track persistent widgets explicitly (e.g., `self._results_persistent = {self.print_btn}`) and skip the whole set in the drain loop.

### IN-04: "User-Specified Diameter (m)" label visible in modes 1/2 with the spinbox hidden

**File:** `SRC/gui/gui.py:917-926`
**Issue:** Only the spinbox is hidden (`setVisible(False)`, 924); the label remains in the layout, so modes 1/2 show a floating label pointing at empty space. The UI-SPEC:188 contract is written about "the box", and the plan built the row this way — but it is a visible UX wart.
**Fix:** Hide the whole `diam_row` (or the label) alongside the spinbox: `self.mode_user.toggled.connect(lambda checked: diam_row_label.setVisible(checked))`.

### IN-05: Legacy card rows keep 1-decimal formats — UI-SPEC:155 declares %.4f for ratios/ν_e

**File:** `SRC/gui/gui.py:585-592`
**Issue:** `k_m`/`k_L`/`k_s`/`nu_e` render with the legacy `:,.1f` default (e.g., "2.3", "3.5 km/s"), while the UI-SPEC formatting contract (line 155) declares `%.4f` for ratios and ν_e. The 01-03 plan truth #2 explicitly mandates byte-identical legacy rows, so the implementation is faithful to the plan — but the spec and plan conflict, and Phase 2 will inherit the ambiguity (export file already uses %.4f, cards use 1 decimal).
**Fix:** Resolve the conflict in the UI-SPEC (amend the spec's contract row to note legacy card rows are exempt) so Phase 2 does not "fix" the cards and silently change the display.

### IN-06: `int()` truncation of fractional payload in export filename

**File:** `SRC/gui/gui.py:1015`
**Issue:** `pl = int(self.pl_spin.value())` — a payload of 1234.5 kg produces a suggested filename `..._pl1234kg.txt`, silently losing precision. Pre-existing (unchanged by this phase).
**Fix:** Use `f"pl{self.pl_spin.value():g}"` or keep one decimal: `f"pl{self.pl_spin.value():.1f}kg"` — matching the export header's `{:.1f}`.

### IN-07: Unreachable "No Results" warning in `_print_results`

**File:** `SRC/gui/gui.py:1010-1012`
**Issue:** The `hasattr(self, '_last_results')` guard with a "Run the staging analysis first." modal is unreachable — `print_btn` is disabled until a successful run captures results (1138), and every input change disables it again (995). Dead defensive path.
**Fix:** Either remove it or, better, keep it as the guard for WR-02's snapshot object.

### IN-08: Radio indicator QSS renders a solid square when checked

**File:** `SRC/gui/gui.py:318-320`
**Issue:** `QRadioButton::indicator:checked { background: ACCENT; }` fills the 16×16 indicator with no `border-radius`, so the checked radio shows as an accent square instead of a filled circle — visually inconsistent with the native radio affordance. Cosmetic only.
**Fix:** Add `border-radius: 8px;` to both `QRadioButton::indicator` and `QRadioButton::indicator:checked`, and a 1px `BORDER` outline on the unchecked state.

---

## Verification notes

- `python -m py_compile SRC/gui/gui.py` → PY_COMPILE_OK.
- `_auto_delta_v()` verified against `SRC/pre-staging-calcs/Orbit_calc.f90:9-10` and `SRC/inout/Typical_Data.f90:3-5` (g_0=9.80665, Radius=6378.0) — faithful mirror; V_circ 7.62 km/s @ 500 km is physically correct.
- No `dv_spin`/`left_layout`/`right_layout`/`root_layout` remnants anywhere under `SRC/gui/`.
- Diff guard regions (DLL load, bridge, `_load_data`, SplashScreen/AppWindow, entry point) have zero hunks — GUI-08 preserved.
- `make gui` / `test_call.py` gate remains unrun (no `build/librocket.dll` on this machine) — tracked as human_judgment coverage in the plan summaries, not a code defect.

---

_Reviewed: 2026-08-14T21:30:00Z_
_Reviewer: the agent (gsd-code-reviewer)_
_Depth: deep_
