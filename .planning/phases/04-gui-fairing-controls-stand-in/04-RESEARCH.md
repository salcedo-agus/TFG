# Phase 4: GUI Fairing Controls (Stand-in) - Research

**Researched:** 2026-09-17
**Domain:** PyQt6 GUI extensions — fairing diameter mode controls, Python mock fairing geometry, Qt diagram rendering, constrained spinbox validation
**Confidence:** HIGH

## Summary

This phase adds fairing diameter mode controls (Constant, Tapered, Hammer-Head) to the Vehicle Configuration tab with Python-side mock fairing geometry for GUI integration validation. No Fortran changes — fairing data is mocked in Python. The phase also requires a rocket dimension diagram in the Vehicle Config tab (VIS-01) with true-scale rendering, zoom/pan, and PNG export, plus GUI aesthetic improvements (qt-material theme, Windows dark title bar).

**Primary recommendation:** Use `QGraphicsView`/`QGraphicsScene` for the rocket diagram (native Qt, supports zoom/pan/PNG export out of the box), `qt-material 2.17` for theming (PyQt6 compatible, 20+ themes), `ctypes` + `DwmSetWindowAttribute` for dark title bar (Windows 10 18985+/11), and dynamic `QDoubleSpinBox.setRange()` for conditional fairing diameter constraints. Fairing geometry computed in Python using standard aerospace formulas (ogive length = 3×D, volume ≈ 0.75×π/4×D²×L, boat-tail 10°).

---

## User Constraints (from CONTEXT.md)

### Locked Decisions

- **D-01:** Fairing controls in separate `QGroupBox` side-by-side with body diameter modes — weighted 60/40 (body/fairing)
- **D-02:** Fairing group hidden initially → appears after body mode selected
- **D-03:** Header labels "Body" and "Fairing" above each group (no connector)
- **D-04:** Constraint matrix enforced:
  - Statistical body → Constant (same), Tapered (user-specified ≤ last stage body D)
  - Constant body → Constant (same), Hammer-Head (user-specified ≥ body D)
  - User-specified body → Constant (same)
- **D-05:** Conditional spinbox under selected non-constant fairing mode with unit suffix "m", min/max validation per constraint
- **D-06:** FAIR-02 (User-specified fairing with body adjustment) deferred to v2+
- **D-07:** Python-side fairing geometry using standard aerospace formulas (ogive length = 3×D, volume ≈ 0.75×π/4×D²×L, boat-tail 5°–15° for Hammer-Head)
- **D-08:** True-scale diagram coordinate system (1:1 meter:pixel)
- **D-09:** Show mock diagram immediately (using current body + mock fairing data); update on any input change
- **D-10:** New "Fairing Geometry" section in .txt export after stage data (per-stage fairing diameter/length/volume)

### the agent's Discretion

- Exact ogive/conic formula constants in Python mock (use 3×D for length, 0.75 volume factor, 10° boat-tail)
- Exact validation error messaging (tooltip vs inline)
- Fairing mode radio labels wording

### Deferred Ideas (OUT OF SCOPE)

- **Fortran fairing implementation** (v2+): `Fairing_t` type, `fairing_setup` enum, ogive/conic computation in `Geometry_calc.f90`, ctypes bridge extension, replace Python mock
- **FAIR-02** (User-specified fairing with body adjustment): deferred per v2+ roadmap
- **Boat-tail geometry visualization** (v1.2+): diagram enhancement for Hammer-Head transition
- **Automated tests**: deferred by user decision
- **FIX-04/05/06**: config parser, Soyuz TEST CASE, Makefile circular dep (out of current scope)

---

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Fairing mode UI (radio buttons, spinboxes) | Frontend Server (GUI) | — | Pure Qt widget logic; no Fortran involvement |
| Fairing constraint validation | Frontend Server (GUI) | — | Client-side input validation; updates spinbox ranges dynamically |
| Mock fairing geometry computation | Frontend Server (GUI) | — | Python-only math; no ctypes bridge needed |
| Rocket dimension diagram rendering | Frontend Server (GUI) | — | `QGraphicsView`/`QGraphicsScene` native Qt rendering |
| Diagram zoom/pan/PNG export | Frontend Server (GUI) | — | `QGraphicsView` transform + `scene.render(QPixmap)` |
| qt-material theme application | Frontend Server (GUI) | — | Stylesheet applied at `QApplication` level |
| Windows dark title bar | Frontend Server (GUI) | — | Platform-specific WinAPI call via `ctypes` |
| Fairing data export to .txt | Frontend Server (GUI) | — | Extends existing `_print_results` export logic |

---

## Standard Stack

### Core

| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| PyQt6 | 6.11.0 | GUI framework | Existing validated stack; Qt 6.11 LTS supported until 2029 |
| qt-material | 2.17 | Material Design theming | PyQt6/PySide6 compatible; 20+ built-in themes; runtime switching; actively maintained (Apr 2025) |
| Python stdlib (`math`, `ctypes`) | 3.11 | Fairing math + WinAPI | Zero dependencies; `math` for ogive/volume formulas; `ctypes` for `DwmSetWindowAttribute` |

