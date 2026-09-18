# Phase 4: GUI Fairing Controls (Stand-in) - Context

**Gathered:** 2026-09-17
**Status:** Ready for planning

<domain>
## Phase Boundary

Add fairing diameter mode controls (Constant, Tapered, Hammer-Head) to the Vehicle Configuration tab with Python-side mock fairing geometry. No Fortran changes — fairing data is mocked in Python for GUI integration validation. This phase delivers the GUI controls and mock data pipeline; actual Fortran fairing computation is deferred to v2+.
</domain>

<decisions>
## Implementation Decisions

### Fairing Mode UI Layout
- **D-01:** Fairing controls in separate `QGroupBox` side-by-side with body diameter modes — weighted 60/40 (body/fairing) — **Reversibility:** reversible (layout change only)
- **D-02:** Fairing group hidden initially → appears after body mode selected — **Reversibility:** reversible (visibility toggle)
- **D-03:** Header labels "Body" and "Fairing" above each group (no connector) — **Reversibility:** reversible (label text)

### Fairing ↔ Body Mode Constraints
- **D-04:** Constraint matrix enforced:
  - Statistical body → Constant (same), Tapered (user-specified ≤ last stage body D)
  - Constant body → Constant (same), Hammer-Head (user-specified ≥ body D)
  - User-specified body → Constant (same)
  — **Reversibility:** costly (validation logic spans multiple widgets)
- **D-05:** Conditional spinbox under selected non-constant fairing mode with unit suffix "m", min/max validation per constraint — **Reversibility:** reversible (input constraints)
- **D-06:** FAIR-02 (User-specified fairing with body adjustment) deferred to v2+ — **Reversibility:** reversible (not implemented)

### Mock Fairing Data Computation
- **D-07:** Python-side fairing geometry using standard aerospace formulas (ogive length = 3×D, volume ≈ 0.75×π/4×D²×L, boat-tail 5°–15° for Hammer-Head) — **Reversibility:** reversible (mock only, replaced by Fortran in v2+)
- **D-08:** True-scale diagram coordinate system (1:1 meter:pixel) — **Reversibility:** reversible (rendering logic)

### Diagram & Export
- **D-09:** Show mock diagram immediately (using current body + mock fairing data); update on any input change — **Reversibility:** reversible (timing/trigger)
- **D-10:** New "Fairing Geometry" section in .txt export after stage data (per-stage fairing diameter/length/volume) — **Reversibility:** reversible (export format)

### the agent's Discretion
- Exact ogive/conic formula constants in Python mock (use 3×D for length, 0.75 volume factor, 10° boat-tail)
- Exact validation error messaging (tooltip vs inline)
- Fairing mode radio labels wording

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Requirements & project definition
- `.planning/REQUIREMENTS.md` — FAIR-01, FAIR-03, FAIR-04, VIS-01/02/03, GUI-09/10/11 (v1.1 scope)
- `.planning/ROADMAP.md` — Phase 4 section: goal, success criteria, UI hint
- `.planning/PROJECT.md` — Current Milestone v1.1, constraints (Fortran core, ctypes bridge, config.txt separate)

### Prior phase context (carried forward)
- `.planning/milestones/v1.0-phases/01-centralized-3-tab-gui/01-CONTEXT.md` — D-11/D-12 (body diameter modes), D-13/D-14 (splash, config.txt), vehicle tab structure
- `.planning/milestones/v1.0-phases/02-full-pipeline-exposure/02-CONTEXT.md` — D-01..D-05 (V_circ label/export contract, full pipeline wiring, diameter mode handoff), deferred ISP/k_s authority
- `.planning/milestones/v1.0-phases/03-bridge-correctness-fixes/03-CONTEXT.md` — D-01..D-09 (rm_L authority, single bridge, build/-only, MinGW discovery), deferred FIX-04/05/06

### Existing GUI code (read to understand current Vehicle Config tab)
- `SRC/gui/gui.py` — Vehicle tab (`_build_vehicle_tab`, lines 823-907): body diameter mode radios, `mode_group`, `diameter_spin`, visibility contract, `diameter_mode` state stored on MainWindow
- `SRC/gui/gui.py` — `_on_inputs_changed` (line 966): invalidates results on any input change
- `SRC/gui/gui.py` — `_run` (line 1034): calls `rocket_lib.run_full_pipeline` with `diameter_setup` and `user_diameter`
- `SRC/gui/typical_data_ranges.py` — ISP/k_s data source (auto-generated from `Typical_Data.f90`)

