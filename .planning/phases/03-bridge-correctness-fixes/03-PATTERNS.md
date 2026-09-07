# Phase 3: Bridge & Correctness Fixes — Pattern Map

**Mapped:** 2026-09-06
**Files analyzed:** 13 modified files (+ 6 reference-only)
**Analogs found:** 13 / 13 (all self-analogs — this phase is in-place deletion + one-path consolidation)

> **Phase shape (from CONTEXT.md D-01..D-09):** remove the `run_staging` bridge at every
> layer (Fortran subroutine → Python wrapper → gui.py inline twin → test consumers),
> leave `run_full_pipeline` as the ONLY bridge entry, drop the Python-side `MINGW_BIN`
> lookup (build/-only DLL load), and replace the Makefile's hardcoded MinGW path with
> `?=` discovery + override + error hint. Every target has a **self-analog**: the
> surviving `run_full_pipeline` path in each file IS the pattern source, exactly as
> Phase 2 extended `run_staging` as its own self-analog (`02-PATTERNS.md:3-13`).
> Nothing new is invented — the phase deletes the duplicate and keeps the survivor.
>
> **Planning constraint (D-05, RESEARCH §Summary):** the dedup must land as ONE
> coordinated wave (Fortran + DLL rebuild + Python bridge + both test files + bounds
> test). `unittest discover` imports `test_rocket_lib.py:23` which imports
> `run_staging` at module scope — splitting the removal across waves produces a red
> suite at collection time. Never separate the wrapper removal from the test edit.

---

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|---|---|---|---|---|
| `SRC/interface/C_Interface.f90` (modify — DELETE `run_staging` 10–102) | interface (Fortran bind(C) entry) | request-response (scalars+arrays in, flat arrays+scalars out) | `run_full_pipeline` `C_Interface.f90:104-221` (self) | exact |
| `SRC/interface/rocket_lib.py` (modify — DELETE wrapper+argtypes 26–43/72–115; trim MINGW block 19–21) | service (ctypes bridge) | request-response | `run_full_pipeline` argtypes `rocket_lib.py:45-70` + wrapper `117-176` + load block `17-24` (self) | exact |
| `SRC/gui/gui.py` (modify — DELETE dead twin+`_lib`+candidates 20/25-26/32-56/58-111; fix comments 30/911) | component (GUI controller) | event-driven (GUI event → bridge call → render) | `_run` `gui.py:1118-1152` + `import rocket_lib` `29-30` (self) | exact |
| `SRC/test/test_rocket_lib.py` (modify — trim import 23; DELETE `RunStagingWrapperContract` 148–164; ADD D-02 bounds test) | test | verification | `RunFullPipelineVariantDomains._baseline` `95-145` + `N3_CONFIG` `30-39` (self) | exact |
| `SRC/test_call.py` (modify — DELETE run_staging block 1–20; keep + rework full-pipeline smoke 22–73 per D-07) | utility (CLI smoke hook) | request-response | full-pipeline smoke block `test_call.py:22-73` (self); `load_config` `Typical_Data.f90:896-938` for config-driven args | exact (partial for config-driven part) |
| `SRC/Makefile` (modify — line 52 `:=` → `?=` discovery + error hint; runtime-DLL copy 168–174 STAYS) | config (build) | batch | platform block `42-81` + runtime-DLL copy `168-174` (self); RESEARCH.md:214-224 verified pattern | exact |
| `AGENTS.md` (modify — amend current priorities) | config (project conventions) | — | self | exact |
| `.planning/codebase/CONCERNS.md` (refresh — rows 19–23, 44–49, 69–73 → resolved) | docs | — | self | exact |
| `.planning/codebase/INTEGRATIONS.md` (refresh — lines 47, 63–65) | docs | — | self | exact |
| `.planning/codebase/STRUCTURE.md` (refresh — lines 29, 77) | docs | — | self | exact |
| `.planning/codebase/TESTING.md` (refresh — lines 42–44, 58, 100) | docs | — | self | exact |
| `.planning/PROJECT.md` (refresh — lines 30–32, 45) | docs | — | self | exact |
| `.planning/REQUIREMENTS.md` (refresh — FIX-01/02/03 ticked, lines 26–28) | docs | — | self | exact |

### Reference-only files (read, NOT modified — hard boundary)

