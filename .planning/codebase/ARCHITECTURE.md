<!-- refreshed: 2026-08-13 -->
# Architecture

**Analysis Date:** 2026-08-13

## System Overview

TFG is a conceptual launch-vehicle design tool: it sizes multi-stage rockets and optimizes staging mass ratios for a given mission (orbit height, payload mass). The system is a two-language hybrid — a Fortran computational core linked into a shared library, wrapped with a C ABI, and driven by a Python (PyQt6) GUI.

```text
┌───────────────────────────────────────────────────────────────────────────┐
│                     UI LAYER (Python / PyQt6)                              │
│  SplashScreen  MainWindow  StageInputWidget  ResultCard                    │
│  `SRC/gui/gui.py`  +  `SRC/gui/typical_data_ranges.py` (generated data)    │
└───────────────────────────────┬───────────────────────────────────────────┘
                                │ ctypes CDLL("librocket.dll")
                                ▼
┌───────────────────────────────────────────────────────────────────────────┐
│                     BRIDGE LAYER                                           │
│  `SRC/interface/rocket_lib.py`        (ctypes wrapper, argtypes/restype)  │
│  `SRC/interface/C_Interface.f90`      (bind(C) subroutine run_staging)    │
└───────────────────────────────┬───────────────────────────────────────────┘
                                │ Fortran call
                                ▼
┌───────────────────────────────────────────────────────────────────────────┐
│                     COMPUTATIONAL CORE (Fortran 90, gfortran)             │
│  staging/        `Staging.f90` `Stage_Optimization_Loop.f90`              │
│  pre-staging/    `Payload_Mass_calc.f90` `Orbit_calc.f90`                 │
│  pre-simulation/ `Thrust_calc.f90`                                        │
└───────────────────────────────┬───────────────────────────────────────────┘
                                │ use typical_data (module globals)
                                ▼
┌───────────────────────────────────────────────────────────────────────────┐
│                     DATA & CONFIG LAYER                                    │
│  `SRC/inout/Typical_Data.f90`  (constants, typical_data, data_entry,      │
│                                 load_config)                              │
│  `SRC/config.txt`              (mission + propellant config)              │
│  `SRC/inout/parse_typical_data.py`  → generates gui data ranges           │
└───────────────────────────────────────────────────────────────────────────┘
```

## Component Responsibilities

| Component | Responsibility | File |
|-----------|----------------|------|
| `program TFG` | Fortran standalone entry: data entry → pre-staging calcs → staging loop → console report | `SRC/Main.f90` |
| `module rocket_types` | Derived types `Stage_t`, `Rocket_t` — the core data model | `SRC/staging/Rocket_Types.f90` |
| `module constants` | Physical constants (`pi`, `g_0`, `Radius`) | `SRC/inout/Typical_Data.f90` (lines 1-6) |
| `module typical_data` | Module-level mission globals + `data_entry`/`load_config` subroutines | `SRC/inout/Typical_Data.f90` |
| `subroutine STAGING` | Stage mass-ratio optimizer: bisection root-find on Lagrange multiplier L, then per-stage masses | `SRC/staging/Staging.f90` |
| `subroutine STAGING_LOOP` | Outer ΔV iteration loop (staging → thrust → ΔV loss → converge) | `SRC/staging/Stage_Optimization_Loop.f90` |
| `subroutine DV_loss` | Empirical ΔV-loss model (K3/K4 correlations on orbit height, T/W) | `SRC/staging/Stage_Optimization_Loop.f90` (lines 34-74) |
| `subroutine Payload_Mass_calculator` | Effective payload = satellite + PAF adapter mass (eq. 11) | `SRC/pre-staging-calcs/Payload_Mass_calc.f90` |
| `subroutine orbit_speed_calculator` | Circular-orbit velocity from orbit height | `SRC/pre-staging-calcs/Orbit_calc.f90` |
| `subroutine stage_Thrust_calculator` | Thrust, mass flow, burn time per stage (hardcoded 3-stage T/W correlations) | `SRC/pre-simulation-calcs/Thrust_calc.f90` |
| `subroutine run_staging` | C-ABI entry point: copies ctypes inputs into globals/Rocket_t, calls STAGING, packs results + min check | `SRC/interface/C_Interface.f90` |
| `rocket_lib.py` | Python ctypes wrapper exposing `run_staging()` returning a results dict | `SRC/interface/rocket_lib.py` |
| `gui.py` | PyQt6 GUI: splash, mission inputs, per-stage ISP/k_s sliders, result cards, save-to-txt | `SRC/gui/gui.py` |
| `parse_typical_data.py` | Code generator: parses `Typical_Data.f90` select-case blocks → `gui/typical_data_ranges.py` | `SRC/inout/parse_typical_data.py` |
| `TEST/Staging/*.f90` | Legacy reference implementation of the same staging math (Howard Curtis, Orbital Mechanics) — not part of the build | `TEST/Staging/main.f90`, `TEST/Staging/data_entry.f90` |