### Codebase map
- `.planning/codebase/ARCHITECTURE.md` — pipeline layers, bridge architecture
- `.planning/codebase/INTEGRATIONS.md` — ctypes contract, DLL loading
- `.planning/codebase/CONCERNS.md` — known issues (config parser, Soyuz TEST CASE, Makefile circular dep)

### Fortran diameter-setup source (to mirror mode semantics)
- `SRC/inout/Typical_Data.f90` — `Diameter_setup` 1/2/3 definitions
- `SRC/pre-simulation-calcs/Geometry_calc.f90` — `rocket_geometry_calculation`, statistical/constant/user diameter logic (lines 92-105)

### Fairing geometry references (for Python mock)
- NASA SP-8037: Launch vehicle fairing design (ogive/conic geometry, boat-tail angles)
- TU Delft launch vehicle design notes: fairing length/diameter ratios (3–4×D)

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `SRC/gui/gui.py` `_build_vehicle_tab`: existing radio group pattern (`QButtonGroup` with `buttonToggled`), visibility contract (`mode_user.toggled.connect(diameter_spin.setVisible)`), stored `diameter_mode` on MainWindow
- `SRC/gui/gui.py` `_on_inputs_changed`: central invalidation logic — fairing changes must connect here
- `SRC/gui/gui.py` `_run`: passes `diameter_setup` and `user_diameter` to `run_full_pipeline` — fairing args will be added
- `SRC/gui/ResultCard` (line 464): metric grid with `.get()` defaults rendering "—" for missing data — fairing metrics will follow same pattern

### Established Patterns
- PyQt6 widget-based UI, ctypes DLL bridge, English GUI text
- `QButtonGroup` for mutually-exclusive modes with integer IDs (1/2/3)
- Visibility contracts: widgets built once, shown/hidden, never rebuilt
- Invalidation on input change: `_on_inputs_changed` clears results, resets `_last_v_circ`, disables Save
- ResultCard uses `data.get(key)` with "—" placeholder for partial state

### Integration Points
- New fairing args added to `run_full_pipeline` call in `_run` (append to arg list for backward compat)
- Fairing mode + user diameter stored on MainWindow like `diameter_mode`
- Fairing mock data passed to `RocketDiagramView` (Phase 5) and included in `_print_results` export
- `_on_inputs_changed` must connect fairing widget signals for proper invalidation

</code_context>

<specifics>
## Specific Ideas

- "I want to add fairing diameter configuration in the same tab... constant diameter should make the fairing the same size as the body, while the 'user-specified' option should make the body adjust to the size of the fairing the user inputs... Hammer-Head rockets should have a fairing bigger than the body, in this configuration the body diameter is constant and statistically defined while the fairing diameter is defined by the user"
- "For smaller fairing I mean that the diameter of the fairing is user specified, but it should have a constraint as to not be bigger than the body diameter"
- "The Hammer-Head option should be visible when body diameter is constant: Body diameter constant + User defined fairing diameter = hammerhead... restriction for fairing diameter so it is always bigger than or equal to the body diameter"
- "For statistically determined body: same fairing size and smaller fairing"
- Mock diagram shown immediately, true-scale, updates on any input change

</specifics>

<deferred>
## Deferred Ideas

- **Fortran fairing implementation** (v2+): `Fairing_t` type, `fairing_setup` enum, ogive/conic computation in `Geometry_calc.f90`, ctypes bridge extension, replace Python mock
- **FAIR-02** (User-specified fairing with body adjustment): deferred per v2+ roadmap
- **Boat-tail geometry visualization** (v1.2+): diagram enhancement for Hammer-Head transition
- **Automated tests**: deferred by user decision
- **FIX-04/05/06**: config parser, Soyuz TEST CASE, Makefile circular dep (out of current scope)

### Reviewed Todos (not folded)
None — discussion stayed within phase scope

</deferred>

---

*Phase: 04-gui-fairing-controls-stand-in*
*Context gathered: 2026-09-17*