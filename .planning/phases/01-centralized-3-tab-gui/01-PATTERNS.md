# Phase 1: Centralized 3-Tab GUI — Pattern Map

**Mapped:** 2026-08-14
**Files analyzed:** 8 (7 new/modified components — all within `SRC/gui/gui.py` — + 1 reference-only)
**Analogs found:** 7 / 8

> **Phase shape (from RESEARCH.md):** single-file restructuring of `SRC/gui/gui.py`. No new modules, no Fortran changes, no new packages (PyQt6 6.11.0 already present). Every target component below has a **self-analog**: the existing code IS the pattern source (D-08 "reuse beats redesign"). The implementer relocates, extends, and re-wires — never redesigns.

---

## File Classification

| Target (all in `SRC/gui/gui.py` unless noted) | Role | Data Flow | Closest Analog | Match Quality |
|---|---|---|---|---|
| `MainWindow` 3-tab shell (`_build_ui` + 3 tab builders) | window shell | request-response (widget events) | `MainWindow._build_ui` split panels `gui.py:712-815` | exact (self) |
| Results tab (`_build_results_tab` + render path) | tab page / results surface | display: bridge dict → widgets | right results panel `gui.py:803-815` + `_run` render block `gui.py:945-985` | exact |
| Setup tab (`_build_setup_tab`) | tab page / form | GUI → bridge (input collection + validation) | left input panel `gui.py:719-799` + mission group `gui.py:742-768` | exact (verbatim relocation, D-08) |
| Vehicle Configuration tab (new) | tab page / form | state holder (no Run dependency) | mission group `QGroupBox`+grid pattern `gui.py:742-768`; mode semantics from Fortran `Geometry_calc.f90:92-105` | role-match (no radio-group widget exists yet) |
| `ResultCard` extension | reusable widget | display | `ResultCard` class `gui.py:532-577` | exact (self) |
| `STYLE` QSS extension (tab bar + radios) | styling config | n/a | `STYLE` string `gui.py:147-312` + palette constants `gui.py:134-146` | exact (self) |
| Mission inputs rework (orbit-height spinbox, ΔV-auto label, `dv_spin` removal) | data exchange | GUI → bridge + export | mission group `gui.py:742-766`, `_print_results` `gui.py:864-907` | exact |
| Bridge call adjustments (`_run` ΔV source) | data exchange | GUI → Fortran via ctypes | local `run_staging` `gui.py:80-110`; twin `rocket_lib.py:45-88` | exact |
| `SRC/interface/rocket_lib.py` | **NOT MODIFIED (Phase 3 dedup — A5)** | — | — | reference-only |

---

## Pattern Assignments

### 1. `MainWindow` 3-tab shell (window shell, request-response)

**Analog:** `MainWindow._build_ui` `gui.py:712-815` (self)

**Imports pattern** (`gui.py:9-17`) — add `QTabWidget` and `QRadioButton` to the existing `QtWidgets` import; keep stdlib → PyQt6 → local order (CONVENTIONS.md:33-38):

