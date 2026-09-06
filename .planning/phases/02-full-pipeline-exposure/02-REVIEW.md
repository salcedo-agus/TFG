---
phase: 02-full-pipeline-exposure
reviewed: 2026-09-06T22:45:00Z
depth: standard
files_reviewed: 5
files_reviewed_list:
  - SRC/interface/C_Interface.f90
  - SRC/pre-simulation-calcs/Geometry_calc.f90
  - SRC/interface/rocket_lib.py
  - SRC/test_call.py
  - SRC/gui/gui.py
findings:
  critical: 1
  warning: 3
  info: 2
  total: 6
status: issues_found
---

# Phase 2: Code Review Report

**Reviewed:** 2026-09-06T22:45:00Z
**Depth:** standard
**Files Reviewed:** 5
**Status:** issues_found

## Summary

Reviewed the phase-02 diff (commits 0566f41, 5b36481, 70095ec, 6cd13b3, 51a5695, 3e7eab2 vs d6538d8): the new `run_full_pipeline` bind(C) entry in `C_Interface.f90`, the store-back loop in `Geometry_calc.f90`, the `rocket_lib.py` wrapper + argtypes, the `test_call.py` smoke block, and the GUI wiring in `gui.py`. The bridge contract itself is sound: the argtypes list mirrors the bind(C) signature 1:1 (23 params, order verified by cross-checking both files), the console-path call order is reproduced (payload → orbit → STAGING_LOOP → geometry), all globals the pipeline reads are seeded, and the volume identity `pi/4·D²·L` matches Geometry_calc.f90:105.

The critical defect is on the geometry path: with `n_stages < 3` and Constant diameter mode (mode 2), ghost stage-2/3 slots computed from zero mass and the *last real stage's* propellant (the `min(i, n_stages)` fallback) pollute `maxval(Diameter_vector)` and silently force wrong diameters/lengths/volumes on every real stage. Three warnings cover input-integrity and physics-domain gaps that the new GUI path exposes without guards.

## Critical Issues

### CR-01: Ghost-stage diameter pollutes Constant mode (diameter_setup=2) for n_stages < 3 — silently wrong geometry

**File:** `SRC/pre-simulation-calcs/Geometry_calc.f90:101` (trigger: `SRC/interface/C_Interface.f90:156-157`)
**Issue:** `run_full_pipeline` seeds `second_stage_propellant_and_oxidizer = propellant_in(min(2, n_stages))` and `third_stage_propellant_and_oxidizer = propellant_in(min(3, n_stages))` (C_Interface.f90:156-157), and `Mass_vector(2)/(3)` stay 0 for n<3 (Geometry_calc.f90:14, filled only for i=1..n). Geometry_calc still executes all three per-stage select cases unconditionally, so for n=2 the *ghost* third-stage slot gets a diameter computed from zero mass using the stage-2 propellant — e.g. LH2/LOX gives `0.0139·0² − 0.3527·0 + 4.8378 = 4.8378 m` (Geometry_calc.f90:71); for n=1 both slots 2 and 3 are ghosts (e.g. 2.4729 m and 4.8378 m, lines 47/71). In Constant mode, `Diameter_vector = maxval(Diameter_vector)` (line 101) includes these ghost slots, so every real stage is forced to the ghost value (≈4.84 m vs ~3.6/3.0 m real statistical widths for a typical 3-stage-derived 2-stage design) — then Length (line 105) and the packed volume (C_Interface.f90:190-191) are recomputed wrong as well. Fully reachable from the GUI: `n_stages_spin` range is 1–3 and Constant is an advertised radio mode. No error or warning surfaces — results look valid. (Side effect: ghost slots also print spurious "WARNING: without statistical data…" lines to the console for n<3.)

**Fix:** Bound the Constant-mode max to the real stages — `Diameter_vector = maxval(Diameter_vector(1:Rocket%number_of_stages))` in Geometry_calc.f90 case(2) — and/or skip the per-stage select cases for `i > Rocket%number_of_stages` so ghost slots never receive computed values.

## Warnings

### WR-01: ISP/k_s slider value changes do not invalidate results — stale numbers remain visible and exportable

