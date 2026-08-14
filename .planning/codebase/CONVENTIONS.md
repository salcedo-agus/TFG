# Coding Conventions

**Analysis Date:** 2026-08-14

## Naming Patterns

**Files:**
- Fortran: PascalCase for derived-type modules (`Rocket_Types.f90`), mixed for subroutine files (`Orbit_calc.f90`, `Staging.f90`, `Geometry_calc.f90`)
- Python: `snake_case.py` (`rocket_lib.py`, `parse_typical_data.py`)
- Auto-generated file marked clearly: `typical_data_ranges.py` header says "DO NOT EDIT MANUALLY"

**Functions/Subroutines:**
- Fortran subroutines: `PascalCase` or `snake_case` inconsistently — `STAGING`, `DV_loss`, `data_entry`, `load_config`, `orbit_speed_calculator`, `stage_Thrust_calculator`, `rocket_geometry_calculation`, `Payload_Mass_calculator`. Mixed style is a known inconsistency (newer code leans snake_case: `stage_Thrust_calculator`, `rocket_geometry_calculation`).

**Variables:**
- Fortran: `snake_case` for module globals (`orbit_height`, `payload_mass`), short names for locals (`a`, `b`, `c`, `i`, `L`, `T`)
- Spanish comments and mixed English/Spanish warning messages ("Raiz fuera del rango", "WARNING este no es valido")

**Types:**
- Derived types: `Stage_t`, `Rocket_t` (PascalCase + `_t` suffix), fields snake_case (`m_0`, `m_i`, `k_m`, `nu_e`)

## Code Style

**Formatting:**
- No formatter configured (no fprettify, no pre-commit)
- gfortran `-O2 -Wall` in `SRC/Makefile:12`
- Fixed tab/space mix: `Typical_Data.f90` uses tab indentation in select-case blocks; `Staging.f90` uses spaces

**Linting:**
- Python: no linter config (no ruff/black/flake8 config files present)
- Fortran: only `-Wall` at compile time

## Import Organization

**Python order:**
1. stdlib (`sys`, `os`, `ctypes`, `re`)
2. third-party (`PyQt6.*`)
3. local generated module (`typical_data_ranges` loaded via `importlib` + `sys.path` injection in `gui.py:114-130`)

**Path Aliases:**
- None; GUI uses relative path juggling: `os.path.dirname(os.path.abspath(__file__))` to locate `interface/`, `build/`, and `gui/` (`gui.py:23-29`)

## Error Handling

**Patterns:**
- Fortran: print `WARNING: ...` and continue (config parser `Typical_Data.f90:884-941`); `stop` only on fatal config errors (missing file `:863-866`, unknown diameter setup `:812`)
- Python: try/except around ctypes call → `QMessageBox.critical` (`gui.py:933-943`)
- Solver functions return no error codes; validity only checked via the eq-26 minimum check (`Staging.f90:125-137`)

## Logging

**Framework:** None — `print*` (Fortran) / `print()` (Python) only

**Patterns:**
- Debug prints inside the solver loop are heavy and unconditional (`Root_Finding.f90:63,75-82`, `Staging.f90:57`)

## Comments

**When to Comment:**
- Section banners with `!===== ... =====` dividers naming the governing equation (e.g. `Staging.f90:80` "initial mass of the Rocket is solved using eq 20")
- Spanish and English mixed; occasional inline equation references ("eq 26")

**JSDoc/TSDoc:**
- Python modules carry docstrings (module-level, e.g. `rocket_lib.py:1-5`)
- Fortran: no doc-comment convention

## Function Design

**Size:**
- `Typical_Data.f90` `data_entry` is ~800 lines of select-case data tables — the dominant pattern is data-as-code
- Subroutines otherwise small (10–100 lines)

**Parameters:**
- Solver subroutines take `type(Rocket_t)` by `intent(inout)` and mutate fields; module globals used implicitly where convenient (`payload_mass`, `number_of_stages`)

**Return Values:**
- Functions used for scalar results (`g(L, Rocket)`); most work done in subroutines mutating the Rocket object

## Module Design

**Exports:**
- Fortran modules export everything (no `private` statements anywhere); `use` brings in all module globals
- Python modules are small single-purpose scripts

**Barrel Files:**
- None

---

*Convention analysis: 2026-08-14*