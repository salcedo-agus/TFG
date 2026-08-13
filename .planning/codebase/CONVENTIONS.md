# Coding Conventions

**Analysis Date:** 2026-08-13

The codebase is a mixed Fortran 90 (computational core) + Python 3 (GUI / bridge / codegen) project. Conventions are split by language; Fortran is the primary computational language, Python wraps it via a C-interface DLL.

## Naming Patterns

**Fortran — Files:**
- `*.f90` free-form Fortran 90 source. One or more modules/subroutines per file.
- File names are `Pascal_Case.f90` matching the primary symbol inside, but NOT consistently: `Staging.f90` contains `STAGING` and `g`, `Rocket_Types.f90` contains `rocket_types` (lowercase module in Pascal file), `Typical_Data.f90` contains lowercase modules `constants` + `typical_data`.
- Directory names use kebab-case: `pre-staging-calcs/`, `pre-simulation-calcs/` (see `SRC/` layout).

**Fortran — Modules:**
- Module names are lowercase `snake_case`: `rocket_types`, `typical_data`, `constants`, `c_interface` (`SRC/staging/Rocket_Types.f90:1`, `SRC/inout/Typical_Data.f90:1`, `SRC/interface/C_Interface.f90:1`).

**Fortran — Types:**
- Derived types end in `_t`: `Stage_t`, `Rocket_t` (`SRC/staging/Rocket_Types.f90:3,22`).

**Fortran — Subroutines/Functions:**
- Mixed and inconsistent. Observed styles:
  - ALL_CAPS for the solver core: `STAGING`, `STAGING_LOOP` (`SRC/staging/Staging.f90:1`, `SRC/staging/Stage_Optimization_Loop.f90:1`)
  - snake_case: `data_entry`, `load_config`, `to_lower`, `orbit_speed_calculator` (`SRC/inout/Typical_Data.f90:50,822,908`, `SRC/pre-staging-calcs/Orbit_calc.f90:1`)
  - Pascal-ish/mixed: `Payload_Mass_calculator`, `stage_Thrust_calculator` (`SRC/pre-staging-calcs/Payload_Mass_calc.f90:1`, `SRC/pre-simulation-calcs/Thrust_calc.f90:1`)
- **Prescription:** use lowercase `snake_case` for new subroutines/functions; keep the ALL_CAPS `STAGING`/`STAGING_LOOP` names untouched (call sites in `SRC/Main.f90:14` and `SRC/interface/C_Interface.f90:54`).

**Fortran — Variables:**
- `real(8)` for double precision everywhere (never `double precision` or `real*8`); `integer` plain. See `SRC/staging/Rocket_Types.f90:4-19`.
- Loop indices are single letters `i` (`SRC/staging/Staging.f90:13`).
- Descriptive lowercase names with underscores: `number_of_stages`, `orbit_height`, `payload_mass`, `delta_v` (`SRC/inout/Typical_Data.f90:36-39`).
- Stage-specific globals use `First_stage_*`, `Second_stage_*`, `Third_stage_*` prefixes with `_lower`/`_upper`/`_mean` suffixes (`SRC/inout/Typical_Data.f90:11-33`).
- Short math variables (Lagrange multiplier `L`, root-finding `a,b,c,h,res`) are single letters with a trailing comment explaining meaning (`SRC/staging/Staging.f90:7-11`).

**Python — Functions/Variables:**
- `snake_case` for functions and locals: `run_staging`, `_load_data`, `parse_fortran`, `write_output`, `_flush`, `_clean_name` (`SRC/interface/rocket_lib.py:45`, `SRC/inout/parse_typical_data.py:55,180,194,209`).
- Private helpers prefixed with single underscore: `_flush`, `_clean_name`, `_load_data`, `_build`, `_run`, `_print_results` (`SRC/gui/gui.py:116,327,909`).
- UPPER_SNAKE_CASE module-level constants: `PROPELLANTS`, `CYCLES`, `TYPICAL_DATA_BY_STAGE`, color palette `BG_DARK`, `ACCENT`, regexes `RE_PROP_CASE` etc. (`SRC/gui/gui.py:130,134-145`, `SRC/gui/typical_data_ranges.py:12`, `SRC/inout/parse_typical_data.py:28-52`).
- Path constants at module top: `GUI_DIR`, `ROOT_DIR`, `BUILD_DIR`, `SCRIPT_DIR`, `FORTRAN_FILE`, `OUTPUT_FILE` (`SRC/gui/gui.py:23-26`, `SRC/inout/parse_typical_data.py:21-24`).

