# Technology Stack

**Project:** TFG — Multi-Stage Launch Vehicle Design Tool (v1.1 GUI Visual Enhancements & Fairing Configuration)
**Researched:** 2026-09-17

## Existing Validated Stack (DO NOT CHANGE)

| Technology | Version | Purpose | Why |
|------------|---------|---------|-----|
| Fortran | 90/2008 (gfortran) | Computational core (staging solver, pre-staging, pre-simulation) | Existing validated pipeline; non-negotiable per constraints |
| Python | 3.11 | GUI host, ctypes bridge, config parsing | Existing; compatible with all new libs below |
| PyQt6 | 6.6+ (current 6.11) | GUI framework (3-tab workbench) | Existing; central to all new features |
| ctypes | stdlib | Python↔Fortran bridge (`librocket.dll`) | Existing validated single entry `run_full_pipeline` |
| MinGW | TDM-GCC-64 (discovered at build) | Fortran compiler on Windows | Fixed in Phase 3 (FIX-03); no hardcoded path |
| numpy | 1.24+ | Numerical arrays for Fortran bridge | Already a transitive dependency |

---

## Recommended Stack Additions for v1.1

### Core Visualization — Rocket Dimension Diagrams

| Library | Version | Purpose | Why |
|---------|---------|---------|-----|
| **pyqtgraph** | 0.13.7+ | Interactive 2D engineering diagrams in Vehicle Config tab | **Primary recommendation.** Built on Qt's native `QGraphicsView`/`QGraphicsScene`; 75–150× faster than matplotlib for interactive widgets (SciPy 2023 benchmark); designed for mathematics/scientific/engineering apps; supports PyQt6 6.8+, Python 3.12+ (SPEC 0); MIT license; zero extra deps beyond numpy. Integrates as a `QWidget` directly into the Vehicle Config tab. |
| **matplotlib** | 3.11+ | Fallback / export-quality static diagrams | **Secondary option.** Richer plot types, publication-quality output, familiar API. Renders as bitmap via Agg backend — slower for interactive use, Qt unaware of plot elements. Use only if PyQtGraph cannot express a specific diagram type. Embed via `FigureCanvasQTAgg` from `matplotlib.backends.backend_qtagg`. |

**Decision:** Use **pyqtgraph** as the primary diagram engine. It is purpose-built for interactive engineering GUIS in PyQt6, performs dramatically better for the "post-analysis" rocket dimension diagrams (diameter, length, volume per stage) that need pan/zoom/interactivity, and adds only `numpy` (already present). Matplotlib remains available as a fallback for static export.

### GUI Aesthetics & Styling

| Library | Version | Purpose | Why |
|---------|---------|---------|-----|
| **qt-material** | 2.17 | Material Design inspired themes (dark/light), runtime switching | **Primary recommendation.** Actively maintained (2025 commits); 18 built-in themes; custom accent colors/fonts via `extra` dict; runtime theme switching without restart; exports `.qss`/`.rcc` for standalone/C++ use; density scaling for accessibility; works with PyQt6 via `from qt_material import apply_stylesheet`. One-line integration: `apply_stylesheet(app, theme='dark_teal.xml')`. |
| **qt-modern-style** | 2.0.1 | Clean corporate-style light theme + 500+ SVG icons | **Alternative if Material isn't desired.** Zero dependencies; one-line setup `qt_modern_style.get_stylesheet()`; includes professional icon set; supports `primary`/`danger` button properties and `hint`/`muted` label properties via Qt properties. Light-theme only (no dark mode). |
| **qdarkstyle** | 3.2.3 | Comprehensive dark/light stylesheets | **Fallback.** Most complete stylesheet coverage (all Qt widgets); supports PyQt6 via `load_stylesheet_pyqt6()`; but heavier, less modern aesthetic than qt-material. |
| **Custom QSS** | — | Fine-grained control without extra deps | **Always available.** Native Qt approach; use for targeted overrides on top of a base theme. No version to track. |

**Decision:** Adopt **qt-material** as the base theme (`dark_teal.xml` or `light_blue.xml` with `invert_secondary=True`). It gives a modern, engineering-appropriate look with minimal code, supports runtime switching (useful for user preference), and integrates cleanly with PyQt6. Layer custom QSS for rocket-diagram-specific widgets (e.g., diagram canvas border, stage color coding). Do NOT add qt-modern-style or qdarkstyle unless qt-material proves insufficient.

### ASCII Art Exploration (GUI-09)

