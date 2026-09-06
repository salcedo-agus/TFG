# Phase 2: Full Pipeline Exposure - Context

**Gathered:** 2026-08-15
**Status:** Ready for planning

<domain>
## Phase Boundary

Expose the complete Fortran pipeline (orbit → payload → staging → thrust → geometry) to the GUI through a single ctypes entry point, reusing existing Fortran modules — no physics reimplementation in Python. The GUI's Run must populate real ΔV, thrust-derived and geometry results, replacing the interim `_auto_delta_v()` V_circ mirror and the "—" placeholders in the Results tab. Requires a new bind(C) entry in `C_Interface.f90`, a Python wrapper in `rocket_lib.py`, and GUI wiring.

</domain>

<decisions>
## Implementation Decisions

### ΔV computation & label source
- **D-01:** The Setup "ΔV (auto)" label — and the exported Delta-V line and suggested filename — display **V_circ** (pure circular orbital velocity), not the converged staging ΔV. Locked in because the label now comes from Fortran and the export contract must match what the user sees (UAT verified label == Delta-V line == filename). — **Reversibility:** reversible — per-stage ΔV rows still expose the converged value, so switching the label later only changes one rendering path.
- **D-02:** The ctypes/GUI path runs the **full `STAGING_LOOP`** (thrust + `DV_loss` iteration to 1e-6 convergence, up to 50 iters, `Stage_Optimization_Loop.f90:30-45`), replacing the current single `call STAGING` in `C_Interface.f90:61`. `orbit_speed_calculator` runs first so the `V_circ` global is set (`STAGING_LOOP` reads it at line 24), matching the console path (`Main.f90:14`).
- **D-03:** Per-stage ΔV in the Results tab's "Stage ΔV / Diameter — Length / Volume" rows come from the **converged `STAGING_LOOP` output** (loss-inclusive per-stage distribution), not a V_circ-proportional split. — **Reversibility:** reversible — the rows are additive/dynamic (gui.py:598-601 `.get()` defaults), so the source can change without touching the card layout.
- **D-04:** The label's V_circ value comes **from the Fortran pipeline** (`orbit_speed_calculator`), returned to Python through the new entry. The Python `_auto_delta_v()` mirror (gui.py:1002-1005, documented "marked for removal, do not extend") is **removed** in this phase.
- **D-05:** The exported Delta-V line / filename uses V_circ per D-01 — the existing `_print_results` (gui.py:1019-1022) keeps using the same V_circ source, preserving the UAT-verified export contract.

### the agent's Discretion
- Exact bind(C) signature shape and how many output arrays the single entry packs (masses/ratios/ΔV/thrust/geometry) — the ROADMAP says "single ctypes entry", the planner decides the parameter layout.
- Whether the new entry replaces `run_staging` or adds alongside it in `rocket_lib.py` (see Deferred: FIX-02 bridge dedup stays in Phase 3).
- Whether thrust metrics (thrust, mass flow, burn time from `Thrust_calc.f90`) surface in the GUI or only drive the loop internally.
- How `Diameter_setup` mode (1/2/3) + user diameter flow from the Vehicle Configuration tab (already stored on MainWindow, gui.py:905/950) into `rocket_geometry_calculation`.
- How per-stage ISP/k_s reach the pipeline: sliders vs propellant/ox tables (undecided this session — see Deferred note).

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Requirements & project definition
- `.planning/REQUIREMENTS.md` — PIPE-01 (GUI drives full pipeline: orbit → payload → staging → thrust → geometry), PIPE-02 (C_Interface exposes bindings; single ctypes entry; no physics reimplementation)
- `.planning/PROJECT.md` — constraints (Fortran core non-negotiable, ctypes bridge, config.txt separate path), known concerns
- `.planning/ROADMAP.md` — Phase 2 section: goal, success criteria (single entry runs full pipeline; GUI results from full pipeline; reuse existing Fortran modules), plan list (02-01 Fortran entry, 02-02 Python wrapper + GUI wiring)