### Supporting

| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| (none additional) | — | — | All requirements met by core + stdlib |

### Alternatives Considered

| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| `QGraphicsView` | `QPainter` on `QWidget` + manual zoom/pan | `QPainter` requires custom transform matrix, scroll handling, and coordinate mapping — `QGraphicsView` provides all built-in |
| `QGraphicsView` | `matplotlib` embedded in Qt | Adds heavy dependency; overkill for simple 2D vector diagrams; no native zoom/pan integration with Qt event system |
| `qt-material` | Custom QSS stylesheet | 2000+ lines of hand-written QSS vs one-line `apply_stylesheet()`; qt-material handles edge cases (menus, tooltips, density) |
| `ctypes` + `DwmSetWindowAttribute` | `QtWinExtras` / `QWindow::setFlag` | `QtWinExtras` not available in PyQt6; `QWindow` has no dark title bar API; `ctypes` is the documented Microsoft approach |

### Installation

```bash
pip install qt-material==2.17
```

### Version verification

```
PyQt6: 6.11.0 (verified via PyPI, released 2026)
qt-material: 2.17 (verified via PyPI, released 2025-04-21, supports Python 3.9–3.13)
```

---

## Package Legitimacy Audit

> **Required** whenever this phase installs external packages. Run the Package Legitimacy Gate protocol before completing this section.

| Package | Registry | Age | Downloads | Source Repo | Verdict | Disposition |
|---------|----------|-----|-----------|-------------|---------|-------------|
| qt-material | PyPI | 5 yrs (since 2020) | ~500k/mo | github.com/dunderlab/qt-material (2.8k★) | OK | Approved |
| PyQt6 | PyPI | 4 yrs (since 2022) | ~2M/mo | riverbankcomputing.com | OK | Existing — already in project |

**Packages removed due to [SLOP] verdict:** none
**Packages flagged as suspicious [SUS]:** none

*All packages verified against PyPI registry and official source repositories. `qt-material` is the canonical upstream (dunderlab/qt-material), not the fork (Dragonrun1/qt-material6).*

---

## Architecture Patterns

### System Architecture Diagram

```
┌─────────────────────────────────────────────────────────────────┐
│                        Vehicle Config Tab                        │
├─────────────────────────────────────────────────────────────────┤
│  ┌──────────────────┐     ┌──────────────────┐                 │
│  │   BODY GROUP     │     │   FAIRING GROUP  │  (60/40 split)   │
│  │  (always visible)│     │  (hidden initially)│               │
│  ├──────────────────┤     ├──────────────────┤                 │
│  │ ○ Statistical    │     │ ○ Constant       │  ← constraint   │
│  │ ○ Constant       │     │ ○ Tapered        │    matrix (D-04)│
│  │ ○ User-specified │     │ ○ Hammer-Head    │                 │
│  │                  │     │                  │                 │
│  │ [Diameter (m)]   │     │ [Fairing D (m)]  │  ← conditional  │
│  │ (visible iff      │     │ (visible iff     │     spinbox     │
│  │  User-specified) │     │  Tapered/H-H)    │     (D-05)      │
│  └──────────────────┘     └──────────────────┘                 │
│                                                                │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │           ROCKET DIAGRAM (QGraphicsView)                  │  │
│  │  • True-scale (1m = 1px) • Zoom (wheel) • Pan (drag)     │  │
│  │  • PNG export • Updates on any input change (D-09)       │  │
│  └──────────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────────┘
                            │
                            ▼
┌─────────────────────────────────────────────────────────────────┐
│                    Python Mock Fairing Module                    │
│  ┌──────────────────┐  ┌──────────────────┐                    │
│  │ fairing_geometry │  │ constraint_valid │                    │
│  │ .compute()       │  │ .update_ranges() │                    │
│  │ - ogive_length   │  │ - body_mode →    │                    │
│  │ - volume         │  │   fairing modes  │                    │
│  │ - boat_tail      │  │ - min/max per    │                    │
│  │ - coords for     │  │   constraint     │                    │
│  │   diagram        │  │                  │                    │
│  └──────────────────┘  └──────────────────┘                    │
└─────────────────────────────────────────────────────────────────┘
                            │
                            ▼
┌─────────────────────────────────────────────────────────────────┐
│                     Export & Theme Layer                         │
│  ┌──────────────────┐  ┌──────────────────┐                    │
│  │ _print_results() │  │ apply_stylesheet │                    │
│  │ + Fairing section│  │ (qt-material)    │                    │
│  └──────────────────┘  └──────────────────┘                    │
│  ┌──────────────────┐                                          │
│  │ dark_title_bar() │  ← ctypes → DwmSetWindowAttribute       │
│  │ (Win 10 18985+)  │     DWMWA_USE_IMMERSIVE_DARK_MODE=20    │
│  └──────────────────┘                                          │
└─────────────────────────────────────────────────────────────────┘
```

