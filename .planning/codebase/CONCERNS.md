# Codebase Concerns

**Analysis Date:** 2026-08-13

Project: TFG — conceptual design software for multi-stage space launchers (Fortran 90 solver + Python/PyQt6 GUI + ctypes bridge to a shared library). Source layout: `SRC/` (Fortran modules + Python), `build/` (compiled artifacts, gitignored), `TEST/` (throwaway prototypes, not wired to any harness).

## Critical Bugs

### Orbit speed calculation has a m/km unit mismatch (ΔV 31.6× too large)

- Issue: `SRC/pre-staging-calcs/Orbit_calc.f90:10` computes `delta_v = sqrt(g_0*Radius**2 / r)` with `g_0 = 9.80665` **m/s²** but `Radius = 6378` and `r` in **km** (`SRC/inout/Typical_Data.f90:5`). The missing m→km conversion (factor 1e-3) makes the result numerically 31.6× too large.
- Verified numerically: for the default 407 km orbit the code produces `delta_v ≈ 242.5` (interpreted as km/s) vs the correct circular speed of **7.665 km/s**.
- Impact: the standalone path (`make fortran`, `SRC/Main.f90:12`) feeds ΔV ≈ 242 km/s into `STAGING` (`SRC/staging/Staging.f90`), so the bisection bracket `[0.1, 0.8]` never contains the root (`g(L)` returns ~-242), the loop runs to the 100-iteration cap, and all stage masses are garbage. `SRC/staging/Stage_Optimization_Loop.f90:12` has the same m/km mixing in `V_ast = sqrt(V_circ**2 + 2*g_0*orbit_height*(Radius/(Radius+orbit_height))**2)` (second term ~1000× too large).
- Fix approach: convert consistently — either `g_0/1000.d0` (km/s²) in both formulas, or compute in SI and convert the result. Add a golden-value test (e.g., assert `delta_v ≈ 7.66` for h = 407 km).

### `Rocket%rm_L` uninitialized on the Python/GUI path — output masses scale garbage

- Issue: the ctypes entry point `run_staging` in `SRC/interface/C_Interface.f90` builds a `Rocket_t` and calls `STAGING` directly, but nothing sets `Rocket%rm_L`. `STAGING` then executes `Rocket%stage(1)%m_0 = Rocket%rm_L * Rocket%stage(1)%m_0` (`SRC/staging/Staging.f90:84`). `Rocket%rm_L` is only assigned in `Payload_Mass_calculator` (`SRC/pre-staging-calcs/Payload_Mass_calc.f90:19`), which is **not** called on the C path (nor in `TEST/` or the standalone main).
- Impact: every mass output the GUI displays (`total_initial_mass`, per-stage `m0/mf/mp/ms` in `SRC/gui/gui.py`) is scaled by uninitialized stack memory. Results are non-deterministic run to run.
- Fix approach: set `Rocket%rm_L = payload_mass_in + adapter_mass` in `C_Interface.f90` before calling `STAGING`, or have `STAGING` fall back to the module global `payload_mass` when `rm_L == 0`. Add a smoke test comparing GUI-path output to a hand-computed value.

### `DV_loss` uses uninitialized variables (confirmed by gfortran -Wall)

- Issue: in `SRC/staging/Stage_Optimization_Loop.f90`, `expo = -0.333d0*DV_loss2/(g_0*ISP)` (line 62) reads `DV_loss2` **before** it is assigned at line 70 (`DV_loss2 = K3 + K4*T_mix`), and `ISP` (declared line 44) is **never assigned**. The formulas are circular: `expo → T_3s → T_mix → DV_loss2`.
- Compiler evidence: `gfortran -O2 -Wall` reports `'dv_loss2' is used uninitialized in this function` and `'isp' is used uninitialized in this function` (also flags dead locals `dv_loss1`, `dv_old`, `err`, `i`, `k1`, `k2`).
- Impact: the first and every subsequent `DV_loss` evaluation uses garbage in `expo`, so the converged `delta_v` in `STAGING_LOOP` is not physically meaningful. This is the core of the pre-simulation loss model, so all trajectory-loss numbers are suspect.
- Fix approach: derive the intended iteration (this looks like a fixed-point on `T_3s`/`DV_loss2`); either initialize `DV_loss2` from the previous iteration's value, reorder the algebra, or move the `expo` line after the `DV_loss2` assignment. Requires re-derivation from the reference (likely Edberg / Curtis), not a blind reorder.

