# Feature Landscape

**Domain:** Multi-stage launch vehicle design desktop tool (Fortran core + PyQt6 GUI)
**Researched:** 2026-09-17

## Table Stakes

Features users expect in a launch vehicle design tool. Missing = product feels incomplete.

| Feature | Why Expected | Complexity | Notes |
|---------|--------------|------------|-------|
| **Rocket side-view diagram showing stage dimensions** | Standard in every launch vehicle design tool (OpenRocket, RockSim, AEROS, Eagle Rock, rp1-rocket-designer). Engineers need visual confirmation of stage stacking, diameter transitions, and overall proportions. | Medium | Requires matplotlib/PyQt6 canvas embedding; needs stage diameter, length, volume data from pipeline. Depends on VIS-01. |
| **Fairing diameter mode selector** | Real launch vehicles offer multiple fairing configurations (constant, custom, hammerhead). Users expect to choose fairing-to-body relationship. | Low-Medium | UI control only; logic lives in Fortran geometry calculations. Depends on FAIR-01/02/03. |
| **Per-stage geometry display (diameter, length, volume)** | Already validated in Phase 1 (Results tab). Vehicle Config tab needs post-analysis visual summary. | Low | Data already computed by pipeline; just needs visual presentation. |
| **Zoom/pan on rocket diagram** | Standard interaction for technical diagrams. Users need to inspect stage details at different scales. | Low | Matplotlib NavigationToolbar provides this out of the box. |
| **Export diagram as image (PNG/SVG)** | Engineers need diagrams for reports, presentations, documentation. | Low | Matplotlib `Figure.savefig()` supports PNG, SVG, PDF. |
| **Real-time diagram update when parameters change** | Expected in interactive design tools (rp1-rocket-designer, rocket-edu-sim show live SVG updates). | Medium | Requires connecting GUI parameter signals to diagram refresh. Debouncing needed. |

## Differentiators

Features that set this tool apart. Not expected, but highly valued by aerospace engineers.

| Feature | Value Proposition | Complexity | Notes |
|---------|-------------------|------------|-------|
| **Hammer-Head fairing mode with boat-tail visualization** | Shows the aerodynamic transition geometry (boat-tail angle, diameter step) that drives transonic buffet loads — critical for real launch vehicle design (Vega-C, Falcon 9, Atlas V). No other conceptual tool visualizes this. | Medium-High | Requires Fairing mode "Hammer-Head" (FAIR-03) + boat-tail parameters. Visualization shows step geometry + boat-tail angle. Depends on FAIR-03. |
| **ASCII-art rocket diagram as lightweight fallback** | Works in terminal/headless environments, CI logs, quick debugging. Zero dependencies, instant render. Unique for a desktop GUI tool. | Low | Pure Python text generation. Can be a toggle in GUI. |
| **Stage mass/geometry correlation overlay** | Color-code stages by mass ratio, ΔV contribution, or structural fraction on the diagram. Turns a static drawing into an analytical view. | Medium | Requires mapping pipeline outputs (k_m, k_s, ΔV) to visual properties. High engineering value. |
| **Fairing volume/payload envelope shading** | Shows usable payload volume inside fairing vs. fairing outer mold line. Critical for payload integration. | Medium | Needs fairing inner diameter, cylindrical length, nose cone geometry. |
| **Side-by-side configuration comparison** | Compare Constant vs Hammer-Head fairing on same vehicle — visual trade study. Matches rocket-edu-sim's trade-study heatmaps but for geometry. | Medium-High | Requires dual-canvas or tabbed view. High value for design decisions. |

## Anti-Features

Features to explicitly NOT build.

| Anti-Feature | Why Avoid | What to Do Instead |
|--------------|-----------|-------------------|
| **3D interactive rocket model** | High complexity (OpenGL/Qt3D), not needed for conceptual design. 2D side view + base view is standard (OpenRocket, RockSim). 3D adds rotation/lighting complexity without engineering value at this stage. | 2D side view (primary) + optional base view (diameter cross-section). Use matplotlib 2D patches. |
| **Real-time CFD/aerodynamic visualization** | Requires CFD solver integration — far beyond conceptual design scope. Hammerhead buffet analysis is PhD-level work (see TU Delft papers). | Static diagram with boat-tail angle annotation; link to literature for transonic warnings. |
| **Full CAD export (STEP/IGES)** | Requires CAD kernel (OpenCASCADE) or complex geometry engine. AEROS exports OBJ/STL/OpenSCAD from Python — but that's production CAD, not conceptual. | SVG/PNG export for reports. OpenSCAD script generation (text-based) as lightweight alternative. |
| **Animated staging separation** | Visual flair without engineering utility. Conceptual design focuses on static sizing, not dynamic events. | Static stacked diagram with stage separation lines labeled. |
| **Custom nose cone shape editor (ogive, parabolic, Sears-Haack)** | Nose cone geometry doesn't affect the staging solver or mass budgets in this tool's scope. Fairing shape is a downstream aerodynamics concern. | Fixed ogive/bi-conic fairing shape; annotate boat-tail angle for Hammer-Head mode. |
| **Dark-mode-only aesthetics** | Engineering tools often used in bright offices, printed screenshots, or shared screens. Force dark mode breaks accessibility and printing. | System-following theme (Qt palette) + optional user override. Light mode default. |

