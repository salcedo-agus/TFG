# Technology Stack

**Analysis Date:** 2026-08-14

## Languages

**Primary:**
- Fortran 90/2008 - Computational core (staging solver, orbit, geometry, thrust). Compiled with gfortran 10.3.0 (TDM-GCC-64 on Windows). Uses F90 modules, `iso_c_binding`, and the F2008 `IEEE_ARITHMETIC` intrinsic.
  - Files: `SRC/staging/*.f90`, `SRC/pre-staging-calcs/*.f90`, `SRC/pre-simulation-calcs/*.f90`, `SRC/inout/Typical_Data.f90`, `SRC/interface/C_Interface.f90`, `SRC/Main.f90`

**Secondary:**
- Python 3.11.1 - GUI, ctypes bridge, and Fortran-source code generator
  - Files: `SRC/gui/gui.py`, `SRC/interface/rocket_lib.py`, `SRC/inout/parse_typical_data.py`, `SRC/test_call.py`

## Runtime

**Environment:**
- Windows (primary dev target, TDM-GCC-64), macOS and Linux branches supported in `SRC/Makefile`
- Python 3.11.1 (Windows)

**Package Manager:**
- None for Fortran (gfortran only)
- Python: no requirements.txt / pyproject.toml present — only external dependency is PyQt6 (installed manually)
- Lockfile: missing

## Frameworks

**Core:**
- None — bare Fortran 90 modules, no external Fortran libraries

**Testing:**
- None automated — manual `SRC/test_call.py` DLL smoke test; stale Fortran prototypes in `TEST/Staging/`

**Build/Dev:**
- GNU Make (single `SRC/Makefile` driving gfortran and `make gui`)

## Key Dependencies

**Critical:**
- gfortran 10.3.0 (TDM-GCC-64) - the only Fortran compiler; hardcoded `MINGW_BIN := C:/TDM-GCC-64/bin` in `SRC/Makefile:52`
- PyQt6 - the only external Python package, used by `SRC/gui/gui.py`

**Infrastructure:**
- MinGW runtime DLLs (`libgfortran_64-5.dll`, `libgcc_s_seh_64-1.dll`, `libquadmath_64-0.dll`, `libwinpthread_64-1.dll`) copied to `build/` on Windows link (`SRC/Makefile:168-174`)

## Configuration

**Environment:**
- `config.txt` parsed at runtime by hand-rolled parser `load_config` in `SRC/inout/Typical_Data.f90:855` (reads `SRC/config.txt` relative to CWD)
- Keys: `orbit_height` [km], `payload_mass` [kg], `number_of_stages`, per-stage `*_propellant_and_oxidizer` (1–8), per-stage `*_combustion_cycle` (0–5), `Diameter_setup` (1–3), `user_defined_diameter`
- Optional `MINGW_BIN` env var for the MinGW bin dir (`SRC/gui/gui.py:36-45`)

**Build:**
- `SRC/Makefile` — targets: `all`, `fortran`, `gui`, `parse`, `clean`; `-O2 -Wall` flags; modules emitted to `../build` via `-J`

## Platform Requirements

**Development:**
- Windows + TDM-GCC-64 (hardcoded path), or macOS/Linux with gfortran + python3
- Python 3.11 with PyQt6

**Production:**
- Standalone desktop app; ships `librocket.dll` + MinGW runtime DLLs in `build/`

---

*Stack analysis: 2026-08-14*