| Library | Version | Purpose | Why |
|---------|---------|---------|-----|
| **art** | 6.5 | Text → ASCII art (fonts, decorations, barcode) | **For text-based ASCII headers/logos.** Pure Python, no deps; `text2art("TFG", font="block")` returns string; many fonts; decorations (barcode, etc.). Use for splash screen ASCII logo or section headers. |
| **ascii-art-python** | 2.1.1 | Image/video → ASCII art (density/edge/hybrid modes) | **If exploring image-to-ASCII for diagrams.** Requires `opencv-python-headless` (extra dep); converts images to terminal graphics; overkill for text-only needs. |
| **pyascii** | (GitHub) | Image/GIF → ASCII with PyQt6 GUI | **Reference implementation.** Has a PyQt6 GUI (`pyascii_gui.py`) demonstrating ASCII rendering in Qt; useful as a pattern reference, not as a dependency. |

**Decision:** Use **art (v6.5)** for the ASCII art candidate exploration — it's lightweight, pure Python, and generates text-based ASCII from strings (perfect for a splash/logo). Do not add image-to-ASCII libs unless the exploration specifically requires converting rocket diagram images to ASCII.

### Fairing Configuration (FAIR-01/02/03)

| Library | Version | Purpose | Why |
|---------|---------|---------|-----|
| *(none)* | — | Fairing diameter modes: Constant / User-specified / Hammer-Head | **No new libraries needed.** Pure PyQt6 UI logic: combo box for mode selection, conditional input fields (spinbox for user fairing diameter), and passing the selected mode + values through the existing `config.txt` → Fortran pipeline. The Fortran side may need new variables in the `Rocket` type, but that's Fortran code, not a Python library. |

---

## Alternatives Considered

| Category | Recommended | Alternative | Why Not |
|----------|-------------|-------------|---------|
| Interactive diagrams | **pyqtgraph** | matplotlib + `FigureCanvasQTAgg` | Matplotlib renders bitmaps; 75–150× slower for interactive widgets; Qt unaware of plot internals; higher memory. |
| Interactive diagrams | **pyqtgraph** | Raw `QGraphicsView`/`QGraphicsScene` | PyQtGraph *is* a thin, battle-tested layer over `QGraphicsView` with PlotWidget, ViewBox, GraphicsLayout, ROI tools — reimplementing wastes time. |
| Theming | **qt-material** | qt-modern-style | qt-modern-style is light-theme only; no dark mode; fewer built-in themes; no runtime switching API. |
| Theming | **qt-material** | qdarkstyle | qdarkstyle is comprehensive but dated aesthetic; heavier stylesheet; no built-in theme switching helper. |
| Theming | **qt-material** | Custom QSS only | Doable but reinvents wheel; qt-material provides 18 polished themes + switching + customization in ~50 KB. |
| ASCII art | **art** | pyfiglet / pyascii / ascii-art-python | `art` is pure Python, actively maintained (v6.5 2025), text→ASCII focus matches "ASCII art candidate" requirement; others add heavy deps (OpenCV) or are image-focused. |

---

## Installation

```bash
# Core (already present)
pip install pyqt6 numpy

# NEW for v1.1
pip install pyqtgraph==0.13.7
pip install qt-material==2.17
pip install art==6.5

# Optional: matplotlib (already common; only if needed for static export)
pip install matplotlib==3.11.1
```

**Note:** All new packages support Python 3.11+ and PyQt6 6.8+. `pyqtgraph` requires `numpy>=2.0` (already satisfied). No Fortran-side dependencies change.

---

## Sources

- PyQtGraph: GitHub (pyqtgraph/pyqtgraph), SciPy 2023 proceedings (75–150× faster than Matplotlib ImageItem), pyqtgraph.org — **HIGH confidence**
- qt-material: PyPI (v2.17), GitHub (dunderlab/qt-material), ReadTheDocs — **HIGH confidence**
- qt-modern-style: PyPI (v2.0.1) — **MEDIUM confidence** (less community adoption)
- qdarkstyle: GitHub (ColinDuquesnoy/QDarkStyleSheet v3.2.3), PyPI — **MEDIUM confidence**
- matplotlib Qt embedding: Matplotlib 3.11.1 official docs (backend_qtagg), Python GUIs tutorials — **HIGH confidence**
- art (ASCII): PyPI (v6.5), GitHub (sepandhaghighi/art), Anaconda — **HIGH confidence**
- ascii-art-python: PyPI (v2.1.1, 2026-05-13) — **LOW confidence** (new, OpenCV dep, not text-focused)