**File:** `SRC/gui/gui.py:398-399`
**Issue:** `isp_slider.valueChanged` and `ks_slider.valueChanged` connect only to the label updaters; neither routes through `_on_inputs_changed`. The phase extended invalidation to orbit/payload/stages (pre-existing) and to the diameter configuration (51a5695), but the ISP/k_s slider values — which are direct solver inputs (`get_values` reads them at gui.py:536-537, `_run` passes them at 1145-1146) — still leave the previous run's cards, `_last_v_circ` label, and the export path (Save stays enabled, `_print_results` writes the old converged numbers) intact after a drag. This contradicts the phase's own contract, "converged numbers are never displayed or exported against changed inputs" (02-02-PLAN truth #6 / D-04/D-05), and silently ships results that do not match the current inputs.

**Fix:** Connect both sliders' `valueChanged` to `_on_inputs_changed` *after* the construction-time `setValue` calls in `_update_ranges()` (e.g. in the post-construction wiring block, or via a `_initialized` guard flag), so the initial range/mean population does not fire a spurious clear.

### WR-02: Empty/inverted geometry-table rows yield negative or NaN diameters/lengths/volumes with no user-facing signal

**File:** `SRC/pre-simulation-calcs/Geometry_calc.f90:27-41,52,54-64,85-89,105` (packed at `SRC/interface/C_Interface.f90:188-191`)
**Issue:** Valid GUI combinations can fall into geometry branches with no data (e.g. stage-2 CH4/LOX, `!COMPLETAR`, line 52; UDMH/LOX at line 54) or fit inversions (stage-1 LH2/LOX diameter goes negative below ~11.6 t stage mass, line 21). Vacant branches leave `Diameter_vector=0, Volume_vector=0` → `0/0 = NaN` at line 105, and inversions produce negative diameters. The NaN guard in ResultCard (gui.py:580-591) silently renders "—" while "✔ Minimum confirmed" and all masses still display as valid; negative values render literally (e.g. "-1.57 m"). The only signal is a Fortran console print invisible in a packaged app. The plan flagged this only for the smoke hook and the T3 checklist; the shipped GUI path has no guard.

**Fix:** After `rocket_geometry_calculation`, validate in `run_full_pipeline` that every packed diameter/length/volume is finite and > 0 and return/surface a warning when a stage lacks geometry data (e.g. extend the packed result with a per-stage `geometry_valid` flag or raise a catchable error the GUI can show).

### WR-03: Negative-thrust domain (light vehicles) silently corrupts converged ΔV — reachable from GUI minimums

**File:** `SRC/pre-simulation-calcs/Thrust_calc.f90:19-21` (exposed via `SRC/interface/C_Interface.f90:173` STAGING_LOOP)
**Issue:** `stage_thrust(1) = 1.459·m0·g_0 − 486.6 < 0` for m0 < 34.0 t; `stage_thrust(2) < 0` for m0 < 6.2 t (line 20). Negative thrust → negative `m_dot` → negative `t_burn` → distorted `rt_burn`, which feeds `DV_loss` (Stage_Optimization_Loop.f90:74-88) and can drive the converged total below `V_circ` — physically impossible — with no error. The GUI's minimums (payload 1.0 kg, orbit 100 km, n=1) land in this domain, so a single-stage run with a small payload silently produces a per-stage ΔV sum below the orbital speed, and `total_initial_mass`/`minimum_found` still display as valid results. The smoke assertion (v_circ < sum(dv)) holds only for the smoke's inputs.

**Fix:** In `run_full_pipeline`, validate `Rocket%stage(i)%T > 0` and `sum(D_v) >= V_circ` after STAGING_LOOP and surface an error/tooltip instead of returning garbage; at minimum, extend the GUI-side pre-check to reject inputs that push stage-1 mass below the thrust-regression domain.

## Info

### IN-01: Dead bridge twin and unused accessor left in gui.py

**File:** `SRC/gui/gui.py:20-111, 459-463`
**Issue:** The inline `_lib`/`run_staging` twin (lines 20-111) is now unreferenced — `_run` calls `rocket_lib.run_full_pipeline` (line 1141) and no other call site of the inline `run_staging` remains (line 97 is its own definition). It also loads `librocket.dll` a second time via a second CDLL handle (line 58 vs rocket_lib.py:22). `_get_data` (line 459) is never called anywhere in the file. Kept deliberately per the Phase-3 FIX-02/FIX-03 plan — tracked here as debt, not a defect.
**Fix:** Delete in Phase 3 during bridge dedup; optionally grep-guard against resurrection.

### IN-02: Duplicated `_last_results` assignment in `_run` success path

**File:** `SRC/gui/gui.py:1199, 1207`
**Issue:** `self._last_results = results` is assigned twice (line 1199 inside the configs block, line 1207 after the tab switch). Harmless but redundant.
**Fix:** Remove the second assignment (line 1207).

---

_Reviewed: 2026-09-06T22:45:00Z_
_Reviewer: the agent (gsd-code-reviewer)_
_Depth: standard_