**Python — Classes/Methods:**
- Classes are `PascalCase`: `StageInputWidget`, `ResultCard`, `SplashScreen`, `MainWindow`, `AppWindow`, `NoScrollComboBox` (`SRC/gui/gui.py:315,319,532,582,704,990`).
- Methods are `snake_case`; private ones prefixed `_`: `_build`, `_prop_changed`, `_update_ranges`, `get_values` (`SRC/gui/gui.py:327,397,455,512`).
- Widget attributes named after the control: `self.isp_slider`, `self.ks_slider`, `self.dv_spin`, `self.run_btn` (`SRC/gui/gui.py:352,369,747,780`).

## Code Style

**Fortran:**
- Compiled with `gfortran -O2 -Wall` (`SRC/Makefile:11-12`). No strict style checker; `-Wall` warnings are not treated as errors.
- 4-space indentation for module/section bodies; `do`/`select case` bodies indented one level (`SRC/inout/Typical_Data.f90:74-115`).
- Continuation lines use trailing `&` (e.g. `SRC/interface/C_Interface.f90:79-81`).
- Double literals carry explicit `d0` suffix: `1.d0`, `0.1d0`, `1.e-5`, `1.e-3` (`SRC/staging/Staging.f90:21-24,47`).
- No space after commas in `do i=1, ...` and `case(1)` (`SRC/staging/Staging.f90:16`); `print*,` with comma but no space.
- Section banners separate blocks: `!===== TITLE =====` and `!#### TITLE ####` (`SRC/staging/Staging.f90:10-20`, `SRC/inout/Typical_Data.f90:10-34`).
- `end subroutine` / `end function` / `end module` without the name (`SRC/staging/Staging.f90:142,179`, `SRC/staging/Rocket_Types.f90:37`).

**Python:**
- No linter/formatter config detected (no `pyproject.toml`, `.flake8`, `ruff.toml`, etc.). Style follows PEP 8 closely by hand: 4-space indent, blank lines between top-level defs, module docstrings.
- Aligned `=` in related assignment blocks:
  ```python
  total_m0  = ctypes.c_double()
  min_found = ctypes.c_int()
  ```
  (`SRC/interface/rocket_lib.py:61-62`, also `SRC/gui/gui.py:23-26`)
- Alignment of dict keys:
  ```python
  return {
      "total_initial_mass": total_m0.value,
      "minimum_found":      bool(min_found.value),
  ```
  (`SRC/interface/rocket_lib.py:71-73`)
- Long argument lists wrap with aligned comments:
  ```python
  lib.run_staging.argtypes = [
      ctypes.POINTER(ctypes.c_int),    # n_stages
      ctypes.POINTER(ctypes.c_double), # delta_v
  ```
  (`SRC/interface/rocket_lib.py:27-43`)
- Box-drawing comment separators: `# ── Section ──────...` (`SRC/gui/gui.py:19,112,133,314,531,581,703,989,1022`, `SRC/inout/parse_typical_data.py:19,26,72`).
- f-strings with format specs used throughout the GUI: `f"{val:.1f} s"`, `f"{results['total_initial_mass']:,.1f} kg"` (`SRC/gui/gui.py:505,951`).
- Inline comments explain intent, e.g. `# build/ sits one level above SRC/, so two levels above interface/` (`SRC/interface/rocket_lib.py:14-15`).

## Import Organization

**Python order:**
1. Standard library first: `import sys`, `import os`, `import ctypes`, `import re`, `from datetime import datetime` (`SRC/interface/rocket_lib.py:7-9`, `SRC/inout/parse_typical_data.py:14-17`)
2. Third-party packages: `from PyQt6.QtWidgets import ...` (`SRC/gui/gui.py:9-17`)
3. Local modules last (often inside functions to avoid import-order problems): `from rocket_lib import run_staging` (`SRC/test_call.py:2`); `import typical_data_ranges as _tdr` inside `_load_data()` (`SRC/gui/gui.py:116-128`).

**Path Aliases:**
- None (`sys.path` manipulation is used instead — see `SRC/gui/gui.py:29` and `SRC/gui/gui.py:119-120`).
- Inter-module paths are computed from `os.path.dirname(os.path.abspath(__file__))` relative to the file's own location, never cwd-relative (`SRC/interface/rocket_lib.py:12-15`).

**Fortran:**
- `use` statements at the top of each unit, alphabetically-ish: `use typical_data`, `use rocket_types`, `use constants` (`SRC/staging/Staging.f90:2-4`). `iso_c_binding` first in the C-interface module (`SRC/interface/C_Interface.f90:2`).
- `implicit none` is present in every module/program/subroutine (verified across all 16 units, e.g. `SRC/staging/Staging.f90:5`). Always include it.

## Error Handling