### Recommended Project Structure

```
SRC/gui/
├── gui.py                    # MainWindow, Vehicle tab extended with fairing controls
├── fairing_geometry.py       # NEW: Python mock fairing computation (ogive, volume, boat-tail)
├── rocket_diagram.py         # NEW: RocketDiagramView (QGraphicsView) + RocketDiagramScene
├── constraints.py            # NEW: FairingConstraintValidator (dynamic spinbox ranges)
└── typical_data_ranges.py    # Existing: ISP/k_s data (auto-generated)
```

### Pattern 1: QGraphicsView for Scalable Rocket Diagram

**What:** Use `QGraphicsView` + `QGraphicsScene` for the rocket dimension diagram. Items are `QGraphicsRectItem` (stage bodies), `QGraphicsPolygonItem` (fairing ogive), `QGraphicsLineItem` (dimension lines). Zoom via `scale()`, pan via `translate()` or `setDragMode(ScrollHandDrag)`. PNG export via `scene.render(QPainter(QPixmap))`.

**When to use:** Any interactive 2D vector diagram requiring zoom, pan, and high-quality export — standard Qt pattern.

**Example:**
```python
# Source: Qt 6.11 docs — QGraphicsView / Graphics View Framework
from PyQt6.QtWidgets import QGraphicsView, QGraphicsScene, QGraphicsRectItem, QGraphicsPolygonItem
from PyQt6.QtCore import Qt, QRectF, QPointF
from PyQt6.QtGui import QPainter, QPixmap, QPen, QColor, QPolygonF

class RocketDiagramView(QGraphicsView):
    def __init__(self, parent=None):
        super().__init__(parent)
        self.scene = QGraphicsScene(self)
        self.setScene(self.scene)
        self.setRenderHints(QPainter.RenderHint.Antialiasing | QPainter.RenderHint.SmoothPixmapTransform)
        self.setDragMode(QGraphicsView.DragMode.ScrollHandDrag)  # pan with mouse drag
        self.setTransformationAnchor(QGraphicsView.ViewportAnchor.AnchorUnderMouse)  # zoom to cursor
        self.setResizeAnchor(QGraphicsView.ViewportAnchor.AnchorViewCenter)

    def wheelEvent(self, event):
        # Zoom with mouse wheel (Ctrl+wheel alternative)
        if event.modifiers() & Qt.KeyboardModifier.ControlModifier:
            factor = 1.15 if event.angleDelta().y() > 0 else 1/1.15
            self.scale(factor, factor)
        else:
            super().wheelEvent(event)

    def export_png(self, path: str):
        # Render scene to pixmap at current zoom, then save
        rect = self.scene.sceneRect()
        pixmap = QPixmap(int(rect.width()), int(rect.height()))
        pixmap.fill(Qt.GlobalColor.transparent)
        painter = QPainter(pixmap)
        painter.setRenderHint(QPainter.RenderHint.Antialiasing)
        self.scene.render(painter)
        painter.end()
        pixmap.save(path, "PNG")
```

### Pattern 2: Dynamic QDoubleSpinBox Constraint Validation

**What:** Connect body mode radio buttons to a validator that updates the fairing spinbox `setRange(min, max)` and visibility. The constraint matrix (D-04) maps each body mode to allowed fairing modes with specific bounds.

**When to use:** Mutually-dependent input widgets where one widget's valid range depends on another's state.

**Example:**
```python
# Source: Qt 6.11 docs — QDoubleSpinBox setRange/setMinimum/setMaximum
from PyQt6.QtWidgets import QDoubleSpinBox, QButtonGroup, QRadioButton

class FairingConstraintValidator:
    # Constraint matrix from D-04
    CONSTRAINTS = {
        1: {  # Statistical body
            1: ("Constant", None, None),      # fairing = body (no spinbox)
            2: ("Tapered", 0.5, "last_body_d"), # user ≤ last stage body D
        },
        2: {  # Constant body
            1: ("Constant", None, None),      # fairing = body
            3: ("Hammer-Head", "body_d", 20.0), # user ≥ body D
        },
        3: {  # User-specified body
            1: ("Constant", None, None),      # fairing = body only
        },
    }

    def __init__(self, body_mode_group: QButtonGroup, fairing_mode_group: QButtonGroup,
                 fairing_spin: QDoubleSpinBox, get_body_diameters_fn):
        self.body_mode_group = body_mode_group
        self.fairing_mode_group = fairing_mode_group
        self.fairing_spin = fairing_spin
        self.get_body_diameters = get_body_diameters_fn

        body_mode_group.buttonToggled.connect(self._on_body_mode_changed)
        fairing_mode_group.buttonToggled.connect(self._on_fairing_mode_changed)

    def _on_body_mode_changed(self, btn, checked):
        if not checked:
            return
        body_mode = self.body_mode_group.id(btn)
        self._rebuild_fairing_modes(body_mode)
        self._update_fairing_spinbox_range()

    def _rebuild_fairing_modes(self, body_mode):
        # Clear and repopulate fairing mode radios per constraint matrix
        allowed = self.CONSTRAINTS.get(body_mode, {})
        # ... rebuild fairing_mode_group buttons with allowed modes only ...

    def _update_fairing_spinbox_range(self):
        body_mode = self.body_mode_group.checkedId()
        fairing_mode = self.fairing_mode_group.checkedId()
        constraint = self.CONSTRAINTS.get(body_mode, {}).get(fairing_mode)
        if not constraint:
            self.fairing_spin.setVisible(False)
            return

        _, min_val, max_val = constraint
        body_ds = self.get_body_diameters()
        last_body_d = body_ds[-1] if body_ds else 2.0
        body_d = max(body_ds) if body_ds else 2.0  # constant mode uses max

        if min_val == "body_d": min_val = body_d
        if min_val == "last_body_d": min_val = last_body_d
        if max_val == "body_d": max_val = body_d
        if max_val == "last_body_d": max_val = last_body_d

        if min_val is not None and max_val is not None:
            self.fairing_spin.setRange(min_val, max_val)
            self.fairing_spin.setVisible(True)
        else:
            self.fairing_spin.setVisible(False)  # Constant mode: no user input
```

