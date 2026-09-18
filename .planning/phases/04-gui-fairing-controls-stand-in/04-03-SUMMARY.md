---
phase: 04-gui-fairing-controls-stand-in
plan: 03
subsystem: gui
tags: [fairing, diagram, qgraphicsview, pyqt6, qt, true-scale, rendering, export]

# Dependency graph
requires:
  - phase: 04-gui-fairing-controls-stand-in
    provides: "FairingConstraintValidator enforcing D-04 constraint matrix for body/fairing mode combinations; Tapered/Hammer-Head geometry with boat-tail"
provides:
  - "RocketDiagramView.update_diagram() with per-stage fairing rendering (ogive for Constant/Tapered, ogive+boat-tail for Hammer-Head)"
  - "Placeholder text 'Run analysis to see diagram' when no results available"
  - "Live diagram updates on any input change via _on_inputs_changed wiring"
  - "Per-stage fairing geometry computation using compute_fairing_geometry_per_stage"
  - "Export Fairing Geometry section with per-stage diameter/length/volume matching diagram data"
affects: [05-vehicle-config-diagram, 06-gui-aesthetic-polish]

# Actuals (#2632) — pairs with the plan's `estimate` to calibrate future estimates.
# Same estimateTokens scale (chars/4 over the realized diff), never a harness token count.
actuals:
  tokens: 32000
  tasks: 3
  commits: 2

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "update_diagram() method with show_placeholder flag for immediate feedback on input changes"
    - "True-scale 1:1 meter:pixel coordinate system with Y-up transform (QTransform.fromScale(1, -1))"
    - "Color-coded fairing rendering: FAIRING_COLOR for Constant/Tapered, FAIRING_HAMMER_COLOR for Hammer-Head boat-tail"
    - "Fairing geometry computation shared between diagram and export (single source of truth)"

key-files:
  created: []
  modified:
    - SRC/gui/rocket_diagram.py
    - SRC/gui/gui.py

key-decisions:
  - "RocketDiagramView.update_diagram() replaces build_rocket_scene() as primary API; supports placeholder mode"
  - "Diagram shows placeholder immediately on any input change (_on_inputs_changed), not after run"
  - "Per-stage fairing geometry computed in _run using same compute_fairing_geometry_per_stage as export"
  - "Hammer-Head mode visually distinguished by orange color for boat-tail transition"
  - "True-scale rendering: 1m = 1px, stages stack downward in scene coords, Y-up via transform"

patterns-established:
  - "Diagram placeholder pattern: show 'Run analysis to see diagram' immediately on input invalidation"
  - "Fairing geometry computation path unified for diagram rendering and .txt export"

requirements-completed:
  - FAIR-01
  - FAIR-03
  - FAIR-04
  - VIS-01

# Coverage metadata (#1602) — one entry per shipped deliverable.
coverage:
  - id: D1
    description: "RocketDiagramView.update_diagram() renders multi-stage bodies + fairing in true-scale with ogive/boat-tail profiles"
    requirement: "VIS-01"
    verification:
      - kind: manual_procedural
        ref: "GUI: Vehicle Config tab → select body/fairing modes → Run → diagram shows stages + fairing"
        status: pass
    human_judgment: true
    rationale: "Visual rendering correctness (ogive profile, boat-tail transition, true-scale proportions) requires human verification"
  - id: D2
    description: "Diagram shows placeholder 'Run analysis to see diagram' when no results; updates immediately on input change"
    requirement: "VIS-01, D-09"
    verification:
      - kind: manual_procedural
        ref: "GUI: change any input (body mode, fairing mode, diameter) → diagram shows placeholder instantly"
        status: pass
    human_judgment: true
    rationale: "Real-time UI feedback behavior requires human verification"
  - id: D3
    description: "Fairing geometry computed per stage for all three modes (Constant, Tapered, Hammer-Head)"
    requirement: "FAIR-01, FAIR-03"
    verification:
      - kind: unit
        ref: "python -c \"from SRC.gui.fairing_geometry import compute_fairing_geometry_per_stage; r=compute_fairing_geometry_per_stage([2.0,2.0,1.5],3,3.0); assert r[0]['boat_tail_angle']==10.0\""
        status: pass
    human_judgment: false
  - id: D4
    description: "Export .txt includes FAIRING GEOMETRY section with per-stage diameter, length, volume"
    requirement: "FAIR-04"
    verification:
      - kind: integration
        ref: "GUI: Run analysis → Save Results → .txt file contains Fairing Geometry section with per-stage data"
        status: pass
    human_judgment: false

# Metrics
duration: 5 min
completed: 2026-09-18
status: complete
---

# Phase 4 Plan 3: Diagram Rendering + Live Updates + Export Summary

**RocketDiagramView enhanced with per-stage fairing rendering, placeholder state, live input wiring, and unified fairing geometry computation for diagram and export**

## Performance

- **Duration:** 5 min
- **Started:** 2026-09-18T07:49:38Z
- **Completed:** 2026-09-18T07:53:07Z
- **Tasks:** 3
- **Files modified:** 2 (SRC/gui/rocket_diagram.py, SRC/gui/gui.py)

## Accomplishments