## Pattern Overview

**Overall:** Layered pipeline architecture — "data entry → pre-staging → staging optimization loop → (future) trajectory simulation" — following the phases of the launcher conceptual-design methodology in `README.md`.

**Key Characteristics:**
- **Language split by role:** Fortran 90 owns all numerical computation; Python owns UI, data marshalling (ctypes), and code generation. No logic is shared — the Fortran core is the single source of truth for physics.
- **C-ABI boundary:** `bind(C)` subroutine + flat `c_double`/`c_int` arrays, never passing derived types across the boundary. Python allocates arrays, Fortran fills them.
- **Module-global state as implicit I/O:** `typical_data` globals (`delta_v`, `payload_mass`, `number_of_stages`, `orbit_height`, `*_stage_*` lookups) are read/written by every calculation subroutine instead of being passed as arguments.
- **Phase-oriented directory layout:** `pre-staging-calcs/`, `staging/`, `pre-simulation-calcs/` mirror the design pipeline order; the Makefile compiles them in strict dependency order (`SRC/Makefile` lines 24-32).
- **Generated code:** GUI data tables (`gui/typical_data_ranges.py`) are machine-generated from the Fortran data file via `make parse`.

## Layers

**UI Layer (Python/PyQt6):**
- Purpose: Collect mission + per-stage inputs, display results, export text reports
- Location: `SRC/gui/gui.py`
- Contains: `SplashScreen` (line 582), `StageInputWidget` (line 319), `ResultCard` (line 532), `MainWindow` (line 704), `AppWindow` (line 990), plus a **duplicated** ctypes `run_staging()` (line 80) and `_load_data()` (line 116)
- Depends on: `build/librocket.dll` via ctypes; `gui/typical_data_ranges.py` for ISP/k_s ranges
- Used by: `make gui` target (`SRC/Makefile` line 190)

**Bridge Layer:**
- Purpose: Marshals flat C arrays between Python and Fortran
- Location: `SRC/interface/` — `rocket_lib.py`, `C_Interface.f90`
- Contains: ctypes argtypes declaration (15 pointer args), `run_staging()` Python facade, Fortran `run_staging` C wrapper that builds `Rocket_t`, calls `STAGING`, and re-packs results
- Depends on: compiled `librocket.dll/.so/.dylib` in `build/`; MinGW runtime DLLs on Windows
- Used by: `SRC/test_call.py`; the GUI **does not** import `rocket_lib.py` (it re-declares the ctypes binding itself)

**Computational Core (Fortran):**
- Purpose: All physics — staging optimization, orbit velocity, payload mass, thrust sizing
- Location: `SRC/staging/`, `SRC/pre-staging-calcs/`, `SRC/pre-simulation-calcs/`
- Contains: `STAGING`, `STAGING_LOOP`, `DV_loss`, `Payload_Mass_calculator`, `orbit_speed_calculator`, `stage_Thrust_calculator`
- Depends on: `module typical_data` globals + `module rocket_types` derived types (compile-order enforced by `SRC/Makefile`)
- Used by: `Main.f90` (standalone) and `C_Interface.f90` (library)

**Data & Config Layer:**
- Purpose: Mission parameters, propellant/cycle lookup tables, config file parsing, code generation
- Location: `SRC/inout/`
- Contains: `Typical_Data.f90` (constants + typical_data + data_entry + load_config + to_lower), `parse_typical_data.py`, `SRC/config.txt`
- Depends on: nothing (leaf layer)
- Used by: all layers above

## Data Flow

### Primary Request Path (GUI → library)