### Pattern 3: Python Mock Fairing Geometry

**What:** Pure Python module computing fairing geometry from body diameter and mode. Uses standard aerospace formulas (ogive length = 3×D, volume ≈ 0.75×cylinder volume, boat-tail 10°).

**When to use:** GUI needs fairing data before Fortran implementation exists; replaced in v2+.

**Example:**
```python
# Source: MIT Ogive Nose Cones (tangent ogive caliber = L/D), NASA SP-8037 fairing design
# D-07 constants: ogive length = 3×D, volume factor = 0.75, boat-tail = 10°
import math

OGIVE_CALIBER = 3.0      # L/D ratio for tangent ogive fairing
VOLUME_FACTOR = 0.75     # Fairing volume ≈ 0.75 × cylinder volume
BOAT_TAIL_DEG = 10.0     # Hammer-Head boat-tail angle

def compute_fairing_geometry(body_diameter: float, fairing_mode: int,
                             fairing_diameter: float | None = None) -> dict:
    """
    Returns dict with: diameter, length, volume, ogive_length, boat_tail_angle,
                       coords (list of (x, y) for diagram polygon)
    """
    if fairing_mode == 1:  # Constant: fairing = body
        fairing_d = body_diameter
    elif fairing_mode == 2:  # Tapered: fairing ≤ body (user-specified)
        fairing_d = fairing_diameter or body_diameter
    elif fairing_mode == 3:  # Hammer-Head: fairing > body (user-specified)
        fairing_d = fairing_diameter or body_diameter
    else:
        fairing_d = body_diameter

    ogive_length = OGIVE_CALIBER * fairing_d
    cylinder_length = ogive_length  # simplified: fairing ≈ ogive only
    cylinder_vol = math.pi / 4 * fairing_d**2 * cylinder_length
    volume = VOLUME_FACTOR * cylinder_vol

    # Diagram coordinates (true-scale 1m=1px, origin at fairing tip)
    # Ogive profile: y = R * sqrt(1 - (x/L)^2) for tangent ogive
    R = fairing_d / 2
    L = ogive_length
    coords = [(0.0, 0.0)]  # tip
    for i in range(1, 21):  # 20 segments
        x = L * i / 20
        y = R * math.sqrt(max(0, 1 - (x / L)**2))
        coords.append((x, y))
    # Add cylindrical section if needed, then boat-tail for Hammer-Head
    if fairing_mode == 3:
        bt_angle = math.radians(BOAT_TAIL_DEG)
        bt_length = (fairing_d - body_diameter) / 2 / math.tan(bt_angle)
        coords.append((L + bt_length, body_diameter / 2))

    return {
        "diameter": fairing_d,
        "length": ogive_length + (bt_length if fairing_mode == 3 else 0),
        "volume": volume,
        "ogive_length": ogive_length,
        "boat_tail_angle": BOAT_TAIL_DEG if fairing_mode == 3 else 0.0,
        "coords": coords,
    }
```

### Anti-Patterns to Avoid

- **Hand-rolling diagram zoom/pan:** Don't implement custom transform matrices on `QWidget.paintEvent` — `QGraphicsView` provides tested, performant zoom/pan with `setTransform()`/`setDragMode()`.
- **Rebuilding widgets on mode change:** Don't delete/recreate fairing radio buttons — build once, show/hide via `setVisible()`, like the existing `diameter_spin` visibility contract (gui.py:887, 896).
- **Hardcoding constraint logic in signal handlers:** Centralize constraint matrix in a validator class (Pattern 2) — avoids scattered `if body_mode == X and fairing_mode == Y` chains.
- **Calling `apply_stylesheet()` before `QApplication` creation:** qt-material docs explicitly warn: "qt_material must be imported after PySide or PyQt!" — import order matters.