**Fortran:**
- Fatal errors: `print *, "ERROR: ..."` followed by `stop` — config file missing or unreadable (`SRC/inout/Typical_Data.f90:830-839`).
- Recoverable errors: `print *, "WARNING: ..."` and continue — invalid config lines, unknown keys, failed numeric reads (`SRC/inout/Typical_Data.f90:852,865-897`).
- I/O status is checked via `iostat=ios` (`SRC/inout/Typical_Data.f90:835-839,842-843`).
- Invalid propellant/cycle combos print `print*, "WARNING este no es valido"` and leave values zeroed (`SRC/inout/Typical_Data.f90:110-114`).
- Root-finding failure mode: bisection prints `"Raiz fuera del rango"` when the root leaves the bracket, but the loop continues (`SRC/staging/Staging.f90:47-57`) — no exit signal.
- **Prescription:** for new Fortran code, keep the `WARNING`-print pattern for recoverable conditions and `stop` for unrecoverable ones; do not silently continue on `iostat /= 0` without at least a print.

**Python:**
- GUI wraps the DLL call in `try/except Exception as e` and surfaces `QMessageBox.critical(self, "Fortran Error", str(e))` (`SRC/gui/gui.py:933-943`).
- Missing generated data module handled by `try/except ImportError` with a printed WARNING and a degraded fallback value (`SRC/gui/gui.py:121-128`).
- User-facing validation errors use `QMessageBox.warning` (`SRC/gui/gui.py:864-866,924-931`).
- `parse_typical_data.py` exits with `sys.exit(1)` after printing `ERROR:` when the Fortran source is missing (`SRC/inout/parse_typical_data.py:273-275`).
- No custom exception classes; no assertions used for validation.

## Logging

**Framework:** None in either language — no `logging` module in Python, no logging library in Fortran.

**Fortran Patterns:**
- `print*,` for all console output: progress/iteration dumps (`SRC/staging/Staging.f90:59-66`), input echo (`SRC/inout/Typical_Data.f90:60-69`), and final results (`SRC/Main.f90:17-27`).
- Decorative separators in output: `print*, "============= DATA ENTRY =========="`, `"==========================================="` (`SRC/inout/Typical_Data.f90:60`, `SRC/Main.f90:18`).
- Results are printed with aligned column labels: `print*, "ISP:               ", Rocket%stage(i)%ISP` (`SRC/Main.f90:20-26`).

**Python Patterns:**
- Plain `print()` for CLI scripts and diagnostics (`SRC/inout/parse_typical_data.py:272-286`, `SRC/test_call.py:12-17`, `SRC/gui/gui.py:53-55`).
- GUI never prints — it renders into widgets and message boxes.

## Comments

**When to Comment:**
- Equation references are documented as Fortran comments: `!Eq 3`, `!===== L is solved using eq 19 =====`, `! equation 11.87 Orbital mechanic Howard Curtis` (`SRC/staging/Staging.f90:17,20`, `TEST/Staging/main.f90:19`).
- Unit annotations inline: `![km/s]`, `![m/s]` (`SRC/staging/Staging.f90:17`, `SRC/inout/Typical_Data.f90:4`).
- Input/output contract comments at subroutine heads: `!IN:   initial mass of each stage (m_0i)` / `!OUT:  Thrust (T_i)...` (`SRC/pre-simulation-calcs/Thrust_calc.f90:2-3`, `SRC/pre-staging-calcs/Payload_Mass_calc.f90:2-3`).
- Banners mark phase sections: `!#### PRE-STAGING ####`, `!===== The mass ratios ... =====` (`SRC/Main.f90:10`, `SRC/staging/Staging.f90:72-76`).
- Bug-fix narrative comments explain derived formulas: `! --- BUG FIX: evaluate the minimum condition (eq 26) for every stage ---` (`SRC/interface/C_Interface.f90:70-73`).
- Language note: comments are a mix of English and Spanish (e.g. `!ACA IRIA MODULO DE ORBITAS...`, `!FALTARIA TAMBIEN...` in `SRC/staging/Stage_Optimization_Loop.f90:38-39`; `! Signo como en Orbital Mechanics` in `SRC/staging/Staging.f90:173`). New comments may use either, but keep them in the language of the surrounding section.
- Dead code is left as commented-out blocks rather than deleted (e.g. the Newton-Raphson block `SRC/staging/Staging.f90:26-41`, hardcoded stage vars `SRC/staging/Staging.f90:152-171`, `SRC/inout/Typical_Data.f90:807-813`).

**JSDoc/TSDoc:** Not applicable.

**Python docstrings:**
- Every module file opens with a `"""..."""` docstring explaining purpose and usage (`SRC/interface/rocket_lib.py:1-5`, `SRC/gui/gui.py:1-5`, `SRC/inout/parse_typical_data.py:1-12`, `SRC/gui/typical_data_ranges.py:1-10`).
- Functions with non-obvious behavior get docstrings: `run_staging` ("Call the Fortran STAGING solver. Returns a dict with results."), `parse_fortran` (return contract), `_flush`, `_clean_name` (`SRC/interface/rocket_lib.py:46`, `SRC/inout/parse_typical_data.py:55-64,180-181,194-195`).
- Methods get one-line docstrings when behavior is not obvious: `_prop_changed`, `_cycle_changed`, `_set_invalid_state`, `get_values` (`SRC/gui/gui.py:397-398,412-413,436-437,512-513`).
- Auto-generated file carries a banner: `AUTO-GENERATED by parse_typical_data.py on <timestamp>` + `DO NOT EDIT MANUALLY.` (`SRC/gui/typical_data_ranges.py:4-9`).