1. User selects mission params and per-stage propellant/cycle/ISP/k_s in `gui.py` (`MainWindow._run`, `SRC/gui/gui.py:909`)
2. `gui.py` calls its local `run_staging()` (line 80) → `ctypes.CDLL("librocket.dll").run_staging` (line 96)
3. Fortran `run_staging` receives flat arrays (`SRC/interface/C_Interface.f90:9`), sets module globals (`delta_v`, `payload_mass`, `number_of_stages`), allocates `Rocket%stage(n)`, fills ISP/k_s per stage (lines 44-51)
4. `STAGING(Rocket)` runs the optimizer (`SRC/staging/Staging.f90:1`):
   - `nu_e = ISP * g_0 / 1000` per stage (line 17)
   - Bisection on Lagrange multiplier L in [0.1, 0.8] minimizing residual of `g(L)` (lines 43-69)
   - Mass ratios `k_m` via eq. 18 (line 74), total initial mass via eq. 20 (lines 79-84), propellant/structure masses eqs. 21-22 (lines 88-96), payload ratios, per-stage ΔV via rocket equation (lines 137-141)
   - Minimum check eq. 26 (lines 124-135)
5. Fortran packs results into output arrays; re-checks minimum condition (eq. 26) redundantly (lines 70-90); returns `minimum_found_out`
6. Python receives dict with `total_initial_mass`, `minimum_found`, per-stage `m0/mf/mp/ms/k_m/k_s/k_L/nu_e` (`SRC/interface/rocket_lib.py:71`)
7. `MainWindow` renders summary + `ResultCard`s; "Save Results" writes a formatted `.txt` (`SRC/gui/gui.py:864`)

### Secondary Flow (Fortran standalone CLI)

1. `make fortran` → `program TFG` (`SRC/Main.f90:1`)
2. `data_entry(Rocket)` (`SRC/inout/Typical_Data.f90:50`): `load_config("config.txt")` parses key=value config (lines 822-906), then propellant/cycle select-case blocks fill ISP/k_s lower/upper/mean globals; allocates `Rocket%stage`
3. `Payload_Mass_calculator(Rocket)` → `Rocket%rm_L` (payload + PAF) (`SRC/pre-staging-calcs/Payload_Mass_calc.f90`)
4. `orbit_speed_calculator` → `delta_v` global (circular orbit) (`SRC/pre-staging-calcs/Orbit_calc.f90`)
5. `STAGING_LOOP(Rocket)` (`SRC/staging/Stage_Optimization_Loop.f90:1`): seed ΔV from empirical expression, iterate `STAGING` → `stage_Thrust_calculator` → `DV_loss` until `err < 1e-3`
6. Console report of per-stage ISP, masses, ratios (`SRC/Main.f90:17-27`)

### Code-Generation Flow

1. Engineer edits propellant/cycle data in `SRC/inout/Typical_Data.f90` (select-case blocks with `First/Second/Third_stage_ISP_*` assignments)
2. `make parse` runs `SRC/inout/parse_typical_data.py` — a regex state machine parses the Fortran blocks (only first-stage block, since all three are identical, line 62) and writes `SRC/gui/typical_data_ranges.py` (`PROPELLANTS`, `CYCLES`, `TYPICAL_DATA_STAGE_1..3`, `TYPICAL_DATA_BY_STAGE`)
3. GUI loads the generated file at startup (`gui.py:116` `_load_data`)

**State Management:**
- Mission state lives in **module-level globals** of `module typical_data` (`SRC/inout/Typical_Data.f90:36-47`): `delta_v`, `orbit_height`, `payload_mass`, `number_of_stages`, plus 18 `*_stage_ISP/ks_*` range variables. Every calc subroutine imports and mutates these — this is implicit global state, not passed parameters.
- Vehicle state lives in `type(Rocket_t)` with allocatable `stage(:)` array; owned by the caller (`Main.f90`, `C_Interface.f90`) and passed `intent(inout)` into subroutines.
- GUI state: module-level `PROPELLANTS`/`CYCLES`/`TYPICAL_DATA_BY_STAGE` loaded once; `_last_results`/`_last_configs` cached on `MainWindow` for the save feature.

## Key Abstractions

**`type(Rocket_t)` / `type(Stage_t)`:**
- Purpose: The single vehicle data model — per-stage (m_0, m_f, m_L, m_s, m_p, k_m, k_s, k_L, ISP, T, m_dot, t_burn, D_v, nu_e) and whole-rocket aggregates (rm_*, rk_*, rt_burn)
- Examples: `SRC/staging/Rocket_Types.f90:3-36`
- Pattern: Fortran derived types; `stage(:)` is allocatable — must be allocated by the caller before use