### Config parser writes `first_stage_combustion_cycle` for all three stage keys

- Issue: `SRC/inout/Typical_Data.f90:891-897` — the `case ("second_stage_combustion_cycle")` and `case ("third_stage_combustion_cycle")` branches both `read(value, *, iostat=ios) first_stage_combustion_cycle`. The second/third stage cycle settings in `SRC/config.txt` are silently ignored; the first stage's value is used for every stage.
- Impact: with `config.txt` (stage 1 = 0, stages 2-3 = 0) it happens to be harmless today, but any config with different per-stage cycles produces wrong ISP tables and wrong results with no error.
- Fix approach: read into `second_stage_combustion_cycle` / `third_stage_combustion_cycle` respectively (copy-paste slip). Add a config round-trip test.

## Tech Debt

### Config-driven propellant/cycle selection is dead code — hardcoded TEST CASE always wins

- Issue: `SRC/inout/Typical_Data.f90:797-818` unconditionally overwrites the ~700 lines of `select case` ISP/k_s tables with `ISP_vector = (400, 350, 300)`, `k_s_vector = (0.10, 0.15, 0.20)` ("TEST CASE"). The real table assignments (`First_stage_ISP_mean` etc.) are commented out.
- Impact: `config.txt` propellant and combustion-cycle settings have **zero effect** on results. Users picking LH2/LOX vs RP-1 get identical answers. The GUI is the only path that uses real data (via `SRC/gui/typical_data_ranges.py`), so GUI and CLI results differ systematically.
- Fix approach: wire the config-selected mean values through (`ISP_vector(i) = ..._ISP_mean`, `k_s_vector(i) = ..._ks_mean`), keep the test case only behind a flag or in `TEST/`.

### Two divergent computation pipelines (GUI vs standalone)

- Issue: the GUI path (`C_Interface.f90` → `STAGING`) solves staging once with the GUI's ΔV. The standalone path (`SRC/Main.f90` → `STAGING_LOOP` → `STAGING` + `stage_Thrust_calculator` + `DV_loss`) iterates ΔV with the loss model. The two pipelines share `STAGING` but diverge everywhere else, and the C path never calls `Stage_Optimization_Loop`, `Thrust_calc`, or `Payload_Mass_calc`.
- Impact: identical inputs yield different outputs depending on entry point; bugs fixed in one path (e.g., the min-check "BUG FIX" in `C_Interface.f90:70-90`) silently diverge from `Staging.f90:123-135`.
- Fix approach: expose `STAGING_LOOP` (or a single orchestrator subroutine) through `C_Interface` so the GUI and CLI share one pipeline.

### Duplicated ctypes bridge and DLL-loading logic

- Issue: `run_staging` wrapper + argtypes are copy-pasted in `SRC/interface/rocket_lib.py:45-88` and `SRC/gui/gui.py:80-110`; MinGW path probing is duplicated across `SRC/gui/gui.py:38-55`, `SRC/interface/rocket_lib.py:17-24`, and the `SRC/Makefile:50-55,158-161`. `gui.py` inserts `interface/` on `sys.path` (line 29) but never imports `rocket_lib` — dead setup.
- Impact: the two bridges can drift (they are identical today); a fix in one is easy to miss in the other.
- Fix approach: make `gui.py` import `rocket_lib.run_staging` and delete the local copy.

### Generated GUI data file has drifted from the Fortran source

