<!-- refreshed: 2026-08-14 -->
# Architecture

**Analysis Date:** 2026-08-14

## System Overview

```text
┌──────────────────────────────────────────────────────────────────────┐
│                        GUI & Python Layer                            │
│   `SRC/gui/gui.py` (PyQt6)  ·  `SRC/interface/rocket_lib.py`        │
│   `SRC/inout/parse_typical_data.py` (codegen)                        │
├────────────────────────────────────────────┬─────────────────────────┤
│            ctypes bridge (librocket.dll)   │  config.txt             │
└───────────────┬────────────────────────────┴─────────────────────────┘
                ▼
┌──────────────────────────────────────────────────────────────────────┐
│                     Fortran Entry Points                             │
│   `SRC/Main.f90` (standalone)  ·  `SRC/interface/C_Interface.f90`    │
├──────────────────────────────────────────────────────────────────────┤
│   PRE-STAGING   `Orbit_calc.f90`, `Payload_Mass_calc.f90`           │
│   STAGING       `Staging.f90`, `Root_Finding.f90`,                  │
│                 `Stage_Optimization_Loop.f90`                        │
│   PRE-SIM       `Thrust_calc.f90`, `Geometry_calc.f90`              │
│   DATA          `Typical_Data.f90`, `Rocket_Types.f90`              │
└──────────────────────────────────────────────────────────────────────┘
                │
                ▼
┌──────────────────────────────────────────────────────────────────────┐
│            Output  → stdout / .txt results file                       │
└──────────────────────────────────────────────────────────────────────┘
```

## Component Responsibilities

| Component | Responsibility | File |
|-----------|----------------|------|
| `rocket_types` | `Stage_t` / `Rocket_t` derived types holding all masses, ratios, ISP, thrust, geometry | `SRC/staging/Rocket_Types.f90` |
| `constants` | `pi`, `g_0`, `Radius` physical constants | `SRC/inout/Typical_Data.f90:1` |
| `typical_data` | module globals (config values), `data_entry`, `load_config`, `to_lower` | `SRC/inout/Typical_Data.f90` |
| `orbit_speed_calculator` | circular orbit velocity `V_circ` | `SRC/pre-staging-calcs/Orbit_calc.f90` |
| `Payload_Mass_calculator` | effective payload incl. PAF adapter mass → `Rocket%rm_L` | `SRC/pre-staging-calcs/Payload_Mass_calc.f90` |
| `STAGING_LOOP` / `DV_loss` | iterates ΔV until convergence; loss model | `SRC/staging/Stage_Optimization_Loop.f90` |
| `STAGING` | solves optimal staging mass ratios via Bolzano bisection on `L` | `SRC/staging/Staging.f90` |
| `Root_Finding_Methods` | `Bolzano_Interval_Start`, `Bolzano_Bisection`, (stub) `Newton_Raphson` | `SRC/staging/Root_Finding.f90` |
| `stage_Thrust_calculator` | empirical stage thrust, mass flow, burn time | `SRC/pre-simulation-calcs/Thrust_calc.f90` |
| `rocket_geometry_calculation` | statistical diameter/volume/length per propellant | `SRC/pre-simulation-calcs/Geometry_calc.f90` |
| `c_interface` | `run_staging` C-bindable entry for Python | `SRC/interface/C_Interface.f90` |

## Pattern Overview

**Overall:** Pipeline / procedural multi-pass design: PRE-STAGING → STAGING → PRE-SIMULATION, orchestrated linearly in `SRC/Main.f90:8-17`. Fortran uses module + external-subroutine style; shared state flows through module globals in `typical_data` plus a `Rocket_t` object threaded through subroutines.

**Key Characteristics:**
- Dual entry points: standalone Fortran (`Main.f90`) and Python ctypes (`run_staging`) — two code paths into the same solver
- Shared global state lives in module variables (`typical_data`): `V_circ`, `orbit_height`, `payload_mass`, `number_of_stages`, per-stage propellant/cycle indices
- Numerical root finding uses a procedure pointer (`func_interface`) + bisection
- New modules `Root_Finding.f90` (extracted from `Staging.f90`) and `Geometry_calc.f90` (new pre-simulation sizing) were added in the latest refactor

