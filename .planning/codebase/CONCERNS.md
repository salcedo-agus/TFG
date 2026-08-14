# Codebase Concerns

**Analysis Date:** 2026-08-14

## Tech Debt

**[Config parser writes all stage-cycle keys to the same variable]:**
- Issue: In `load_config` (`SRC/inout/Typical_Data.f90:924-930`), the `case ("second_stage_combustion_cycle")` and `case ("third_stage_combustion_cycle")` branches both `read` into `first_stage_combustion_cycle`. Second/third stage cycle selections from `config.txt` are silently ignored and overwritten.
- Files: `SRC/inout/Typical_Data.f90:924-930`
- Impact: Multi-stage combustion cycles can never be configured independently via config; stage 2/3 cycles always equal stage 1's value.
- Fix approach: Change the two branches to read into `second_stage_combustion_cycle` and `third_stage_combustion_cycle` respectively.

**[Dead "TEST CASE" overrides statistical ISP/ks data]:**
- Issue: `data_entry` computes ISP/ks from the propellant/cycle tables (the ~800-line select-case blocks) but then unconditionally overwrites them with a hardcoded Soyuz 2-1v TEST CASE (`Typical_Data.f90:824-832`). The `ISP_vector = First_stage_ISP_mean` lines are commented out.
- Files: `SRC/inout/Typical_Data.f90:816-845`
- Impact: All the carefully maintained propellant/cycle ISP and k_s tables (`typical_data_ranges.py`) have **no effect** on the Fortran executable; the same values are only used by the GUI. The Fortran solver always runs the Soyuz case.
- Fix approach: Restore the `First_stage_ISP_mean` / `First_stage_ks_mean` assignments (or gate the TEST CASE behind a flag).

**[Duplicated ctypes bridge]:**
- Issue: `run_staging` ctypes wrapper defined twice — `SRC/interface/rocket_lib.py:45` and inline in `SRC/gui/gui.py:80`.
- Files: `SRC/interface/rocket_lib.py`, `SRC/gui/gui.py`
- Impact: Two copies of the 15-argument signature can drift; maintenance duplicated.
- Fix approach: `gui.py` should import `run_staging` from `rocket_lib` (it already adds `interface/` to `sys.path` at `gui.py:29`).

**[Staging.f90 `g` function retains a large commented-out block]:**
- Issue: ~20 lines of commented-out alternate formulations remain in `SRC/staging/Staging.f90:12-31`.
- Impact: Confusing; hides which sign convention is actually used.
- Fix approach: Delete the dead block; keep the active "Signo como en Orbital Mechanics" formulation.

**[`T_a` computed then immediately overwritten]:**
- Issue: `Stage_Optimization_Loop.f90:12-21` sets `T_a` from a stage-count if/else (180/520/820), then line 23 unconditionally reassigns `T_a = 400.d0`.
- Files: `SRC/staging/Stage_Optimization_Loop.f90:12-23`
- Impact: The stage-count logic is dead code; ascent time is always 400 s.
- Fix approach: Remove the overwrite or remove the if/else.

**[Stale TEST/ prototypes]:**
- Issue: `TEST/Staging/main.f90` and `TEST/Staging/data_entry.f90` reference modules/variables (`dataEntry`, `c1`, `e1`, `Isp1`) that no longer exist in the codebase and are not in the Makefile.
- Files: `TEST/Staging/*.f90`
- Impact: Misleading as validation; cannot compile against current code.
- Fix approach: Update or delete; if kept as reference, document that they are obsolete.

## Known Bugs

**[`Rocket%rm_L` never initialized on the ctypes/GUI path]:**
- Symptoms: On the Python path, `run_staging` (`SRC/interface/C_Interface.f90:9`) sets module globals `payload_mass`, `number_of_stages`, `delta_v` but **never sets `Rocket%rm_L`**. `STAGING` then reads `Rocket%rm_L` when computing the stage-1 initial mass (`SRC/staging/Staging.f90:86`). The Fortran main path sets it via `Payload_Mass_calculator`, but the ctypes path does not.
- Files: `SRC/interface/C_Interface.f90:40-54`, `SRC/staging/Staging.f90:86`, `SRC/pre-staging-calcs/Payload_Mass_calc.f90`
- Trigger: Any GUI or `test_call.py` run — the payload mass is effectively uninitialized/garbage on that path.
- Workaround: None in code; GUI results may be nonsensical.
- Fix: In `run_staging`, set `Rocket%rm_L = payload_mass_in` (or call the payload/PAB logic).

**[Second/third-stage combustion cycle config ignored]**: See Tech Debt item 1 above — this is also a functional bug.

## Security Considerations

**[No secrets / credential surface]:**
- Risk: None present — the codebase has no env secrets, auth, or network I/O. The only environment touch is the optional `MINGW_BIN` path (`SRC/gui/gui.py:36`).
- Files: N/A
- Current mitigation: N/A
- Recommendations: Keep `.env`/credential files out; the `.gitignore` already excludes build artifacts (`*.o`, `*.mod`, `*.dll`).