- Issue: `SRC/gui/typical_data_ranges.py` is auto-generated by `SRC/inout/parse_typical_data.py` ("DO NOT EDIT MANUALLY", generated 2026-06-17), but `SRC/inout/Typical_Data.f90` was last changed 2026-07-13. Concrete drift: the generated file marks stage-1 UDMH/LOX + Pressure `(4, 5)` as `None`/invalid (`typical_data_ranges.py:66`), while the current Fortran assigns zero ISP values for that combo with no `WARNING` print (`Typical_Data.f90:222-229`) — a fresh parse would emit a `(0,0,0, ...)` tuple instead.
- Impact: GUI validity rules and slider ranges can disagree with the solver's tables; users get "Invalid combination" or stale ranges until someone remembers to re-run `make parse`.
- Fix approach: regenerate now, and add a drift check (e.g., a CI step or a `make` dependency that fails when the generated file is older than the Fortran file).

### Stale throwaway prototypes in TEST/

- Issue: `TEST/Staging/main.f90` + `TEST/Staging/data_entry.f90` are a hardcoded 3-stage prototype of the same staging math (Curtis eq. 11.75-11.87), not compiled by the `SRC/Makefile` and not run by any harness. It contains its own root solver (`get_optimal_mass`, Newton iteration with fixed 50 iterations) that duplicates `Staging.f90`'s `g(L)` with a different sign convention for the min check (`TEST/Staging/main.f90:46` vs `Staging.f90:126`).
- Impact: confusion about which code is authoritative; the prototype's sign conventions can mislead fixes to `Staging.f90`.
- Fix approach: either fold the verified math into a real test harness (see Test Coverage Gaps) or delete the directory.

### Dead code and magic numbers

- `SRC/staging/Staging.f90:26-41` — full commented-out Newton-Raphson solver; `:152-172` — three commented alternative formulations of `g(L)`. Function `g` at `:144` still has `real(8) sum` naming that shadows the intrinsic.
- `SRC/staging/Staging.f90:24` — `res = 1905.d0` magic initial residual; `:56-57` — `res = abs(a - b)` is immediately overwritten by `res = abs(g(c, Rocket))` (dead assignment; loop really terminates on `|g(c)|`).
- `SRC/staging/Stage_Optimization_Loop.f90:52-56` — commented-out `K1/K2/DV_loss1` alternative; `:13` — magic constants in the `DV_old` initial guess (`1.5e-3`, `8.82e-2`, `1036.d0`); `:58-60` — empirical `K3/K4` correlations with no citation.
- `SRC/Makefile:51-55` — `RUNTIME_DLLS` variable defined but never used (the copy step `:156-162` re-hardcodes the paths).
- `SRC/gui/gui.py:16` — `QThread` imported but never used (solver runs on the UI thread); `:12` — `QSizePolicy` unused; `:432` — `__import__('PyQt6.QtGui', ...)` dynamic import when `QColor` is already imported at `:17`.
- `SRC/Main.f90:12` — `call orbit_speed_calculator` without parentheses/arguments (works, but inconsistent with `Payload_Mass_calculator(Rocket)`).

## Known Bugs

- **Bisection never verifies the bracket**: `SRC/staging/Staging.f90:47-67` — when neither `g(a)*g(c) < 0` nor `g(b)*g(c) < 0` holds, it prints `"Raiz fuera del rango"` and keeps looping; with the ΔV units bug (above) this is exactly what happens, and the loop exits only via the `i < 100` cap, leaving `L = c` from the last midpoint — garbage used as the solution with no error.
- **Thrust table assumes 3 stages**: `SRC/pre-simulation-calcs/Thrust_calc.f90:17-19` hardcodes `stage_thrust(1..3)` regression equations but `stage_initial_mass(2)`/`(3)` are only filled for `i <= number_of_stages` (`:13-15`). For a 1- or 2-stage rocket (allowed by `SRC/gui/gui.py:764` and `SRC/config.txt`), stages 2/3 thrust is computed from uninitialized memory. The subroutine also lacks `implicit none` (`i` implicitly typed) and reads `Rocket%stage(i)%ISP` which is 0.0 in some config paths (`m_dot` → division by zero).
- **No iteration cap in `STAGING_LOOP`**: `SRC/staging/Stage_Optimization_Loop.f90:17` — `do while(err > 1e-3)` with no maximum-iteration guard; if the fixed-point oscillates, the program hangs forever with no output other than `DV_new` spam.
- **`number_of_stages > 3` reads out of bounds**: `SRC/inout/Typical_Data.f90:815-818` loops `i=1, number_of_stages` over fixed `ISP_vector(3)`/`k_s_vector(3)`. `config.txt` allows any value; no validation anywhere. Silent garbage without `-fcheck=all`.
- **`load_config` accepts malformed values silently**: `SRC/inout/Typical_Data.f90:863-897` — on a bad `read`, it prints a WARNING and leaves the module variable at its previous/undefined value; the program continues. Missing file → bare `stop` with no guidance (`:829-833`).

