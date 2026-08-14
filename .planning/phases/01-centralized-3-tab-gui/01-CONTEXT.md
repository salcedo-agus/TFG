# Phase 1: Centralized 3-Tab GUI - Context

**Gathered:** 2026-08-14
**Status:** Ready for planning

<domain>
## Phase Boundary

Restructure the GUI into a centralized 3-tab workbench with mission inputs, results display, geometry results, and vehicle-configuration (diameter mode). This phase is GUI/Python-only — no Fortran interface changes. The splash screen, existing sliders, propellant/combustion-cycle selectors, "Save Results" export, and minimum-confirmed indicator all remain and are relocated/resurfaced within the new tab structure.

</domain>

<decisions>
## Implementation Decisions

### Centralized layout
- **D-01:** Centralized 3-tab interface, not scattered panels. Three tabs: Results (central), Setup, Vehicle Configuration.
- **D-02:** Tab order: Results tab first (the central/home surface), then Setup, then Vehicle Configuration.

### Results tab (central)
- **D-03:** Shows per-stage rocket and stage masses: m0, mf, mp, ms
- **D-04:** Shows per-stage mass ratios k_m, k_s, k_L and exhaust velocity
- **D-05:** Shows per-stage ΔV
- **D-06:** Shows geometry results per stage: diameter, length, volume
- **D-07:** Retains the existing "Save Results" export and the minimum-confirmed indicator

### Setup tab
- **D-08:** Keeps the sliders and propellant + combustion-cycle selectors exactly as they are today — relocated into this tab, not redesigned
- **D-09:** Holds the new mission inputs: orbit height (km), payload mass (kg), stage count
- **D-10:** ΔV is computed internally by the pipeline — the user does NOT enter ΔV by hand

### Vehicle Configuration tab
- **D-11:** Offers three diameter modes: statistically-determined, constant, and user-specified
- **D-12:** User-specified mode exposes a box where the user enters the diameter value

### Presentation
- **D-13:** Splash screen is preserved as-is
- **D-14:** config.txt remains a separate input path — the GUI is independent of it (user decision)

### the agent's Discretion
- Exact widget styling/spacing/typography of the tabs
- Layout of results within the Results tab (table vs cards vs grouped fields)
- How to reflect pipeline outputs the Fortran side does not yet expose (results may be partially populated pending Phase 2 pipeline wiring — this phase focuses on the tab shell and data surface)
- QThread/worker patterns for running the solver without freezing the UI

</decisions>

<specifics>
## Specific Ideas

- "I want the GUI to be centralized. A central tab with results (Rocket and stage masses, Delta V for each stage, etc.), another tab with sliders and propellant/combustion cycle setup just as it is right now, and another for choosing vehicle configuration (constant diameter, staged diameters and specified diameter), where the last option has a box for the user to specify the diameter."
- "Keep splash" (user decision)
- "Keep separate" for config.txt (user decision)

</specifics>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Requirements & project definition
- `.planning/PROJECT.md` — Project context, requirements (GUI-01..08), constraints, decisions
- `.planning/REQUIREMENTS.md` — v1 requirements GUI-01..GUI-08 (tab structure, results scope, mission inputs, diameter modes, splash)
- `.planning/ROADMAP.md` — Phase 1 section: goal, success criteria, plan list (01-01, 01-02, 01-03)

### Existing GUI code (read to understand what is being restructured)
- `SRC/gui/gui.py` — Current PyQt6 GUI: sliders, propellant/cycle selectors, results cards, save results, minimum-confirmed indicator, splash, ctypes `run_staging` bridge (line ~80)
- `SRC/interface/rocket_lib.py` — ctypes bridge module (line ~45)
- `SRC/inout/Typical_Data.f90` — config parser, diameter-setup modes (`Diameter_setup` 1/2/3), ISP/k_s tables (for understanding existing diameter modes to mirror in the GUI)

### Codebase map
- `.planning/codebase/ARCHITECTURE.md` — system architecture and pipeline
- `.planning/codebase/STRUCTURE.md` — file layout and responsibilities
- `.planning/codebase/CONVENTIONS.md` — code/style conventions
- `.planning/codebase/INTEGRATIONS.md` — how Python/Fortran bridge works
- `.planning/codebase/CONCERNS.md` — known issues (duplicated bridge, rm_L, etc.)

### Fortran diameter-setup source of truth (to mirror mode semantics)
- `SRC/inout/Typical_Data.f90` §diameter_setup — the 1/2/3 modes the GUI's Vehicle Configuration tab mirrors

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `SRC/gui/gui.py` splash screen: reusable as-is (D-13)
- `SRC/gui/gui.py` sliders + propellant/combustion-cycle widgets: relocate verbatim into Setup tab (D-08)
- `SRC/gui/gui.py` save-results export + minimum-confirmed indicator: reuse in Results tab (D-07)
- `SRC/interface/rocket_lib.py` ctypes bridge: source of stage results already returned to GUI

### Established Patterns
- PyQt6 widget-based UI, ctypes DLL bridge, English GUI text
- Results surfaced via Python dataclass/struct returned from `run_staging`

### Integration Points
- GUI → `rocket_lib.run_staging(...)` → `librocket.dll` — existing result path, reused for stage masses/mass ratios/ΔV in Results tab
- Vehicle Configuration diameter mode semantics mirror `Diameter_setup` modes in `Typical_Data.f90`

</code_context>

<deferred>
## Deferred Ideas

- Wiring the full pipeline (orbit → payload → staging → thrust → geometry) — Phase 2 (results tab may show only what the staging path already provides until then)
- Correctness fixes (rm_L init, dedup bridge, MinGW path) — Phase 3
- **Supersession (2026-08-15):** the `rm_L init` item above is pulled forward from Phase 3 by UAT gap G-01-2's closure plan `01-04` (orchestrator-approved gap closure); FIX-02 bridge dedup, FIX-03 MinGW path, and FIX-05 TEST CASE override remain deferred to Phase 3.
- Automated tests — deferred to a future session (user decision)

</deferred>

---

*Phase: 01-centralized-3-tab-gui*
*Context gathered: 2026-08-14*