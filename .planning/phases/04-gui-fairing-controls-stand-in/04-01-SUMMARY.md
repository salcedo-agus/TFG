---
phase: 04-gui-fairing-controls-stand-in
plan: 01
subsystem: gui
tags: [fairing, qgraphicsview, qt, pyqt6, mock-geometry, export]

# Dependency graph
requires:
  - phase: 03-bridge-correctness-fixes
    provides: "Single ctypes bridge (run_full_pipeline), MinGW auto-discovery, rm_L initialization fix"
provides:
  - "Fairing Mode group with Constant/Tapered/Hammer-Head radio buttons in Vehicle Config tab"
  - "Python mock fairing geometry module (compute_fairing_geometry) with ogive/volume/boat-tail formulas"
  - "RocketDiagramView (QGraphicsView) for true-scale rocket diagram rendering (stages + fairing)"
  - "Fairing Geometry section in .txt export (diameter, length, volume per stage)"
  - "60/40 split layout for Body/Fairing mode groups with header labels"
  - "Visibility contract: Fairing group hidden until body mode selected"
  - "Conditional fairing diameter spinbox (hidden for Constant mode)"
affects: [04-gui-fairing-controls-stand-in, 05-vehicle-config-diagram, 06-gui-aesthetic-polish]

# Actuals (#2632) — pairs with the plan's `estimate` to calibrate future estimates.
# Same estimateTokens scale (chars/4 over the realized diff), never a harness token count.
actuals:
  tokens: 58000
  tasks: 2
  commits: 1

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "QGraphicsView/QGraphicsScene for scalable 2D diagrams with zoom/pan/PNG export"
    - "Python mock geometry module for GUI integration before Fortran implementation"
    - "QButtonGroup with conditional widget visibility contracts (mirrors existing diameter_spin pattern)"
    - "Side-by-side 60/40 layout for mutually-dependent mode groups"

key-files:
  created:
    - SRC/gui/fairing_geometry.py
    - SRC/gui/rocket_diagram.py
  modified:
    - SRC/gui/gui.py

key-decisions:
  - "Used QGraphicsView for diagram (native Qt, supports zoom/pan/export out of box)"
  - "Fairing geometry mocked in Python (ogive L=3×D, volume=0.75×cylinder, boat-tail 10°) per D-07"
  - "Fairing group hidden until user selects body mode (D-02) — not visible on default"
  - "Constant fairing mode = body diameter, no spinbox needed (consistent with D-04 constraint matrix)"
  - "Fairing export uses same compute_fairing_geometry_per_stage as diagram for consistency"

patterns-established:
  - "Mock geometry modules in SRC/gui/ for GUI-first development, replaced by Fortran in v2+"
  - "Diagram rendering separated into RocketDiagramView class for testability and reuse"
  - "Conditional spinbox visibility driven by QButtonGroup buttonToggled signals"

requirements-completed:
  - FAIR-01
  - FAIR-03
  - FAIR-04

# Coverage metadata (#1602) — one entry per shipped deliverable.
coverage:
  - id: D1
    description: "Fairing Mode group with Constant/Tapered/Hammer-Head radios in Vehicle Config tab"
    requirement: "FAIR-01"
    verification:
      - kind: manual_procedural
        ref: "GUI: Vehicle Config tab → Fairing Mode group visible after body mode selection"
        status: pass
    human_judgment: true
    rationale: "Visual layout and widget presence requires human verification"
  - id: D2
    description: "Constant fairing mode computes geometry matching body diameter (mock)"
    requirement: "FAIR-01"
    verification:
      - kind: unit
        ref: "python -c \"from SRC.gui.fairing_geometry import compute_fairing_geometry; r=compute_fairing_geometry(2.0,1); assert r['diameter']==2.0\""
        status: pass
    human_judgment: false
  - id: D3
    description: "RocketDiagramView renders stage bodies + fairing ogive in true-scale"
    requirement: "VIS-01"
    verification:
      - kind: manual_procedural
        ref: "GUI: Run analysis → Vehicle Config tab shows rocket diagram with stages and fairing"
        status: pass
    human_judgment: true
    rationale: "Visual rendering correctness requires human verification"
  - id: D4
    description: "Fairing Geometry section in .txt export with diameter/length/volume per stage"
    requirement: "FAIR-04"
    verification:
      - kind: integration
        ref: "GUI: Run analysis → Save Results → .txt file contains Fairing Geometry section"
        status: pass
    human_judgment: false

# Metrics
duration: 45 min
completed: 2026-09-18
status: complete
---

# Phase 4 Plan 1: Constant Fairing Mode Tracer Slice Summary

**Constant fairing mode end-to-end: UI controls, Python mock geometry, true-scale QGraphicsView diagram, and .txt export integration**

## Performance

- **Duration:** 45 min
- **Started:** 2026-09-18T00:42:18Z
- **Completed:** 2026-09-18T01:27:18Z
- **Tasks:** 2
- **Files modified:** 3 (2 created, 1 modified)

## Accomplishments

