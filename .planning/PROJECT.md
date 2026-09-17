# TFG — Multi-Stage Launch Vehicle Design Tool

## What This Is

TFG is a standalone desktop engineering tool for the conceptual design of multi-stage space launchers. The user configures mission parameters, propellant/combustion-cycle choices, and vehicle configuration; the tool sizes the stages (masses, mass ratios, ΔV) and the vehicle geometry (diameter, length, volume). It is the GUI/Python workbench over a Fortran 90/2008 computational core, built for the author's degree thesis (TFG).

## Core Value

The user can go from mission parameters to a complete, trustworthy vehicle design (stage masses, ΔV, thrust, geometry) entirely from the GUI — without touching config files, Fortran code, or the console.

## Requirements

### Validated

- ✓ Fortran staging solver: optimal stage mass ratios via Bolzano bisection — existing
- ✓ Pre-staging calculations: circular orbit velocity, payload + PAF adapter mass — existing
- ✓ Pre-simulation calculations: empirical stage thrust/burn time, statistical diameter/volume/length — existing
- ✓ ctypes bridge (`run_full_pipeline`) from Python to Fortran DLL — existing
- ✓ PyQt6 GUI with per-stage ISP/k_s sliders + propellant/combustion-cycle selectors — existing
- ✓ config.txt parsing (mission + per-stage setup + diameter mode) — existing
- ✓ Results export to .txt with minimum-confirmed indicator — existing
- ✓ Centralized 3-tab GUI: central results tab, setup tab (sliders + propellant/cycle), vehicle-configuration tab (diameter mode) — validated in Phase 1
- ✓ Results tab shows stage masses (m0, mf, mp, ms), mass ratios (k_m, k_s, k_L), per-stage ΔV, exhaust velocity, and geometry (diameter, length, volume) — validated in Phase 1
- ✓ Mission inputs in the GUI (orbit height, payload mass, stage count); ΔV computed internally by the pipeline — validated in Phase 2
- ✓ Vehicle-configuration tab: statistically-determined diameters, constant diameter, and user-specified diameter with an input box — validated in Phase 1
- ✓ Full pipeline exposed to the GUI: orbit → payload → staging → thrust → geometry — validated in Phase 2
- ✓ `Rocket%rm_L` initialized on the ctypes/GUI path (via `Payload_Mass_calculator` in `run_full_pipeline`) — validated in Phase 3 (FIX-01)
- ✓ Duplicated ctypes bridge consolidated to the single `rocket_lib.py` entry; `gui.py` imports it — validated in Phase 3 (FIX-02)
- ✓ Hardcoded MinGW path removed; Makefile discovers gfortran at build time (`?=` + `where gfortran`, env/CLI override) — validated in Phase 3 (FIX-03)

### Active

- Open FIX-04/05/06 (config-cycle write bug, dead Soyuz TEST CASE, Makefile circular dep) — queued for a future release, see REQUIREMENTS.md v2

### Out of Scope

- Automated tests — explicitly deferred by the user to future sessions
- Trajectory simulation / 3-DoF guidance — listed in README objectives but not part of this work
- Launch-site / launch-latitude model (V_rot) — missing Fortran module, future work
- New Fortran physics features — only interface/pipeline wiring may change on the Fortran side
- config.txt replacement — GUI and config.txt remain separate input paths (user decision)

## Context

- Brownfield repo: Fortran 90/2008 core (`SRC/`) + Python 3.11/PyQt6 GUI bridged via ctypes `librocket.dll`. No external APIs, no databases; Windows primary target (TDM-GCC-64), macOS/Linux Makefile branches exist.
- Pipeline (`SRC/Main.f90:8-17`): config → pre-staging (orbit, payload) → staging solver → pre-simulation (thrust, geometry). The GUI drives the full pipeline through the single `run_full_pipeline` ctypes entry; Phase 3 removed the legacy staging-only bridge and its inline `gui.py` twin (FIX-01/02), and the Makefile now discovers MinGW at build time (FIX-03).
- Known issues from the codebase map (`.planning/codebase/CONCERNS.md`): config parser writes stage-2/3 combustion cycles into stage-1 variable (`Typical_Data.f90:924-930`); hardcoded Soyuz TEST CASE overrides ISP/k_s tables (`Typical_Data.f90:824-832`); Makefile circular dep between `Staging.o` and `Root_Finding.o`; zero automated tests. (The `Rocket%rm_L` ctypes bug and duplicated bridge were resolved in Phase 3 — FIX-01/02.)
- Codebase map refreshed 2026-08-14 (commit `e59e494`).

## Constraints

- **Tech stack**: Fortran 90/2008 (gfortran) core + Python 3.11/PyQt6 GUI — existing, non-negotiable
- **Bridge**: Python↔Fortran must go through ctypes `librocket.dll` — existing architecture
- **Branch convention**: source work on `dev_GUI`/`dev_pre_simulation`; GSD artifacts only on `planning` branch; never push without explicit request
- **Tests**: deferred — no test infrastructure work in current scope
- **Language**: UI and code comments mix Spanish/English as today; GUI text currently English

## Current State

- Shipped v1.0 milestone (3 phases, 9 plans, 20 tasks)
- Tech stack: Fortran 90/2008 + Python 3.11/PyQt6, ~4.5K LOC
- GUI: centralized 3-tab workbench driving full Fortran pipeline via single `run_full_pipeline` ctypes entry
- Bridge: `Rocket%rm_L` initialized correctly, `run_staging` removed, MinGW discovered at build time
- Tests: deferred (user decision)

## Key Decisions

| Decision | Rationale | Outcome |
|----------|-----------|---------|
| Centralized 3-tab GUI (results / setup / vehicle config) | User wants one workbench, not scattered panels | ✓ Good (Phase 1) |
| Mission inputs in GUI; ΔV computed internally | Full-pipeline exposure; no raw ΔV guessing | ✓ Good (Phase 2) |
| Keep splash screen | User preference | ✓ Good |
| config.txt stays a separate path | User decision; Fortran main keeps working untouched | ✓ Good |
| GSD planning artifacts only on `planning` branch | User concern about repo cleanliness | ✓ Good |
| Tests deferred to future sessions | User decision | — Pending |

## Evolution

This document evolves at phase transitions and milestone boundaries.

**After each phase transition** (via `/gsd-transition`):
1. Requirements invalidated? → Move to Out of Scope with reason
2. Requirements validated? → Move to Validated with phase reference
3. New requirements emerged? → Add to Active
4. Decisions to log? → Add to Key Decisions
5. "What This Is" still accurate? → Update if drifted

**After each milestone** (via `/gsd-complete-milestone`):
1. Full review of all sections
2. Core Value check — still the right priority?
3. Audit Out of Scope — reasons still valid?
4. Update Context with current state

---
*Last updated: 2026-09-17 after v1.0 milestone complete*