| File | Role in this phase |
|---|---|
| `SRC/pre-staging-calcs/Payload_Mass_calc.f90` | The **single rm_L authority** (D-01). `Payload_Mass_calculator` sets `Rocket%rm_L` (line 19) from `m_adapter = 0.0755d0 * payload_mass + 50` (line 12). `run_full_pipeline` already calls it (`C_Interface.f90:169`) — after D-04 this is the ONLY writer. Byte-identical. |
| `SRC/staging/Staging.f90` | `STAGING` **stays** — reads `Rocket%rm_L` at lines 86/106; sole remaining caller after removal is `STAGING_LOOP` (`Stage_Optimization_Loop.f90:34`). Byte-identical. |
| `SRC/staging/Stage_Optimization_Loop.f90` | `STAGING_LOOP` self-seeds `Rocket%delta_v` (line 26) — so deleting `run_staging`'s `delta_v` set (C_Interface.f90:41) orphans nothing. Byte-identical. |
| `SRC/test/test_gui_full_pipeline.py` | 13-test Phase-2 GUI-invocation suite. Grep confirms **no `run_staging` references** — survives untouched; D-05 keeps it green as-is. |
| `SRC/inout/Typical_Data.f90` | `load_config` (896–938) — the Fortran config.txt parser; the only precedent for D-07's config-driven `test_call.py` args. FIX-04/05 bugs in this file are OUT OF SCOPE. Byte-identical. |
| `SRC/Main.f90:8-17` | Console-path pipeline order — the call sequence `run_full_pipeline` reproduces. Byte-identical. |
| `build/librocket.dll` (+ 4 runtime DLLs) | Regenerated by `make all` in the same wave as the `C_Interface.f90` edit; then negative-export check `assert not hasattr(rocket_lib.lib, "run_staging")`. Not in git. |

---

## Pattern Assignments

### 1. `SRC/interface/C_Interface.f90` (interface, request-response)

**Analog:** `run_full_pipeline` `C_Interface.f90:104-221` (self — the surviving entry; its shape is what remains after deleting lines 10-102)

**Deletion surface** (D-04): `subroutine run_staging` lines 10-102 — the entire subroutine, including its inline rm_L copy at **lines 54-59** (`Rocket%rm_L = payload_mass + 0.0755d0 * payload_mass + 50.d0`) which is the FIX-01 second formula source that dies with the entry (D-01: no second copy ever).

**Orphan check (verified in RESEARCH.md:61,314-321):** nothing outside `run_staging` needs its seeds:
- `Rocket%delta_v` → also set by `STAGING_LOOP` (`Stage_Optimization_Loop.f90:26`)
- `payload_mass` / `number_of_stages` → also seeded by `run_full_pipeline` (`C_Interface.f90:146-147`)
- bare-`STAGING` callers after deletion → `Stage_Optimization_Loop.f90:34` only

**Surviving pattern — module header** (lines 1-8) stays as-is:
```fortran
module c_interface
    use iso_c_binding
    use rocket_types
    use typical_data
    use constants                                      ! added Phase 2 for pi
    implicit none
contains
```

**Surviving pattern — the single rm_L authority call** (line 169) — after D-04 this is the ONLY rm_L write on the bridge:
```fortran
    call Payload_Mass_calculator(Rocket)   ! sets Rocket%rm_L (PAF eq. 11)
```

**Surviving pattern — globals seeding** (lines 145-157) — already the only seeding path after the deletion:
```fortran
    ! --- Seed module-level globals read by the pipeline ---
    payload_mass          = payload_mass_in
    number_of_stages      = n_stages
    orbit_height          = orbit_height_in        ! [km], GUI units
    diameter_setup        = diameter_setup_in
    user_defined_diameter = user_diameter_in
    first_stage_propellant_and_oxidizer  = propellant_in(1)
    second_stage_propellant_and_oxidizer = propellant_in(min(2, n_stages))
    third_stage_propellant_and_oxidizer  = propellant_in(min(3, n_stages))
```

**Surviving pattern — pipeline call order** (lines 169-175, mirrors `Main.f90:8-17`; order is mandatory):
```fortran
    call Payload_Mass_calculator(Rocket)   ! sets Rocket%rm_L (PAF eq. 11)
    call orbit_speed_calculator            ! sets V_circ global BEFORE STAGING_LOOP
    call STAGING_LOOP(Rocket)              ! converged loop, not single STAGING
    call rocket_geometry_calculation(Rocket)
```

