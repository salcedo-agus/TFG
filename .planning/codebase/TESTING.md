# Testing Patterns

**Analysis Date:** 2026-08-14

## Test Framework

**Runner:**
- None — no automated test framework for either Fortran or Python
- No test config files (no pytest.ini, no CMake/CTest)

**Assertion Library:**
- None

**Run Commands:**
```bash
make fortran              # runs the standalone executable (prints results to stdout)
python test_call.py       # manual DLL smoke test — must be run from SRC/ (imports rocket_lib)
```

## Test File Organization

**Location:**
- `SRC/test_call.py` — Python smoke test for the ctypes bridge
- `TEST/Staging/main.f90` + `TEST/Staging/data_entry.f90` — standalone Fortran prototypes

**Naming:**
- `test_call.py` (smoke test); no `test_*.py` or `*.test.*` conventions

**Structure:**
```
TEST/Staging/          # stale prototypes (reference modules dataEntry, c1/e1... that no longer exist)
SRC/test_call.py       # manual smoke test
```

## Test Structure

**Suite Organization:**
No suites exist. The only executable "test" is `SRC/test_call.py`:

```python
# SRC/test_call.py — hardcoded 3-stage case, prints results
from rocket_lib import run_staging
results = run_staging(n_stages=3, delta_v=10.0, payload_mass=5000.0,
                      isp_list=[400.0, 350.0, 300.0], ks_list=[0.10, 0.15, 0.20])
```

**Patterns:**
- Manual golden-value checking against published staging solutions (e.g. Soyuz 2-1v hardcoded as TEST CASE in `Typical_Data.f90:824-832`) — no assertions, visual inspection only

## Mocking

**Framework:** None

**Patterns:**
- N/A — no tests to mock in; the ctypes DLL itself is the unit under test

**What to Mock:**
- If adding tests, isolate Fortran solver from config parsing by calling `run_staging` directly (it already bypasses `load_config`)

**What NOT to Mock:**
- The Fortran solver — the point is to exercise `librocket.dll` for real

## Fixtures and Factories

**Test Data:**
- Hand-written literals inline (e.g. `test_call.py:4-10`); the ISP/ks data tables in `Typical_Data.f90` serve as reference data (Soyuz 2-1v case)
- Generated reference: `gui/typical_data_ranges.py` (auto-generated from `Typical_Data.f90` by `parse_typical_data.py`, so data stays in sync if regenerated)

**Location:**
- Inline in scripts; `SRC/config.txt` for config-driven runs

## Coverage

**Requirements:** None enforced — no coverage tooling

**View Coverage:**
- Not possible currently

## Test Types

**Unit Tests:**
- None

**Integration Tests:**
- `SRC/test_call.py` exercises the full ctypes → Fortran → results path (manual run)

**E2E Tests:**
- `make fortran` / `make gui` manual runs; no automated E2E

## Common Patterns

**Async Testing:**
- N/A

**Error Testing:**
- No error-path tests; `load_config` warnings tested only by eye

## Recommended Test Gaps (high priority)

1. Golden-value check for the staging solver: verify `run_staging` against the known Soyuz 2-1v case (`ISP=[297, 359]`, `k_s=[0.0791, 0.0938]`, 2 stages) — currently the hardcoded TEST CASE in `Typical_Data.f90:824-832`
2. Golden-value check for `orbit_speed_calculator`: 200 km orbit → V_circ ≈ 7.79 km/s (regression guard for the unit fix in `Orbit_calc.f90`)
3. Round-trip test for `load_config` parsing all keys including the second/third-stage combustion cycles (would catch the config-write bug in `Typical_Data.f90:924-930`)
4. Consistency check between `typical_data_ranges.py` and `Typical_Data.f90` (run `parse_typical_data.py` and diff)

---

*Testing analysis: 2026-08-14*