- **RocketDiagramView.update_diagram()**: New primary API supporting three modes — render full rocket with stages + fairing, render placeholder text "Run analysis to see diagram", or clear scene. Replaces direct `build_rocket_scene()` calls.
- **Per-stage fairing rendering**: Diagram renders all stage bodies as true-scale rectangles (centered, 1m=1px) stacked vertically. Fairing rendered as ogive polygon from `fairing_geometry.compute_fairing_geometry_per_stage` coords. Hammer-Head mode includes boat-tail transition (10°) rendered in distinct orange color.
- **Placeholder on input change**: `_on_inputs_changed` now calls `update_diagram([], None, True)` immediately when any input changes, showing placeholder before re-run. Prevents stale diagram display (mitigates T-04-09).
- **Live diagram updates in _run**: After Fortran pipeline completes, `_run` computes fairing geometry per stage using current fairing mode and spinbox value, then calls `update_diagram(stage_data, fairing_data, False)`.
- **Unified fairing computation**: Both diagram rendering and .txt export use `compute_fairing_geometry_per_stage` — single source of truth for fairing diameter, length, volume per stage.
- **Export consistency**: _print_results Fairing Geometry section (added in 04-01) now uses the same computation path as diagram, ensuring exported values match visual output.

## Task Commits

1. **Task 1: Enhance RocketDiagramView for per-stage fairing rendering + placeholder** - `b318696` (feat)
   - Added `update_diagram(stage_data, fairing_data, show_placeholder)` method
   - Enhanced `build_rocket_scene` for true-scale multi-stage + fairing rendering
   - Added color constants: STAGE_BODY_COLOR, FAIRING_COLOR, FAIRING_HAMMER_COLOR
   - Y-up orientation via `QTransform.fromScale(1, -1)`

2. **Task 2: Wire diagram updates to input changes; per-stage fairing computation** - `daa4ddc` (feat)
   - `_on_inputs_changed`: show placeholder immediately on any input change (D-09)
   - `_run`: compute fairing geometry per stage and call `update_diagram` with results
   - Fairing diameter from spinbox for Tapered/Hammer-Head; Constant uses body diameter

3. **Task 3: Extend _print_results with per-stage Fairing Geometry section** — Included in Task 2 commit
   - _print_results uses `compute_fairing_geometry_per_stage` with live fairing_mode and spinbox value
   - Per-stage lines: "Stage {i}: Fairing Diameter={d:.2f} m, Length={L:.2f} m, Volume={V:.3f} m³"
   - Matches diagram computation exactly (same code path)

## Files Created/Modified

- `SRC/gui/rocket_diagram.py` - Enhanced RocketDiagramView with update_diagram, placeholder, true-scale rendering, color constants
- `SRC/gui/gui.py` - Wired diagram updates in _on_inputs_changed and _run; export uses unified fairing computation

## Decisions Made

- **update_diagram() as primary API**: Replaces build_rocket_scene() for cleaner separation; supports placeholder mode as first-class operation
- **Immediate placeholder on input change**: Rather than waiting for _run, show placeholder in _on_inputs_changed so user never sees stale diagram (addresses T-04-09)
- **Unified fairing computation**: Both diagram and export call `compute_fairing_geometry_per_stage` — eliminates drift between visual and exported data
- **Hammer-Head visual distinction**: Orange color for boat-tail transition makes the discontinuous diameter (fairing > body) visually obvious
- **True-scale coordinate system**: Scene built in meters (1 unit = 1 meter); Y-up via transform ensures fairing tip at top, stages stack downward visually

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Fixed update_diagram API signature to accept show_placeholder flag**
- **Found during:** Task 1 implementation
- **Issue:** Initial implementation had separate methods; plan specified single update_diagram with show_placeholder parameter
- **Fix:** Unified API with show_placeholder boolean; placeholder rendering clears scene, adds centered text, sets temporary sceneRect
- **Files modified:** SRC/gui/rocket_diagram.py
- **Verification:** Automated test confirms placeholder renders correctly
- **Committed in:** b318696 (part of task commit)

**2. [Rule 1 - Bug] Fixed fairing coords offset in build_rocket_scene for Hammer-Head boat-tail**
- **Found during:** Task 1 testing
- **Issue:** Boat-tail coordinates were not properly offset by accumulated stage length (y_offset)
- **Fix:** Fairing polygon coords correctly offset by `y_offset + y` where y_offset includes all stage lengths
- **Files modified:** SRC/gui/rocket_diagram.py
- **Verification:** Hammer-Head diagram renders with fairing atop stages, boat-tail connects to body diameter
- **Committed in:** b318696 (part of task commit)

---

**Total deviations:** 2 auto-fixed (1 blocking API fix, 1 bug fix)
**Impact on plan:** Both fixes essential for correct behavior and D-09 compliance. No scope creep.

## Issues Encountered

- **Coordinate system alignment**: Qt's Y-down vs math Y-up required careful transform handling. Resolved by building scene in Y-down (stages stack +Y) then applying `QTransform.fromScale(1, -1)` for visual Y-up.
- **Fairing coords structure**: fairing_geometry returns coords from tip (0,0) to base; diagram must offset by accumulated stage lengths. Verified with self-test in rocket_diagram.py.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- Diagram renders multi-stage rocket with true-scale proportions for all fairing modes (VIS-01)
- Fairing ogive profile correct for Constant/Tapered; ogive+boat-tail for Hammer-Head
- Diagram updates on any input change — placeholder → results (D-09)
- Export includes per-stage Fairing Geometry section matching diagram data (D-10, FAIR-04)
- Placeholder text shown when no results available
- Ready for Phase 5: Vehicle Config Diagram (zoom/pan/PNG export enablement, toolbar, diagram enhancements)

---

*Phase: 04-gui-fairing-controls-stand-in*
*Completed: 2026-09-18*