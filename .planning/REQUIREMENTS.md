# Requirements: TFG — Multi-Stage Launch Vehicle Design Tool

**Defined:** 2026-08-14
**Core Value:** The user can go from mission parameters to a complete, trustworthy vehicle design (stage masses, ΔV, thrust, geometry) entirely from the GUI.

## v1 Requirements

### GUI — Centralized Workbench

- [x] **GUI-01**: App opens to a centralized 3-tab interface: a central Results tab, a Setup tab (sliders + propellant/combustion-cycle selectors), and a Vehicle Configuration tab (diameter mode)
- [ ] **GUI-02**: Results tab shows, per stage, m0, mf, mp, ms, mass ratios (k_m, k_s, k_L), per-stage ΔV, and exhaust velocity
- [ ] **GUI-03**: Results tab shows geometry results per stage (diameter, length, volume)
- [ ] **GUI-04**: Results tab retains the "Save Results" export and the minimum-confirmed indicator
- [x] **GUI-05**: Mission inputs live in the GUI (orbit height, payload mass, stage count); ΔV is computed internally by the pipeline, not entered by hand
- [x] **GUI-06**: Vehicle Configuration tab offers statistically-determined, constant, and user-specified diameter modes
- [x] **GUI-07**: User-specified diameter mode exposes an input box for the diameter value
- [x] **GUI-08**: Launch splash screen is preserved

### Pipeline Exposure

- [ ] **PIPE-01**: GUI drives the full pipeline: orbit → payload → staging → thrust → geometry
- [ ] **PIPE-02**: Fortran interface (C_Interface) exposes bindings needed to run the full pipeline from Python (single ctypes entry), reusing existing modules — no physics reimplementation in Python

### Fortran Bridge & Correctness

- [ ] **FIX-01**: `Rocket%rm_L` is initialized on the ctypes/GUI path (currently unset; read at `Staging.f90:86`)
- [ ] **FIX-02**: The duplicated `run_staging` ctypes bridge is consolidated into one module (`rocket_lib.py`), and `gui.py` uses it
- [ ] **FIX-03**: Hardcoded MinGW path is removed/replaced with a resolvable library path

## v2 Requirements

Deferred to future release. Tracked but not in current roadmap.

### Known Fortran Correctness (out of current scope)

- **FIX-04**: Config parser writes stage-2/3 combustion cycles into `first_stage_combustion_cycle` (`Typical_Data.f90:924-930`)
- **FIX-05**: Hardcoded Soyuz TEST CASE overrides all ISP/k_s tables in the Fortran path (`Typical_Data.f90:824-832`)
- **FIX-06**: Makefile circular dependency between `Staging.o` and `Root_Finding.o`

### Physics / Simulation

- **SIM-01**: Trajectory / 3-DoF guidance simulation (README objective)
- **SIM-02**: Launch-site / launch-latitude model (V_rot)

## Out of Scope

| Feature | Reason |
|---------|--------|
| Automated tests | Explicitly deferred by user to future sessions |
| New Fortran physics features | Only interface/pipeline wiring may change on Fortran side |
| config.txt replacement | GUI and config.txt remain separate input paths (user decision) |
| Trajectory simulation | Listed in README objectives, not part of this work |
| Launch-site model | Missing Fortran module, future work |

## Traceability

| Requirement | Phase | Status |
|-------------|-------|--------|
| GUI-01 | Phase 1 | Complete |
| GUI-02 | Phase 1 | Pending |
| GUI-03 | Phase 1 | Pending |
| GUI-04 | Phase 1 | Pending |
| GUI-05 | Phase 1 | Complete |
| GUI-06 | Phase 1 | Complete |
| GUI-07 | Phase 1 | Complete |
| GUI-08 | Phase 1 | Complete |
| PIPE-01 | Phase 2 | Pending |
| PIPE-02 | Phase 2 | Pending |
| FIX-01 | Phase 3 | Pending |
| FIX-02 | Phase 3 | Pending |
| FIX-03 | Phase 3 | Pending |

**Coverage:**

- v1 requirements: 13 total
- Mapped to phases: 13
- Unmapped: 0 ✓

---
*Requirements defined: 2026-08-14*
*Last updated: 2026-08-14 after initial definition*
