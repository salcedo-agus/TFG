# Codebase Structure

**Analysis Date:** 2026-08-13

## Directory Layout

```
TFG/
├── SRC/                       # All source code (Fortran + Python)
│   ├── Main.f90               # Fortran standalone entry point (program TFG)
│   ├── Makefile               # Build: library, executable, GUI, parse, clean
│   ├── config.txt             # Mission & propellant configuration (key=value)
│   ├── test_call.py           # Scripted smoke test of the ctypes bridge
│   ├── inout/                 # Data/config layer + code generator
│   │   ├── Typical_Data.f90   # constants + typical_data modules, data_entry,
│   │   │                       # load_config, to_lower (917 lines)
│   │   └── parse_typical_data.py  # Generates gui/typical_data_ranges.py
│   ├── interface/             # Python↔Fortran bridge
│   │   ├── C_Interface.f90    # bind(C) run_staging export
│   │   └── rocket_lib.py      # ctypes wrapper
│   ├── gui/                   # PyQt6 desktop GUI
│   │   ├── gui.py             # Full GUI app (1028 lines)
│   │   └── typical_data_ranges.py  # AUTO-GENERATED ISP/k_s tables
│   ├── staging/               # Core optimizer
│   │   ├── Rocket_Types.f90   # Stage_t / Rocket_t derived types
│   │   ├── Staging.f90        # STAGING solver (bisection on Lagrange multiplier)
│   │   └── Stage_Optimization_Loop.f90  # STAGING_LOOP + DV_loss
│   ├── pre-staging-calcs/     # Calculations before staging
│   │   ├── Orbit_calc.f90     # orbit_speed_calculator
│   │   └── Payload_Mass_calc.f90  # Payload_Mass_calculator (PAF adapter)
│   └── pre-simulation-calcs/  # Calculations feeding trajectory sim (future)
│       └── Thrust_calc.f90    # stage_Thrust_calculator (T, m_dot, t_burn)
├── TEST/
│   └── Staging/               # Legacy reference prototype (not in build)
│       ├── main.f90           # Newton–Raphson optimal-staging solver
│       └── data_entry.f90     # Hardcoded 3-stage parameters
├── build/                     # Compiled artifacts (gitignored)
│   ├── librocket.dll/.so/.dylib  # Shared library output
│   ├── rocket.exe             # Fortran standalone executable
│   ├── *.o / *.mod            # Objects + module files
│   └── libgfortran*.dll etc.  # MinGW runtime DLLs (copied on Windows)
├── .planning/                 # GSD planning artifacts (codebase maps etc.)
└── README.md                  # Project overview (Spanish) + objectives
```

## Directory Purposes

**SRC/:**
- Purpose: All source code — Fortran computational core, Python GUI, code generator, build system
- Contains: one directory per architecture layer + entry points + Makefile + config
- Key files: `SRC/Makefile`, `SRC/Main.f90`, `SRC/config.txt`

**SRC/inout/:**
- Purpose: Mission data entry, config parsing, physical constants, and the Fortran→Python data generator
- Contains: `Typical_Data.f90` (defines `module constants`, `module typical_data`, `data_entry`, `load_config`), `parse_typical_data.py`
- Key files: `SRC/inout/Typical_Data.f90` (single source of truth for ISP/k_s tables), `SRC/inout/parse_typical_data.py`
- Note: parser is invoked via `make parse` (`SRC/Makefile:182`); generated output lands in `gui/`

**SRC/interface/:**
- Purpose: The only place where Python and Fortran meet — ctypes wrapper + C-ABI export
- Contains: `C_Interface.f90` (exports `run_staging`), `rocket_lib.py`
- Key files: both; they form one contract pair (argtypes in Python must match the `bind(C)` signature)

**SRC/gui/:**
- Purpose: PyQt6 desktop application — splash screen, mission inputs, stage sliders, result cards, text export
- Contains: `gui.py` (all UI classes in one file), `typical_data_ranges.py` (generated)
- Key files: `SRC/gui/gui.py`; do NOT hand-edit `typical_data_ranges.py`

**SRC/staging/:**
- Purpose: Optimal-staging math — derived types, root finding, outer iteration loop
- Contains: `Rocket_Types.f90`, `Staging.f90`, `Stage_Optimization_Loop.f90`
- Key files: `SRC/staging/Rocket_Types.f90` (data model used by every module)

**SRC/pre-staging-calcs/:**
- Purpose: Calculations that must run before staging — orbit velocity, effective payload mass
- Contains: `Orbit_calc.f90`, `Payload_Mass_calc.f90`

**SRC/pre-simulation-calcs/:**
- Purpose: Calculations that feed trajectory simulation (currently just thrust sizing)
- Contains: `Thrust_calc.f90`

**TEST/:**
- Purpose: Standalone test/reference code, not wired into the build
- Contains: `TEST/Staging/` legacy prototype (main.f90 + data_entry.f90)
- Key files: `TEST/Staging/main.f90`

**build/:**
- Purpose: All compiled outputs — shared library, executable, objects, module files, MinGW runtime DLLs
- Contains: `librocket.dll` (or `.so`/`.dylib`), `rocket.exe`, `*.o`, `*.mod`, runtime DLLs
- Generated: Yes (by `make all` / `make fortran`)
- Committed: No (gitignored — `*.dll`, `*.so`, `*.o`, `*.mod` in `.gitignore`)

## Key File Locations

