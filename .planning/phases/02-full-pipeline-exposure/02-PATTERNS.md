# Phase 2: Full Pipeline Exposure — Pattern Map

**Mapped:** 2026-09-06
**Files analyzed:** 3 modified files (+ 10 reference-only pipeline modules)
**Analogs found:** 3 / 3 (all self-analogs — this phase extends existing entries, nothing is new-role)

> **Phase shape (from CONTEXT.md, --skip-research):** extend one Fortran bind(C) entry
> (`C_Interface.f90`), extend one ctypes wrapper (`rocket_lib.py`), and re-wire the GUI
> call path (`gui.py`). Every target has a **self-analog**: the existing `run_staging`
> entry/wrapper/call-site IS the pattern source. Nothing new is invented — the new
> full-pipeline entry is `run_staging` widened to the whole `Main.f90:8-17` sequence:
> `payload_mass` → `orbit_speed_calculator` → `STAGING_LOOP` → `rocket_geometry_calculation`.
> The planner decides the bind(C) signature shape and output packing (D-02, Agent's Discretion).

---

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|---|---|---|---|---|
| `SRC/interface/C_Interface.f90` (modify — new full-pipeline bind(C) entry) | interface (Fortran bind(C) entry point) | request-response (scalars+arrays in, flat arrays+scalars out) | `run_staging` `C_Interface.f90:9-101` (self) | exact |
| `SRC/interface/rocket_lib.py` (modify — new full-pipeline ctypes wrapper) | service (ctypes bridge) | request-response | `run_staging` wrapper `rocket_lib.py:45-88` + argtypes `26-43` (self) | exact |
| `SRC/gui/gui.py` (modify — `_run` call site, `_auto_delta_v` removal, `_print_results` V_circ source, results render) | component (GUI controller) | request-response (event → bridge → render) | `_run` `gui.py:1066-1159` + `_print_results` `1014-1064` (self) | exact |

### Reference-only files (read, NOT modified — the new entry wires these in)

| File | Role in this phase |
|---|---|
| `SRC/Main.f90:8-17` | Console-path call order — the exact sequence the new entry must reproduce |
| `SRC/staging/Stage_Optimization_Loop.f90` | `STAGING_LOOP` (lines 1-48) — replaces the single `STAGING` call (D-02); reads `number_of_stages`, `V_circ`, `orbit_height` globals |
| `SRC/pre-staging-calcs/Orbit_calc.f90` | `orbit_speed_calculator` — sets `V_circ` global; must run before `STAGING_LOOP` (D-02) |
| `SRC/pre-staging-calcs/Payload_Mass_calc.f90` | `Payload_Mass_calculator` — sets `Rocket%rm_L` (console path); currently hand-mirrored inline at `C_Interface.f90:56-58` |
| `SRC/pre-simulation-calcs/Thrust_calc.f90` | `stage_Thrust_calculator` — sets stage `T`, `m_dot`, `t_burn` + `Rocket%rt_burn` (called inside `STAGING_LOOP`; DISCRETION: surface to GUI or keep internal) |
| `SRC/pre-simulation-calcs/Geometry_calc.f90` | `rocket_geometry_calculation` — sets stage `Diameter`/`Length`; reads `diameter_setup` / `user_defined_diameter` + propellant globals |
| `SRC/staging/Rocket_Types.f90` | `Stage_t` fields available to pack: `D_v` (line 19), `T`, `m_dot`, `t_burn` (16-18), `Diameter`, `Length` (22-23) |
| `SRC/staging/Staging.f90` | `STAGING` — sets per-stage `D_v` (line 141), `m_i` (147) — read after `STAGING_LOOP` converges (D-03) |
| `SRC/inout/Typical_Data.f90:36-50` | Module globals the ctypes path must seed: `V_circ`, `orbit_height`, `payload_mass`, `number_of_stages`, `diameter_setup`, `user_defined_diameter` (+ propellant/cycle ints, see Note B) |
| `SRC/Makefile` | Build — OBJS already links every pipeline module into `librocket`; all subroutines called (`STAGING_LOOP`, `orbit_speed_calculator`, `rocket_geometry_calculation`, `Payload_Mass_calculator`) are **external**, so `C_Interface.o` needs no new `.mod` deps (rule 5, lines 127-130) |
| `SRC/test_call.py` | Converts `run_staging` results to text — a smoke-test/verification hook, not production code |

---

## Pattern Assignments

### 1. `SRC/interface/C_Interface.f90` (interface, request-response)

**Analog:** `run_staging` `C_Interface.f90:9-101` (self — the new entry is this pattern widened)

**bind(C) signature pattern — header** (`C_Interface.f90:9-16`) — scalar args are `intent(in/out)` pointers, **no `VALUE`** (Python passes `byref`):
```fortran
subroutine run_staging(                         &
    n_stages,                                   &
    delta_v_in, payload_mass_in,                &
    isp_in, ks_in,                              &
    m0_out, mf_out, mp_out, ms_out,             &
    km_out, ks_out, kl_out,                     &
    nu_e_out, total_m0_out, minimum_found_out   &
    ) bind(C, name="run_staging")

    integer(c_int),  intent(in)  :: n_stages        ! no VALUE
    real(c_double),  intent(in)  :: delta_v_in      ! no VALUE
    real(c_double),  intent(in)  :: payload_mass_in ! no VALUE
    real(c_double),  intent(in)  :: isp_in(n_stages)
    real(c_double),  intent(in)  :: ks_in(n_stages)

    real(c_double),  intent(out) :: m0_out(n_stages)
    ...
    real(c_double),  intent(out) :: total_m0_out
    integer(c_int),  intent(out) :: minimum_found_out
```
New entries to add (planner's discretion on exact layout): `orbit_height_in`, `diameter_setup_in`, `user_diameter_in`; outputs `v_circ_out` (V_circ, D-01/D-04), per-stage `dv_out`, `diameter_out`, `length_out` (D-03), optionally `thrust_out`, `m_dot_out`, `t_burn_out` and `rt_burn_out`. Stage_t fields are all `real(8)` (Rocket_Types.f90:15-23) → `real(c_double)` in the bind.

**Module-global seeding pattern** (`C_Interface.f90:39-42`) — extend for every global the pipeline reads:
```fortran
    ! --- Set module-level globals used by STAGING ---
    Rocket%delta_v          = delta_v_in
    payload_mass     = payload_mass_in
    number_of_stages = n_stages
```
New globals that MUST be seeded before the pipeline calls (currently **never set on the ctypes path**):
- `orbit_height` — read by `orbit_speed_calculator` (`Orbit_calc.f90:9`) and `STAGING_LOOP` (`Stage_Optimization_Loop.f90:24`). **Do not skip: without it V_circ and the loss model are wrong.**
- `diameter_setup`, `user_defined_diameter` — read by `rocket_geometry_calculation` (`Geometry_calc.f90:92-104`); feed from GUI `self.diameter_mode`/`self.diameter_spin` (`gui.py:905, 924-930, 949-955`).
- `V_circ` — set by calling `orbit_speed_calculator` (not assigned by hand — PIPE-02).

**`Rocket%rm_L` init pattern** (`C_Interface.f90:53-58`) — keep, or replace the hand-mirrored PAF formula with the real call (console path):
```fortran
    ! --- Initialize Rocket%rm_L (G-01-2) ---
    Rocket%rm_L = payload_mass + 0.0755d0 * payload_mass + 50.d0
```
D-02/console parity suggests: `call Payload_Mass_calculator(Rocket)` after seeding `payload_mass` (equivalent formula, `Payload_Mass_calc.f90:11-19`) — planner's call; either way `Rocket%rm_L` must be set before `STAGING_LOOP` (Staging.f90:86 reads it).

**Pipeline call sequence — copy from the console path** (`Main.f90:8-17`), replacing the single `call STAGING(Rocket)` at `C_Interface.f90:61` (D-02):
```fortran
    call Payload_Mass_calculator(Rocket)   ! or keep inline formula above
    call orbit_speed_calculator            ! sets V_circ global — run BEFORE STAGING_LOOP (D-02)
    call STAGING_LOOP(Rocket)              ! converges delta_v + DV_loss to 1e-6, ≤50 iters
    call rocket_geometry_calculation(Rocket)
```
Notes the planner must carry into the plan:
- `STAGING_LOOP` calls `stage_Thrust_calculator` internally (`Stage_Optimization_Loop.f90:36`) — thrust metrics are computed for free; surfacing them is pure output-packing.
- `STAGING_LOOP` prints `'Delta_V = '` each iteration and the iteration count (`Stage_Optimization_Loop.f90:43-46`); the GUI will inherit console prints — acceptable, note in plan.
- `Stage_Optimization_Loop.f90:23` hardcodes `T_a = 400.d0` after the stage-count selection — console-path quirk inherited by the GUI path; do NOT "fix" silently.

**Result packing pattern** (`C_Interface.f90:64-75`) — extend the loop with the new per-stage outputs; `D_v` is already set by `STAGING` at `Staging.f90:141` (converged value after the loop — D-03), `Diameter`/`Length` by `Geometry_calc.f90:105/22-104`:
```fortran
    do i = 1, n_stages
        m0_out(i)   = Rocket%stage(i)%m_0
        ...
        nu_e_out(i) = Rocket%stage(i)%nu_e
    end do

    total_m0_out = Rocket%rm_0
```

**Minimum-found check** (`C_Interface.f90:77-97`) — the eq-26 check is duplicated between `run_staging` (lines 81-91) and `STAGING` itself (`Staging.f90:126-136`); keep run_staging's copy as the pack path (it sets `minimum_found_out` from `check_count`) — planner's call whether to reuse, but do not invent a third copy.

**Cleanup** (`C_Interface.f90:99`): `deallocate(Rocket%stage)` — keep after the new sequence.

---

### 2. `SRC/interface/rocket_lib.py` (service, request-response)

**Analog:** `run_staging` `rocket_lib.py:26-88` (self). The new wrapper is added **alongside** `run_staging` (Deferred FIX-02 — dedup stays Phase 3; the GUI's inline twin is dropped when it switches, planner's discretion per CONTEXT line 95).

**DLL-load + argtypes declaration pattern** (`rocket_lib.py:17-43`) — extend the argtypes list to match the new bind(C) signature (same count/order discipline — this list is the Fortran↔Python contract):
```python
lib.run_staging.restype = None
lib.run_staging.argtypes = [
    ctypes.POINTER(ctypes.c_int),    # n_stages
    ctypes.POINTER(ctypes.c_double), # delta_v
    ctypes.POINTER(ctypes.c_double), # payload_mass
    ctypes.POINTER(ctypes.c_double), # isp_in      (array)
    ...
    ctypes.POINTER(ctypes.c_int),    # minimum_found_out
]
```
New wrapper adds scalars by `ctypes.byref` and per-stage arrays by `(ctypes.c_double * n_stages)()` (see below).

**Wrapper boilerplate pattern** (`rocket_lib.py:45-69`) — scalars in/out + flat arrays, one `lib.<entry>(...)` call:
```python
def run_staging(n_stages, delta_v, payload_mass, isp_list, ks_list):
    """Call the Fortran STAGING solver. Returns a dict with results."""
    n  = ctypes.c_int(n_stages)
    dv = ctypes.c_double(delta_v)
    pl = ctypes.c_double(payload_mass)

    isp  = (ctypes.c_double * n_stages)(*isp_list)
    ks   = (ctypes.c_double * n_stages)(*ks_list)
    m0   = (ctypes.c_double * n_stages)()
    ...
    total_m0  = ctypes.c_double()
    min_found = ctypes.c_int()

    lib.run_staging(
        ctypes.byref(n), ctypes.byref(dv), ctypes.byref(pl),
        isp, ks,
        m0, mf, mp, ms, km, ks_o, kl, nu_e,
        ctypes.byref(total_m0), ctypes.byref(min_found)
    )
```
New full-pipeline wrapper: same shape; add `orbit_height_in`, `diameter_setup_in`, `user_diameter_in` inputs and the new out-scalars (`v_circ`, `rt_burn`) via `ctypes.c_double()` + `byref`.

**Return-dict pattern** (`rocket_lib.py:71-88`) — extend with `v_circ` (D-01/D-04: label + export source) and the per-stage keys the `ResultCard` already reads via `.get()` (`gui.py:600-603` → `dv`, `diameter`, `length`, `volume`; D-03): the wrapper's dict becomes the single contract the GUI consumes:
```python
    return {
        "total_initial_mass": total_m0.value,
        "minimum_found":      bool(min_found.value),
        "v_circ":             v_circ.value,          # NEW — label + export (D-01/D-05)
        "rt_burn":            rt_burn.value,         # NEW (optional, thrust discretion)
        "stages": [
            {
                "stage":   i + 1,
                "m0":      m0[i],
                ...
                "nu_e":    nu_e[i],
                "dv":      dv[i],                    # NEW — converged per-stage ΔV (D-03)
                "diameter": diameter[i],             # NEW
                "length":   length[i],               # NEW
                "volume":   volume[i],               # NEW (computed? see note)
                "thrust":   thrust[i],               # NEW (discretion: T / m_dot / t_burn)
            }
            for i in range(n_stages)
        ]
    }
```

---

### 3. `SRC/gui/gui.py` (component, request-response)

**Analog:** `_run` `gui.py:1066-1159` + `_print_results` `1014-1064` + `ResultCard` `541-605` (self).

**Call-site swap** (`gui.py:1090-1097`) — replace the inline `run_staging` with the new full-pipeline wrapper; new inputs already live on MainWindow (Phase 1 handoff, `gui.py:802-807, 905, 924-930, 949-955`):
```python
        try:
            results = run_staging(
                n_stages=n,
                delta_v=self._auto_delta_v(),
                payload_mass=self.pl_spin.value(),
                isp_list=isp_list,
                ks_list=ks_list,
            )
```
→ new call: `n_stages=n, orbit_height=self.orbit_height.value(), payload_mass=self.pl_spin.value(), isp_list=isp_list, ks_list=ks_list, diameter_setup=self.diameter_mode, user_diameter=self.diameter_spin.value()`. (Exact parameter layout follows the wrapper signature the planner fixes in Pattern 2; `delta_v`/`_auto_delta_v` argument disappears — the solver converges internally, D-02.)

**`_auto_delta_v` removal** (`gui.py:1002-1008`, docstring says "marked for removal, do not extend" — D-04). Its three call sites must switch to the Fortran-returned `v_circ`:
- `_update_auto_dv_label` (`gui.py:1010-1012`): reads the label from the last run's `v_circ` → store `self._last_v_circ = results["v_circ"]` in the `_run` success path (next to `self._last_results = results`, `gui.py:1146-1152`) and read it here; pre-run behavior (label before first run) is planner's call — a "—" placeholder matches the partial-state idiom (see Shared Patterns §6).
- `_print_results` (`gui.py:1019` `dv = self._auto_delta_v()`): → `dv = self._last_v_circ` (D-05 — export contract unchanged otherwise; filename line 1022 and Delta-V line 1035 keep the same format).
- `_run` (`gui.py:1093`): the argument disappears (solver-internal).

**Results render** (`gui.py:1122-1137`) — per-stage cards need zero signature churn: `ResultCard` already reads `data.get("dv")`, `data.get("diameter")`, `data.get("length")`, `data.get("volume")` (`gui.py:598-603`) and renders "—" for missing values. Once the wrapper packs them, the rows populate and the partial-state hint (`gui.py:1130-1137`) self-disables (its `any(... is None)` condition stops matching when all four keys are present). Remove or leave — planner's call; leaving it is inert.

**Error handling pattern — verbatim reuse** (`gui.py:1081-1088` validation → `QMessageBox.warning`, `1157-1159` bridge failure → critical):
```python
        try:
            results = run_staging(...)
            ...
        except Exception as e:
            QMessageBox.critical(self, "Fortran Error", str(e))
            return
```

**Bridge-import note (Deferred FIX-02):** `gui.py:29` already inserts `interface/` into `sys.path`, so `import rocket_lib` works from gui.py. The new wrapper lives only in `rocket_lib.py` — do NOT add a third copy of the ctypes machinery in gui.py. Removing the local `_lib`/`run_staging` (`gui.py:19-110`) is Phase 3 dedup, but the old inline duplicate is dropped when the GUI switches to the new entry "if it naturally lands there" (CONTEXT line 95 — planner's discretion).

---

## Shared Patterns

### 1. bind(C) pointer-scalar contract (no VALUE)
**Source:** `C_Interface.f90:18-20` + `rocket_lib.py:27-43`
**Apply to:** the new entry + wrapper — every scalar arg is `ctypes.POINTER(...)` on the Python side and `intent(in/out)` w/o `VALUE` on the Fortran side; arrays are explicit-shape `real(c_double) :: x(n)` passed as `(ctypes.c_double * n)()` buffers. Never `byref` a Python float; never `VALUE` in the bind.

### 2. ctypes array packing
**Source:** `rocket_lib.py:51-62`
**Apply to:** new wrapper — inputs `(ctypes.c_double * n_stages)(*in_list)`, outputs `(ctypes.c_double * n_stages)()` zero-initialized, results read by index into the returned dict.

### 3. Module-global seeding before solver calls
**Source:** `C_Interface.f90:39-42`
**Apply to:** the new entry — seed `payload_mass`, `number_of_stages`, `orbit_height`, `diameter_setup`, `user_defined_diameter` from the new args; `V_circ` comes from `orbit_speed_calculator` (never hand-computed, PIPE-02); `Rocket%rm_L` from the PAF formula or `Payload_Mass_calculator`.
**Note B (planner MUST decide):** `rocket_geometry_calculation` also reads `first/second/third_stage_propellant_and_oxidizer` (`Geometry_calc.f90:19-90`), which the ctypes path never sets → `case default` warnings and zero diameter/volume vectors. Either pass propellant/cycle ints from the GUI's `StageInputWidget` combos, or accept the empty-geometry warnings pending the deferred ISP/k_s authority decision (CONTEXT Deferred).

### 4. Pipeline call order
**Source:** `Main.f90:8-17` (console path — source of truth)
**Apply to:** the new entry's body. Order is mandatory: `Payload_Mass_calculator`/rm_L → `orbit_speed_calculator` (sets global read by `STAGING_LOOP` at `Stage_Optimization_Loop.f90:24`) → `STAGING_LOOP` → `rocket_geometry_calculation`.

### 5. GUI bridge-failure handling
**Source:** `gui.py:1090-1097` + `1157-1159`
**Apply to:** `_run` — wrap the new call in the same try/except; `QMessageBox.critical(self, "Fortran Error", str(e))` on any exception, return early. Input validation stays a `QMessageBox.warning` pre-check (`gui.py:1081-1088`).

### 6. Partial-state rendering with `.get()` defaults
**Source:** `gui.py:598-603` (ResultCard rows 4-5), `1129-1137` (hint), `972-983` (empty state)
**Apply to:** the results path — every new per-stage key is rendered through `data.get(key)` → "—" in `TEXT_DIM` when absent, so Phase 2 fills rows without touching card layout (CONTEXT: rows are additive/dynamic, D-03 reversibility). Store run outputs on `self._last_results` / `self._last_v_circ` at `gui.py:1146-1152`; `_print_results` guards on `hasattr(self, '_last_results')` (`gui.py:1015-1017`).

### 7. Bridge duplication guard
**Source:** `gui.py:19-110` (inline twin) vs `rocket_lib.py:17-88` (canonical)
**Apply to:** all Python work — the new entry is declared and wrapped exactly once in `rocket_lib.py`. gui.py imports it (`sys.path` hook already at `gui.py:29`); the inline `_lib`/`run_staging` twin is deleted when the switch lands (FIX-02, Phase 3 — no third copy ever).

---

## No Analog Found

| Target | Role | Data Flow | Reason / Substitute |
|--------|------|-----------|---------------------|
| V_circ feed-back from Fortran to the Setup "ΔV (auto)" label after a run | state exchange | Fortran → GUI | No codebase precedent — the label computes locally today (`_update_auto_dv_label` `gui.py:1010-1012` → `_auto_delta_v`). Substitute: the `_last_results` storage idiom (`gui.py:1146-1152`) extended with `self._last_v_circ`; pre-run placeholder per Shared Patterns §6. |
| Thrust metrics surfaced in the GUI (T / m_dot / t_burn / rt_burn) | display (optional) | Fortran → GUI | No GUI display exists; `Thrust_calc.f90:24-26` computes them inside `STAGING_LOOP` already. If surfaced, pack via the Pattern 1 result-packing loop and render with the `add_metric` idiom (`gui.py:569-588`); otherwise keep internal (CONTEXT discretion). |