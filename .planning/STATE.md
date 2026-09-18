---
gsd_state_version: 1.0
milestone: v1.1
milestone_name: milestone
status: in-progress
stopped_at: Completed 04-03-PLAN.md
last_updated: "2026-09-18T13:59:23.482Z"
progress:
  total_phases: 3
  completed_phases: 1
  total_plans: 3
  completed_plans: 3
  percent: 33
current_phase_name: GUI Fairing Controls (Stand-in)
---

# STATE: TFG v1.1 — GUI Visual Enhancements & Fairing Configuration

**Project:** TFG — Multi-Stage Launch Vehicle Design Tool
**Milestone:** v1.1
**Generated:** 2026-09-17
**Schema Version:** 1

---

## Project Reference

**Core Value:** The user can go from mission parameters to a complete, trustworthy vehicle design (stage masses, ΔV, thrust, geometry) entirely from the GUI — without touching config files, Fortran code, or the console.

**Current Focus:** Phase 04 — GUI Fairing Controls (Stand-in)

**Milestone Goal:** Add rocket visualization diagrams and fairing diameter configuration to the Vehicle Configuration tab, plus explore GUI aesthetic directions.

---

## Current Position

| Field | Value |
|-------|-------|
| **Current Phase** | 4. GUI Fairing Controls (Stand-in) |
| **Current Plan** | 04-03 (completed) — phase complete |
| **Phase Status** | Complete (3/3 plans) |
| **Overall Progress** | ████░░░░░░ 33% (1/3 phases) |

---

## Performance Metrics

| Metric | Value |
|--------|-------|
| Phases Completed | 0 / 3 |
| Plans Executed | 3 |
| Tasks Completed | 8 |
| Requirements Validated | 4 / 11 (FAIR-01, FAIR-03, FAIR-04, VIS-01) |
| Commits This Milestone | 6 |
| Last Commit | daa4ddc (feat: Wire diagram updates to input changes; per-stage fairing computation) |

---
**Per-Plan Metrics:**

| Plan | Duration | Tasks | Files |
|------|----------|-------|-------|
| Phase 04-gui-fairing-controls-stand-in P01 | 45 min | 2 tasks | 3 files |
| Phase 04-gui-fairing-controls-stand-in P02 | 45 min | 3 tasks | 3 files |
| Phase 04-gui-fairing-controls-stand-in P03 | 5 min | 3 tasks | 2 files |

## Accumulated Context

### Decisions Logged

| Date | Decision | Rationale |
|------|----------|-----------|
| 2026-09-17 | Phase 4 starts v1.1 (v1.0 ended at Phase 3) | Sequential phase numbering across milestones |
| 2026-09-17 | 3 phases for v1.1 (Fortran → Diagram → Aesthetics) | Research-recommended dependency order; standard granularity |
| 2026-09-17 | PyQtGraph/QGraphicsView for diagrams (not Matplotlib) | Native Qt, 75–150× faster, no theme clashes, MIT license |
| 2026-09-17 | qt-material for theming (dark_teal default) | 18 themes, runtime switching, PyQt6 compatible |
| 2026-09-17 | Fortran fairing changes first (enum divergence risk) | CONCERNS.md shows config parser bug with combustion cycles; fairing adds second diameter concept |
| 2026-09-17 | Windows dark title bar via WinAPI (DwmSetWindowAttribute) | QSS only styles client area; title bar stays white without WinAPI |
| 2026-09-18 | Fairing geometry mocked in Python for Phase 4 | GUI-first integration validation; Fortran implementation deferred to v2+ |
| 2026-09-18 | QGraphicsView for true-scale diagram rendering | Native zoom/pan/export, 1:1 meter:pixel coordinate system |
| 2026-09-18 | Fairing group hidden until body mode selected (D-02) | Prevents UI clutter; appears on user interaction, not default state |

### Active Todos

- [x] Execute Plan 04-01 (Constant fairing mode tracer: UI, mock geometry, diagram, export)
- [x] Execute Plan 04-02 (Fairing constraint validator, Tapered/Hammer-Head spinbox ranges)
- [x] Execute Plan 04-03 (Diagram rendering + live updates + export for all modes)
- [ ] Plan Phase 5 (Vehicle Config Diagram)
- [ ] Plan Phase 6 (GUI Aesthetic Polish)