## Layers

**Data/Types Layer:**
- Purpose: derived types + physical constants + config globals
- Location: `SRC/staging/Rocket_Types.f90`, `SRC/inout/Typical_Data.f90`
- Contains: type definitions, constants, `load_config`
- Depends on: nothing
- Used by: everything

**Pre-Staging Layer:**
- Purpose: mission-level inputs (orbit, payload)
- Location: `SRC/pre-staging-calcs/`
- Contains: `Orbit_calc.f90`, `Payload_Mass_calc.f90`
- Depends on: `typical_data`, `rocket_types`, `constants`
- Used by: `Main.f90`, staging loop

**Staging Layer:**
- Purpose: optimal multi-stage mass sizing
- Location: `SRC/staging/`
- Contains: `Staging.f90`, `Root_Finding.f90`, `Stage_Optimization_Loop.f90`, `Rocket_Types.f90`
- Depends on: `typical_data`, `constants`, `Root_Finding_Methods`
- Used by: `Main.f90`, `c_interface`

**Pre-Simulation Layer:**
- Purpose: engine thrust + vehicle geometry sizing
- Location: `SRC/pre-simulation-calcs/`
- Contains: `Thrust_calc.f90`, `Geometry_calc.f90`
- Depends on: `typical_data`, `rocket_types`, `constants`
- Used by: `Main.f90`, `Stage_Optimization_Loop`

**Interface Layer:**
- Purpose: C-bindable bridge to Python
- Location: `SRC/interface/`
- Contains: `C_Interface.f90`, `rocket_lib.py`
- Depends on: `rocket_types`, `typical_data`, `iso_c_binding`
- Used by: `gui.py`, `test_call.py`

## Data Flow

### Primary Request Path (standalone)

1. `data_entry(Rocket)` loads `config.txt` and populates `Rocket%stage(:)%ISP`, `%k_s` (`SRC/inout/Typical_Data.f90:53`)
2. `Payload_Mass_calculator(Rocket)` sets `Rocket%rm_L` (`SRC/pre-staging-calcs/Payload_Mass_calc.f90`)
3. `orbit_speed_calculator` sets global `V_circ` (`SRC/pre-staging-calcs/Orbit_calc.f90`)
4. `STAGING_LOOP(Rocket)` iterates: `STAGING` → `stage_Thrust_calculator` → `DV_loss` until ΔV converges (`SRC/staging/Stage_Optimization_Loop.f90:30-45`)
5. `rocket_geometry_calculation(Rocket)` sizes diameters/lengths (`SRC/pre-simulation-calcs/Geometry_calc.f90`)
6. Results printed per stage (`SRC/Main.f90:19-29`)

### GUI / ctypes Path

1. `gui.py` collects stage ISP/k_s + ΔV + payload (`SRC/gui/gui.py:_run`)
2. `run_staging(...)` → ctypes → `C_Interface.f90:run_staging` sets module globals, builds `Rocket`, calls `STAGING` (`SRC/interface/C_Interface.f90:40-54`)
3. Arrays packed back to Python for display (`SRC/interface/C_Interface.f90:57-90`)

**State Management:**
- Module globals in `typical_data` (shared, not thread-safe) plus an explicit `Rocket_t` object passed by reference. `C_Interface.f90` mutates module globals (`payload_mass`, `number_of_stages`, `V_circ`) before calling `STAGING`.

## Key Abstractions

**`Rocket_t` / `Stage_t`:**
- Purpose: container for all masses, ratios, ISP, thrust, geometry
- Examples: `SRC/staging/Rocket_Types.f90`
- Pattern: plain derived types, one field per physical quantity

