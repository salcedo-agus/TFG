# Milestones

## v1.0 milestone (Shipped: 2026-09-17)

**Phases completed:** 3 phases, 9 plans, 20 tasks

**Key accomplishments:**

- Single-file restructure of `SRC/gui/gui.py` into a QTabWidget workbench: Results (index 0, active on open) / Setup / Vehicle Configuration, with the old input panel moved verbatim into Setup (D-08), the old render surface moved verbatim into Results (D-07), and tab-bar/radio QSS appended to STYLE.
- Mission-input rework in the Setup tab (dv_spin removed per D-10 — orbit height 100-2000 km now drives an interim read-only auto-ΔV computed as the V_circ mirror of Orbit_calc.f90:9-10, feeding the solver call and the export header/filename) plus a fully built Vehicle Configuration tab (3 diameter-mode radios mapped to Fortran 1/2/3 with the user-specified box under a strict visibility contract, state stored for Phase 2 handoff).
- ResultCard extended to 10 metric slots (per-stage ΔV + diameter/length/volume rendered as intentional TEXT_DIM "—" placeholders with a one-shot partial-state hint until Phase 2 packs them), auto-switch to Results after a successful Run, and the export/minimum-indicator contracts verified byte-identical (auto ΔV line, filename pattern, dialog-per-save idempotency, blocking single-thread guarantee).
- 1. [Rule 3 - Blocking] Fortran '::' required for initialized component — plan's literal text did not compile
- G-01-4 (blocker) closed: `SRC/test_call.py` bridges SRC/interface/rocket_lib.py via the gui.py:29 `sys.path.insert` pattern, and TESTING.md documents the post-reorg run contract — the ModuleNotFoundError is eliminated from any CWD.
- Single new bind(C) entry `run_full_pipeline` (payload → orbit → STAGING_LOOP → geometry on seeded module globals), Geometry_calc store-back wiring, ctypes wrapper, and an asserted smoke hook proving V_circ provenance and loss-inclusive per-stage ΔV — run_staging and the Makefile byte-untouched.
- The GUI now runs the complete Fortran pipeline (orbit → payload → staging → thrust → geometry) through the single `rocket_lib.run_full_pipeline` entry: the Setup "ΔV (auto)" label, the export Delta-V line and the suggested filename all source from the Fortran V_circ, diameter-configuration changes invalidate results like every other input, and a shared Run button is reachable from every tab except Results — T3 interactively approved, both follow-ups implemented and offscreen-verified.
- D-02 conservative-bounds regression test (`ConservativeBoundsGuard.test_conservative_bounds_n3`) proving `Rocket%rm_L` is finite and physical on the ctypes/GUI path, with all 24 tests green against a freshly rebuilt `librocket.dll` — establishing the pre-dedup baseline for 03-02
- run_full_pipeline is now the sole bridge entry end-to-end; FIX-01/02/03 closed; Makefile discovers MinGW at build time; codebase map refreshed; full suite green at every commit

---
