# Roadmap: TFG — Multi-Stage Launch Vehicle Design Tool

## Overview

The project moves from a splash + single-panel raw-slider GUI to a centralized 3-tab workbench that drives the entire Fortran pipeline. First we build the tabbed GUI shell and results surface, then wire the full pipeline through a single ctypes entry point, then fix the known Fortran-bridge correctness bugs. Tests are deferred by user decision to a future session.

## Phases

**Phase Numbering:**

- Integer phases (1, 2, 3): Planned milestone work

- [ ] **Phase 1: Centralized 3-Tab GUI** - Build the tabbed workbench (results / setup / vehicle-config) with mission inputs, results display, and splash preserved
- [ ] **Phase 2: Full Pipeline Exposure** - Add a single ctypes pipeline entry point so the GUI runs orbit → payload → staging → thrust → geometry
- [ ] **Phase 3: Bridge & Correctness Fixes** - Fix `Rocket%rm_L` init, deduplicate the ctypes bridge, remove the hardcoded MinGW path

## Phase Details

### Phase 1: Centralized 3-Tab GUI

**Goal**: Restructure the GUI into a centralized 3-tab workbench with mission inputs, results display, geometry results, and vehicle-configuration (diameter mode).
**Depends on**: Nothing (first phase)
**Requirements**: GUI-01, GUI-02, GUI-03, GUI-04, GUI-05, GUI-06, GUI-07, GUI-08
**Success Criteria** (what must be TRUE):

  1. App opens to three tabs: Results (central), Setup (sliders + propellant/cycle), Vehicle Configuration (diameter mode)
  2. Results tab shows per-stage masses, mass ratios, per-stage ΔV, exhaust velocity, and geometry (diameter, length, volume)
  3. Mission inputs (orbit height, payload mass, stage count) are editable in the GUI; ΔV is not entered by hand
  4. Vehicle Configuration offers statistical / constant / user-specified diameter, and specified diameter shows an input box
  5. "Save Results" export, minimum-confirmed indicator, and splash screen all still work

**Plans**: 3/3 plans executed

Plans:

- [x] 01-01-PLAN.md
- [x] 01-02-PLAN.md
- [x] 01-03-PLAN.md

**Wave 1**

- [x] 01-01: Refactor GUI shell into 3 tabs; move existing sliders/propellant-cycle into Setup tab

**Wave 2** *(blocked on Wave 1 completion)*

- [x] 01-02: Add mission inputs and Vehicle Configuration tab (diameter modes + input box)

**Wave 3** *(blocked on Wave 2 completion)*

- [x] 01-03: Add results surface (stage masses, ΔV, geometry) with export and minimum-confirmed indicator

### Phase 2: Full Pipeline Exposure

**Goal**: Expose the complete Fortran pipeline to the GUI through a single ctypes entry point, reusing existing Fortran modules (no physics reimplementation in Python).
**Depends on**: Phase 1
**Requirements**: PIPE-01, PIPE-02
**Success Criteria** (what must be TRUE):

  1. A single ctypes function runs the full pipeline: orbit → payload → staging → thrust → geometry
  2. GUI results populate from the full pipeline, not just the staging solver
  3. All pipeline results are reused via the existing Fortran modules (no duplicated physics in Python)

**Plans**: 2 plans

Plans:

- [ ] 02-01: Add Fortran bind(C) pipeline entry to C_Interface (reuse pre-staging, staging, thrust, geometry)
- [ ] 02-02: Add Python wrapper in rocket_lib.py and wire the GUI to the full pipeline

### Phase 3: Bridge & Correctness Fixes

**Goal**: Fix the three known Fortran-bridge correctness issues: `Rocket%rm_L` init, duplicated ctypes bridge, hardcoded MinGW path.
**Depends on**: Phase 2
**Requirements**: FIX-01, FIX-02, FIX-03
**Success Criteria** (what must be TRUE):

  1. `Rocket%rm_L` is correctly initialized on the ctypes/GUI path (no garbage in stage-2 mass ratio)
  2. Only one ctypes bridge module exists; gui.py imports it
  3. Library path resolution no longer depends on a hardcoded MinGW directory

**Plans**: 2 plans

Plans:

- [ ] 03-01: Fix `Rocket%rm_L` initialization on the ctypes path
- [ ] 03-02: Consolidate ctypes bridge into rocket_lib.py and remove hardcoded MinGW path

## Progress

**Execution Order:**
Phases execute in numeric order: 1 → 2 → 3

| Phase | Plans Complete | Status | Completed |
|-------|----------------|--------|-----------|
| 1. Centralized 3-Tab GUI | 3/3 | In Progress|  |
| 2. Full Pipeline Exposure | 0/2 | Not started | - |
| 3. Bridge & Correctness Fixes | 0/2 | Not started | - |