## Performance Bottlenecks

**[Excessive stdout printing in the solver loop]:**
- Problem: `Bolzano_Bisection` prints the bisection point every iteration (`Root_Finding.f90:63`), `STAGING` prints per stage (`Staging.f90:57`), and `STAGING_LOOP` prints on every ΔV iteration (`Stage_Optimization_Loop.f90:43`).
- Files: `SRC/staging/Root_Finding.f90`, `SRC/staging/Staging.f90`, `SRC/staging/Stage_Optimization_Loop.f90`
- Cause: Unconditional `print*` statements in inner loops.
- Improvement path: Gate prints behind a verbosity flag or remove.

**[Hardcoded MinGW path]:**
- Problem: `SRC/Makefile:52` hardcodes `MINGW_BIN := C:/TDM-GCC-64/bin`; runtime DLL copy and GUI DLL search depend on it.
- Files: `SRC/Makefile`, `SRC/gui/gui.py`
- Cause: Single-machine assumption.
- Improvement path: Discover MinGW via `where gfortran` / environment rather than hardcoding.

## Fragile Areas

**[Makefile circular / order-dependent module deps]:**
- Files: `SRC/Makefile:117-125`
- Why fragile: `Root_Finding.o` is declared to depend on `Staging.o` (rule 3) while `Staging.o` depends on `Root_Finding.o` (rule 4) — a circular dependency. Also `OBJS` order (`Staging` before `Root_Finding`) contradicts the declared rules. `Staging.f90` `use`s `Root_Finding_Methods` and `Root_Finding.f90` `use`s only `rocket_types`, so a clean dependency is `Staging.o ← Root_Finding.o`. The current rules only build because stale `.mod` files persist in `build/`.
- Safe modification: Fix rule 3's dependency to remove `Staging.o` from `Root_Finding.o`; reorder `OBJS` to compile `Root_Finding` before `Staging`.
- Test coverage: None.

**[Module-global shared state across two entry points]:**
- Files: `SRC/inout/Typical_Data.f90`, `SRC/interface/C_Interface.f90`
- Why fragile: The ctypes path and the main path must each initialize module globals + `Rocket%rm_L` consistently, and they do not (see bug above).
- Safe modification: Move configuration into the `Rocket_t` object; eliminate implicit globals.
- Test coverage: None.

## Scaling Limits

**[Fixed 3-stage cap]:**
- Current capacity: GUI enforces `n_stages` 1–3 (`gui.py:764`); code uses fixed `dimension(3)` arrays (`Geometry_calc.f90:7-10`, `Thrust_calc.f90:11-12`); `Typical_Data.f90` has first/second/third-stage tables only.
- Limit: Hard-capped at 3 stages; adding a 4th stage requires touching many fixed-size arrays and tables.
- Scaling path: Refactor to allocatable/loop-driven arrays driven by `number_of_stages`.

## Dependencies at Risk

**[PyQt6 — only external Python dep, not version-pinned]:**
- Risk: No `requirements.txt`; `import PyQt6` may break on Python/pip version drift.
- Impact: GUI won't launch.
- Migration plan: Pin `PyQt6>=6.5` in a `requirements.txt`.

## Missing Critical Features

**[No automated test suite]:** See TESTING.md — zero tests; correctness relies on manual inspection of printed values.

**[No trajectory/simulation model]:** `README.md` lists trajectory simulation, gravity-turn guidance, and environment models as objectives, but the code only performs staging sizing + geometry. Pre-simulation sizing exists but no actual trajectory/integration is implemented.

**[No launch-site / launch latitude model]:** `DV_loss` in `Stage_Optimization_Loop.f90:55` has a comment "FALTARIA TAMBIEN UN MODULO QUE TENGA DATOS DEL LUGAR DE LANZAMIENTO PARA SACAR V_rot" (missing module for launch-site data to get `V_rot`); `V_rot` is hardcoded to `0.d0`.

## Test Coverage Gaps

**[Staging solver]:** No golden-value regression test.
- Files: `SRC/staging/Staging.f90`
- Risk: The `Orbit_calc`/`DV_loss` unit correction (commit `370893f`) has no test guarding it.
- Priority: High

**[Config parser]:** No test for stage-cycle key parsing.
- Files: `SRC/inout/Typical_Data.f90`
- Risk: The second/third-cycle write bug (line 924-930) was introduced and went undetected.
- Priority: High

**[Geometry sizing]:** New module `Geometry_calc.f90` untested.
- Files: `SRC/pre-simulation-calcs/Geometry_calc.f90`
- Risk: Statistical regressions keyed by propellant have many "WARNING: without statistical data" branches that silently leave vectors at 0.
- Priority: Medium

---

*Concerns audit: 2026-08-14*