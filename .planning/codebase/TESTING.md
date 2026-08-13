# Testing Patterns

**Analysis Date:** 2026-08-13

There is no automated test framework in this repository. Verification is done through two manual artifacts: a standalone Fortran validation program (`TEST/Staging/`) that checks the staging math against a published textbook reference, and Python smoke scripts that exercise the DLL bridge. No CI pipeline exists.

## Test Framework

**Runner:**
- None. No pytest, unittest, or any test runner is installed or configured (no `requirements.txt`, no `pyproject.toml`, no `conftest.py`, no CI config files).
- Fortran validation is a standalone program compiled manually with gfortran.
- Python verification is a plain script executed with `python`.

**Assertion Library:**
- None. Verification is done via printed output and manual inspection, plus in-code logical checks (e.g. the "local minimum" condition computed inside the programs themselves).

**Run Commands:**

```bash
# Fortran validation program (TEST/Staging/)
gfortran -O2 -Wall main.f90 data_entry.f90 -o main.exe
./main.exe

# Python bridge smoke test (requires build/librocket.dll built via make)
cd SRC
python test_call.py
```

## Test File Organization

**Location:**
- Fortran validation programs live in `TEST/Staging/`, completely separate from `SRC/`:
  - `TEST/Staging/main.f90` — the test program (`program optimalStagedRocket`)
  - `TEST/Staging/data_entry.f90` — input fixtures (`module dataEntry`)
- Python smoke test lives inside `SRC/`: `SRC/test_call.py` (sits next to the code it exercises, not in `TEST/`).

**Naming:**
- Fortran test files reuse production names (`main.f90`, `data_entry.f90`) inside the `TEST/Staging/` folder.
- Python smoke test named `test_call.py` (not `test_*.py`-style, so it is not picked up by any test runner).

**Structure:**
```
TEST/
└── Staging/            # Standalone Fortran validation of optimal staging
    ├── main.f90        # Program: Newton root-find + mass chain + minimum check
    └── data_entry.f90  # Module: fixed input parameters (Isp, e, payload, v_burn_off)
```

## Test Structure

**Suite Organization:** There are no test suites. Each artifact is a standalone executable/script.

**Fortran validation program pattern** (`TEST/Staging/main.f90`):
```fortran
Program optimalStagedRocket
  use dataEntry
  implicit none
  ...
  call init_data()
  ! Newton iteration on the root-finding function
  do i=1, 50
     res = res - get_optimal_mass(res)*2*h/(get_optimal_mass(res+h)-get_optimal_mass(res-h))
  end do
  ! Recompute stage masses with the textbook equations (11.75-11.87, Curtis)
  n1=(c1*res-1)/(c1*e1*res)
  ...
  ! Local-minimum verification (eq 11.85)
  check = res*c1*(e1*n1-1)**2 + 2*e1*n1 -1
  if( check > 0) sum = sum +1
  if(sum==3)then
     print*, "  ### Found a local minimum ###"
  else
     print*, "Local minimun not foud, try again"
     stop
  end if
  ! Print all results for manual inspection
end Program optimalStagedRocket
```

**Python smoke test pattern** (`SRC/test_call.py`):
```python
from rocket_lib import run_staging

results = run_staging(
    n_stages     = 3,
    delta_v      = 10.0,
    payload_mass = 5000.0,
    isp_list     = [400.0, 350.0, 300.0],
    ks_list      = [0.10,  0.15,  0.20],
)

print(f"Total initial mass: {results['total_initial_mass']:.1f} kg")
print(f"Minimum found: {results['minimum_found']}")
```

**Patterns:**
- Reference-based validation: the TEST program reimplements the Curtis "Orbital Mechanics" equations independently and compares the outcome (minimum found / not found) with the production solver's own check.
- `stop` on failed validation (`TEST/Staging/main.f90:55-57`) — a non-zero exit is the failure signal.
- Print-and-inspect for all numeric outputs; there are no tolerances, no assertions, and no pass/fail exit codes in the Python script.

## Mocking

**Framework:** Not applicable — no mocks are used anywhere.

**Patterns:**
- The Fortran bridge is not mocked: `SRC/test_call.py` and the GUI call the real DLL (`ctypes.CDLL` in `SRC/interface/rocket_lib.py:22-24`, `SRC/gui/gui.py:57-59`).
- Fixed input data (Isp, structural ratios, payload) are hardcoded as `parameter` constants in `TEST/Staging/data_entry.f90:3-18` — this is the closest thing to a test fixture.

