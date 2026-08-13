# Technology Stack

**Analysis Date:** 2026-08-13

## Languages

**Primary:**
- Fortran (modern dialect, F90–F2008 features) - Core numerical engine: staging optimization, orbit/payload/thrust calcs. All solver code in `SRC/**/*.f90`.
  - Uses F2008 `iso_c_binding` for the Python bridge (`SRC/interface/C_Interface.f90`), F2008 `newunit` file I/O (`SRC/inout/Typical_Data.f90:835`), derived types with allocatable components (`SRC/staging/Rocket_Types.f90`), module procedures, `intent(in/out)`.
- Python 3.11 - GUI layer and tooling: `SRC/gui/gui.py` (desktop app), `SRC/interface/rocket_lib.py` (FFI bridge), `SRC/inout/parse_typical_data.py` (code generator), `SRC/test_call.py` (bridge smoke test).
  - Version evidence: `SRC/gui/__pycache__/*.cpython-311.pyc`; `python --version` reports 3.11.1.

**Secondary:**
- Make (GNU make) - Build orchestration: `SRC/Makefile` (platform-aware, 208 lines).
- C ABI (ISO C) - ABI contract between Fortran and Python via `bind(C, name="run_staging")` in `SRC/interface/C_Interface.f90`; no C source files exist, the C layer is only the symbol-level interface.

## Runtime

**Environment:**
- Desktop application; no server runtime. Python 3.11.1 hosts the GUI; the Fortran solver runs inside the Python process via a shared library (`ctypes` load, no subprocess).
- Fortran compiled artifacts: `build/librocket.dll` (Windows), `build/librocket.so` (Linux), `build/librocket.dylib` (macOS) — produced by `SRC/Makefile`.
- Also a standalone Fortran executable path: `build/rocket.exe` via `make fortran` (`SRC/Makefile:168-176`).

**Package Manager:**
- Python: pip (implicit — **no** `requirements.txt`, `pyproject.toml`, `Pipfile`, or `setup.py` exists anywhere in the repo; PyQt6 must be installed manually).
- Fortran: none (system gfortran, TDM-GCC-64 distribution on Windows).
- Lockfile: missing (Python deps unpinned).

## Frameworks

**Core:**
- PyQt6 - GUI framework for `SRC/gui/gui.py` (QtWidgets, QtCore, QtGui modules; custom QSS dark theme, splash screen with `QPropertyAnimation` fade, `QThread`/`pyqtSignal` imported).
- ctypes (Python stdlib) - FFI bridge; `ctypes.CDLL` loads `librocket.dll`/`librocket.so` and declares `run_staging` argtypes in both `SRC/interface/rocket_lib.py:26-43` and (duplicated) `SRC/gui/gui.py:61-78`.

**Testing:**
- None formal. Ad-hoc: `SRC/test_call.py` calls `run_staging` directly; `TEST/Staging/` holds legacy Fortran standalone prototypes (`TEST/Staging/main.f90`, `TEST/Staging/data_entry.f90`) not wired into the Makefile.

**Build/Dev:**
- GNU make + gfortran via `SRC/Makefile`:
  - `make all` — compile Fortran objects and link shared library.
  - `make fortran` — link and run the standalone executable.
  - `make gui` — build library then launch `python SRC/gui/gui.py`.
  - `make parse` — regenerate `SRC/gui/typical_data_ranges.py` from `SRC/inout/Typical_Data.f90`.
  - `make clean` — remove `build/`.
  - Flags: `FFLAGS := -O2 -Wall`, module dirs `-Jbuild -Ibuild`, shared link `-shared -m64` (Win) / `-shared -fPIC` (Unix).
  - Windows post-link step copies MinGW runtime DLLs (`libgfortran_64-5.dll`, `libgcc_s_seh_64-1.dll`, `libquadmath_64-0.dll`, `libwinpthread_64-1.dll`) from `C:/TDM-GCC-64/bin` into `build/` (`SRC/Makefile:156-162`).

## Key Dependencies

**Critical:**
- PyQt6 - entire GUI depends on it; version unpinned.
- gfortran 10.3.0 (TDM-GCC-64 MinGW distribution on Windows) - sole Fortran compiler; the Makefile hardcodes the MinGW bin path `C:/TDM-GCC-64/bin` (`SRC/Makefile:50`), also probed at runtime by the GUI with fallbacks (`SRC/gui/gui.py:38-45`).
- ctypes (stdlib) - the only bridge between Python and Fortran; no f2py/cython used.

**Infrastructure:**
- PyQt6.QtCore `QThread`/`pyqtSignal` - imported in `SRC/gui/gui.py:16` (threading support scaffold).
- Python stdlib only elsewhere: `re` (parser in `SRC/inout/parse_typical_data.py:14`), `os`, `sys`, `datetime`, `importlib`.

## Configuration

**Environment:**
- Mission/propellant configuration lives in `SRC/config.txt` — a hand-rolled `key = value` INI-like file (`;` and `#` comments). Parsed by a Fortran parser `load_config()` in `SRC/inout/Typical_Data.f90:822-906` (no external config library; keys hardcoded in a `select case`).
- Keys: `orbit_height [km]`, `payload_mass [kg]`, `number_of_stages`, per-stage `*_propellant_and_oxidizer` (1–8), per-stage `*_combustion_cycle` (0–5). Full key list with comments: `SRC/config.txt`.
- GUI inputs (ΔV, payload, stages, ISP, k_s) are set in the UI, not `config.txt` — `config.txt` feeds only the standalone Fortran path (`SRC/Main.f90` → `data_entry` → `load_config`).

**Build:**
- `SRC/Makefile` — the single build config; platform detection via `OS`/`uname -s` (`SRC/Makefile:41-79`).
- `SRC/gui/typical_data_ranges.py` — AUTO-GENERATED data module (header states "DO NOT EDIT MANUALLY"); regenerate with `make parse` after editing `SRC/inout/Typical_Data.f90` (`SRC/inout/parse_typical_data.py:4-11`).
- `.gitignore` — ignores `*.dll`, `*.so`, `*.o`, `*.mod`, `__pycache__/`, `*.pyc`. Note: `build/` directory itself is not ignored but all its contents are covered by the extension rules.

## Platform Requirements

**Development:**
- Windows (primary; the Makefile and GUI both assume it first), with TDM-GCC-64 MinGW installed at `C:/TDM-GCC-64/bin` (also accepts `MINGW_BIN` env var; fallbacks for MSYS2/mingw64 probed at runtime, `SRC/gui/gui.py:38-45`).
- macOS (Darwin) and Linux supported by the Makefile branches (`SRC/Makefile:58-78`), producing `.dylib`/`.so` respectively; the GUI loads `librocket.so` on non-Windows (`SRC/gui/gui.py:59`).
- Python 3.11 with PyQt6 installed; GNU make; gfortran.

**Production:**
- None — academic/desktop TFG (final degree project) tool, distributed as source; no packaging, installer, or deployment config exists.

---

*Stack analysis: 2026-08-13*