---

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Interactive 2D diagram with zoom/pan/export | Custom `QWidget` + `QPainter` + mouse event handling | `QGraphicsView` + `QGraphicsScene` | Built-in affine transforms, scroll-hand-drag, `scene.render(QPainter)` for PNG; 50+ lines vs 500+ |
| Material Design theming | Custom QSS stylesheet (2000+ lines) | `qt-material.apply_stylesheet()` | Handles all widget states, menus, tooltips, density scaling; one-line theme switch |
| Windows dark title bar | Custom title bar widget (`setWindowFlag(FramelessWindowHint)`) | `DwmSetWindowAttribute` via `ctypes` | Native title bar preserves system behavior (snap, context menu, accessibility); custom bars break Win+arrows, taskbar preview |
| Fairing geometry formulas | Ad-hoc approximations | Standard aerospace formulas (ogive caliber 3:1, volume factor 0.75) | Documented in NASA SP-8037, MIT ogive notes, TU Delft launch vehicle design — matches real fairing proportions |

**Key insight:** The diagram, theming, and title bar are all solved problems in the Qt ecosystem. Custom implementations introduce maintenance burden, accessibility regressions, and platform-specific bugs. The mock fairing math is ~30 lines of standard geometry — no library needed.

---

## Common Pitfalls

### Pitfall 1: qt-material Import Order Breaks Theming
**What goes wrong:** `apply_stylesheet()` has no effect or crashes if imported before `PyQt6.QtWidgets`.
**Why it happens:** qt-material inspects Qt widget classes at import time to generate stylesheet selectors.
**How to avoid:** In `gui.py`, import `from qt_material import apply_stylesheet` **after** `from PyQt6.QtWidgets import ...`.
**Warning signs:** Theme not applied; `WARNING:root:qt_material must be imported after PySide or PyQt!` in console.

### Pitfall 2: Dark Title Bar Fails on Windows 10 < 18985
**What goes wrong:** `DwmSetWindowAttribute` returns `E_INVALIDARG` or no visual change.
**Why it happens:** `DWMWA_USE_IMMERSIVE_DARK_MODE` (20) requires Windows 10 build 18985+ (May 2019) or Windows 11.
**How to avoid:** Guard with `sys.getwindowsversion().build >= 18985`; fallback gracefully (no dark title bar).
**Warning signs:** `ctypes` call returns non-zero HRESULT; title bar stays white on dark theme.

### Pitfall 3: Fairing Spinbox Shows Stale Range After Body Mode Change
**What goes wrong:** User selects "Statistical" body → "Tapered" fairing (max = last body D), then switches body to "Constant" → fairing spinbox still shows old max.
**Why it happens:** Constraint validator not connected to body mode `buttonToggled`, or `setRange()` not called on transition.
**How to avoid:** Single validator class (Pattern 2) connected to **both** body and fairing mode groups; always call `_update_fairing_spinbox_range()` on any mode change.
**Warning signs:** Spinbox accepts values violating D-04 matrix; export shows invalid fairing/body combination.

### Pitfall 4: Diagram Coordinates Don't Match True-Scale (1m=1px)
**What goes wrong:** Rocket stages appear squashed/stretched; fairing ogive looks wrong.
**Why it happens:** Scene coordinates use arbitrary units; `QGraphicsView` default 1:1 mapping assumes pixels.
**How to avoid:** Build scene in **meters** (1 unit = 1 meter); set `view.setTransform(QTransform.fromScale(1, -1))` to flip Y (Qt Y-down vs math Y-up); diagram renders 1:1.
**Warning signs:** Stage lengths visually inconsistent with diameter; fairing ogive not 3×D visibly.

### Pitfall 5: Fairing Data Missing from Export
**What goes wrong:** `.txt` export shows stage geometry but no "Fairing Geometry" section.
**Why it happens:** `_print_results()` not updated to include fairing fields from mock data.
**How to avoid:** Extend `_print_results` export loop (gui.py:1016-1028) to append fairing metrics per stage after stage data; mirror `ResultCard.add_metric` pattern with `.get()` defaults.
**Warning signs:** Export file ends at `=======` without fairing section; VIS-01/FAIR-04 acceptance fails.

---

## Code Examples

