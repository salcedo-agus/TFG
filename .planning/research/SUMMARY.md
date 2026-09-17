# Project Research Summary

**Project:** TFG — Multi-Stage Launch Vehicle Design Tool (v1.1 GUI Visual Enhancements & Fairing Configuration)
**Domain:** Engineering desktop application (Fortran 90/2008 computational core + PyQt6 GUI)
**Researched:** 2026-09-17
**Confidence:** HIGH

## Executive Summary

TFG is a mature desktop tool for conceptual multi-stage launch vehicle design, with a validated Fortran pipeline (staging solver, pre-staging, pre-simulation) exposed to a PyQt6 GUI via a single `run_full_pipeline` ctypes bridge. The v1.1 scope adds three capabilities: interactive rocket dimension diagrams in the Vehicle Config tab, three fairing diameter modes (Constant, User-specified, Hammer-Head), and GUI aesthetic improvements (modern theming, ASCII art exploration).

Research converges on a clear path: **use `pyqtgraph`/`QGraphicsView` for diagrams** (native Qt, 75–150× faster than Matplotlib for interactive use, no theme clashes), **adopt `qt-material` for theming** (18 themes, runtime switching, dark/light support, Windows title bar fixable via WinAPI), and **implement fairing modes in Fortran first** (separate `fairing_setup` enum + `Fairing_t` type) before wiring GUI controls — avoiding the enum-divergence pitfall that plagues this codebase. The critical dependency chain is: Fortran fairing geometry → ctypes bridge extension → GUI fairing radios → Vehicle Config diagram rendering. Aesthetic work (GUI-09) can parallelize but must address the Windows dark title bar issue first as it underpins all visual credibility.

Key risks are Matplotlib canvas lifecycle leaks in the tabbed interface, fairing/body mode combinatorial confusion (9 combos, some invalid), and Hammer-Head geometry breaking the single-diameter-per-stage assumption. All are preventable with the patterns documented in ARCHITECTURE.md and mitigations in PITFALLS.md.

## Key Findings

### Recommended Stack

**Existing validated stack (unchanged):** Fortran 90/2008 (gfortran), Python 3.11, PyQt6 6.6+, ctypes bridge (`librocket.dll`), MinGW TDM-GCC-64 (auto-discovered), numpy 1.24+.

**New additions for v1.1:**

| Library | Purpose | Rationale |
|---------|---------|-----------|
| **pyqtgraph 0.13.7+** | Primary 2D rocket diagrams in Vehicle Config tab | Built on `QGraphicsView`/`QGraphicsScene`; 75–150× faster than Matplotlib for interactive widgets; MIT license; zero deps beyond numpy; integrates as `QWidget` |
| **matplotlib 3.11+** | Fallback static export (PNG/SVG) | Publication-quality output if PyQtGraph cannot express a diagram type; embed via `FigureCanvasQTAgg` |
| **qt-material 2.17** | Base theme (dark/light), runtime switching | 18 themes, custom accent/fonts, exports QSS/RCC, one-line `apply_stylesheet()`; actively maintained |
| **art 6.5** | ASCII art headers/logo (GUI-09 exploration) | Pure Python, text→ASCII focus, no heavy deps; `text2art("TFG", font="block")` |
| *(none)* | Fairing logic | Pure PyQt6 UI + Fortran extensions — no new Python libraries |

**Decision:** PyQtGraph as primary diagram engine (native Qt, fast, themeable). qt-material as base theme with custom QSS overrides. Reject Matplotlib for primary diagrams (bitmap rendering, theme mismatch, memory leaks). Reject ASCII art as UI strategy (DPI scaling, accessibility, Hammer-Head impossible in text).

### Expected Features

**Must have (table stakes — v1.1 core):**
- Rocket side-view diagram showing stage dimensions (diameter, length, volume per stage) — standard in OpenRocket, RockSim, AEROS
- Fairing diameter mode selector (Constant / User-specified / Hammer-Head) — real launch vehicles offer multiple fairing configs
- Per-stage geometry display — already computed by pipeline, needs visual presentation
- Zoom/pan on diagram — standard interaction for technical diagrams
- Export diagram as PNG/SVG — engineers need diagrams for reports
- Real-time diagram update when parameters change (debounced) — expected in interactive tools