## Security Considerations

- **Attack surface is minimal**: local desktop tool, no network I/O, no user-supplied file parsing beyond `config.txt` and the results save path (GUI uses `QFileDialog`). No secrets or credentials exist anywhere in the repo (no `.env`, no keys; `SRC/config.txt` is mission parameters only).
- **DLL search-path hazard (low)**: `SRC/gui/gui.py:47-51` and `SRC/interface/rocket_lib.py:19-21` add arbitrary MinGW bin directories to the DLL search path before loading `librocket.dll`. A malicious `libgfortran_64-5.dll` placed in one of those candidate dirs would be loaded. Acceptable for a student tool, but the path list should come from a single config source, not three hardcoded copies.
- **Recommendations**: (1) validate `number_of_stages` against [1,3] in `load_config`; (2) add `-fcheck=all -finit-real=snan` (or `-fbacktrace`) to the debug build so uninitialized-variable bugs surface instead of producing plausible garbage; (3) keep `build/` out of git (already done via `.gitignore` — verified `git ls-files` contains no `.o`/`.mod`/`.pyc`/`.dll`).

## Performance Bottlenecks

- **GUI freezes during solve**: `SRC/gui/gui.py:909-943` runs the ctypes call synchronously on the Qt main thread; `STAGING` also prints ~20-40 lines of iteration spam to stdout per solve (`SRC/staging/Staging.f90:59-66`). `QThread` is imported but never used.
  - Cause: no background worker; solver is fast (<100 bisection steps) so the freeze is brief, but the loop in `STAGING_LOOP` can hang indefinitely (see Known Bugs).
  - Improvement path: move the solve into a `QThread` worker emitting a result signal (the import already anticipates this); suppress Fortran `print*` debug output behind a verbosity flag.
- **No other hotspots**: the numeric core is O(stages × 100 iterations); memory use is trivial. Not a concern area beyond the above.

## Fragile Areas

- **The Fortran→Python data pipeline**: `SRC/inout/Typical_Data.f90` → `SRC/inout/parse_typical_data.py` (regex state machine over Fortran comments and `WARNING` print statements) → `SRC/gui/typical_data_ranges.py` → `SRC/gui/gui.py`. Any reformatting of the Fortran (e.g., `WARNING` message wording, `= 445.6d0` → `= 445.6e0`, renamed variables) silently breaks or desyncs the parse (values default to 0.0 via `_flush` defaults, `parse_typical_data.py:185-191`). The parser also assumes the three stage blocks are structurally identical (only the first block provides names, `parse_typical_data.py:62-64`). Already drifted once (see Tech Debt). Safe modification: change Fortran, immediately regenerate, and diff the generated file; add a test that parses and checks key tuples.
- **`Staging.f90` root finding**: the bisection assumes `g` changes sign inside `[0.1, 0.8]`; any ΔV outside the valid range (including the current units bug) silently yields garbage `L`. Safe modification: validate `g(a)*g(b) < 0` up front and `stop` with a clear message.
- **MinGW toolchain coupling**: `SRC/Makefile:50,158-161`, `SRC/gui/gui.py:38-45`, and `SRC/interface/rocket_lib.py:19` all hardcode `C:\TDM-GCC-64\bin`; the Makefile silently skips copying missing runtime DLLs, deferring failure to a cryptic `ctypes` load error at GUI startup.
- **Test coverage**: none. There is no automated test for any of the math (see Test Coverage Gaps). The `TEST/` prototypes are the only "verification" and they duplicate rather than test the production code.