### Fairing Mode Radio Group (extends existing pattern from gui.py:850-875)
```python
# Source: Existing gui.py _build_vehicle_tab pattern (QButtonGroup + visibility contract)
self.fairing_mode_group = QGroupBox("FAIRING MODE")
fairing_mode_layout = QVBoxLayout(self.fairing_mode_group)
fairing_mode_layout.setSpacing(10)

self.fairing_mode_const = QRadioButton("Constant (same as body)")
self.fairing_mode_tapered = QRadioButton("Tapered (smaller than body)")
self.fairing_mode_hammer = QRadioButton("Hammer-Head (larger than body)")

self.fairing_mode_buttons = QButtonGroup(self)
self.fairing_mode_buttons.addButton(self.fairing_mode_const, 1)
self.fairing_mode_buttons.addButton(self.fairing_mode_tapered, 2)
self.fairing_mode_buttons.addButton(self.fairing_mode_hammer, 3)

self.fairing_mode = 1  # default
self.fairing_mode_const.setChecked(True)

fairing_mode_layout.addWidget(self.fairing_mode_const)
fairing_mode_layout.addWidget(self._vehicle_helper(
    "Constant: fairing diameter equals body diameter"))
fairing_mode_layout.addWidget(self.fairing_mode_tapered)
fairing_mode_layout.addWidget(self._vehicle_helper(
    "Tapered: fairing diameter ≤ last stage body diameter (user-specified)"))
fairing_mode_layout.addWidget(self.fairing_mode_hammer)
fairing_mode_layout.addWidget(self._vehicle_helper(
    "Hammer-Head: fairing diameter ≥ body diameter (user-specified)"))

# Conditional spinbox (mirrors diameter_spin pattern gui.py:880-889)
fairing_diam_row = QHBoxLayout()
fairing_diam_row.addWidget(QLabel("Fairing Diameter (m)"))
self.fairing_diameter_spin = QDoubleSpinBox()
self.fairing_diameter_spin.setRange(0.5, 20.0)
self.fairing_diameter_spin.setValue(2.00)
self.fairing_diameter_spin.setDecimals(2)
self.fairing_diameter_spin.setSingleStep(0.1)
self.fairing_diameter_spin.setSuffix(" m")
self.fairing_diameter_spin.setVisible(False)
fairing_diam_row.addWidget(self.fairing_diameter_spin)
self.vehicle_layout.addLayout(fairing_diam_row)

# Visibility + invalidation (mirrors gui.py:896-903)
self.fairing_mode_buttons.buttonToggled.connect(self._on_fairing_mode_toggled)
self.fairing_mode_buttons.buttonToggled.connect(self._on_inputs_changed)
self.fairing_diameter_spin.valueChanged.connect(self._on_inputs_changed)
```

### Rocket Diagram Scene Construction (true-scale, per-stage bodies + fairing)
```python
# Source: Qt 6.11 Graphics View Framework — QGraphicsScene.addRect/addPolygon
def build_rocket_scene(self, stage_data: list[dict], fairing_data: list[dict]):
    self.scene.clear()
    # stage_data: [{diameter, length, ...}, ...] from Fortran results
    # fairing_data: [{diameter, length, coords, ...}, ...] from fairing_geometry.py

    y_offset = 0.0  # stack stages vertically (true-scale meters)
    max_d = max(s["diameter"] for s in stage_data) if stage_data else 2.0
    scene_width = max(max_d, fairing_data[0]["diameter"] if fairing_data else 0) * 1.5
    scene_height = sum(s["length"] for s in stage_data) + (fairing_data[0]["length"] if fairing_data else 0)

    # Stage bodies (rectangles centered at x=0)
    for stage in stage_data:
        d = stage["diameter"]
        L = stage["length"]
        rect = QRectF(-d/2, y_offset, d, L)
        item = QGraphicsRectItem(rect)
        item.setPen(QPen(QColor(ACCENT), 0.02))  # 2cm cosmetic pen
        item.setBrush(QColor(BG_CARD))
        self.scene.addItem(item)
        y_offset += L

    # Fairing (polygon from ogive coords)
    if fairing_data:
        f = fairing_data[0]
        polygon = QPolygonF([QPointF(x, y_offset + y) for x, y in f["coords"]])
        # Mirror for left side
        left_poly = QPolygonF([QPointF(-x, y_offset + y) for x, y in f["coords"]])
        fairing_poly = left_poly + polygon[::-1]  # closed loop
        item = QGraphicsPolygonItem(fairing_poly)
        item.setPen(QPen(QColor(ACCENT2), 0.02))
        item.setBrush(QColor(ACCENT2).lighter(150))
        self.scene.addItem(item)

    self.scene.setSceneRect(-scene_width/2, 0, scene_width, scene_height)
    self.fitInView(self.scene.sceneRect(), Qt.AspectRatioMode.KeepAspectRatio)
```

### Dark Title Bar (Windows only, guarded)
```python
# Source: Microsoft Learn — DwmSetWindowAttribute / DWMWA_USE_IMMERSIVE_DARK_MODE
# GitHub gist Olikonsti/879edbf69b801d8519bf25e804cec0aa
import sys
import ctypes as ct

def apply_dark_title_bar(window: QMainWindow):
    """Enable dark title bar on Windows 10 18985+ / Windows 11."""
    if sys.platform != "win32":
        return
    try:
        # Windows 10 build 18985 = 19H1 (May 2019)
        if sys.getwindowsversion().build < 18985:
            return

        DWMWA_USE_IMMERSIVE_DARK_MODE = 20
        hwnd = int(window.winId())  # PyQt6: winId() returns int
        value = ct.c_int(1)  # TRUE
        result = ct.windll.dwmapi.DwmSetWindowAttribute(
            hwnd, DWMWA_USE_IMMERSIVE_DARK_MODE,
            ct.byref(value), ct.sizeof(value)
        )
        if result != 0:  # S_OK = 0
            print(f"Dark title bar failed: HRESULT={result:#x}")
    except Exception as e:
        print(f"Dark title bar unavailable: {e}")

# Call in AppWindow._launch() after main window shows (gui.py:1155-1166)
def _launch(self):
    # ... existing fade animation ...
    self._anim.finished.connect(lambda: self._finish_launch())

def _finish_launch(self):
    self._stack.setCurrentIndex(1)
    apply_dark_title_bar(self._main)  # apply after window is shown
```