## Function Design

**Size:**
- Fortran subroutines are single-purpose and short (11–74 lines each, e.g. `orbit_speed_calculator` 11 lines, `DV_loss` 40 lines). The outliers are `data_entry` (770 lines of nested `select case` blocks in `SRC/inout/Typical_Data.f90:50-820`) and `STAGING` (178 lines, `SRC/staging/Staging.f90`).
- Python: `gui.py` is a single 1028-line file with large `_build_ui` / `_build` methods (100+ lines each, `SRC/gui/gui.py:589-700,712-823`). New code should extract helpers rather than grow these methods.

**Parameters:**
- Fortran: explicit `intent(in)` / `intent(inout)` on typed dummy args in the newer interface code (`SRC/interface/C_Interface.f90:18-33`, `SRC/staging/Staging.f90:6`, `SRC/staging/Stage_Optimization_Loop.f90:6,41`). Older subroutines omit `intent` entirely (`SRC/inout/Typical_Data.f90:53`, `SRC/pre-simulation-calcs/Thrust_calc.f90:7`). **Always declare intent on new subroutines.**
- Module-level globals are used instead of parameters for mission data: `delta_v`, `payload_mass`, `orbit_height`, `number_of_stages` live in module `typical_data` and are read/written by every layer (`SRC/inout/Typical_Data.f90:36-39`, set from `SRC/interface/C_Interface.f90:40-42`).
- Python: positional parameters in small wrappers (`run_staging(n_stages, delta_v, payload_mass, isp_list, ks_list)` — `SRC/interface/rocket_lib.py:45`); call sites use keyword args (`SRC/test_call.py:4-10`). No defaults on the bridge function.

**Return Values:**
- Fortran: subroutines communicate results by mutating the `Rocket_t` derived type (`Rocket%stage(i)%m_0`, etc.) — see `SRC/staging/Staging.f90:79-121`. Only one plain function exists, `g(L, Rocket)`, returning `real(8)` (`SRC/staging/Staging.f90:144-179`).
- Python: `run_staging` returns a plain dict with `"total_initial_mass"`, `"minimum_found"` (bool), and a `"stages"` list of dicts (`SRC/interface/rocket_lib.py:71-88`). `parse_fortran` returns a 3-tuple of dicts (`SRC/inout/parse_typical_data.py:55-64`).
- Flag convention: Fortran `minimum_found_out = 1/0` (`SRC/interface/C_Interface.f90:86-90`) is converted to Python `bool(...)` (`SRC/interface/rocket_lib.py:73`).

## Module Design

**Fortran:**
- Modules group related data + procedures: `rocket_types` (derived types), `typical_data` (mission globals + data entry + config parsing), `constants` (physical constants), `c_interface` (bind(C) wrapper) — `SRC/staging/Rocket_Types.f90`, `SRC/inout/Typical_Data.f90:1-48`, `SRC/interface/C_Interface.f90`.
- Physical constants as `parameter`: `pi`, `g_0`, `Radius` (`SRC/inout/Typical_Data.f90:3-5`).
- The `c_interface` module is the single export surface to Python: one `bind(C, name="run_staging")` subroutine with flat arrays in / out (`SRC/interface/C_Interface.f90:9-16`).
- Fortran sources are compiled into a shared library `librocket.dll`/`.so` and loaded via `ctypes` (`SRC/Makefile:43-44,153-155`, `SRC/interface/rocket_lib.py:22-24`).

**Python:**
- One module per responsibility: `rocket_lib.py` (DLL bridge), `gui.py` (PyQt6 app), `parse_typical_data.py` (Fortran→Python codegen), `typical_data_ranges.py` (generated data). Entry points guard with `if __name__ == "__main__":` (`SRC/gui/gui.py:1023-1028`, `SRC/inout/parse_typical_data.py:289-290`).
- Generated data module is consumed through a lazy loader with `importlib.reload` so edits are picked up without restarting (`SRC/gui/gui.py:116-128`).
- **Barrel files:** none.
- Data format convention: the generated module uses dicts keyed `(propellant_index, cycle_index)` with 6-tuples `(isp_lo, isp_hi, isp_mean, ks_lo, ks_hi, ks_mean)` and `None` marking invalid combinations (`SRC/gui/typical_data_ranges.py:32-34`).

---

*Convention analysis: 2026-08-13*