## Scaling Limits

- **Stages**: the solver core (`STAGING`, `Stage_Optimization_Loop`) is written generically over `Rocket%number_of_stages`, but everything around it is fixed at 3: `Typical_Data.f90` data tables (first/second/third stage), `Thrust_calc.f90` regression equations, `gui.py`'s `TYPICAL_DATA_BY_STAGE[1..3]`, `config.txt`'s per-stage keys, and the GUI spinbox cap (`gui.py:764`). Supporting N stages means replacing all five — currently 3 is the hard limit.
- **Propellant/cycle combos**: the tables allow 8 propellants × 6 cycles but most combos are zeros or invalid; stage 3 has almost no data (`typical_data_ranges.py:169-234`). The GUI correctly disables sliders for missing data, but the solver itself will happily use `ISP = 0` from the CLI path → `nu_e = 0` → division by zero in `Staging.f90:74`.

## Dependencies at Risk

- **PyQt6**: no `requirements.txt`/`pyproject.toml` pins the version; GUI fails at import for users without PyQt6 installed. Python 3.11 observed (`SRC/gui/__pycache__/typical_data_ranges.cpython-311.pyc`). Risk: environment setup friction, no reproducibility.
- **gfortran / MinGW (TDM-GCC 10.3.0)**: build toolchain is Windows-specific by default (`SRC/Makefile:41-55`); macOS path is broken end-to-end (the Python bridge loads `librocket.so` even though the Makefile builds `librocket.dylib` — `SRC/interface/rocket_lib.py:23-24`, `SRC/gui/gui.py:58-59`; macOS also has no runtime-DLL step, which is fine, but the `.so` load will fail).
- **No CI**: no pipeline exists to compile Fortran, regenerate `typical_data_ranges.py`, or run any test — every regression above shipped silently.

## Missing Critical Features

- **Trajectory/loss model integration**: `DV_loss`'s comment (`Stage_Optimization_Loop.f90:38-39`) acknowledges a missing launch-site module (`V_rot = 0.d0` hardcoded at `:50`); README goals (3-DoF trajectory simulator, gravity turn/pitch program guidance, atmospheric models) are unimplemented — the repo currently contains only the staging optimizer plus a thrust/loss iteration that is broken (see Critical Bugs).
- **Validation against real launchers** (README goal): no comparison data, no regression fixtures. Combined with the ΔV units bug and the uninitialized `rm_L`, none of the current outputs can be trusted as physically validated.

## Test Coverage Gaps

- **Everything is untested** — no unit, integration, or E2E tests exist for either language.
  - What's not tested: `Orbit_calc` output (would have caught the 31.6× units bug), `Staging` mass conservation (Σ m_p + m_s + payload == m_0), `load_config` parsing (would have caught the cycle-key copy-paste), the ctypes contract between `C_Interface.f90` and `rocket_lib.py` (would have caught the uninitialized `rm_L`), and the `parse_typical_data.py` → `typical_data_ranges.py` round trip (would have caught the drift).
  - Files: all of `SRC/staging/`, `SRC/pre-staging-calcs/`, `SRC/pre-simulation-calcs/`, `SRC/inout/`, `SRC/interface/`, `SRC/gui/`.
  - Risk: every numeric output of the program is currently unverified; a regression in any equation is invisible.
  - Priority: High — at minimum add: (1) golden-value tests for `orbit_speed_calculator` (407 km → 7.665 km/s) and `STAGING` (known-good mass split); (2) a Python smoke test calling `run_staging` and asserting `total_initial_mass ≈ payload-based expectation`; (3) a config parse test asserting per-stage cycle variables are independent; (4) a regeneration drift check comparing `typical_data_ranges.py` against a fresh parse.

---

*Concerns audit: 2026-08-13*