### qt-material Theme Application
```python
# Source: qt-material 2.17 docs — apply_stylesheet() usage
# In gui.py __main__ block (line 1170-1175)
if __name__ == "__main__":
    app = QApplication(sys.argv)
    # IMPORTANT: import qt_material AFTER PyQt6 widgets
    from qt_material import apply_stylesheet
    apply_stylesheet(app, theme='dark_teal.xml')  # or 'dark_blue.xml', etc.
    # Optional: custom density/colors via extra dict
    # apply_stylesheet(app, theme='dark_teal.xml', extra={'density_scale': '-1'})
    window = AppWindow()
    window.show()
    sys.exit(app.exec())
```

---

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Custom `QWidget` + `QPainter` for diagrams | `QGraphicsView`/`QGraphicsScene` | Qt 4.2 (2006) | Built-in zoom/pan/transform/export; scene-graph architecture |
| Hand-written QSS for Material Design | `qt-material` library | 2020 (v1.0) | 20+ themes, runtime switch, density, export to .qss |
| Custom frameless window for dark title bar | `DwmSetWindowAttribute` (DWMWA_USE_IMMERSIVE_DARK_MODE) | Windows 10 18985 (2019) | Native title bar preserved; no snap/menu/accessibility loss |
| Hardcoded spinbox ranges | Dynamic `setRange()` via signal-connected validator | Qt 5.0+ | Reactive constraints; single source of truth for validation matrix |

**Deprecated/outdated:**
- `QtWinExtras` module: Not available in Qt6/PyQt6; replaced by direct `ctypes` WinAPI
- `QGraphicsView.setMatrix()`: Replaced by `setTransform(QTransform)` (Qt 5.3+)
- `qt-material` < 2.0: Pre-Qt6; no PyQt6 support

---

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | Ogive caliber 3:1 (length = 3×D) is appropriate for all fairing modes | Mock fairing geometry | Visual discrepancy vs real fairing; mitigated by D-07 "agent's discretion" on constants |
| A2 | Volume factor 0.75 × cylinder volume approximates fairing volume | Mock fairing geometry | Export numbers differ from future Fortran implementation; v2+ replaces mock |
| A3 | Boat-tail 10° is standard for Hammer-Head transition | Mock fairing geometry | Diagram shape slightly off; D-07 allows 5°–15° range |
| A4 | `DwmSetWindowAttribute` works on all target Windows versions | Dark title bar | Title bar stays light on old Windows; graceful degradation implemented |
| A5 | `qt-material 2.17` compatible with PyQt6 6.11 | Standard Stack | Theme not applied; fallback to existing custom STYLE in gui.py |
| A6 | Fairing constraint matrix (D-04) covers all valid combinations | Architecture Patterns | Invalid UI state allows impossible configurations; validator enforces matrix |

---

## Open Questions