### Fortran pipeline (source-of-truth modules being exposed)
- `SRC/Main.f90` — console path ordering: `data_entry` → `Payload_Mass_calculator` → `orbit_speed_calculator` → `STAGING_LOOP` → `rocket_geometry_calculation` (lines 8-17)
- `SRC/interface/C_Interface.f90` — existing `run_staging` bind(C) (lines 9-101); the model for the new full-pipeline entry; inits `Rocket%rm_L` on the ctypes path (G-01-2 fix, lines 53-58)
- `SRC/staging/Stage_Optimization_Loop.f90` — `STAGING_LOOP` / `DV_loss`: ΔV convergence loop, gravity/atmospheric loss model (lines 1-90)
- `SRC/pre-staging-calcs/Orbit_calc.f90` — `orbit_speed_calculator`, sets `V_circ` global (must be called before STAGING_LOOP)
- `SRC/pre-staging-calcs/Payload_Mass_calc.f90` — `Payload_Mass_calculator`, sets `Rocket%rm_L` incl. PAF adapter mass (console path; ctypes path currently hardcodes the PAF formula at C_Interface.f90:58)
- `SRC/pre-simulation-calcs/Thrust_calc.f90` — `stage_Thrust_calculator` (thrust, mass flow, burn time) used inside STAGING_LOOP
- `SRC/pre-simulation-calcs/Geometry_calc.f90` — `rocket_geometry_calculation`: statistical diameter/length/volume; `Diameter_setup` modes 1/2/3

### Python bridge & GUI
- `SRC/interface/rocket_lib.py` — ctypes wrapper, `run_staging` (lines 45-88); home for the new full-pipeline wrapper
- `SRC/gui/gui.py` — GUI run path: `_run` (line 1066), `_auto_delta_v` mirror (lines 1002-1008, to be removed), `_print_results` export (lines 1014-1064), diameter-mode handoff state (lines 905/950), Results rows `.get()` defaults for ΔV/geometry (lines 598-601)

### Codebase map
- `.planning/codebase/ARCHITECTURE.md` — pipeline layers, both entry points, module-global-state anti-pattern
- `.planning/codebase/INTEGRATIONS.md` — bridge layer (Fortran ↔ Python), DLL loading
- `.planning/codebase/STACK.md` — build (single SRC/Makefile), DLL + MinGW runtime deployment
- `.planning/codebase/CONCERNS.md` — known bridge issues (duplicated wrapper, etc.)

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `SRC/staging/Stage_Optimization_Loop.f90` `STAGING_LOOP`: ready-to-run converged solver — call it directly from C_Interface (D-02)
- `SRC/interface/C_Interface.f90` `run_staging`: the arg-packing pattern to extend for the full pipeline's wider output (masses/ratios/ΔV/geometry)
- `SRC/interface/rocket_lib.py` `run_staging`: the ctypes boilerplate to extend for the new wrapper
- MainWindow diameter mode + value (gui.py:905/950) — already stored for this phase's handoff

### Established Patterns
- bind(C) scalar-by-`intent(in/out)` + per-stage arrays, packed back to Python via ctypes
- Module globals (`V_circ`, `payload_mass`, `number_of_stages`) set on the ctypes path before solver calls
- GUI reads results through `.get()`-defaulted dict rows so missing keys render "—" (partial-state hint, gui.py:598-601/1129-1135)

### Integration Points
- New bind(C) entry in `C_Interface.f90` → new wrapper in `rocket_lib.py` → GUI `_run` (gui.py:1066) called in place of the current `run_staging` inline call (gui.py:1091)
- IV `orbital` `V_circ` returned to Python must feed both the Setup label (D-01/D-04) and the export (D-05)
- `STAGING_LOOP` requires `number_of_stages` + per-stage ISP/k_s + `orbit_height` globals set before call (Stage_Optimization_Loop.f90:12-24 reads `number_of_stages`, `V_circ`, `orbit_height`)

</code_context>

<specifics>
## Specific Ideas

No additional specific references beyond the decisions above — the user was clear that ΔV must remain internally computed and never hand-entered (D-10 from Phase 1 still governs), the label stays V_circ, and the solver converges for real.

</specifics>

<deferred>
## Deferred Ideas

- **ISP/k_s authority (sliders vs propellant/ox tables)** — whether the full-pipeline entry derives per-stage ISP/k_s from the propellant/combustion-cycle tables (console path) or continues taking slider values (current GUI path). Flagged in discussion but not resolved this session. NOTE: the hardcoded Soyuz TEST CASE overrides all ISP/k_s tables on the Fortran path (FIX-05, `Typical_Data.f90:824-832`) — relevant if tables become authoritative.
- **FIX-02 bridge dedup** — consolidating the duplicated `run_staging` (rocket_lib.py:45 + gui.py:80) is Phase 3, not this phase, per REQUIREMENTS traceability; the new pipeline wrapper lives in `rocket_lib.py`, but the old inline duplicate in gui.py is removed when the GUI switches to the new entry if it naturally lands there — planner's discretion.
- **FIX-03 hardcoded MinGW path** — Phase 3 (rocket_lib.py:19 / gui.py:36).
- No reviewed-but-deferred todos (no todos matched this phase).

</deferred>

---

*Phase: 2-full-pipeline-exposure*
*Context gathered: 2026-08-15*