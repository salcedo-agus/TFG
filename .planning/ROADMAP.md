# ROADMAP: TFG v1.1 — GUI Visual Enhancements & Fairing Configuration

**Project:** TFG — Multi-Stage Launch Vehicle Design Tool
**Milestone:** v1.1
**Core Value:** The user can go from mission parameters to a complete, trustworthy vehicle design (stage masses, ΔV, thrust, geometry) entirely from the GUI — without touching config files, Fortran code, or the console.
**Granularity:** Standard (3 phases for 11 requirements)
**Phase Convention:** Sequential
**Generated:** 2026-09-17

---

## Phases

- [x] **Phase 4: GUI Fairing Controls (Stand-in)** — Add fairing diameter mode controls to Vehicle Config tab with Python-side mock fairing data; no Fortran changes
- [ ] **Phase 5: Vehicle Config Diagram** — Render interactive rocket dimension diagram in Vehicle Config tab using mock fairing data; zoom/pan/export; real-time updates
- [ ] **Phase 6: GUI Aesthetic Polish** — Apply modern qt-material theme, Windows dark title bar, evaluate ASCII art splash candidate

---

## Phase Details

### Phase 4: GUI Fairing Controls (Stand-in)

**Goal**: Add fairing diameter mode controls (Constant, User-specified, Hammer-Head) to Vehicle Config tab with Python-side mock fairing geometry. No Fortran changes — fairing data is mocked in Python for GUI integration validation.
**Depends on**: v1.0 complete (Phase 3)
**Requirements**: FAIR-01, FAIR-02, FAIR-03, FAIR-04
**Success Criteria** (what must be TRUE):

  1. User sees Fairing Mode radio group in Vehicle Config tab with 3 modes: Constant, User-specified, Hammer-Head
  2. Constant mode: fairing diameter equals body diameter (displayed in diagram)
  3. User-specified mode: body diameter adjusts to match user fairing input; fairing diameter shown in diagram
  4. Hammer-Head mode: fairing diameter > body diameter; body uses statistically-defined diameter; fairing uses user-defined diameter; diagram shows ogive profile
  5. Fairing geometry (diameter, length, volume per stage) included in `.txt` results export (mock data for now)

**Plans**: 3/3 plans executed

- [x] 04-01-PLAN.md — Tracer: Constant fairing mode end-to-end (UI, mock geometry, diagram, export)
- [x] 04-02-PLAN.md — Constraint validator + Tapered/Hammer-Head modes (D-04 matrix)
- [x] 04-03-PLAN.md — Diagram rendering + export for all modes, live updates

**UI hint**: yes

### Phase 5: Vehicle Config Diagram

**Goal**: Interactive rocket dimension diagram in Vehicle Config tab showing per-stage body + mock fairing geometry with zoom, pan, export, and real-time updates.
**Depends on**: Phase 4
**Requirements**: VIS-01, VIS-02, VIS-03
**Success Criteria** (what must be TRUE):

  1. User sees a side-view rocket diagram in Vehicle Config tab displaying per-stage body diameter, length, volume, and mock fairing geometry (ogive when fairing > body)
  2. User can zoom (mouse wheel) and pan (drag) the diagram using native `QGraphicsView` interactions
  3. User can export the diagram as PNG or SVG via a toolbar/button action
  4. Diagram updates automatically when analysis results change (fairing mode, diameter mode, stage count, payload, orbit) — shows "Run analysis to see diagram" placeholder when stale
  5. Diagram correctly renders Hammer-Head fairing profile (discontinuous diameter: fairing ogive atop constant-diameter body stages)

**Plans**: TBD
**UI hint**: yes

### Phase 6: GUI Aesthetic Polish

**Goal**: Modern, cohesive visual presentation across the GUI with dark/light theme switching, Windows dark title bar, and evaluated ASCII art candidate.
**Depends on**: Phase 4 (can parallelize; title bar fix must land before diagram screenshots)
**Requirements**: GUI-09, GUI-10, GUI-11
**Success Criteria** (what must be TRUE):

  1. User sees a modern dark theme (qt-material `dark_teal` base + custom QSS overrides) applied consistently across all tabs, widgets, and the `RocketDiagramView`
  2. User can switch between dark and light themes at runtime via a menu action without restarting the application
  4. On Windows 10/11, the window title bar is dark when dark theme is active (via `DwmSetWindowAttribute` WinAPI call with graceful degradation on older Windows)
  5. ASCII art splash/logo (via `art` library) appears in debug/console output at startup — not rendered in the GUI
  6. Font family and sizing are consistent between Qt widgets (QSS) and any Matplotlib static exports (rcParams synced)

**Plans**: TBD
**UI hint**: yes

---

## Progress Table

| Phase | Plans Complete | Status | Completed |
|-------|----------------|--------|-----------|
| 4. GUI Fairing Controls (Stand-in) | 3/3 | Complete | 2026-09-18 |
| 5. Vehicle Config Diagram | 0/0 | Not started | - |
| 6. GUI Aesthetic Polish | 0/0 | Not started | - |

---

## Future (v2+)

**Fortran Fairing Implementation** — Actual fairing geometry computation in Fortran core:

- Add `Fairing_t` type and `fairing_setup` enum in `Rocket_Types.f90` / `Typical_Data.f90`
- Implement fairing logic in `Geometry_calc.f90` (ogive/conic formulas, boat-tail angles)
- Extend `run_full_pipeline` ctypes signature with `fairing_mode_in`, `fairing_user_diameter_in` args
- Return `fairing_diameter`, `fairing_length`, `fairing_volume` scalars from Fortran
- Replace Python mock data with real Fortran output in Phase 4/5 GUI code