1. **Fairing mode radio labels wording** (agent's discretion)
   - What we know: D-03 says "Constant", "Tapered", "Hammer-Head" as modes; helper text in D-04
   - What's unclear: Exact label text for radios (e.g., "Constant (same as body)" vs "Constant")
   - Recommendation: Use descriptive labels matching D-04 semantics; user can adjust in review

2. **Validation error messaging** (agent's discretion)
   - What we know: D-05 requires min/max per constraint; spinbox enforces via `setRange()`
   - What's unclear: Show tooltip on hover? Inline label? Status bar message?
   - Recommendation: Tooltip on spinbox when value at boundary ("Fairing diameter must be ≥ body diameter (Hammer-Head mode)"); minimal UI clutter

3. **Diagram coordinate origin and Y-axis direction**
   - What we know: D-08 true-scale 1:1 meter:pixel; Qt Y-down
   - What's unclear: Origin at fairing tip (top) or stage 1 base (bottom)?
   - Recommendation: Origin at fairing tip (x=0, y=0), stages stack downward (+Y); matches rocket visual convention

---

## Environment Availability

> Skip this section if the phase has no external dependencies (code/config-only changes).

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| Python | All | ✓ | 3.11 | — |
| PyQt6 | GUI, diagrams, theming | ✓ | 6.11.0 | — |
| qt-material | GUI-09 theming | ⬜ (install) | 2.17 | Existing custom STYLE in gui.py |
| Windows dwmapi.dll | GUI-10 dark title bar | ✓ (Windows) | OS-provided | Graceful no-op on non-Windows/old builds |
| MinGW/gfortran | Fortran build (unchanged) | ✓ | Via Makefile `?=` discovery | — |

**Missing dependencies with no fallback:** none
**Missing dependencies with fallback:** qt-material (install via pip; fallback to existing STYLE)

---

## Validation Architecture

### Test Framework
| Property | Value |
|----------|-------|
| Framework | pytest (deferred per user decision — no test infrastructure in current scope) |
| Config file | none — see Wave 0 |
| Quick run command | `pytest -x` (when implemented) |
| Full suite command | `pytest` (when implemented) |

### Phase Requirements → Test Map
| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| FAIR-01 | Constant mode: fairing D = body D | unit | `pytest tests/test_fairing.py::test_constant_mode` | ❌ Wave 0 |
| FAIR-03 | Hammer-Head: fairing D ≥ body D | unit | `pytest tests/test_fairing.py::test_hammerhead_constraint` | ❌ Wave 0 |
| FAIR-04 | Fairing geometry in .txt export | integration | `pytest tests/test_export.py::test_fairing_section` | ❌ Wave 0 |
| VIS-01 | Diagram renders stages + fairing | manual | N/A — visual verification | ❌ Wave 0 |
| VIS-02 | Zoom/pan/PNG export works | manual | N/A — visual verification | ❌ Wave 0 |
| GUI-09 | qt-material theme applied | manual | N/A — visual verification | ❌ Wave 0 |
| GUI-10 | Dark title bar on Windows | manual | N/A — visual verification | ❌ Wave 0 |

### Sampling Rate
- **Per task commit:** N/A (tests deferred)
- **Per wave merge:** N/A (tests deferred)
- **Phase gate:** Manual verification per UAT criteria in CONTEXT.md

### Wave 0 Gaps
- [ ] `tests/test_fairing_geometry.py` — covers FAIR-01/03 mock computations
- [ ] `tests/test_constraints.py` — covers D-04 matrix validation
- [ ] `tests/test_diagram.py` — covers VIS-01/02/03 rendering
- [ ] `tests/test_export.py` — covers FAIR-04 export format
- [ ] Framework install: `pip install pytest pytest-qt` — if tests enabled later

*(Tests explicitly deferred by user — Wave 0 gaps documented for future enablement)*

---

## Security Domain

> Required when `security_enforcement` is enabled (absent = enabled). Omit only if explicitly `false` in config.

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | no | — (standalone desktop, no auth) |
| V3 Session Management | no | — (no sessions) |
| V4 Access Control | no | — (local app, no multi-user) |
| V5 Input Validation | yes | `QDoubleSpinBox.setRange()` + `FairingConstraintValidator` — bounds enforced at widget level |
| V6 Cryptography | no | — (no crypto) |

### Known Threat Patterns for PyQt6 Desktop App

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Malicious config.txt input | Tampering | Fortran parser validates ranges; GUI spinboxes enforce bounds |
| DLL hijacking (librocket.dll) | Spoofing | `os.add_dll_directory(BUILD_DIR)` restricts load path; build/-only |
| Untrusted .txt export content | Tampering | Export is write-only; no parsing of exported files |

---

## Sources

### Primary (HIGH confidence)
- Qt 6.11 Documentation — QGraphicsView, Graphics View Framework, QDoubleSpinBox [VERIFIED: doc.qt.io]
- qt-material 2.17 PyPI/GitHub — version, PyQt6 compatibility, themes, usage [VERIFIED: pypi.org/project/qt-material, github.com/dunderlab/qt-material]
- Microsoft Learn — DWMWA_USE_IMMERSIVE_DARK_MODE, DwmSetWindowAttribute [VERIFIED: learn.microsoft.com]
- MIT Ogive Nose Cones — tangent ogive formula, caliber = L/D [CITED: wikis.mit.edu/confluence/download/attachments/117324408/Ogive%20Nose%20Cones.pdf]

### Secondary (MEDIUM confidence)
- NASA SP-8037 fairing design references (general geometry principles) [CITED: ntrs.nasa.gov search results]
- TU Delft launch vehicle design notes (fairing L/D ratios 3–4×D) [CITED: web search results]

### Tertiary (LOW confidence)
- GitHub gist Olikonsti/879edbf69b801d8519bf25e804cec0aa — PyQt dark title bar pattern [ASSUMED: community pattern, not official]

---

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH — PyQt6/qt-material versions verified on PyPI; ctypes/math are stdlib
- Architecture: HIGH — Patterns follow existing gui.py conventions (QButtonGroup, visibility contracts, invalidation)
- Pitfalls: HIGH — Based on documented Qt/qmaterial/WinAPI behaviors and existing codebase patterns
- Fairing geometry: MEDIUM — Constants from D-07 (agent's discretion); formulas from aerospace references

**Research date:** 2026-09-17
**Valid until:** 2026-12-17 (stable Qt/PyQt6 ecosystem; qt-material actively maintained)