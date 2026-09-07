# Phase 3: Bridge & Correctness Fixes - Context

**Gathered:** 2026-09-06
**Status:** Ready for planning

<domain>
## Phase Boundary

Consolidate the Fortran↔Python ctypes bridge to a single authoritative entry and remove three correctness shortcuts (REQUIREMENTS.md FIX-01/02/03):

- **FIX-01** — `Rocket%rm_L` is initialized on every bridge path from a single formula source.
- **FIX-02** — the duplicated `run_staging` ctypes bridge is consolidated into one module; `gui.py` uses it (decided: single-entry removal, D-04).
- **FIX-03** — hardcoded MinGW path is removed/replaced with a resolvable library path.

Scope anchor: the code is NOT broken-from-scratch — the GUI already runs `rocket_lib.run_full_pipeline` (`gui.py:1143`) and `Rocket%rm_L` is already initialized on both bridge entries (via two different mechanisms). This phase is **consolidation to one authoritative path**, not green-field fixing.

Hard boundary: console-path Fortran algorithm files stay byte-identical — only `SRC/interface/C_Interface.f90` (bridge-entry edits) is touched on the Fortran side; `Staging.f90`, `Stage_Optimization_Loop.f90`, `Payload_Mass_calc.f90`, `Geometry_calc.f90`, `Thrust_calc.f90` algorithms are NOT modified. FIX-04/FIX-05/FIX-06 remain out of scope (REQUIREMENTS.md:34-38).

</domain>

<decisions>
## Implementation Decisions

### rm_L authority (FIX-01)
- **D-01:** `Rocket%rm_L` is computed ONLY by `Payload_Mass_calculator` (`Payload_Mass_calc.f90`, eq. 11: `rm_L = payload_mass + 0.0755*payload_mass + 50`). Every remaining bridge entry calls it. The inline formula copy in `run_staging` (`C_Interface.f90:54-59`) dies with that entry (D-04) — no second copy is ever created.
- **D-02:** Regression guard — conservative bounds added to `SRC/test/test_rocket_lib.py`: stage-1 mass `m0` finite AND `> payload+PAF`, and `k_L ∈ (0,1)`. Catches uninitialized/garbage masses cheaply without pinning exact physics.
- **D-03:** rm_L consolidation is FOLDED into the bridge-dedup change, not a standalone fix. Planner rescopes 03-01 vs 03-02 accordingly (03-01 may reduce to verification + the bounds test if dedup absorbs the formula removal).

### Bridge consolidation (FIX-02)
- **D-04:** SINGLE-ENTRY consolidation — remove `run_staging` at every layer:
  - Fortran `run_staging` subroutine (`C_Interface.f90:10-102`)
  - Python wrapper + argtypes (`rocket_lib.py:26-27,72-91`)
  - gui.py dead inline twin + private `_lib` DLL handle (`gui.py:30,58-111` — unreferenced dead code, IN-01)
  - `test_call.py` run_staging segment (`test_call.py:5,7`)
  - `RunStagingWrapperContract` test class (`test_rocket_lib.py:148+`)
  - `run_full_pipeline` becomes the ONLY bridge entry. Fortran `STAGING` itself STAYS (still called by `STAGING_LOOP` at `Stage_Optimization_Loop.f90:34` and the console path).
- **D-05:** Test suite reworked INSIDE the phase so it stays green at every commit: remove `RunStagingWrapperContract`, add the D-02 bounds test. No red-commit states.
- **D-06:** Codebase-map/docs refreshed in-phase, same commit set: `CONCERNS.md` dup-bridge (line 20) and rm_L (line 45) rows → resolved; `INTEGRATIONS.md` `run_staging` entry (line 63) + the "MINGW_BIN optional override" note removed; `STRUCTURE.md`/`TESTING.md` `run_staging` references updated; `PROJECT.md` (line 31 pending FIX-02) + `REQUIREMENTS.md` (FIX-01/02/03 ticked) + `AGENTS.md` priorities amended.
- **D-07:** `SRC/test_call.py` CONVERTED to a `run_full_pipeline` smoke (stays a standalone CLI smoke hook against the real DLL; needs the config-driven args incl. `diameter_mode`/`diameter`/`propellant_list`).