**`func_interface` (abstract interface):**
- Purpose: lets root-finding routines accept any scalar function `f(L, Rocket)`
- Examples: `SRC/staging/Root_Finding.f90:3-11`
- Pattern: abstract interface + procedure pointer, used by `Bolzano_Bisection`

## Entry Points

**`program TFG` (standalone):**
- Location: `SRC/Main.f90:1`
- Triggers: `make fortran`
- Responsibilities: runs full pipeline, prints results

**`run_staging` (bind(C)):**
- Location: `SRC/interface/C_Interface.f90:9`
- Triggers: Python ctypes call
- Responsibilities: expose STAGING solver to GUI

## Architectural Constraints

- **Threading:** Single-threaded. No OpenMP, no threading in either Fortran or Python.
- **Global state:** Module globals in `SRC/inout/Typical_Data.f90` (`V_circ`, `orbit_height`, `payload_mass`, `number_of_stages`, per-stage indices) — shared mutable state, mutated by `C_Interface.f90` on the ctypes path. Not reentrant.
- **Circular imports:** None in Python (GUI imports `typical_data_ranges`, `rocket_lib` optional).
- **Dual entry duplication:** `Main.f90` initializes `Rocket%rm_L` via `Payload_Mass_calculator`, but the ctypes path does **not** — a functional gap (see CONCERNS.md).
- **Build ordering:** `SRC/Makefile` declares circular module dependencies between `Staging.o` and `Root_Finding.o` (see CONCERNS.md).

## Anti-Patterns

### Module-Global Implicit State

**What happens:** Configuration and intermediate values live in module globals (`payload_mass`, `V_circ`, `number_of_stages`) rather than being passed as arguments. `C_Interface.f90:40-42` writes them just before calling `STAGING`.
**Why it's wrong:** Two entry points (`Main.f90` vs ctypes) must each remember to initialize these globals; the ctypes path forgets `Rocket%rm_L`, causing inconsistent behavior. Hard to test in isolation.
**Do this instead:** Pass state explicitly as arguments (the `Rocket_t` object already provides this container). `Payload_Mass_calculator` correctly sets `Rocket%rm_L` on the object; the ctypes path should too.

### Duplicated Bridge Wrapper

**What happens:** The ctypes `run_staging` wrapper is defined in both `SRC/interface/rocket_lib.py:45` and inlined again in `SRC/gui/gui.py:80`.
**Why it's wrong:** Two copies of the same 15-argument signature can drift apart; changes must be made twice.
**Do this instead:** Have `gui.py` import `rocket_lib.run_staging` (it already inserts `interface/` on `sys.path` at `SRC/gui/gui.py:29`).

### Heavy `print*` Debug Output in Solver

**What happens:** `STAGING` and `Bolzano_Bisection` emit many `print*` statements per call, and `STAGING_LOOP` prints on every iteration.
**Why it's wrong:** Solvers are called many times; stdout is spammed, slowing the GUI and obscuring real results.
**Do this instead:** Remove or gate debug prints behind a verbosity flag.

## Error Handling

**Strategy:** Minimal. Fortran uses `print*, "WARNING..."` for invalid config/combinations and `stop` only in a couple of cases (e.g. `SRC/inout/Typical_Data.f90:812` unknown diameter setup). No error codes returned from the solver; Python catches generic exceptions from ctypes in `gui.py:941`.

**Patterns:**
- `load_config` prints `WARNING` and skips malformed lines (`SRC/inout/Typical_Data.f90:884-941`)
- `Bolzano_Interval_Start` prints "Valid start point not found" and "Raiz fuera del rango" (`SRC/staging/Root_Finding.f90:33,69`)
- GUI surfaces `QMessageBox` warnings for missing data / DLL errors (`SRC/gui/gui.py:924-943`)

## Cross-Cutting Concerns

**Logging:** None — stdout prints only.
**Validation:** Config parser skips bad lines with warnings; GUI validates stage data presence before running.
**Authentication:** N/A.

---

*Architecture analysis: 2026-08-14*