**`run_staging` C-ABI subroutine:**
- Purpose: The only exported symbol. Flat-array in/out contract, no derived types across the boundary
- Examples: `SRC/interface/C_Interface.f90:9-94`
- Pattern: `bind(C, name="run_staging")`; scalar args passed by reference (no VALUE attribute, lines 18-20); arrays passed as `c_double` pointers; mirrors module globals into `Rocket_t`

**`module typical_data` globals:**
- Purpose: Mission parameters and engine lookup data shared by all calculation modules
- Examples: `SRC/inout/Typical_Data.f90:8-47`
- Pattern: global variables in a module (`delta_v`, `payload_mass`, `number_of_stages`, `orbit_height`, propellant/cycle indices, ISP/k_s ranges)

**`rocket_lib.py` ctypes facade:**
- Purpose: Type-safe Python entry point; hides ctypes boilerplate; returns dict results
- Examples: `SRC/interface/rocket_lib.py:45-88`
- Pattern: declares `restype`/`argtypes` once at module import, builds ctypes arrays per call

**`typical_data_ranges.py` generated tables:**
- Purpose: Single source for GUI dropdowns + slider ranges; keyed by `(propellant_index, cycle_index)`, `None` marks invalid combinations
- Examples: `SRC/gui/typical_data_ranges.py` (PROPELLANTS line 12, CYCLES line 23, TYPICAL_DATA_STAGE_1 line 35)
- Pattern: auto-generated; never hand-edit

## Entry Points

**Fortran standalone:**
- Location: `SRC/Main.f90`
- Triggers: `make fortran` (`SRC/Makefile:169`)
- Responsibilities: full pipeline incl. config file parsing and ΔV-loss iteration loop; console output

**Python GUI:**
- Location: `SRC/gui/gui.py` (`if __name__ == "__main__"` line 1023)
- Triggers: `make gui` (`SRC/Makefile:190`); requires prebuilt `build/librocket.dll` + MinGW runtime DLLs
- Responsibilities: interactive sizing; only runs `STAGING` (no thrust/ΔV-loss loop — receives `delta_v` directly)

**Scripted call example:**
- Location: `SRC/test_call.py`
- Triggers: `python test_call.py` from `SRC/interface/` or with `interface/` on `sys.path`
- Responsibilities: smoke test of the ctypes bridge

**Legacy prototype:**
- Location: `TEST/Staging/main.f90` (+ `data_entry.f90`)
- Triggers: manual compile with gfortran (no Makefile)
- Responsibilities: historical reference — Newton–Raphson variant of the same optimal-staging equations (Curtis §11.7); hardcoded 3-stage data

## Architectural Constraints

- **Threading:** Single-threaded everywhere. The GUI calls the Fortran DLL synchronously on the UI thread (`SRC/gui/gui.py:909` `_run`) — a slow solver run blocks the interface. `QThread` is imported (`gui.py:16`) but never instantiated.
- **Global state:** `module typical_data` globals are mutated by `run_staging` (`SRC/interface/C_Interface.f90:40-42`) and read by all calcs — only one mission can be in flight per process. Calling `run_staging` twice in the same process mutates the same globals.
- **Stage count:** `number_of_stages` is configurable, but `SRC/pre-simulation-calcs/Thrust_calc.f90` hardcodes `dimension(3)` thrust arrays with fixed per-stage correlations (lines 9-19), and `gui.py` limits the stage spinbox to 1-3 (`gui.py:764`). The staging math itself is N-stage general.
- **Compile order:** Modules must compile in dependency order (rocket_types → typical_data → calcs → interface → main); enforced manually by Makefile rules, not automatic dependency resolution (`SRC/Makefile:106-148`).
- **Platform:** Build is OS-conditional in the Makefile (Windows/MinGW-TDM, macOS, Linux) with runtime DLL copying for Windows (`SRC/Makefile:41-79, 156-162`).
- **Circular imports:** None — dependency direction is strictly GUI → bridge → core → data. The GUI's `sys.path.insert(0, interface)` (`gui.py:29`) is vestigial (rocket_lib is not actually imported).

## Anti-Patterns

### Duplicated ctypes bridge in the GUI

**What happens:** `gui.py` re-declares the full ctypes `argtypes` list and a second `run_staging()` (`SRC/gui/gui.py:61-110`) instead of importing `SRC/interface/rocket_lib.py`, even though `interface/` is added to `sys.path` at line 29. `test_call.py` and the GUI can drift apart.
**Why it's wrong:** Two sources of truth for the ABI contract; a change in `C_Interface.f90` signatures must be updated in three places.
**Do this instead:** Import `rocket_lib.run_staging` from `SRC/interface/rocket_lib.py` in the GUI; keep the DLL loading in one module.