**Should have (differentiators — v1.1 if feasible, else v1.2):**
- Hammer-Head fairing with boat-tail visualization — shows aerodynamic transition geometry critical for real LV design (Vega-C, Falcon 9, Atlas V)
- ASCII-art rocket diagram as lightweight fallback — works in terminal/CI, zero deps, unique for desktop tool
- Stage mass/geometry correlation overlay — color-code by mass ratio, ΔV, structural fraction
- Fairing volume/payload envelope shading — shows usable payload volume vs. outer mold line

**Defer to v2+:**
- 3D interactive model (OpenGL/Qt3D — overkill for conceptual design)
- Real-time CFD/aero visualization (PhD-level, beyond scope)
- Full CAD export (STEP/IGES — requires OpenCASCADE)
- Animated staging separation (visual flair, no engineering value)
- Custom nose cone shape editor (doesn't affect staging solver)
- Dark-mode-only aesthetics (breaks printing/accessibility)

### Architecture Approach

**Pattern-driven additive architecture** — all changes are local and append-only:

1. **Fortran Core (`librocket.dll`)** — `run_full_pipeline` entry orchestrates: payload mass → orbit speed → STAGING_LOOP (bisection) → geometry calculation. New: `fairing_setup` global + `Fairing_t` type in `Rocket_Types.f90` + fairing diameter computation in `Geometry_calc.f90`.

2. **ctypes Bridge (`rocket_lib.py` + `C_Interface.f90`)** — Extend `argtypes` append-only with `fairing_mode_in`, `fairing_user_diameter_in`; return `fairing_diameter`, `fairing_length`, `fairing_volume` scalars. Backward compatible via `OPTIONAL` Fortran args.

3. **Python GUI (`gui.py`)** — Three tabs (Results, Setup, Vehicle Config). Vehicle tab gains: two radio groups (Body Diameter Mode + Fairing Mode), `RocketDiagramView` (`QGraphicsView`-based widget), diagram invalidation wired to `_on_inputs_changed()`.

4. **New `RocketDiagramView` widget** — Consumes `results["stages"]` (with new `fairing_diameter` field), paints body rectangles + fairing ogive via `QGraphicsRectItem`/`QGraphicsPolygonItem`. Single instance, reused across runs.

**Data flow:** GUI inputs → extended `run_full_pipeline()` → Fortran computes body + fairing geometry per stage → returns enriched stage dicts → GUI updates ResultCard + `RocketDiagramView.set_stages()`.

### Critical Pitfalls

1. **Matplotlib canvas lifecycle leaks in tabbed interface** — Embedding `FigureCanvasQTAgg` in Vehicle Config tab (`QScrollArea` + `QTabWidget`) accumulates figures on re-run. **Prevention:** Single canvas instance attribute created once in `_build_vehicle_tab()`, clear/redraw via `ax.cla()`, parent to tab's inner widget, guard re-entry.

2. **Fairing mode logic divergence between GUI and Fortran** — GUI implements fairing modes but Fortran `Geometry_calc.f90` only computes body diameter. Silent mismatch: GUI shows Hammer-Head, solver computes constant body. **Prevention:** Extend Fortran FIRST — add `fairing_setup` global + `Fairing_diameter_vector` in `Geometry_calc.f90` before any GUI work; mirror enum exactly; shared constants module.

3. **Diagram data staleness after input changes** — Vehicle Config diagram not connected to `_on_inputs_changed()`; shows old geometry after mode changes. **Prevention:** Connect `self._clear_vehicle_diagram()` to `_on_inputs_changed()`; show placeholder when `not hasattr(self, '_last_results')`; reuse existing guard pattern.

4. **ASCII art / custom painting vs. Matplotlib — wrong tool choice** — ASCII in `QLabel` breaks on HiDPI, font substitution, no interaction. **Prevention:** Use `QPainter` on custom `QWidget` (native, HiDPI, styleable) or Matplotlib with explicit dark theme sync. Reject ASCII for UI.

5. **Hammer-Head fairing breaks constant-diameter assumptions** — Discontinuous diameter profile (fairing > body); `Length_vector = Volume * 4 / (π * D²)` assumes uniform cylinder; `Rocket_t` has no fairing fields. **Prevention:** Add `Fairing_t` derived type to `Rocket_Types.f90`; extend `Rocket_t` with `fairing` component; compute fairing geometry separately in `Geometry_calc.f90`; return fairing scalars via ctypes.

6. **Qt dark theme title bar mismatch on Windows** — QSS styles client area only; title bar stays white on Win10/11. **Prevention:** `DwmSetWindowAttribute(DWMWA_USE_IMMERSIVE_DARK_MODE)` via ctypes + `QApplication.setStyle("Fusion")` — do first in GUI-09.

## Implications for Roadmap

Based on research, the following phase structure is recommended:

### Phase 1: Fortran Fairing Foundation (FAIR-01/02/03 Core)
**Rationale:** Fairing geometry must exist in Fortran before GUI can expose it. Pitfall 2 (enum divergence) and Pitfall 5 (Hammer-Head data model) require Fortran changes first. This phase unblocks all downstream GUI work.
**Delivers:**
- `Fairing_t` type in `Rocket_Types.f90` with `diameter`, `length`, `volume`
- `fairing_setup` global (1=Match body, 2=User-specified, 3=Hammer-Head) + `fairing_user_diameter` in `Geometry_calc.f90`
- Fairing geometry computation in `rocket_geometry_calculation` (ogive/conic length/volume formulas)
- Extended `run_full_pipeline` ctypes signature (append `fairing_mode_in`, `fairing_user_diameter_in`; return fairing scalars)
- Updated `.txt` export format with fairing block (version-tagged)
**Addresses:** FAIR-01 (Constant/Match body), FAIR-02 (User-specified fairing), FAIR-03 (Hammer-Head)
**Avoids:** Pitfall 2 (enum divergence), Pitfall 5 (data model), Pitfall 10 (export format)
**Uses:** Existing stack only (no new Python deps)

### Phase 2: Vehicle Config Diagram (VIS-01)
**Rationale:** Diagram rendering depends on fairing data from Phase 1. Must wire invalidation before rendering (Pitfall 3). PyQtGraph/QGraphicsView approach avoids Pitfalls 1, 4, 7, 11, 15.
**Delivers:**
- `RocketDiagramView` (`QGraphicsView`-based widget) in Vehicle Config tab
- Body diameter mode radios (existing 3) + Fairing mode radios (NEW 3, labeled "Match body", "User-specified", "Hammer-Head")
- Diagram renders stacked stages: body rectangles + fairing ogive (if `fairing_diameter > body_diameter`)
- Stage labels with diameter, length, volume; fairing annotation
- Zoom/pan via `QGraphicsView` native; export PNG/SVG via `QPainter`/`QGraphicsScene.render()`
- Diagram invalidation wired to `_on_inputs_changed()` — shows "Run analysis to see diagram" placeholder when stale
**Addresses:** VIS-01 (basic rocket side-view), table-stakes zoom/pan/export
**Avoids:** Pitfall 1 (canvas leak — single instance), Pitfall 3 (staleness), Pitfall 4 (ASCII trap), Pitfall 7 (theme mismatch — QPainter native), Pitfall 11 (QSS specificity — objectName override), Pitfall 15 (aspect ratio — QGraphicsView KeepAspectRatio)
**Uses:** pyqtgraph 0.13.7+ (or raw QGraphicsView), qt-material theme (from Phase 3 or parallel)

### Phase 3: GUI Aesthetic Polish (GUI-09)
**Rationale:** Aesthetic foundation (Windows dark title bar, Fusion style, theme consistency) should be in place before diagram work for visual coherence, but can parallelize with Phase 1. Must do title bar fix first (Pitfall 6).
**Delivers:**
- `qt-material` theme applied (`dark_teal.xml` default, `light_blue.xml` option) with custom QSS overrides for diagram widget
- Windows dark title bar via `DwmSetWindowAttribute` (graceful degradation)
- `QApplication.setStyle("Fusion")` for cross-platform palette consistency
- ASCII art splash/logo via `art` library (debug/logging only, not diagrams)
- Font consistency: Matplotlib `rcParams` synced to QSS `font-family` if Matplotlib used for export
- Theme switching action in menu (runtime, no restart)
**Addresses:** GUI-09 (aesthetic exploration), light theme default, dark mode option
**Avoids:** Pitfall 6 (title bar), Pitfall 7 (Matplotlib background), Pitfall 12 (font inconsistency)
**Uses:** qt-material 2.17, art 6.5

### Phase 4: Diagram Enhancements (Post-MVP)
**Rationale:** Differentiators that build on Phase 1-2 foundation. Can be sliced into sub-phases.
**Delivers (v1.2+):**
- Boat-tail angle visualization on Hammer-Head diagram (requires fairing geometry params in pipeline output)
- Stage mass/geometry correlation overlay (color mapping: k_m, ΔV, structural fraction)
- Fairing volume/payload envelope shading (inner vs. outer diameter)
- Side-by-side configuration comparison (dual canvas or tabbed)
- Real-time diagram update during parameter editing (debounced pipeline re-run)
- OpenSCAD script export (text-based, lightweight)

---

### Phase Ordering Rationale

1. **Fortran first (Phase 1):** The codebase has a known enum-divergence bug (CONCERNS.md: config parser writes stage-2/3 combustion cycles into `first_stage_combustion_cycle`). Fairing modes add a second diameter concept — if GUI and Fortran enums diverge, silent wrong results occur. Fortran changes are prerequisites for ctypes bridge extension.

2. **Diagram second (Phase 2):** Vehicle Config tab is the primary deliverable. Diagram rendering depends on fairing data structure from Phase 1. Wiring invalidation to `_on_inputs_changed()` before rendering logic prevents Pitfall 3.

3. **Aesthetics third (Phase 3):** Can parallelize with Phase 1 (independent), but Windows title bar fix must land before diagram screenshots/reviews. Theme consistency (Pitfall 7, 12) matters for diagram credibility.

4. **Enhancements last (Phase 4):** All differentiators require the base diagram + fairing data. Boat-tail needs fairing geometry params; correlation overlay needs pipeline outputs; comparison view needs dual-canvas architecture.

### Research Flags

**Phases needing deeper research during planning (`--research-phase`):**
- **Phase 1 (FAIR-01/02/03):** Fairing geometry math — exact ogive/conic length/volume formulas for Hammer-Head mode; fairing-to-payload clearance (NASA geometry guide: inner diameter = outer - 2×thickness). Need aerospace reference or empirical correlation.
- **Phase 2 (VIS-01):** Diagram coordinate system — true-scale (1:1 meter:pixel) vs. schematic (fixed height, variable width) — impacts `QPainter` vs. PyQtGraph choice and aspect ratio handling.

**Phases with standard patterns (skip research-phase):**
- **Phase 3 (GUI-09):** qt-material theming, Fusion style, Windows dark title bar WinAPI — well-documented Qt patterns, multiple reference implementations.
- **Phase 2 diagram rendering:** `QGraphicsView`/`QGraphicsScene` for engineering schematics — standard Qt pattern (OpenRocket, Super Calculator, PyQt6 Book).

## Confidence Assessment

| Area | Confidence | Notes |
|------|------------|-------|
| Stack | HIGH | All libraries verified on PyPI/GitHub; pyqtgraph/qt-material/art actively maintained; Python 3.11 + PyQt6 6.8+ compatibility confirmed |
| Features | HIGH | Table-stakes mapped to OpenRocket/RockSim/AEROS/rp1-rocket-designer reference implementations; differentiators grounded in TU Delft/NASA literature |
| Architecture | HIGH | Based on actual codebase analysis (C_Interface.f90, rocket_lib.py, Geometry_calc.f90, gui.py, Rocket_Types.f90); patterns are additive and local |
| Pitfalls | HIGH | Derived from codebase concerns (CONCERNS.md), actual GUI source (tab structure, _on_inputs_changed, STYLE QSS), and documented Qt/Matplotlib ecosystem issues |

**Overall confidence:** HIGH

### Gaps to Address

- **Fairing geometry math:** Exact Hammer-Head fairing length/volume formulas (ogive vs. conic) — need aerospace reference (NASA Coe-Nute Model 11, TU Delft papers) or empirical correlation. *Handle during Phase 1 planning: spike fairing geometry formulas before Fortran implementation.*
- **Diagram coordinate system:** True-scale vs. schematic — impacts rendering approach and aspect ratio. *Handle during Phase 2 planning: prototype both in 1-hour spike.*
- **Fairing-to-payload clearance:** NASA guide shows inner diameter = outer - 2×wall thickness; need thickness assumption or user input. *Handle during Phase 1: add optional fairing thickness parameter with sensible default.*
- **Export format versioning:** `.txt` results format should version-tag for fairing/diagram additions to avoid breaking downstream parsers. *Handle during Phase 1: add format version header to export.*

## Sources

### Primary (HIGH confidence)
- **Codebase analysis** (`.planning/codebase/ARCHITECTURE.md`, `CONCERNS.md`, `STRUCTURE.md`, `INTEGRATIONS.md`) — Fortran pipeline, ctypes bridge, GUI tab structure, diameter mode implementation, known bugs
- **GUI source** (`SRC/gui/gui.py`) — `_build_vehicle_tab`, `_on_inputs_changed`, `_run`, `STYLE` QSS, tab switching logic, `_last_results` pattern
- **Fortran geometry** (`SRC/pre-simulation-calcs/Geometry_calc.f90:92-105`) — `Diameter_setup` cases 1/2/3 implementation
- **Bridge** (`SRC/interface/C_Interface.f90`, `SRC/interface/rocket_lib.py`) — `run_full_pipeline` signature, `diameter_setup_in`, `user_diameter_in`, result packing
- **PyQtGraph** (GitHub pyqtgraph/pyqtgraph, SciPy 2023 proceedings, pyqtgraph.org) — 75–150× faster than Matplotlib, Qt-native, MIT license
- **qt-material** (PyPI v2.17, GitHub dunderlab/qt-material, ReadTheDocs) — 18 themes, runtime switching, PyQt6 support
- **Matplotlib Qt embedding** (Matplotlib 3.11.1 official docs, backend_qtagg, pythonguis.com) — Canvas lifecycle, dark theme styling, static export patterns
- **art ASCII** (PyPI v6.5, GitHub sepandhaghighi/art) — Pure Python text→ASCII, actively maintained

### Secondary (MEDIUM confidence)
- **OpenRocket / RockSim / AEROS / Eagle Rock / rp1-rocket-designer** — Reference implementations for table-stakes diagram features, component model, fairing placement, trade-study patterns
- **TU Delft hammerhead papers** (D'Aguanno 2024, González Romero 2023, Somani 2022) — Hammer-head aerodynamics, boat-tail angles, diameter ratios 1.25–2.0
- **NASA/Coe-Nute Model 11** — Standard hammerhead reference geometry
- **Qt Forum / Qt 6 docs** — Windows dark mode best practices, Fusion style, HiDPI scaling
- **Super Calculator (JinShuo-Li)** — Clean PyQt6 tabbed app with embedded matplotlib, centralized QSS

### Tertiary (LOW confidence)
- **rocket-edu-sim** (Streamlit-based) — Tabbed GUI patterns, trade-study heatmaps
- **PyQt6 Book (Martin Fitzpatrick, 2025)** — Theming, stylesheets, custom widgets, plotting chapter
- **ascii-art-python / pyascii** — Image-to-ASCII (not text-focused, heavy deps) — reviewed but rejected

---

*Research completed: 2026-09-17*
*Ready for roadmap: yes*