**Surviving pattern — result packing + eq-26 check + cleanup** (lines 177-219): the flat-array pack loop, `total_m0_out = Rocket%rm_0` / `v_circ_out = V_circ` (194-195), the eq-26 `check_count` block (197-217), `deallocate(Rocket%stage)` (219). These stay byte-identical — the plan touches only lines 10-102.

**Verification:** rebuild DLL (`make all`) then negative-export check — see Shared Patterns §5.

---

### 2. `SRC/interface/rocket_lib.py` (service, request-response)

**Analog:** `run_full_pipeline` block `rocket_lib.py:45-70 + 117-176` (self — the surviving declaration+wrapper; the load block's target state is 17-24 minus 19-21).

**Deletion surface:**
- Lines 19-21 (`mingw_bin = os.environ.get(...)` + conditional `add_dll_directory`) — D-08: build/-only, env lookup dropped.
- Lines 26-43 (`lib.run_staging.restype/.argtypes`) — D-04.
- Lines 72-115 (`def run_staging(...)` wrapper) — D-04.

**Target load block after D-08** (lines 17-24; lines 19-21 removed):
```python
if sys.platform == "win32":
    os.add_dll_directory(BUILD_DIR)
    lib = ctypes.CDLL(os.path.join(BUILD_DIR, "librocket.dll"))
else:
    lib = ctypes.CDLL(os.path.join(BUILD_DIR, "librocket.so"))
```

**Surviving pattern — single authoritative argtypes declaration** (lines 45-70) — after D-04 this is the ONLY declaration in the codebase (gui.py's copy dies; Pattern 3). The `restype = None` + ordered `ctypes.POINTER(...)` list is the Fortran↔Python contract:
```python
lib.run_full_pipeline.restype = None
lib.run_full_pipeline.argtypes = [
    ctypes.POINTER(ctypes.c_int),    # n_stages
    ctypes.POINTER(ctypes.c_double), # orbit_height
    ...                              # 24 entries total, EXACT bind(C) order
    ctypes.POINTER(ctypes.c_int),    # minimum_found
]
```

**Surviving pattern — wrapper boilerplate** (lines 117-152) — scalars in/out by `byref`, per-stage arrays by `(ctypes.c_double * n_stages)()` / `(ctypes.c_double * n_stages)(*in_list)`:
```python
def run_full_pipeline(n_stages, orbit_height, payload_mass, isp_list, ks_list,
                      propellant_list, diameter_setup, user_diameter):
    n  = ctypes.c_int(n_stages)
    oh = ctypes.c_double(orbit_height)
    ...
    isp  = (ctypes.c_double * n_stages)(*isp_list)
    prop = (ctypes.c_int * n_stages)(*propellant_list)
    m0   = (ctypes.c_double * n_stages)()
    ...
    lib.run_full_pipeline(
        ctypes.byref(n), ctypes.byref(oh), ctypes.byref(pl),
        isp, ks, prop,
        ctypes.byref(ds), ctypes.byref(ud),
        m0, mf, mp, ms, km, ks_o, kl, nu_e, dv, diam, leng, vol,
        ctypes.byref(total_m0), ctypes.byref(v_circ), ctypes.byref(min_found)
    )
```

**Surviving pattern — return-dict contract** (lines 154-176): keys `total_initial_mass`, `minimum_found` (bool), `v_circ`, `stages[].{stage,m0,mf,mp,ms,k_m,k_s,k_L,nu_e,dv,diameter,length,volume}`. This dict is the single contract the GUI consumes (`gui.py:1143-1152`) and the tests assert (`test_rocket_lib.py:54-63`).

---

### 3. `SRC/gui/gui.py` (component, event-driven)

**Analog:** `_run` `gui.py:1118-1152` + `import rocket_lib` line 29-30 (self — the surviving import + call path).

**Deletion surface** (D-04 + D-08, per RESEARCH.md:53):
- Line 20 `import ctypes` — safe only after re-grep proves no surviving `ctypes.` reference (grep this session: every use sits in lines 58-111, the removed twin; line 911 is a comment).
- Lines 25-26 (`BUILD_DIR` computed) + 32-34 (`os.add_dll_directory(os.path.abspath(BUILD_DIR))`) — redundant with rocket_lib's own loader; dead after the twin dies.
- Lines 36-56 (`_MINGW_CANDIDATES` candidate list + WARNING print) — D-08.
- Lines 58-60 (`_lib = ctypes.CDLL(...)`), 62-79 (`_lib.run_staging.restype/.argtypes`), 81-111 (`def run_staging(...)` twin) — unreferenced dead code (IN-01, `02-REVIEW.md:70`).

**Surviving pattern — bridge import** (lines 28-30; comment on 30 must be rewritten — "the inline twin below stays for Phase 3 dedup" is stale after the deletion):
```python
# Make sure interface/ is on the path so rocket_lib can be imported if needed
sys.path.insert(0, os.path.join(ROOT_DIR, "interface"))
import rocket_lib   # full-pipeline bridge entry (02-01)
```

**Surviving pattern — the call site** (lines 1142-1152) — unchanged; this is what D-04 preserves:
```python
        try:
            results = rocket_lib.run_full_pipeline(
                n_stages=n,
                orbit_height=self.orbit_height.value(),
                payload_mass=self.pl_spin.value(),
                isp_list=isp_list,
                ks_list=ks_list,
                propellant_list=[sw.get_propellant_index() for sw in self.stage_widgets],
                diameter_setup=self.diameter_mode,
                user_diameter=self.diameter_spin.value(),
            )
```

**Surviving pattern — error handling** (the try/except wrapped around the call; the `except` branch at ~1153-1155 shows `QMessageBox.critical(self, "Fortran Error", str(e))` + return; input validation is a `QMessageBox.warning` pre-check at 1133-1140). The call site and error handling are byte-untouched — the plan edits ONLY the deleted block + the two stale comments (line 30, line 911 "NOT wired into run_staging").

---

### 4. `SRC/test/test_rocket_lib.py` (test, verification)

**Analog:** `RunFullPipelineContract` (49-92) + `RunFullPipelineVariantDomains` (95-145) + `N3_CONFIG` (30-39) — self; the D-02 bounds test slots into this structure.

**Deletion surface:**
- Line 23: `from rocket_lib import run_full_pipeline, run_staging` → drop `run_staging`. **(Must land in the same commit as the rocket_lib.py removal — D-05; see Pitfall 1.)**
- Lines 148-164: `class RunStagingWrapperContract` (the legacy regression companion).

**Surviving pattern — module-scope imports + config dict** (lines 12-39):
```python
import math
import os
import sys
import unittest

_TEST_DIR  = os.path.dirname(os.path.abspath(__file__))
_SRC_DIR   = os.path.abspath(os.path.join(_TEST_DIR, ".."))
_INTERFACE = os.path.join(_SRC_DIR, "interface")
if _INTERFACE not in sys.path:
    sys.path.insert(0, _INTERFACE)

from rocket_lib import run_full_pipeline

# Smoke baseline (test_call.py): LH2/LOX, n=3, orbit 500 km, payload 5000 kg
N3_CONFIG = dict(
    n_stages=3,
    orbit_height=500.0,
    payload_mass=5000.0,
    isp_list=[400.0, 350.0, 300.0],
    ks_list=[0.10, 0.15, 0.20],
    propellant_list=[1, 1, 1],
    diameter_setup=1,
    user_diameter=2.0,
)
```

**Surviving pattern — `_baseline` helper** (lines 98-100) — the D-02 test should use this, not a fresh call:
```python
    def _baseline(self, **overrides):
        cfg = dict(N3_CONFIG, **overrides)
        return run_full_pipeline(**cfg)
```

**New pattern — D-02 conservative bounds test** (RESEARCH.md:323-339; shape; message wording is discretion). Note: the research sketch references `self.payload_mass`, which does NOT exist on the test classes — the planner must source it from `N3_CONFIG["payload_mass"]` (or a class constant) to mirror the PAF formula:
```python
def test_conservative_bounds_n3(self):
    """D-02: catches uninitialized/garbage masses without pinning physics."""
    r = self._baseline()
    paf = 0.0755 * N3_CONFIG["payload_mass"] + 50.0   # PAF eq. 11 (Payload_Mass_calc.f90:12)
    m0 = r["stages"][0]["m0"]
    self.assertTrue(math.isfinite(m0))
    self.assertGreater(m0, N3_CONFIG["payload_mass"] + paf)   # m0 must exceed payload + PAF
    for s in r["stages"]:
        self.assertGreater(s["k_L"], 0.0)
        self.assertLess(s["k_L"], 1.0)               # k_L ∈ (0,1)
```
Probe data (RESEARCH.md:339): N3 smoke `m0=120771.89`, `paf=427.50`, `k_L=[0.355531]*3` — bounds cannot false-fail on valid inputs across n=1/2/3 × payload 1000-1,000,000 kg × orbit 100-2000 km.

---

### 5. `SRC/test_call.py` (utility / CLI smoke, request-response)

**Analog:** the full-pipeline smoke block `test_call.py:22-73` (self — stays and becomes the whole file); `load_config` `Typical_Data.f90:896-938` (config-driven-args precedent, Fortran side).

**Deletion surface** (D-04): lines 1-20 — the `import os/sys` + `sys.path.insert` + `from rocket_lib import run_staging` + `run_staging(...)` call + its print block. **Note:** lines 2-4 (`os`/`sys` import + sys.path hook) are ALSO needed by the surviving smoke's `from rocket_lib import run_full_pipeline` — the plan must keep the sys.path plumbing, only the `run_staging` import/call/print goes.

**Surviving pattern — the smoke body** (lines 22-73): `run_full_pipeline(...)` call with explicit kwargs, v_circ-print, and the five assertion groups (a)-(e) at lines 46-71:
```python
# ---------------------------------------------------------------------------
# Full-pipeline smoke (run_full_pipeline) — PIPE-02 headless bridge proof
# ---------------------------------------------------------------------------
from rocket_lib import run_full_pipeline

import math

fp = run_full_pipeline(
    n_stages        = 3,
    orbit_height    = 500.0,
    payload_mass    = 5000.0,
    isp_list        = [400.0, 350.0, 300.0],
    ks_list         = [0.10,  0.15,  0.20],
    propellant_list = [1, 1, 1],
    diameter_setup  = 1,
    user_diameter   = 2.0,
)
# (a) v_circ == Orbit_calc.f90:10 formula within 1e-6
# (b) per-stage dv/diameter/length/volume finite and > 0
# (c) volume == pi/4 * D^2 * L identity within 1e-9
# (d) v_circ < sum(dv) < v_circ + 5.0
# (e) total_initial_mass > payload_mass; minimum_found is bool
```

**D-07 extension — config-driven args (NO Python precedent):** the current smoke hardcodes kwargs. D-07 wants config-driven args incl. `diameter_mode`/`diameter`/`propellant_list`. There is **no Python config.txt parser** in the codebase — grep for `config.txt|load_config|configparser` in `SRC/*.py` finds only mirroring comments in `gui.py:948,963`. The only parser is Fortran `load_config` (`Typical_Data.f90:896-938`, keys confirmed in `SRC/config.txt`: `orbit_height`, `payload_mass`, `number_of_stages`, `first/second/third_stage_propellant_and_oxidizer`, `Diameter_setup`, `User_defined_diameter`). Planner's discretion: either a minimal line-parse of config.txt inside test_call.py (matching those keys) or keep the literal kwargs. See No-Analog row.

---

### 6. `SRC/Makefile` (config / build, batch)

**Analog:** self — the platform block (42-81, hardcoded `MINGW_BIN` at 52, dead `RUNTIME_DLLS` at 53-57) plus the runtime-DLL copy (168-174, STAYS). The replacement pattern is **empirically verified on both installed makes** (RESEARCH.md:63, 214-224).

**Change — line 52 replacement** (D-09; note line 52 currently uses `:=` which silently ignores overrides — `?=` is required):
```make
# SRC/Makefile, Windows branch — replace line 52 `MINGW_BIN := C:/TDM-GCC-64/bin` with:
MINGW_BIN ?= $(patsubst %\gfortran.exe,%,$(firstword $(shell where gfortran 2>NUL)))
ifeq ($(strip $(MINGW_BIN)),)
    $(error gfortran not found in PATH. Install TDM-GCC/MinGW-w64 or set MINGW_BIN=<dir> explicitly.)
endif
```
- `where gfortran 2>NUL` → `C:\TDM-GCC-64\bin\gfortran.exe` (2>NUL suppresses the localized stderr INFO line)
- `patsubst %\gfortran.exe,%` strips the executable → the directory; `firstword` guards multiple PATH hits
- The runtime-DLL copy rules (170-173, backslash-joined `$(MINGW_BIN)\libgfortran_64-5.dll` etc.) work unchanged with the discovered backslash path → **do not touch 168-174** (D-08 depends on it)
- Failure mode under a future `sh.exe` on PATH: `where` doesn't exist under sh → empty → the `$(error ...)` hint fires with `MINGW_BIN=<dir>` as the escape hatch (RESEARCH.md Pitfall 3)

**Optional cleanup (discretion):** `RUNTIME_DLLS` (53-57) is a dead variable — the copy rules hardcode the four names. Folding the rules onto it must not change behavior; skipping is fine.

---

### 7-13. Docs refresh targets (D-06) — each is a self-analog

| File | Edits (all in the same commit set as the code wave) |
|---|---|
| `AGENTS.md` | "Current priorities" list (lines 36-42): mark the three fixes as now-done; keep "Automated tests are deferred". |
| `.planning/codebase/CONCERNS.md` | Rows → resolved: "Duplicated ctypes bridge" (19-23), "`Rocket%rm_L` never initialized on the ctypes/GUI path" (44-49), "Hardcoded MinGW path" (69-73). Keep the other rows untouched — FIX-04/05/06 (lines 7-17, 30-34, 77-87) stay open. |
| `.planning/codebase/INTEGRATIONS.md` | Remove the `MINGW_BIN` env-var line (47) and rewrite the Bridge Layer section (61-65) → `run_full_pipeline` only, build/-only DLL load. |
| `.planning/codebase/STRUCTURE.md` | Line 29 `# bind(C) run_staging` → `run_full_pipeline`; line 77 entry updated. |
| `.planning/codebase/TESTING.md` | Lines 42-44 (example uses `run_staging`) → `run_full_pipeline`; line 58 guidance → `run_full_pipeline` (still bypasses `load_config`); line 100 golden-value idea re-pointed at the surviving entry. |
| `.planning/PROJECT.md` | Lines 30-32 (Active FIX-01/02/03) → move to Validated with phase reference; line 45 context paragraph → drop the "interim `run_staging` bridge remains" wording. |
| `.planning/REQUIREMENTS.md` | Lines 26-28: FIX-01/02/03 `[ ]` → `[x]`. |
| `.planning/ROADMAP.md` (optional) | Phase-3 section (80-94) plan checkboxes + progression marks — not in D-06's explicit list; update if the phase flow updates it. |

---

## Shared Patterns

### 1. PAF eq-11 rm_L authority — never re-derive
**Source:** `Payload_Mass_calc.f90:12,19` (the ONLY writer after D-04) + call site `C_Interface.f90:169`.
**Apply to:** `C_Interface.f90` — after deleting the `run_staging` inline copy (54-59), `run_full_pipeline`'s `call Payload_Mass_calculator(Rocket)` is the sole initialization path on the ctypes side. FIX-01 is satisfied by the deletion itself (D-03 fold-in); do NOT add a formula anywhere else.
```fortran
! Payload_Mass_calc.f90:12  —  m_adapter = 0.0755d0 * payload_mass + 50
! Payload_Mass_calc.f90:19  —  Rocket%rm_L = payload_mass + m_adapter
```

### 2. bind(C) pointer-scalar contract (no VALUE)
**Source:** `C_Interface.f90:115-139` (`run_full_pipeline` signature) + `rocket_lib.py:45-70` (argtypes).
**Apply to:** all Python work — every scalar arg is `ctypes.POINTER(...)` on the Python side and `intent(in/out)` WITHOUT `VALUE` on the Fortran side; arrays are explicit-shape `real(c_double) :: x(n)` passed as `(ctypes.c_double * n)()` buffers. Never `byref` a raw Python float; never `VALUE` in the bind. After D-04 the declaration exists exactly once (`rocket_lib.py:45-70`) — see also Shared Pattern 3.

### 3. Single authoritative bridge module
**Source:** `rocket_lib.py:17-176` (target state) vs the deleted twins (`gui.py:19-111`, `rocket_lib.py:26-43/72-115`).
**Apply to:** all Python work — the GUI (and any smoke/test) imports `rocket_lib` and calls `run_full_pipeline(...)`; ctypes machinery (CDLL, add_dll_directory, argtypes) lives ONLY in `rocket_lib.py`. gui.py never re-declares argtypes and holds no DLL handle (PER the 02-PATTERNS "Bridge duplication guard", Shared §7).

### 4. ctypes array packing
**Source:** `rocket_lib.py:127-141`.
**Apply to:** `rocket_lib.py` (survivor) + `test_call.py` (converted smoke) — inputs `(ctypes.c_double * n_stages)(*in_list)` / `(ctypes.c_int * n_stages)(*propellant_list)`, outputs `(ctypes.c_double * n_stages)()` zero-initialized, results read by index into the returned dict.

### 5. Verification order for the dedup wave (D-05 + Pitfall 2)
**Source:** RESEARCH.md:263-273 + `test_rocket_lib.py` collection mechanics.
**Apply to:** the executor's sequence, in order:
1. Edit Fortran (delete 10-102) + Python (delete blocks) + tests (trim import, drop class, add bounds) + test_call + gui.py — same commit.
2. `make all` / `make gui` to regenerate `build/librocket.dll`.
3. Negative export check: `assert not hasattr(rocket_lib.lib, "run_staging")`.
4. `python -m unittest discover -s SRC/test -p "test_*.py"` — full 23+ suite green (10+13 baseline; minus 1 removed run_staging test, plus 1 bounds test).

### 6. GUI bridge-failure handling (unchanged)
**Source:** `gui.py:1133-1140` (validation `QMessageBox.warning`) + 1142-1152 try/except → `QMessageBox.critical(self, "Fortran Error", str(e))` + return.
**Apply to:** gui.py — the `_run` call block survives byte-identical; the plan must NOT disturb the try/except wrapper while deleting the twin above it.

### 7. unittest discovery import discipline
**Source:** `test_rocket_lib.py:12-23` (module-scope `from rocket_lib import ...`).
**Apply to:** `test_rocket_lib.py` + `test_call.py` — module-scope imports of `rocket_lib` symbols are collected at discovery; the `run_staging` import removal and the `rocket_lib.py` wrapper removal are ONE commit or the suite imports red (Pitfall 1). Same discipline: deleting `import ctypes` from gui.py requires a re-grep for surviving `ctypes.` uses first (Pitfall 4).

---

## No Analog Found

| File | Role | Data Flow | Reason / Substitute |
|---|---|---|---|
| `test_call.py` config-driven args (D-07 portion) | utility | batch (config read → bridge call) | No Python-side config.txt parser exists anywhere in `SRC/` (grep: only mirroring comments in `gui.py:948,963`). The only precedent is Fortran `load_config` (`Typical_Data.f90:896-938`) with keys in `SRC/config.txt` (orbit_height, payload_mass, number_of_stages, `<n>_stage_propellant_and_oxidizer`, `Diameter_setup` [note the case], `User_defined_diameter`). Planner discretion: minimal line-parse in test_call.py or keep literals; the `N3_CONFIG` dict (`test_rocket_lib.py:30-39`) is the closest Python-shape precedent. |
| Negative-export check `not hasattr(rocket_lib.lib, "run_staging")` | verification step (not a file) | — | No precedent — it is a one-off verification command (RESEARCH.md:231, 272), not a code artifact. Runs after the rebuild; needs `rocket_lib.lib` accessible (import rocket_lib first). |

---

## Metadata

**Analog search scope:** `SRC/interface/`, `SRC/gui/`, `SRC/test/`, `SRC/`, `SRC/pre-staging-calcs/`, `SRC/inout/`, `.planning/codebase/`, `.planning/PROJECT.md`, `.planning/REQUIREMENTS.md`, `.planning/ROADMAP.md`, `.planning/phases/02-full-pipeline-exposure/`
**Files scanned:** 17 (8 source + 2 test + 3 config + 5 planning docs; + test_gui_full_pipeline.py confirmed untouched by grep)
**Pattern extraction date:** 2026-09-06
**Line numbers valid until:** tree changes before planning — re-verify via the line anchors cited (CONTEXT.md:25-49, RESEARCH.md:18-32, and the file reads above)