### Path resolution (FIX-03)
- **D-08:** Python side is **build/-only** — `rocket_lib.py` loads `build/librocket.dll` via `add_dll_directory(BUILD_DIR)`; the `MINGW_BIN` env lookup (`rocket_lib.py:19`) and the candidate-list block (gui.py:36, removed by D-04) are dropped. This depends on the Makefile continuing to copy the MinGW runtime DLLs into `build/` (`Makefile:168-174`) — that copy STAYS.
- **D-09:** Makefile `MINGW_BIN` (`SRC/Makefile:52`) resolves by DISCOVERY at build time — derive the dir from `where gfortran`/`which gfortran`, overridable via env/CLI `MINGW_BIN`, and fail with a clear hint when MinGW is not found. No drive-letter literal (`C:/TDM-GCC-64/bin`) remains anywhere.

### the agent's Discretion
- 03-01 vs 03-02 rescoping mechanics after the D-03 fold-in (which plan owns which file; execution order).
- Exact bounds-test assertion shape/message wording beyond the D-02 stated bounds.
- Whether to clean up now-orphaned Fortran bits post-removal (module globals seeded only by `run_staging`, unused exports) — permitted only if zero behavior change; skip if any doubt.
- Exact `where gfortran` output-parsing for the D-09 derivation and the error-line wording.
- Whether CR-01/WR-02/WR-03 robustness gaps (recorded by the Phase-2 verifier with disposition "Phase 3/fix") fit inside this phase's FIX scope — include only if they fit without expanding it; otherwise re-file as future-phase defects.

</decisions>

<specifics>
## Specific Ideas

No UI/product specifics. The user asked for a plain-language explanation of the three fixes and consistently chose the clean-consolidation path: **"Payload_Mass_calculator everywhere"**, **"single-entry (remove it all)"**, **"build/-only"**, **"discover, env override"**.

Working theme to honor: ONE authoritative bridge path, no hardcoded machine paths, no trailing dead code, suite stays green at every commit, console-path algorithms byte-untouched.

</specifics>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Phase requirements & traceability
- `.planning/REQUIREMENTS.md` §Fortran Bridge & Correctness (lines 24-38) — FIX-01/02/03 definitions; FIX-04/05/06 out-of-scope list
- `.planning/ROADMAP.md` §Phase 3 (lines 80-84) — phase goal, requirement mapping
- `.planning/PROJECT.md` — pipeline description (line 45), pending FIX-02 item (line 31)

### Bridge contract & carry-forward decisions (Phase 2)
- `.planning/phases/02-full-pipeline-exposure/02-CONTEXT.md` — P2 D-01..D-05 (V_circ label == ΔV line == filename export contract; GUI drives `run_full_pipeline`; converged STAGING_LOOP per-stage ΔV) + deferred ISP/k_s authority note (line 94) + FIX-02/03 deferral notes (lines 95-96)
- `.planning/phases/02-full-pipeline-exposure/02-PATTERNS.md` — bind(C) entry + ctypes wrapper + eq-26 pack pattern (the run_staging self-analog to remove)
- `.planning/phases/02-full-pipeline-exposure/02-02-SUMMARY.md` — Phase 2 delivery; "twin stays byte-untouched for Phase 3" (line 178)
- `.planning/phases/02-full-pipeline-exposure/02-REVIEW.md` — IN-01 debt record: gui.py inline twin is unreferenced dead code (line 70)

### Codebase maps (refresh targets + constraints)
- `.planning/codebase/CONCERNS.md` — lines 20-23 (dup bridge) and 45-49 (rm_L) are the bugs being fixed; rows → resolved in-phase (D-06)
- `.planning/codebase/INTEGRATIONS.md` — ctypes contract (line 63), MINGW_BIN env note (to remove per D-06/D-08)
- `.planning/codebase/STRUCTURE.md` — file/entry map (`run_staging` entry reference, line 77)
- `.planning/codebase/TESTING.md` — run_staging-based test guidance (lines 42-58) to update (D-06); golden-value idea (line 100, tied to out-of-scope FIX-05)