## Feature Dependencies

```
Existing pipeline (validated) → FAIR-01/02/03 (fairing modes in Fortran geometry)
                                ↓
                    VIS-01 (rocket diagram in Vehicle Config tab)
                                ↓
                    GUI-09 (aesthetic exploration) — independent, can parallelize
                                ↓
            Diagram export / zoom / real-time update (enhancements on VIS-01)
                                ↓
            Hammer-Head boat-tail visualization (enhancement on FAIR-03 + VIS-01)
                                ↓
            Stage correlation overlay / comparison view (advanced enhancements)
```

**Critical path:** Fortran fairing geometry → Python bridge → Vehicle Config tab diagram

- FAIR-01/02/03 require Fortran `Pre_simulation` module changes (diameter mode logic)
- VIS-01 requires Python GUI work: matplotlib canvas in Vehicle Config tab, data extraction from `run_full_pipeline` output
- GUI-09 is independent exploration (stylesheets, ASCII art, matplotlib vs QtCharts vs PyQtGraph)

## MVP Recommendation

**Prioritize (v1.1 core):**

1. **FAIR-01: Constant fairing mode** — Fairing diameter = body diameter. Minimal Fortran change, establishes the mode infrastructure.
2. **FAIR-02: User-specified fairing mode** — Body adjusts to fairing input. Adds input field + reverse calculation.
3. **FAIR-03: Hammer-Head mode** — Fairing > body; body constant + statistical; fairing user-defined. Core differentiator.
4. **VIS-01: Basic rocket side-view diagram** — Matplotlib canvas in Vehicle Config tab showing stacked stages with diameter, length, volume labels. Post-analysis (read-only after pipeline runs).
5. **GUI-09: Light theme + ASCII art diagram** — Clean professional look (Qt palette-based), ASCII fallback for logs.

**Defer to v1.2+:**

| Feature | Reason |
|---------|--------|
| Boat-tail angle visualization on diagram | Requires fairing geometry parameters not yet in pipeline output |
| Stage mass/geometry correlation overlay | Needs design iteration on color mapping; nice-to-have |
| Side-by-side configuration comparison | Requires dual-canvas architecture; UX complexity |
| OpenSCAD script export | Low priority; PNG/SVG sufficient for reports |
| Real-time diagram update during parameter editing | Needs signal debouncing + pipeline re-run optimization; can be v1.2 polish |

## Sources

| Source | Type | Confidence | Relevance |
|--------|------|------------|-----------|
| OpenRocket / RockSim documentation | Reference implementation | HIGH | Table-stakes diagram features, component model |
| AEROS (aeros/cad.py, aeros/plots.py) | Reference implementation | HIGH | Concept CAD export, matplotlib vehicle drawings, fairing placement |
| Eagle Rock (eagle_rock/gui/) | Reference implementation | HIGH | PyQt6 workspace/tab architecture, CAD export |
| rp1-rocket-designer (SVG real-time rendering) | Reference implementation | HIGH | Live diagram updates, cross-section view, zoom/pan |
| rocket-edu-sim (trade_study_gui.py) | Reference implementation | MEDIUM | Tabbed GUI, Streamlit-based but shows trade-study patterns |
| TU Delft hammerhead papers (D'Aguanno 2024, González Romero 2023, Somani 2022) | Academic literature | HIGH | Hammer-head aerodynamics, boat-tail angles, diameter ratios, fairing geometry |
| NASA/Coe-Nute Model 11 references | Academic literature | HIGH | Standard hammerhead reference geometry, diameter ratios 1.25–2.0 |
| PyQt6 + Matplotlib embedding tutorials (pythonguis.com, matplotlib.org) | Technical documentation | HIGH | Canvas embedding, toolbar customization, overlay patterns |
| Super Calculator (JinShuo-Li) | Reference implementation | MEDIUM | Clean PyQt6 tabbed app with embedded matplotlib, centralized QSS |
| PyQt6 Book (Martin Fitzpatrick, 2025) | Technical reference | MEDIUM | Theming, stylesheets, custom widgets, plotting chapter |