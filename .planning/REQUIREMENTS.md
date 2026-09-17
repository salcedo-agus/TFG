# Requirements: TFG — Multi-Stage Launch Vehicle Design Tool

**Defined:** 2026-09-17
**Core Value:** The user can go from mission parameters to a complete, trustworthy vehicle design (stage masses, ΔV, thrust, geometry) entirely from the GUI.

## v1 Requirements

### Rocket Visualization (VIS)

- [ ] **VIS-01**: Rocket dimension diagram in Vehicle Config tab — shows per-stage body diameter, length, volume post-analysis
- [ ] **VIS-02**: Diagram supports zoom, pan, and PNG export
- [ ] **VIS-03**: Diagram updates in real-time when results change

### Fairing Configuration (FAIR)

- [ ] **FAIR-01**: Fairing mode "Constant" — fairing diameter equals body diameter
- [ ] **FAIR-02**: Fairing mode "User-specified" — body diameter adjusts to user fairing input
- [ ] **FAIR-03**: Fairing mode "Hammer-Head" — fairing > body; body constant + statistically defined; fairing user-defined
- [ ] **FAIR-04**: Fairing geometry included in results export (.txt)

### GUI Aesthetics (GUI)

- [ ] **GUI-09**: Modern theme applied (qt-material base + custom QSS)
- [ ] **GUI-10**: Windows dark title bar via WinAPI
- [ ] **GUI-11**: ASCII art splash candidate evaluated (debug/console only)

## v2 Requirements

Deferred to future release. Tracked but not in current roadmap.

### Known Fortran Correctness (out of current scope)

- **FIX-04**: Config parser writes stage-2/3 combustion cycles into `first_stage_combustion_cycle` (`Typical_Data.f90:924-930`)
- **FIX-05**: Hardcoded Soyuz TEST CASE overrides all ISP/k_s tables in the Fortran path (`Typical_Data.f90:824-832`)
- **FIX-06**: Makefile circular dependency between `Staging.o` and `Root_Finding.o`

### Physics / Simulation

- **SIM-01**: Trajectory / 3-DoF guidance simulation (README objective)
- **SIM-02**: Launch-site / launch-latitude model (V_rot)

## Out of Scope

| Feature | Reason |
|---------|--------|
| Automated tests | Explicitly deferred by the user to future sessions |
| Trajectory simulation / 3-DoF guidance | Listed in README objectives but not part of this work |
| Launch-site / launch-latitude model (V_rot) | Missing Fortran module, future work |
| New Fortran physics features | Only interface/pipeline wiring may change on the Fortran side |
| config.txt replacement | GUI and config.txt remain separate input paths (user decision) |
| Full ASCII art diagram in GUI | Not HiDPI-compatible, accessibility concerns |
| Boat-tail geometry visualization | v1.2+ differentiator |

## Traceability

| Requirement | Phase | Status |
|-------------|-------|--------|
| VIS-01 | Phase 5 | Pending |
| VIS-02 | Phase 5 | Pending |
| VIS-03 | Phase 5 | Pending |
| FAIR-01 | Phase 4 | Pending |
| FAIR-02 | Phase 4 | Pending |
| FAIR-03 | Phase 4 | Pending |
| FAIR-04 | Phase 4 | Pending |
| GUI-09 | Phase 6 | Pending |
| GUI-10 | Phase 6 | Pending |
| GUI-11 | Phase 6 | Pending |

**Coverage:**

- v1 requirements: 11 total
- Mapped to phases: 11
- Unmapped: 0 ✓

---
*Requirements defined: 2026-09-17*
*Last updated: 2026-09-17 after initial definition*