**Entry Points:**
- `SRC/Main.f90`: Fortran standalone (`make fortran`)
- `SRC/gui/gui.py`: Python GUI (`make gui`; entry at line 1023)
- `SRC/test_call.py`: scripted bridge smoke test
- `SRC/inout/parse_typical_data.py`: code generator (`make parse`; `main()` at line 271)

**Configuration:**
- `SRC/Makefile`: compiler (gfortran), flags, platform detection, all targets
- `SRC/config.txt`: mission parameters + propellant/cycle indices
- `.gitignore`: build artifacts ignored

**Core Logic:**
- `SRC/staging/Staging.f90`: the staging solver
- `SRC/staging/Stage_Optimization_Loop.f90`: ΔV convergence loop + loss model
- `SRC/interface/C_Interface.f90`: ABI export
- `SRC/inout/Typical_Data.f90`: data tables + config parser

**Testing:**
- `SRC/test_call.py`: manual bridge test (prints results)
- `TEST/Staging/`: legacy reference implementation (manual gfortran compile)

## Naming Conventions

**Files:**
- Fortran source: `PascalCase.f90` (e.g., `Rocket_Types.f90`, `Typical_Data.f90`, `Payload_Mass_calc.f90`, `Stage_Optimization_Loop.f90`)
- Fortran main program: `Main.f90`; test prototype uses lowercase `main.f90`
- Python: `snake_case.py` (e.g., `rocket_lib.py`, `parse_typical_data.py`, `typical_data_ranges.py`, `test_call.py`)
- One module per file for the data layer, but note `Staging.f90` and `Stage_Optimization_Loop.f90` contain standalone subroutines (no module wrapper) — follow whichever pattern the file you edit already uses

**Fortran identifiers:**
- Modules: `snake_case` (`rocket_types`, `typical_data`, `constants`, `c_interface`)
- Derived types: `Type_t` suffix (`Stage_t`, `Rocket_t`) — fields use `snake_case` (`m_0`, `k_m`, `nu_e`, `t_burn`)
- Subroutines/functions: UPPERCASE for pipeline stages (`STAGING`, `STAGING_LOOP`, `DV_loss`), mixed for support routines (`data_entry`, `load_config`, `stage_Thrust_calculator`, `orbit_speed_calculator`)
- Globals: `snake_case` with descriptive names (`delta_v`, `orbit_height`, `payload_mass`, `number_of_stages`, `First_stage_ISP_lower`)
- Units documented in inline comments (`! [km/s]`, `! [kg]`)

**Python identifiers:**
- Functions: `snake_case` (`run_staging`, `_load_data`, `_print_results`, `_rebuild_stage_inputs`)
- Classes: `PascalCase` (`StageInputWidget`, `ResultCard`, `SplashScreen`, `MainWindow`, `AppWindow`)
- Qt widgets stored as `self.<name>_<type>` attributes (`self.dv_spin`, `self.pl_spin`, `self.run_btn`)
- Section banners with `# ── ... ──` comment style (`gui.py:19, 112`)

## Where to Add New Code

**New propellant/cycle data (typical):**
- Edit the select-case blocks in `SRC/inout/Typical_Data.f90` (three stage blocks, identical structure)
- Run `make parse` from `SRC/` to regenerate `SRC/gui/typical_data_ranges.py`
- GUI picks it up automatically on next launch

**New calculation module (e.g., trajectory simulation):**
- Create a new phase directory `SRC/<phase>-calcs/` or add to an existing one
- Add the source to `SRC/Makefile` OBJS in dependency order (`SRC/Makefile:24-32`) + a compile rule (lines 106-143); `use typical_data` and `use rocket_types` for globals/types
- Expose via C ABI: add an exported subroutine in `SRC/interface/C_Interface.f90` and mirror the signature in `SRC/interface/rocket_lib.py` (and ideally update `gui.py` to import the wrapper instead of duplicating it)
- Standalone wiring: call it from `SRC/Main.f90` in pipeline order

**New GUI feature:**
- UI logic in `SRC/gui/gui.py` (widget classes near their section banner; `MainWindow._build_ui` at line 712 for layout; `_run` at line 909 for the solve action)
- Any data table change still routes through `SRC/inout/Typical_Data.f90` + `make parse`

**New utility/helper (Python):**
- Bridge helpers: `SRC/interface/rocket_lib.py`; parsing/generation helpers: `SRC/inout/parse_typical_data.py`
- No shared Python utils module exists yet — if one is needed, create `SRC/interface/` or a new `SRC/common/` (must be added to sys.path by callers; `gui.py:29` shows the existing pattern)

**New tests:**
- Follow the existing patterns: scripted Python call (`SRC/test_call.py` style) or standalone Fortran program under `TEST/`; there is no test runner or framework — any new harness must be self-contained

**Build-system change (new target/dependency):**
- Edit `SRC/Makefile`; keep platform-conditional blocks (Windows vs Unix) for paths, DLL copying, and clean commands

## Special Directories

**build/:**
- Purpose: Compiled outputs + runtime DLLs
- Generated: Yes
- Committed: No (see `.gitignore`)

**SRC/gui/__pycache__/:**
- Purpose: Python bytecode cache for gui modules
- Generated: Yes
- Committed: No (`__pycache__/` in `.gitignore`)

**TEST/Staging/:**
- Purpose: Legacy reference implementation of the staging math (no Makefile, not compiled by the project)
- Generated: No
- Committed: Yes

**.planning/:**
- Purpose: GSD planning artifacts, including these codebase maps
- Generated: Yes (by GSD workflow)
- Committed: Yes

---

*Structure analysis: 2026-08-13*