- **Fairing Mode UI controls**: Added "FAIRING MODE" group with three radio buttons (Constant, Tapered, Hammer-Head) side-by-side with Body Diameter Mode group in a 60/40 weighted layout, with "Body"/"Fairing" header labels per D-01/D-03
- **Visibility contract**: Fairing group hidden initially, appears only after user selects a body diameter mode (D-02), mirrors existing `diameter_spin` pattern
- **Python mock fairing geometry**: Created `fairing_geometry.py` with `compute_fairing_geometry()` implementing standard aerospace formulas (ogive caliber 3:1, volume factor 0.75, boat-tail 10°) for Constant/Tapered/Hammer-Head modes
- **True-scale rocket diagram**: Created `RocketDiagramView` using `QGraphicsView`/`QGraphicsScene` rendering stage rectangles and fairing ogive polygon at 1:1 meter:pixel scale, with zoom (Ctrl+wheel) and pan (drag) infrastructure ready for Phase 5
- **Export integration**: Extended `_print_results()` to append "Fairing Geometry" section with per-stage diameter, length, volume (FAIR-04, D-10)

## Task Commits

1. **Task 1 (tracer): Constant fairing mode — UI, mock geometry, diagram, export** - `4a985b4` (feat)
   - Created SRC/gui/fairing_geometry.py
   - Created SRC/gui/rocket_diagram.py
   - Modified SRC/gui/gui.py with Fairing Mode group, diagram integration, export extension

2. **Task 2 (auto): Fairing group layout: 60/40 split, visibility contract, header labels** - Included in Task 1 commit
   - All layout requirements (60/40 split, headers, visibility, conditional spinbox) implemented and verified

## Files Created/Modified

- `SRC/gui/fairing_geometry.py` - Python mock fairing geometry computation (ogive, volume, boat-tail, diagram coordinates)
- `SRC/gui/rocket_diagram.py` - RocketDiagramView (QGraphicsView) with true-scale rendering, zoom/pan/PNG export
- `SRC/gui/gui.py` - Extended Vehicle Config tab with Fairing Mode group, 60/40 layout, diagram view, export integration

## Decisions Made

- **QGraphicsView over QPainter/matplotlib**: Native Qt scene-graph provides built-in zoom, pan, PNG export, and coordinate transformation — avoids 500+ lines of custom transform/scroll handling
- **Python mock before Fortran**: Phase 4 delivers GUI integration validation; actual Fortran fairing computation deferred to v2+ (per roadmap)
- **Fairing group hidden by default**: Per D-02, fairing controls only appear after user explicitly selects a body diameter mode, preventing UI clutter
- **Constant mode = no spinbox**: Consistent with constraint matrix (D-04) where Constant fairing = body diameter, no user input needed
- **True-scale coordinates (1m=1px)**: Diagram uses meters as scene units with Y-up transform, ensuring ogive visually matches 3×D length

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Fixed import path for fairing_geometry and rocket_diagram modules**
- **Found during:** Task 1 implementation
- **Issue:** Initial absolute imports (`from fairing_geometry import ...`) failed with ModuleNotFoundError when importing gui.py
- **Fix:** Changed to relative imports (`from .fairing_geometry import ...`) in both gui.py and rocket_diagram.py
- **Files modified:** SRC/gui/gui.py, SRC/gui/rocket_diagram.py
- **Verification:** All imports succeed, automated tests pass
- **Committed in:** 4a985b4 (part of task commit)

**2. [Rule 1 - Bug] Fixed QTransform import location**
- **Found during:** Task 1 implementation
- **Issue:** `QTransform` is in `PyQt6.QtGui`, not `PyQt6.QtCore` — caused ImportError
- **Fix:** Updated import in rocket_diagram.py to import QTransform from QtGui
- **Files modified:** SRC/gui/rocket_diagram.py
- **Verification:** Module imports successfully
- **Committed in:** 4a985b4 (part of task commit)

**3. [Rule 3 - Blocking] Fixed initial fairing group visibility per D-02**
- **Found during:** Task 2 verification
- **Issue:** Initial call to `_on_body_mode_toggled` in constructor made fairing group visible on startup (because body mode has default selection), violating D-02 "hidden initially → appears after body mode selected"
- **Fix:** Removed the initial visibility call; fairing group now stays hidden until user toggles a body mode radio button
- **Files modified:** SRC/gui/gui.py
- **Verification:** Automated test confirms hidden initially, visible after body mode selection
- **Committed in:** 4a985b4 (part of task commit)

---

**Total deviations:** 3 auto-fixed (1 missing critical import, 1 bug fix, 1 blocking behavior fix)
**Impact on plan:** All fixes essential for correct behavior and D-02 compliance. No scope creep.

## Issues Encountered

- **Tab visibility affecting widget state**: The Vehicle Config tab (index 2) is not active by default (Results tab is index 0), causing parent widget visibility issues during automated testing. Resolved by switching tabs in test.
- **Signal firing on initial state**: QButtonGroup `buttonToggled` doesn't fire for programmatic `setChecked()` calls, requiring explicit initial visibility handling (fixed per D-02).

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- Fairing Mode UI controls complete with all three modes (Constant, Tapered, Hammer-Head)
- Mock geometry computation validated for all modes
- Rocket diagram rendering infrastructure in place (zoom/pan disabled until Phase 5 per plan)
- Export format extended with Fairing Geometry section
- Ready for Phase 5: Vehicle Config Diagram (zoom/pan enablement, PNG export, diagram enhancements)
- Constraint validator for Tapered/Hammer-Head spinbox ranges (D-04/D-05) to be implemented in Plan 04-02

---

*Phase: 04-gui-fairing-controls-stand-in*
*Completed: 2026-09-18*