### Module globals as implicit subroutine I/O

**What happens:** Subroutines like `STAGING` read/write `delta_v`, `payload_mass`, `number_of_stages` globals from `module typical_data` with no explicit arguments (`SRC/staging/Staging.f90:15`, `SRC/staging/Stage_Optimization_Loop.f90:11-14`).
**Why it's wrong:** Hidden coupling — call order matters, re-entrancy is impossible, and `C_Interface.f90` must manually mirror globals into the derived type before calling (lines 40-51).
**Do this instead:** Pass mission parameters into subroutines via the `Rocket_t` type (fields exist: `Rocket%rm_L`, etc.) or an explicit `Mission_t` argument.

### Uninitialized-variable logic in DV_loss

**What happens:** `expo = -0.333d0*DV_loss2/(g_0*ISP)` uses `DV_loss2` and `ISP` before they are computed (`SRC/staging/Stage_Optimization_Loop.f90:62`), and `V_rot` is hardcoded to 0 (line 50).
**Why it's wrong:** Compiler-dependent garbage feeds `T_3s`/`T_mix`/`DV_new`; the loop convergence criterion (`err < 1e-3`, line 17) may be met by accident. Commented-out K1/K2 code (lines 52-56) indicates an abandoned alternative model.
**Do this instead:** Compute `DV_loss2` before use or delete the unused `expo` branch; either finish the `V_rot` (launch-site rotation) model or remove it.

### Legacy prototype duplicated in TEST/

**What happens:** `TEST/Staging/` reimplements the optimal-staging equations with hardcoded constants (`data_entry.f90`) and a Newton–Raphson solver (`main.f90`), separate from the production bisection solver in `SRC/staging/Staging.f90`.
**Why it's wrong:** Two implementations of the same physics drift independently; the TEST version is not wired into any test runner or the Makefile.
**Do this instead:** Either delete it (git history preserves it) or convert it into actual regression tests asserting both solvers agree.

### Hardcoded 3-stage thrust model

**What happens:** `stage_Thrust_calculator` uses `real(8), dimension(3)` vectors and per-stage-index T/W correlations (`SRC/pre-simulation-calcs/Thrust_calc.f90:9-19`) regardless of `number_of_stages`.
**Why it's wrong:** Indexing `stage_thrust(2)`/`stage_thrust(3)` with fewer than 3 stages is out-of-bounds; with more than 3 stages the loop silently leaves stage 4+ with zero thrust.
**Do this instead:** Derive thrust from `Rocket%stage(i)%m_0` with a single T/W correlation parameterized per stage, or gate the model on `number_of_stages`.

## Error Handling

**Strategy:** Defensive prints in Fortran, UI message boxes in Python, no exceptions across the ABI.

**Patterns:**
- Fortran: `print*, "WARNING ..."` for invalid propellant/cycle combinations (`SRC/inout/Typical_Data.f90:110`) and "Raiz fuera del rango" when bisection bracket fails (`SRC/staging/Staging.f90:54`); computation continues with whatever state results
- Python: `try/except` around the DLL call → `QMessageBox.critical` (`SRC/gui/gui.py:933-943`); input validation via `StageInputWidget` validity signals that disable the Run button (`gui.py:853-857`); "missing data" warning at line 924
- Cross-language: the C ABI has no error channel — `minimum_found_out` integer is the only quality signal (check of eq. 26, `SRC/interface/C_Interface.f90:74-90`)

## Cross-Cutting Concerns

**Logging:** None — Fortran uses `print*` to stdout, Python uses `print` for DLL-location warnings (`gui.py:52-55`). No log framework, no levels, no file output (GUI result export is user-triggered, `gui.py:864`).
**Validation:** GUI-side only — slider ranges and combo availability enforced in `StageInputWidget`; no bounds validation on mission params (ΔV spin allows 0.1-100 km/s, `gui.py:748`). Fortran accepts any values; bisection may fail silently.
**Authentication:** Not applicable — local desktop tool, no network surface.
**Configuration:** `SRC/config.txt` key=value format (`;` and `#` comments) parsed by `load_config` (`SRC/inout/Typical_Data.f90:822`); parser is case-insensitive via `to_lower` (line 908).

---

*Architecture analysis: 2026-08-13*