**What to Mock:** Not applicable — when introducing a real test framework (e.g. pytest), mock the `ctypes.CDLL` object to test `rocket_lib.run_staging` argument marshalling without a compiled DLL.

**What NOT to Mock:** The Fortran solver itself — the whole point of the bridge tests is to validate the DLL boundary.

## Fixtures and Factories

**Test Data:**

The fixed inputs in `TEST/Staging/data_entry.f90` mirror the Python smoke test inputs exactly:
```fortran
real(8), parameter :: Isp1 = 400.   ! seconds
real(8), parameter :: Isp2 = 350.
real(8), parameter :: Isp3 = 300.
real(8), parameter :: e1 = 0.10     ! structural ratio
real(8), parameter :: e2 = 0.15
real(8), parameter :: e3 = 0.20
real(8), parameter :: mass_pay_load = 5000.   ! kg
real(8), parameter :: v_burn_off = 10.        ! km/s
```
Equivalent input in `SRC/test_call.py:4-10` and the hardcoded test-case block in `SRC/inout/Typical_Data.f90:797-805`.

**Location:**
- `TEST/Staging/data_entry.f90` (Fortran)
- `SRC/test_call.py` (Python)
- Hardcoded "TEST CASE" block inside production code at `SRC/inout/Typical_Data.f90:797-805` (test data shipped inside the production module — see Test Coverage Gaps).

## Coverage

**Requirements:** None enforced. No coverage tooling exists for either language.

**View Coverage:** Not applicable (no tooling installed).

## Test Types

**Unit Tests:**
- Not used in the formal sense. The closest equivalents:
  - `TEST/Staging/main.f90` validates the `STAGING` algorithm family (mass ratios, step masses, local minimum condition) against an independent textbook implementation.
  - `SRC/interface/C_Interface.f90` contains a defensively re-computed eq-26 minimum check ("BUG FIX" comment, `SRC/interface/C_Interface.f90:70-90`) that effectively re-verifies the solver's own check.

**Integration Tests:**
- `SRC/test_call.py` is the de-facto integration test: it loads `librocket.dll` and exercises the full Fortran→C-interface→Python path, printing the resulting stage masses and the minimum flag.
- The GUI itself (`SRC/gui/gui.py`) is the manual end-to-end test surface — it calls the same `run_staging` bridge (`SRC/gui/gui.py:80-110,934-940`).

**E2E Tests:**
- Not used. GUI behavior (`_run`, `_print_results`, validity gating in `SRC/gui/gui.py:853-862`) is only exercised manually.

## Common Patterns

**Async Testing:**
- Not applicable — no async code and no GUI tests. Note the GUI declares `QThread`/`pyqtSignal` imports (`SRC/gui/gui.py:16`) but does not currently use a worker thread for the solver call; `_run` blocks on the DLL.

**Error Testing:**
- The only error-path exercise is manual: missing `config.txt` triggers `print *, "ERROR: config file not found:"` + `stop` (`SRC/inout/Typical_Data.f90:830-833`); missing `typical_data_ranges.py` triggers the WARNING fallback path (`SRC/gui/gui.py:121-128`). No automated checks for either.

## Test Coverage Gaps

**Untested areas:**
- `load_config` parsing (`SRC/inout/Typical_Data.f90:822-906`) — key/value parsing, comments, `to_lower`, invalid values: only exercised when the standalone executable is run against `SRC/config.txt`.
- The `data_entry` 8×6 propellant/cycle lookup table (`SRC/inout/Typical_Data.f90:50-820`) — the GUI relies on it indirectly, but no test checks the generated `typical_data_ranges.py` matches the Fortran source.
- `parse_typical_data.py` codegen (`SRC/inout/parse_typical_data.py`) — no golden-file test for the generated output; a regression here would silently corrupt GUI data.
- The optimization loop `STAGING_LOOP` / `DV_loss` convergence (`SRC/staging/Stage_Optimization_Loop.f90`) — no convergence/regression test.
- Python-side arg marshalling of `rocket_lib.run_staging` — no tests for wrong array lengths, zero stages, or degenerate inputs.
- Regression between `SRC/staging/Staging.f90` and the independent reference in `TEST/Staging/main.f90` — no automated comparison of their numerical outputs.

**Priority:** High for `parse_typical_data.py` (data integrity), Medium for `load_config` and the DLL bridge, Low for the GUI (manual tool).

---

*Testing analysis: 2026-08-13*