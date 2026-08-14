# Codebase Structure

**Analysis Date:** 2026-08-14

## Directory Layout

```
[project-root]/
├── SRC/                      # All source code (Fortran + Python)
│   ├── Main.f90              # Standalone Fortran entry point
│   ├── Makefile              # Build system (all/fortran/gui/parse/clean)
│   ├── config.txt            # Mission configuration input
│   ├── test_call.py          # Manual DLL smoke test (Python)
│   ├── staging/              # Staging solver core
│   │   ├── Rocket_Types.f90        # Stage_t / Rocket_t derived types
│   │   ├── Root_Finding.f90        # Bolzano bisection root finding (new)
│   │   ├── Staging.f90             # STAGING solver + rocket_functions
│   │   └── Stage_Optimization_Loop.f90  # ΔV iteration loop + DV_loss
│   ├── pre-staging-calcs/    # Mission-level calculations
│   │   ├── Orbit_calc.f90          # Circular orbit velocity
│   │   └── Payload_Mass_calc.f90   # Effective payload (incl. PAF)
│   ├── pre-simulation-calcs/ # Vehicle sizing after staging
│   │   ├── Thrust_calc.f90         # Empirical stage thrust / burn time
│   │   └── Geometry_calc.f90       # Statistical diameter/volume/length (new)
│   ├── inout/                # I/O and data tables
│   │   ├── Typical_Data.f90        # constants, config globals, ISP/ks tables, load_config
│   │   └── parse_typical_data.py   # Codegen: Typical_Data.f90 → typical_data_ranges.py
│   ├── interface/            # Fortran↔Python bridge
│   │   ├── C_Interface.f90         # bind(C) run_staging
│   │   └── rocket_lib.py           # ctypes wrapper
│   └── gui/                  # PyQt6 GUI
│       ├── gui.py                  # Main GUI (splash + staging panel)
│       └── typical_data_ranges.py  # AUTO-GENERATED ISP/ks data (do not edit)
├── TEST/
│   └── Staging/              # Stale standalone prototypes (not in build)
│       ├── main.f90                # Old optimal-staging prototype (references modules that no longer exist)
│       └── data_entry.f90          # Old data entry prototype
├── build/                    # Compiled artifacts (gitignored: *.o, *.mod, *.dll)
└── .planning/                # GSD planning artifacts
```

## Directory Purposes

**SRC/staging:**
- Purpose: Optimal multi-stage mass-ratio solver
- Contains: derived types, root-finding, staging equations, ΔV iteration
- Key files: `Staging.f90`, `Root_Finding.f90`, `Rocket_Types.f90`

**SRC/pre-staging-calcs:**
- Purpose: mission-level inputs (orbit speed, payload mass with PAF)
- Contains: 2 external subroutines
- Key files: `Orbit_calc.f90`, `Payload_Mass_calc.f90`

**SRC/pre-simulation-calcs:**
- Purpose: post-staging vehicle sizing
- Contains: thrust estimation, statistical geometry
- Key files: `Thrust_calc.f90`, `Geometry_calc.f90`

**SRC/inout:**
- Purpose: config parsing, ISP/structural-coefficient tables, codegen
- Contains: `Typical_Data.f90` (958 lines, largest file), `parse_typical_data.py`
- Key files: `Typical_Data.f90`, `parse_typical_data.py`

**SRC/interface:**
- Purpose: C-bindable bridge + Python ctypes wrapper
- Key files: `C_Interface.f90`, `rocket_lib.py`

**SRC/gui:**
- Purpose: PyQt6 desktop GUI
- Contains: `gui.py` (1028 lines), generated data file
- Key files: `gui.py`, `typical_data_ranges.py`

## Key File Locations

**Entry Points:**
- `SRC/Main.f90`: standalone Fortran executable (all targets)
- `SRC/interface/C_Interface.f90:9` (`run_staging`): ctypes entry
- `SRC/gui/gui.py:1023`: Python GUI entry

**Configuration:**
- `SRC/config.txt`: mission parameters consumed by `load_config`
- `SRC/Makefile`: build/launch configuration

**Core Logic:**
- `SRC/staging/Staging.f90`: the STAGING solver (mass equations 18–23, min-check eq 26)
- `SRC/staging/Stage_Optimization_Loop.f90`: ΔV convergence loop + empirical loss model
- `SRC/staging/Root_Finding.f90`: bisection on the staging function `g(L)`
- `SRC/inout/Typical_Data.f90`: engine performance tables (select-case driven)

**Testing:**
- `SRC/test_call.py`: DLL smoke test (manual)
- `TEST/Staging/`: stale prototypes, NOT part of the build

## Naming Conventions

**Files:**
- Fortran: `PascalCase.f90` (`Rocket_Types.f90`, `Orbit_calc.f90`, `Stage_Optimization_Loop.f90`) — mixed; some `snake_case` (`Geometry_calc.f90` was `Geometry_calc` → `rocket_geometry_calculation`)
- Python: `snake_case.py` (`rocket_lib.py`, `parse_typical_data.py`)
- Module files (derived types): `PascalCase`; external-subroutine files: mixed

**Directories:**
- kebab-case: `pre-staging-calcs`, `pre-simulation-calcs`, `inout`, `interface`, `gui`, `staging`

## Where to Add New Code

**New Feature:**
- Primary code: match the pipeline layer — mission calcs → `SRC/pre-staging-calcs/`, staging math → `SRC/staging/`, vehicle sizing → `SRC/pre-simulation-calcs/`, I/O → `SRC/inout/`
- Tests: no test suite exists; add to `SRC/test_call.py` pattern or create `TEST/` properly

**New Component/Module:**
- Implementation: `SRC/<layer>/<Name>.f90`; add to `SRC/Makefile` `OBJS` list AND add an explicit `.o` rule with correct dependencies (currently order-sensitive, see CONCERNS.md)

**Utilities:**
- Shared helpers: extend `SRC/inout/Typical_Data.f90` (constants/config) or a new module in `SRC/staging/`

## Special Directories

**build/:**
- Purpose: compiled `.o`/`.mod` files + `librocket.dll`/`.so` + MinGW runtime DLLs
- Generated: Yes
- Committed: No (gitignored via `*.o`, `*.mod`, `*.dll`, `*.so` in `.gitignore`)

**TEST/:**
- Purpose: standalone prototypes / validation code
- Generated: No
- Committed: Yes (but stale — see CONCERNS.md)

---

*Structure analysis: 2026-08-14*