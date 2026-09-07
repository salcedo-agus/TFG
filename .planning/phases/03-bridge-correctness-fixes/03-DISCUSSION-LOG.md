# Phase 3: Bridge & Correctness Fixes - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-09-06
**Phase:** 03-bridge-correctness-fixes
**Areas discussed:** rm_L authority, Legacy entry fate (bridge consolidation depth), MinGW path strategy

---

## Session preface

- The user's first answer was a scope-creep feature request (rocket diagram in Results). Captured as a deferred idea for its own phase, then redirected back to the Phase 3 gray areas. The user then asked for a plain-language explanation of what the three fixes mean (FIX-01 rm_L, FIX-02 dedup, FIX-03 MinGW path) before selecting areas.

---

## rm_L authority (FIX-01)

### D-01 — source of the rm_L formula

| Option | Description | Selected |
|--------|-------------|----------|
| Payload_Mass_calculator everywhere | Console-path authority; run_staging's inline copy (C_Interface.f90:59) deleted; formula exists exactly once in Fortran | ✓ |
| Keep synced inline copy | Both sites as documented mirrors — less churn, but the duplication stays | |
| You decide | Let researcher/planner decide after reading the flow | |

**User's choice:** Payload_Mass_calculator everywhere
**Notes:** Reinforced that the fix targets the two-copies drift risk; single source of physical truth.

### D-02 — regression guard

| Option | Description | Selected |
|--------|-------------|----------|
| Conservative bounds | test_rocket_lib.py: stage-1 m0 finite & > payload+PAF, k_L in (0,1) — cheap garbage/NaN catcher | ✓ |
| Console cross-check too | Also compare run_full_pipeline vs Fortran main on same config — strongest but heavier | |
| Code only | No test extension this phase | |

**User's choice:** Conservative bounds
**Notes:** Catches uninitialized/garbage masses without pinning exact physics.

### D-03 — sequencing/scoping

| Option | Description | Selected |
|--------|-------------|----------|
| Fold into dedup | rm_L consolidation rides with the bridge cleanup (03-02); one coherent change | ✓ |
| Keep 03-01 standalone | 03-01 fixes rm_L even if run_staging survives | |

**User's choice:** Fold into dedup
**Notes:** Planner rescopes 03-01/03-02 (03-01 may reduce to verification + bounds test).

---

## Legacy entry fate (FIX-02)

### D-04 — dedup depth

| Option | Description | Selected |
|--------|-------------|----------|
| Single-entry (remove it all) | Remove run_staging at every layer: Fortran entry, Python wrapper, gui.py dead twin + _lib, test_call segment, RunStagingWrapperContract class; STAGING itself stays (STAGING_LOOP still calls it) | ✓ |
| Keep tested legacy | Delete only gui.py's dead twin; keep rocket_lib.run_staging + Fortran entry as back-compat | |
| You decide | Let research/planning decide after reading the STAGING vs STAGING_LOOP call graph | |

**User's choice:** Single-entry (remove it all)
**Notes:** Also makes the earlier "shared Fortran helper extraction" idea moot (no duplication left after removal).

### D-05 — suite rework

| Option | Description | Selected |
|--------|-------------|----------|
| Rework the suite | Drop RunStagingWrapperContract; add the rm_L bounds test; suite stays green | ✓ |
| Code only here too | Remove the run_staging test class, no rm_L bounds test added | |

**User's choice:** Rework the suite
**Notes:** No red-commit states.

### D-06 — docs refresh

| Option | Description | Selected |
|--------|-------------|----------|
| Refresh in-phase | CONCERNS/INTEGRATIONS/STRUCTURE/TESTING + PROJECT.md/REQUIREMENTS.md/AGENTS.md updated in the same commit set | ✓ |
| Docs later | Code + suite only; docs refresh deferred | |

**User's choice:** Refresh in-phase

### D-07 — test_call.py fate

| Option | Description | Selected |
|--------|-------------|----------|
| Convert to pipeline | Rewrite the smoke to call run_full_pipeline (config-driven args incl. diameter_mode/diameter/propellant_list) | ✓ |
| Delete it | Suites already cover the bridge end-to-end | |
| You decide | Planner/executor chooses | |

**User's choice:** Convert to pipeline

---

## MinGW path strategy (FIX-03)

### D-08 — Python-side DLL resolution

| Option | Description | Selected |
|--------|-------------|----------|
| build/-only, drop MINGW_BIN | rocket_lib.py loads build/librocket.dll via add_dll_directory(BUILD_DIR) only — Makefile already ships runtime DLLs into build/ | ✓ |
| env + discovery, no default | Keep MINGW_BIN override, replace C:\TDM-GCC-64\bin default with shutil.which discovery | |
| Trimmed candidate list | Shortened known-roots list, still no TDM literal | |
| You decide | Planner/executor picks | |

**User's choice:** build/-only, drop MINGW_BIN
**Notes:** Requires Makefile runtime-DLL copy (168-174) to stay — it does.

### D-09 — Makefile MINGW_BIN

| Option | Description | Selected |
|--------|-------------|----------|
| Discover, env override | MINGW_BIN derives from `where gfortran`/`which gfortran` at build time; env/CLI override; clear error if not found | ✓ |
| Require MINGW_BIN env | No literal, no discovery; fail with hint if unset | |
| Keep Makefile hardcode | Only the Python side fixed | |
| You decide | Planner/executor picks | |

**User's choice:** Discover, env override
**Notes:** Runtime-DLL copy block stays; no drive-letter literal remains anywhere.

---

## the agent's Discretion

- 03-01 vs 03-02 rescoping mechanics after the D-03 fold-in.
- Exact bounds-test assertion shape/messages.
- Cleanup of orphaned Fortran bits seeded only by run_staging (only if zero behavior change).
- Exact `where gfortran` parsing + error wording.
- Whether CR-01/WR-02/WR-03 fit inside this phase's FIX scope (recorded by Phase-2 verifier as "Phase 3/fix").

## Deferred Ideas

- **Rocket-diagram in Results** (per-stage length/diameter drawing from the selected configuration) — own phase, Phase 4 candidate; user-requested this session.
- **ISP/k_s authority (tables vs sliders)** — deferred from Phase 2, blocked by out-of-scope FIX-05.
- **FIX-04 / FIX-05** — out of scope, do not touch.
- **CR-01 / WR-02 / WR-03** — robustness gaps recorded by the Phase-2 verifier; re-file if they don't fit Phase 3 scope.