### Code (source of truth for the removal surface)
- `SRC/interface/C_Interface.f90` — `run_staging` (10-102) to delete; `run_full_pipeline` (line 169 calls `Payload_Mass_calculator`)
- `SRC/interface/rocket_lib.py` — `run_staging` wrapper (26-27,72-91) to delete; DLL load (lines 15-24) → build/-only (D-08)
- `SRC/gui/gui.py` — dead twin + `_lib` (30,58-111) to delete; `_run` call site (1143) survives
- `SRC/pre-staging-calcs/Payload_Mass_calc.f90` — authoritative rm_L (eq. 11) — NOT modified, but MUST be read
- `SRC/staging/Staging.f90` — rm_L read at line 86; `STAGING` stays (used at `Stage_Optimization_Loop.f90:34`)
- `SRC/Makefile` — `MINGW_BIN` (line 52); runtime-DLL copy into build/ (168-174)
- `SRC/test_call.py`, `SRC/test/test_rocket_lib.py` — run_staging consumers to convert/remove (D-04/D-05/D-07)
- `AGENTS.md` — project conventions + current-priorities list (amended in-phase per D-06)

### Robustness gaps recorded for this phase
- `.planning/phases/02-full-pipeline-exposure/02-VERIFICATION.md` §gaps (lines 185-189) — CR-01 ghost-stage Constant-mode pollution, WR-02 NaN/negative geometry, WR-03 negative-thrust domain (planner discretion whether any fit inside scope)

No external specs — standalone desktop app; requirements are fully captured above.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `Payload_Mass_calculator` (`Payload_Mass_calc.f90`) — the single authoritative PAF/rm_L model; bridge entries call it, never re-derive (D-01).
- Makefile runtime-DLL copy into `build/` (`Makefile:168-174`) — the mechanism D-08's build/-only resolution depends on; must not be removed.
- `import rocket_lib` after the sys.path hook (`gui.py:29`) — established single-bridge import pattern that survives dedup.
- `run_full_pipeline` output contract (02-01): keys `total_initial_mass`, `minimum_found`, `v_circ`, `stages[].dv/diameter/length/volume`.

### Established Patterns
- bind(C) entry + ctypes wrapper + `.argtypes` declared exactly once in `rocket_lib.py` (02-PATTERNS self-analog).
- eq-26 minimum-found check + result-packing block — after D-04 only ONE copy remains (in `run_full_pipeline`); never create a third.
- Env-var overrides documented in INTEGRATIONS.md — D-08 removes the Python-side `MINGW_BIN`; D-09 keeps it Makefile/build-time only.

### Integration Points
- `gui.py:1143` `_run` → `rocket_lib.run_full_pipeline(...)` — the surviving call path.
- `test_call.py` CLI smoke — converted to `run_full_pipeline` (D-07).
- `SRC/test/test_rocket_lib.py` + `SRC/test/test_gui_full_pipeline.py` — Phase 2 suites; rework (D-05) keeps them green.
- Makefile gfortran discovery — new build-time resolution boundary (D-09).

</code_context>

<deferred>
## Deferred Ideas

- **Rocket-diagram in Results** (user-requested this session): draw the launch vehicle with per-stage length/diameter from the selected configuration — the pipeline already returns `Diameter`/`Length`/`Volume` per stage. New visualization capability → own phase (Phase 4 candidate); can build on the single-bridge shape Phase 3 locks down.
- **ISP/k_s authority (tables vs sliders)** — deferred from Phase 2 (`02-CONTEXT.md:94`), blocked by out-of-scope FIX-05 (Soyuz TEST CASE overrides the tables). Dedup must PRESERVE today's slider-passing behavior; do not resolve here.
- **FIX-04** (config parser writes stage-2/3 combustion cycles into `first_stage_combustion_cycle`, `Typical_Data.f90:924-930`) and **FIX-05** (dead TEST CASE override) — out of scope, do not touch.
- **CR-01 / WR-02 / WR-03** — Phase-2 verifier disposition "Phase 3/fix": Constant-mode ghost-stage geometry pollution, NaN/negative geometry from vacant branches, negative-thrust domain. Not ROADMAP criteria; include only if they fit without expanding scope (agent discretion), else re-file.

</deferred>

---

*Phase: 03-bridge-correctness-fixes*
*Context gathered: 2026-09-06*