```python
from PyQt6.QtWidgets import (
    QApplication, QMainWindow, QWidget, QVBoxLayout, QHBoxLayout,
    QGridLayout, QLabel, QSpinBox, QDoubleSpinBox, QComboBox,
    QSlider, QPushButton, QScrollArea, QFrame, QSizePolicy,
    QGroupBox, QMessageBox, QStackedWidget, QGraphicsOpacityEffect,
    QFileDialog, QTabWidget, QRadioButton        # ← add these two
)
from PyQt6.QtCore import Qt, QThread, pyqtSignal, QPropertyAnimation, QEasingCurve
from PyQt6.QtGui import QFont, QPalette, QColor
```
(QThread stays a dead import — RESEARCH A6: keep blocking, planner's call whether to drop it.)

**Shell skeleton** — replace the `root_layout = QHBoxLayout(...)` split (`gui.py:713-717`) with the RESEARCH/UI-SPEC tab shell (tab order is contractual, UI-SPEC:129-137):

```python
self.tabs = QTabWidget()
self.setCentralWidget(self.tabs)
self.tabs.addTab(self._build_results_tab(), "Results")                # index 0 — central/home (D-02)
self.tabs.addTab(self._build_setup_tab(),   "Setup")
self.tabs.addTab(self._build_vehicle_tab(), "Vehicle Configuration")  # index 2
```

**Container pattern for each tab page** — copy verbatim from the two existing panels; each tab is a `QScrollArea` + inner `QWidget` + `QVBoxLayout` with `addStretch()` (UI-SPEC:137):
- From left panel (`gui.py:720-729`): `scroll = QScrollArea(); scroll.setWidgetResizable(True)`; inner widget; layout `setContentsMargins(16, 20, 16, 20)`; `setSpacing(14)`.
- From right panel (`gui.py:803-812`): `setContentsMargins(24, 24, 24, 24)` for the Results tab (UI-SPEC lg token).
- Stretch bookends: `layout.addStretch()` at `gui.py:797` (Setup) and `gui.py:812, 985` (Results).

**What to change:** only the container construction. All child widgets move by reference — signals are tab-agnostic (Pitfall 3): `_on_inputs_changed`, `_update_run_button`, `_rebuild_stage_inputs`, `_print_results`, `_run` keep their existing connections.

---

### 2. Results tab — `_build_results_tab` + render path (tab page, display)

**Analog:** right panel construction `gui.py:803-815` + `_run` results render `gui.py:945-985` (self)

**Empty-state + clear pattern** (`gui.py:840-851`) — relocate as-is; the layout they operate on becomes the Results tab layout:

```python
def _show_empty_state(self):
    placeholder = QLabel("Run the analysis to see results here.")
    placeholder.setAlignment(Qt.AlignmentFlag.AlignCenter)
    placeholder.setObjectName("placeholder")
    placeholder.setStyleSheet(f"color: {TEXT_DIM}; font-size: 15px;")
    self.right_layout.insertWidget(0, placeholder)      # → becomes results_layout

def _clear_results(self):
    while self.right_layout.count():
        item = self.right_layout.takeAt(0)
        if item.widget():
            item.widget().deleteLater()
```

**Results render block** (`gui.py:945-985`) — relocate verbatim into the Results tab; order is contractual (UI-SPEC:141-157): summary → min indicator → divider → cards → Save button → stretch:

```python
self._clear_results()
# Summary header — rich-text pattern (gui.py:948-955)
summary = QLabel(
    f"Total Initial Mass:  "
    f"<span style='color:{ACCENT}; font-size:22px; font-weight:700;'>"
    f"{results['total_initial_mass']:,.1f} kg</span>"
)
summary.setTextFormat(Qt.TextFormat.RichText)
summary.setStyleSheet(f"color: {TEXT_PRI}; font-size: 14px;")

# Minimum indicator — verbatim (gui.py:957-963)
min_label = QLabel(
    "✔  Minimum confirmed" if results["minimum_found"]
    else "✘  Minimum not confirmed — check your inputs"
)
color = GREEN if results["minimum_found"] else ACCENT2
min_label.setStyleSheet(f"color: {color}; font-size: 12px; font-weight: 600;")

div = QFrame(); div.setObjectName("divider")

# Stage cards (gui.py:969-971)
for stage in results["stages"]:
    card = ResultCard(stage["stage"], stage)
    self.right_layout.addWidget(card)

self._last_configs = [...]   # gui.py:973-979, verbatim
self._last_results = results
self.print_btn.setEnabled(True)
```

**What to change:**
1. All `self.right_layout` references become the Results-tab layout.
2. **New: auto-switch to tab 0** after a successful run — `self.tabs.setCurrentIndex(0)` after `print_btn.setEnabled(True)` (UI-SPEC:193).
3. `print_btn` ("⬇  Save Results") moves from `gui.py:783-786, 796` into the Results tab, pinned above the final `addStretch()` (UI-SPEC:156).
4. **Partial-state hint** (UI-SPEC:112, Pitfall 5): when any placeholder "—" is rendered, add one 11px `TEXT_DIM` label "ΔV and geometry populate with full pipeline wiring (Phase 2)." below the empty state / cards.

**Data source (unchanged contract):** the bridge return dict (`gui.py:101-110`): keys `total_initial_mass`, `minimum_found`, `stages[].{stage, m0, mf, mp, ms, k_m, k_s, k_L, nu_e}`. Per-stage ΔV and geometry are NOT in the dict (RESEARCH matrix:160-166) → render "—" in `TEXT_DIM`.

---

### 3. Setup tab — `_build_setup_tab` (tab page, form → bridge)

**Analog:** left input panel `gui.py:719-799` (self — **verbatim relocation, D-08**)

**Relocation inventory (verbatim, zero redesign):**
- Header: title `gui.py:732-733` + subtitle `gui.py:734-735` + divider `gui.py:739`
- `stages_container` + `stages_layout` (`gui.py:772-777`) — `_rebuild_stage_inputs` (`gui.py:825-838`) keeps operating on it
- `run_btn` (`gui.py:780-782`, ready-property QSS `gui.py:788-793`, `_update_run_button` `gui.py:853-857`)

**`StageInputWidget` class (`gui.py:319-528`)** — untouched, reused verbatim (propellant/cycle combos, ISP/k_s sliders, `validity_changed` signal, `get_values()` → `(isp, ks, has_data)`).

**Mission Parameters group** (`gui.py:742-766`) — the QGroupBox + QGridLayout input idiom all new inputs must mirror:

```python
mission_group = QGroupBox("MISSION PARAMETERS")
mg_layout = QGridLayout(mission_group)
mg_layout.setSpacing(8)

mg_layout.addWidget(QLabel("Payload Mass  (kg)"), 1, 0)
self.pl_spin = QDoubleSpinBox()
self.pl_spin.setRange(1.0, 1_000_000.0)      # bounded per V5 input-validation (RESEARCH Security Domain)
self.pl_spin.setValue(5000.0)
self.pl_spin.setDecimals(1)
self.pl_spin.setSingleStep(100.0)
mg_layout.addWidget(self.pl_spin, 1, 1)

mg_layout.addWidget(QLabel("Number of Stages"), 2, 0)
self.n_stages_spin = QSpinBox()
self.n_stages_spin.setRange(1, 3)
self.n_stages_spin.setValue(3)
mg_layout.addWidget(self.n_stages_spin, 2, 1)
```

**What to change (mission grid only):**
1. **Remove `dv_spin`** (`gui.py:746-752`) — no ΔV input anywhere (D-10, GUI-05).
2. **Add `orbit_height` spinbox** (NEW — UI-SPEC:166): same idiom, `QDoubleSpinBox`, range **100.0–2000.0**, decimals 1, single step 10.0, default 500.0, label "Orbit Height (km)" at row 0.
3. **Add read-only "ΔV (auto)" label** (UI-SPEC:169): `QLabel` `{:.2f} km/s`, `TEXT_SEC` 12px, updated on orbit-height change; feeds `run_staging` and the export header.

**Signal wiring — preserved across tabs** (Pitfall 3; `gui.py:817-819, 769, 833-834`):
```python
self.pl_spin.valueChanged.connect(self._on_inputs_changed)
self.n_stages_spin.valueChanged.connect(self._on_inputs_changed)
self.n_stages_spin.valueChanged.connect(self._rebuild_stage_inputs)
self.orbit_height.valueChanged.connect(self._on_inputs_changed)   # NEW
self.orbit_height.valueChanged.connect(self._update_auto_dv_label) # NEW
# per StageInputWidget:
sw.validity_changed.connect(self._update_run_button)
sw.validity_changed.connect(self._on_inputs_changed)
```

---

### 4. Vehicle Configuration tab — new (tab page, state holder)

**Analog:** mission group `QGroupBox` + grid idiom `gui.py:742-768` (role-match — no radio group exists in the codebase); mode semantics from Fortran `Geometry_calc.f90:92-105` (source of truth).

**Structure (UI-SPEC:176-189):** header mirroring Setup header (`gui.py:732-739`) → "DIAMETER MODE" `QGroupBox` → 3 `QRadioButton`s, each followed by an 11px `TEXT_SEC` helper label → user-specified diameter `QDoubleSpinBox`.

**Radio group pattern** (standard Qt, no codebase analog — model on the combo pattern in `StageInputWidget._build` `gui.py:331-347` for construction style):

```python
self.diameter_mode = 1                      # stored int 1/2/3 — Phase 2 handoff (Pitfall 8)
self.mode_group = QGroupBox("DIAMETER MODE")
mode_layout = QVBoxLayout(self.mode_group)
mode_layout.setSpacing(10)                  # StageInputWidget inner spacing idiom (gui.py:329)

self.mode_stat = QRadioButton("Statistically determined")   # → 1, default checked (mirrors config.txt Diameter_setup = 1)
self.mode_const = QRadioButton("Constant")                  # → 2
self.mode_user  = QRadioButton("User-specified")            # → 3 (CONTEXT D-11 label; Fortran calls it "Fairing requirement" — A4)
```

**Diameter input box** (D-12, GUI-07; UI-SPEC:188) — spinbox idiom from `pl_spin` `gui.py:755-760`; default 2.00 mirrors `config.txt` `User_defined_diameter = 2.0`:

```python
self.diameter_spin = QDoubleSpinBox()
self.diameter_spin.setRange(0.5, 20.0)
self.diameter_spin.setValue(2.00)
self.diameter_spin.setDecimals(2)
self.diameter_spin.setSingleStep(0.1)
self.diameter_spin.setVisible(False)        # visibility contract: shown only in mode 3
```

**Visibility toggle** — wire `toggled` of each radio:
```python
self.mode_user.toggled.connect(self.diameter_spin.setVisible)
```
(mode 3 radio checked ⇔ box visible; value persists — widgets never rebuilt, UI-SPEC:188, 195.)

**What to change / notes:**
- Store `self.diameter_mode` (int 1/2/3) and the spinbox value as MainWindow state for Phase 2 — **do NOT wire into `run_staging`** (Pitfall 8, UI-SPEC:187).
- Mode semantics mirror `Geometry_calc.f90:92-105`: 1 = per-stage regression + monotonicity pass; 2 = `maxval` of statistical diameters; 3 = `User_defined_diameter` for all stages. Helper copy text per UI-SPEC:121.
- New QSS needed for `QRadioButton` (see Shared Patterns §5).

---

### 5. `ResultCard` extension (reusable widget, display)

**Analog:** `ResultCard` class `gui.py:532-577` (self)

**Core grid + `add_metric` closure** (`gui.py:555-577`) — reuse verbatim; this is the widget's whole data-surface:

```python
grid = QGridLayout()
grid.setHorizontalSpacing(24)
grid.setVerticalSpacing(6)                    # legacy 6px — preserved (UI-SPEC:49)

def add_metric(row, col, label, value, unit="", color=TEXT_PRI):
    lbl = QLabel(label)
    lbl.setStyleSheet(f"color: {TEXT_SEC}; font-size: 11px; border: none;")
    val = QLabel(f"{value:,.1f} {unit}".strip())
    val.setStyleSheet(f"color: {color}; font-size: 14px; font-weight: 600; border: none;")
    grid.addWidget(lbl, row*2,   col)
    grid.addWidget(val, row*2+1, col)

add_metric(0, 0, "Initial Mass (m₀)",    data["m0"],  "kg", TEXT_PRI)
add_metric(0, 1, "Final Mass (m_f)",      data["mf"],  "kg", TEXT_PRI)
add_metric(1, 0, "Propellant Mass (m_p)", data["mp"],  "kg", ACCENT2)
add_metric(1, 1, "Structure Mass (m_s)",  data["ms"],  "kg", TEXT_PRI)
add_metric(2, 0, "Mass Ratio (k_m)",      data["k_m"], "",   ACCENT)
add_metric(2, 1, "Payload Ratio (k_L)",   data["k_L"], "",   ACCENT)
add_metric(3, 0, "Struct. Coeff. (k_s)",  data["k_s"], "",   TEXT_PRI)
add_metric(3, 1, "Exhaust Vel. (ν_e)",    data["nu_e"],"km/s",TEXT_PRI)
```

**What to change (exactly 2 new grid rows, UI-SPEC:144-155):**
- Rows 0–3 unchanged (existing behavior preserved).
- **Extend `add_metric` with a `fmt` parameter** (current hardcoded `:,.1f` is wrong for the new fields): e.g. `val = QLabel(f"{value:{fmt}} {unit}".strip())` with `fmt=":,.1f"` default.
- **Row 4:** `"Stage ΔV"` → `data.get("dv", "—")` `%.2f km/s`; `"Diameter"` → `data.get("diameter", "—")` `%.2f m`.
- **Row 5:** `"Length"` `%.2f m`; `"Volume"` `%.2f m³` — both placeholders ("—" in `TEXT_DIM`) until Phase 2.
- Placeholder rendering: when a value is missing, render `"—"` with `TEXT_DIM` (partial population, user-approved; UI-SPEC:155).
- Caller change: `ResultCard(stage["stage"], stage)` at `gui.py:970` stays — the card reads dict keys with `.get()` defaults so Phase 2 fills them without signature churn.

---

### 6. `STYLE` QSS extension (styling config)

**Analog:** `STYLE` f-string `gui.py:147-312` + palette constants `gui.py:134-146` (self)

**Palette constants — the only color source** (`gui.py:134-146`), verbatim:
```python
BG_DARK = "#0d1117"; BG_PANEL = "#161b22"; BG_CARD = "#1c2128"; BG_INPUT = "#21262d"
ACCENT = "#58a6ff"; ACCENT2 = "#f78166"; TEXT_PRI = "#e6edf3"; TEXT_SEC = "#8b949e"
TEXT_DIM = "#484f58"; BORDER = "#30363d"; GREEN = "#3fb950"; ORANGE = "#d29922"
```

**QSS block to append inside the `STYLE` f-string** (UI-SPEC:88-98; palette verified in `gui.py:134-146`; REQUIRED to fix Pitfall 1 — the blanket `QMainWindow, QWidget` rule `gui.py:148-153` leaves the tab bar un-styled):

```css
QTabWidget::pane { background: #0d1117; border: 1px solid #30363d; }
QTabBar::tab { background: #161b22; color: #8b949e; padding: 8px 24px;
               border: 1px solid #30363d; border-bottom: none; }
QTabBar::tab:selected { background: #1c2128; color: #58a6ff; font-weight: 600; }
QTabBar::tab:!selected:hover { color: #e6edf3; }
QTabBar::tab:top:!selected { margin-top: 3px; }
QRadioButton { color: #e6edf3; background: transparent; }
QRadioButton::indicator { width: 16px; height: 16px; }
QRadioButton::indicator:checked { background: #58a6ff; }
```

**What to change:** append only; do NOT touch existing rules (`launch_btn` `gui.py:266-284`, `print_btn` `gui.py:285-306`, spinbox/combobox/slider blocks, `QFrame#divider` `gui.py:307-311`). No new palette tokens (Coherence contract, UI-SPEC:230).

---

### 7. Mission inputs rework + bridge call adjustments (data exchange)

**Analog:** `_run` `gui.py:909-943`, `_print_results` `gui.py:864-907`, local `run_staging` `gui.py:80-110` (self + `rocket_lib.py:45-88` twin)

**Bridge call — verbatim, only the `delta_v` argument source changes** (`gui.py:933-943`):
```python
try:
    results = run_staging(
        n_stages=n,
        delta_v=self._auto_delta_v(),            # ← was self.dv_spin.value() (gui.py:936) — D-10
        payload_mass=self.pl_spin.value(),
        isp_list=isp_list,
        ks_list=ks_list,
    )
except Exception as e:
    QMessageBox.critical(self, "Fortran Error", str(e))
    return
```
The local `run_staging` copy (`gui.py:80-110`) stays untouched (A5 — dedup is Phase 3). Return-dict contract identical to `rocket_lib.py:71-88`.

**Interim ΔV helper (Open Question 1)** — no Python analog; mirror the Fortran source of truth `Orbit_calc.f90:9-10` (`g_0 = 9.80665`, `Radius = 6378.0` from `Typical_Data.f90:3-5`):

```fortran
! Orbit_calc.f90:9-10 (reference only — Fortran must NOT be changed this phase)
r = Radius + orbit_height
V_circ = sqrt(g_0*Radius**2.d0 / (r * 1000.d0))
```
```python
def _auto_delta_v(self):
    """Interim: V_circ from orbit height (Orbit_calc.f90:9-10). Phase 2 replaces
    this with the full pipeline ΔV (STAGING_LOOP). Marked for removal."""
    g_0, R = 9.80665, 6378.0
    r = R + self.orbit_height.value()
    return (g_0 * R ** 2 / (r * 1000.0)) ** 0.5
```
(Planner's call: (a) this derivation or (b) a fixed placeholder constant — RESEARCH Open Question 1. Either way the value flows to: the "ΔV (auto)" label, `run_staging(delta_v=...)`, and `_print_results`.)

**Export adjustments (Pitfall 2)** — `_print_results` (`gui.py:864-907`) verbatim except the two `self.dv_spin.value()` reads:
- `gui.py:869`: `dv = self.dv_spin.value()` → `dv = self._auto_delta_v()`
- `gui.py:885`: `lines.append(f"  Delta-V:       {self.dv_spin.value():.2f} km/s")` → same auto value (never hand-entered, D-10)
- Filename pattern kept: `default_name = f"staging_{n}stage_dv{dv:.1f}_pl{pl}kg.txt"` (`gui.py:872`)

**Error handling — verbatim reuse** (CONVENTIONS.md:47): validation → `QMessageBox.warning(self, "Missing Data", ...)` (`gui.py:924-931`); Fortran failure → `QMessageBox.critical(self, "Fortran Error", str(e))` (`gui.py:941-943`).

---

### 8. Untouched by design (do NOT modify)

| File / block | Lines | Why |
|---|---|---|
| DLL load + MinGW search | `gui.py:22-59` | FIX-03 is Phase 3; hardcoded paths stay (RESEARCH:312-317) |
| Local `run_staging` bridge | `gui.py:80-110` | A5: dedup is FIX-02/Phase 3; `rocket_lib.py` twin untouched |
| `_load_data()` / typical_data_ranges | `gui.py:114-130` + `typical_data_ranges.py` | generated file, do not edit (header line 5) |
| `SplashScreen` / `AppWindow` / fade | `gui.py:582-700, 990-1019` | D-13: preserved as-is, incl. 600 ms InOutQuad fade |
| Entry point | `gui.py:1023-1028` | `app.setStyleSheet(STYLE)` + `AppWindow` unchanged |
| `SRC/interface/rocket_lib.py` | all | Phase 3 dedup; reference for return-dict shape only |
| All `.f90` files | all | Phase boundary: GUI/Python-only |

---

## Shared Patterns

### 1. QSS token discipline
**Source:** `gui.py:134-146` (constants), `147-312` (STYLE)
**Apply to:** every new widget's `setStyleSheet` and the new STYLE block — f-string interpolation of the 12 named constants only; no inline hex outside `STYLE` (UI-SPEC Coherence, :230). Existing pattern: `f"color: {ACCENT}; font-weight: 700; font-size: 15px;"` (`gui.py:357`).

### 2. Scroll-container + stretch bookends
**Source:** `gui.py:720-727` (left), `803-812` (right)
**Apply to:** all three tab pages. `QScrollArea` + `setWidgetResizable(True)` + inner `QWidget` + `QVBoxLayout` + `addStretch()` at bottom (and top for Results, `gui.py:812`). `setMinimumSize(960, 700)` on `MainWindow` (`gui.py:708`) preserved.

### 3. Ready-property button state
**Source:** `gui.py:787-793` (QSS) + `853-857` (toggle)
**Apply to:** `run_btn` (relocated verbatim) — `setProperty("ready", bool)` + `style().unpolish/polish`. Only existing dynamic-style idiom in the codebase; the diameter-box visibility toggle uses plain `setVisible` instead (simpler, standard Qt).

### 4. Validation + error modals
**Source:** `gui.py:924-931` (warning), `941-943` (critical)
**Apply to:** `_run` unchanged; new spinboxes bounded at construction (orbit height 100–2000, diameter 0.5–20 — V5 input validation, RESEARCH Security Domain:404) — no free-text inputs, no `eval`.

### 5. Cross-tab invalidation wiring
**Source:** `gui.py:817-819` + `859-862` (`_on_inputs_changed` clears results + disables Save)
**Apply to:** Setup tab inputs → Results tab state. Signals are layout-agnostic; only the target layout object changes. New orbit-height spinbox joins the same fan-out.

### 6. ctypes call contract
**Source:** `gui.py:80-110` == `rocket_lib.py:45-88`
**Apply to:** `_run` only — never re-declare `_lib.run_staging` argtypes, never add a third bridge copy (Don't Hand-Roll, RESEARCH:298). Return-dict keys consumed: `total_initial_mass`, `minimum_found`, `stages[]`.

---

## No Analog Found

| Target | Role | Data Flow | Reason / Substitute |
|--------|------|-----------|---------------------|
| Vehicle Configuration radio group | form (new widget type) | state holder | No `QRadioButton` exists anywhere in the codebase; build per standard Qt + mission-group layout idiom (`gui.py:742-768`); QSS from Shared Patterns §5. Mode semantics from Fortran `Geometry_calc.f90:92-105` (verbatim in RESEARCH:204-221). |
| Interim ΔV auto-computation | utility | GUI → bridge | No Python analog (PIPE-02 forbids Python physics); mirror `Orbit_calc.f90:9-10` one-liner, marked for Phase 2 removal (Open Question 1 — planner decides (a) vs (b)). |

---

## Metadata

**Analog search scope:** `SRC/gui/`, `SRC/interface/` (plus `.planning/codebase/` conventions)
**Files scanned:** `gui.py` (1028 lines, full), `rocket_lib.py` (88 lines, full), `typical_data_ranges.py` (header), `STRUCTURE.md`, `CONVENTIONS.md`
**Pattern extraction date:** 2026-08-14