### Blockers

- None currently

### Open Questions

- Fairing constraint validator: exact min/max bounds for Tapered (≤ last stage body D) and Hammer-Head (≥ body D) per D-04 matrix
- Diagram zoom/pan: enable ScrollHandDrag and Ctrl+wheel zoom in Phase 5 (currently disabled per plan)
- qt-material theme: install via `pip install qt-material==2.17` and apply in gui.py entry point
- Dark title bar: Windows-only, guarded by build version check (18985+)

---

## Session Continuity

**Last session:** 2026-09-18T13:59:23.452Z
**Stopped at:** Completed 04-03-PLAN.md
**Resume file:** None

### Last Session

- **Date:** 2026-09-18
- **Work Done:** Executed Plan 04-03 — enhanced RocketDiagramView with per-stage fairing rendering, placeholder state, live input wiring, and unified fairing geometry computation for diagram and export
- **Next Action:** Plan Phase 5 (Vehicle Config Diagram) for zoom/pan/PNG export enablement

### Context for Resume

If resuming mid-phase:

1. Check `.planning/phases/04-gui-fairing-controls-stand-in/PLAN.md` for current plan
2. Review `.planning/phases/04-gui-fairing-controls-stand-in/` for any in-progress work
3. Run `gsd-tools query state.load` to reload this context
4. Continue from last incomplete task

---

## Environment

- **Branch:** `planning` (GSD artifacts only)
- **Source Branches:** `dev_GUI`, `dev_pre_simulation`
- **Build:** `SRC/Makefile` (auto-discovers MinGW via `where gfortran`)
- **Bridge:** `rocket_lib.run_full_pipeline` (single ctypes entry)
- **Tests:** Deferred (user decision)

## Decisions

- [Phase ?]: Fairing geometry mocked in Python for Phase 4 GUI integration; Fortran implementation deferred to v2+ — GUI-first development validates UX before committing to Fortran changes; mock uses standard aerospace formulas (ogive L=3×D, volume=0.75×cylinder, boat-tail 10°)
- [Phase ?]: QGraphicsView/QGraphicsScene for true-scale rocket diagram with native zoom/pan/PNG export — Native Qt scene-graph avoids 500+ lines of custom transform/scroll handling; built-in affine transforms, ScrollHandDrag, scene.render() for PNG
- [Phase ?]: Fairing group hidden until body mode selected (D-02) — appears on user interaction, not default state — Prevents UI clutter; fairing controls only relevant after user chooses body diameter mode; mirrors existing diameter_spin visibility contract
- [Phase 4, Plan 2]: FairingConstraintValidator centralizes D-04 constraint matrix and dynamic spinbox ranges — single source of truth for body/fairing mode validation; expression-based ranges ("body_d", "last_body_d") resolved at runtime
- [Phase 4, Plan 2]: Fairing mode radios rebuilt (not show/hide) on body mode change — ensures only valid combinations exist in button group; prevents stale state from hidden-but-checked radios
- [Phase 4, Plan 2]: Boat-tail geometry for Hammer-Head mode (10°) computed via _boat_tail_coords helper — enables true-scale diagram rendering of fairing-to-body transition
- [Phase ?]: RocketDiagramView.update_diagram() replaces build_rocket_scene() as primary API; supports placeholder mode — Cleaner separation; placeholder as first-class operation
- [Phase ?]: Diagram shows placeholder immediately on any input change (_on_inputs_changed), not after _run — Prevents stale diagram display; addresses T-04-09 threat
- [Phase ?]: Unified fairing computation: both diagram and export call compute_fairing_geometry_per_stage — Single source of truth eliminates drift between visual and exported data
- [Phase ?]: Hammer-Head fairing rendered in distinct orange color for boat-tail transition — Makes discontinuous diameter (fairing > body) visually obvious
- [Phase ?]: True-scale coordinate system: scene built in meters (1 unit = 1 meter), Y-up via QTransform.fromScale(1, -1) — Fairing tip at top, stages stack downward visually; matches rocket visual convention
