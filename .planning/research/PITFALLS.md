# Domain Pitfalls — Rocket Diagrams, Fairing Config, GUI Aesthetics

**Domain:** Engineering desktop GUI (Fortran 90/2008 core + PyQt6) — adding visualization, fairing modes, and aesthetics
**Researched:** 2026-09-17
**Overall confidence:** HIGH (based on codebase analysis + ecosystem patterns)

---

## Critical Pitfalls

*Mistakes that cause rewrites, broken pipelines, or major UX regressions when adding these features to the existing TFG system.*

### Pitfall 1: Matplotlib Canvas Lifecycle & Memory Leaks in Tabbed Interface

**What goes wrong:**  
Embedding `FigureCanvasQTAgg` (Matplotlib) in the Vehicle Configuration tab (index 2) inside a `QScrollArea` with lazy tab switching causes figure/canvas objects to accumulate if not explicitly cleaned up when the tab is hidden or the analysis is re-run. Each re-run creates a new canvas without destroying the old one → memory growth, stale artists, and eventually the GUI freezes or crashes.

**Why it happens:**  
- Matplotlib figures hold references to artists, renderers, and backend resources
- `QScrollArea` + `QTabWidget` does not auto-destroy child widgets on tab switch
- Re-running the pipeline from the Setup tab triggers `_run()` → Results tab shows cards, but Vehicle Config tab may also try to render a diagram
- If diagram rendering is tied to `_run()` but the canvas isn't parented/owned correctly, multiple canvases stack in the layout

**Consequences:**  
- Memory leak ~10–50 MB per re-run (figures + renderers not GC'd)
- Stale diagram shows old stage geometry after input changes
- Qt event loop slows down as timer callbacks accumulate on dead canvases

**Prevention:**  
- **Own the canvas as a single instance attribute** (`self.vehicle_diagram_canvas`) created once in `_build_vehicle_tab()`, not per-run
- **Clear and redraw** (`ax.cla(); canvas.draw()`) instead of recreating
- **Parent the canvas to the Vehicle Config tab's inner widget** (not the scroll area directly) so Qt owns its lifecycle
- **Guard re-entry**: if `hasattr(self, 'vehicle_diagram_canvas')`, reuse it; never `addWidget` a second canvas
- **Disconnect timers/callbacks** explicitly if any dynamic updates are used (not needed for static post-analysis diagrams)

**Detection:**  
- Monitor process memory in Task Manager while repeatedly clicking "Run Staging Analysis"
- Add `print(len(self.vehicle_layout.children()))` debug — should stay constant
- Check `gc.get_objects()` for `FigureCanvasQTAgg` count after 5+ runs

**Phase to address:** Phase 1 (VIS-01 — Rocket dimension diagrams)

---

### Pitfall 2: Fairing Mode Logic Divergence Between GUI and Fortran

**What goes wrong:**  
The GUI's new fairing modes (Constant, User-specified, Hammer-Head) are implemented in Python/Qt but the actual diameter computation lives in `Geometry_calc.f90` (`rocket_geometry_calculation`). If the GUI's `diameter_mode` enum (1/2/3 for body diameter) is extended for fairing without mirroring the same enum + logic in Fortran, the GUI shows one configuration but the solver computes another.

**Why it happens:**  
- Current `diameter_setup` (1=Statistical, 2=Constant body, 3=User body) is passed via `run_full_pipeline` → `diameter_setup` module global → `Geometry_calc.f90:92-104`
- Fairing adds a *second* diameter concept (fairing diameter ≠ body diameter) that doesn't exist in Fortran yet
- GUI radio buttons for fairing mode would need a new `fairing_setup` integer passed to Fortran
- `Geometry_calc.f90` currently only computes `Diameter_vector` (body); no `Fairing_diameter_vector` exists
- The ctypes bridge (`C_Interface.f90`, `rocket_lib.py`) would need new output arrays (`fairing_diameter_out`, `fairing_length_out`)

**Consequences:**  
- Silent mismatch: GUI shows Hammer-Head fairing, but Fortran computes constant body diameter for all stages
- Results export (`.txt`) shows body diameters only; fairing data missing
- User trusts the diagram but the solver used different assumptions

**Prevention:**  
- **Extend the Fortran side FIRST**: add `fairing_setup` module global + `Fairing_diameter_vector` in `Geometry_calc.f90` before any GUI work
- **Mirror the enum exactly**: GUI `fairing_mode` int values (1=Constant, 2=User-specified, 3=Hammer-Head) must match Fortran `fairing_setup` case values
- **Pass through ctypes bridge**: add `fairing_setup_in` + `fairing_diameter_out(n_stages)` to `run_full_pipeline` signature (both Fortran and Python)
- **Single source of truth**: define the mode constants in a shared Python module (e.g. `src/interface/modes.py`) imported by both `gui.py` and `rocket_lib.py`
- **Validate round-trip**: unit test that GUI mode 3 → Fortran case 3 → output fairing diameter > body diameter

**Detection:**  
- Add debug print in `C_Interface.f90` showing received `fairing_setup_in`
- Compare GUI `fairing_mode` vs. exported results for fairing diameter

**Phase to address:** Phase 2 (FAIR-01/02/03 — Fairing diameter modes) — **must precede GUI fairing controls**

---

### Pitfall 3: Diagram Data Staleness After Input Changes (State Integrity)

**What goes wrong:**  
The Vehicle Config tab diagram renders *post-analysis* geometry (diameter, length, volume per stage). If the user changes inputs (Setup tab: ISP, k_s, orbit, payload; Vehicle Config tab: diameter mode, fairing mode) but does **not** re-run, the diagram still shows the old converged geometry — violating the existing "invalidate on any input change" contract established in `_on_inputs_changed()` (lines 966–971 in `gui.py`).

**Why it happens:**  
- Current `_on_inputs_changed()` clears Results tab cards and disables Save Results
- Vehicle Config tab diagram is **not** connected to `_on_inputs_changed()` — it's a passive display
- Fairing mode radios (`mode_buttons.buttonToggled`) *do* connect to `_on_inputs_changed()` (line 902), but diagram refresh does not
- Diagram rendering likely reads from `self._last_results` (staged results dict) which is only updated on successful `_run()`

**Consequences:**  
- User tweaks fairing mode → diagram still shows old body diameters (stale)
- User switches diameter mode Constant → User-specified → diagram doesn't update until next Run
- Violates D-04/D-05 state integrity: "no stale converged numbers are shown or exported against changed inputs"

**Prevention:**  
- **Connect diagram invalidation to `_on_inputs_changed()`**: add `self._clear_vehicle_diagram()` call there
- **Show placeholder state** in Vehicle Config tab when results are invalid (mirror Results tab "Run the analysis to see results here")
- **Gate diagram rendering behind `hasattr(self, '_last_results')`** — if no valid results, show "Run analysis to see diagram"
- **Reuse the existing `_last_results` guard pattern** from `_print_results()` (lines 981–985)

**Detection:**  
- Change diameter mode in Vehicle Config tab → diagram should immediately show placeholder, not old data
- Switch to Results tab → should show "Run the analysis to see results here" (already works)
- Re-run → diagram populates with fresh data

**Phase to address:** Phase 1 (VIS-01) — wire invalidation *before* diagram rendering logic

---

### Pitfall 4: ASCII Art / Custom Painting vs. Matplotlib — Wrong Tool Choice

**What goes wrong:**  
The requirement mentions "ASCII art candidate" for GUI aesthetics (GUI-09). If the team implements rocket diagrams as ASCII art in a `QLabel` or `QTextEdit` (monospace), it will:
- Not scale with DPI / HiDPI displays (blurry or tiny on 150%+ scaling)
- Break on font substitution (monospace font missing on target OS)
- Prevent tooltip/interaction (hover for stage values, click to copy)
- Require manual layout calculations (character columns ≈ meters) that drift with font metrics

**Why it happens:**  
- "ASCII art" sounds lightweight and dependency-free
- Existing GUI uses pure Qt widgets (no Matplotlib yet), so adding `matplotlib` feels heavy
- The dark theme (`STYLE` in `gui.py`) uses custom QSS — Matplotlib figures need explicit dark background styling to match

**Consequences:**  
- Diagram looks unprofessional on Windows 10/11 default 150% scaling
- No accessibility (screen readers can't parse ASCII diagram)
- Fairing Hammer-Head visualization (body + fairing offset) nearly impossible in fixed-width text
- Technical debt: eventual rewrite to Matplotlib/Qt painting anyway

**Prevention:**  
- **Use `QPainter` on a custom `QWidget`** for static engineering diagrams — native Qt, no extra deps, HiDPI-native, styleable via QSS
- **If Matplotlib is preferred** (team familiarity), use `FigureCanvasQTAgg` with `Figure(facecolor=BG_DARK)` and explicit `ax.set_facecolor(BG_PANEL)` to match the app theme
- **Reject ASCII art** for anything but debug logging; it's not a UI strategy
- **Prototype both** in a spike (1 hour each) — compare rendering quality, DPI scaling, and code complexity

**Detection:**  
- Test on 150% and 200% Windows scaling
- Verify diagram colors match `BG_DARK`/`BG_PANEL`/`ACCENT` from `gui.py` STYLE

**Phase to address:** Phase 1 (VIS-01) — decide rendering approach *before* implementing diagram logic

---

### Pitfall 5: Hammer-Head Fairing Geometry Breaks Constant-Diameter Assumptions

**What goes wrong:**  
The Hammer-Head mode (fairing diameter > body diameter; body constant + statistically defined; fairing user-defined) introduces a **discontinuous diameter profile** along the rocket length. Existing code assumes:
- `Diameter_vector` is monotonically non-decreasing top-to-bottom (Constant mode enforces this via `maxval`)
- `Length_vector = Volume_vector * 4 / (π * Diameter²)` — single diameter per stage
- Results export (`_print_results`) prints one diameter per stage

**Why it happens:**  
- `Geometry_calc.f90:105` computes `Longitud_vector = Volume_vector * 4 / (pi * Diameter_vector**2)` assuming uniform cylinder per stage
- Hammer-Head means Stage 1 (bottom) has body diameter D_body, but fairing sits on top with D_fairing > D_body
- The fairing is *not a stage* — it's a payload envelope. Current `Rocket_t` has no fairing fields
- Stage count is fixed at 1–3; fairing would be a 4th "pseudo-stage" or a separate struct

**Consequences:**  
- Length calculation wrong for fairing section (uses body diameter instead of fairing diameter)
- CG/CP calculations (if ever added) would miss fairing contribution
- Diagram shows fairing wider than body but length math uses body diameter → visual vs. numeric mismatch
- Export `.txt` cannot represent fairing dimensions with current format

**Prevention:**  
- **Model fairing as a separate entity in Fortran**: add `Fairing_t` derived type with `diameter`, `length`, `volume` to `Rocket_Types.f90`
- **Extend `Rocket_t`**: add `Rocket%fairing` (optional, allocatable or pointer)
- **Compute fairing geometry in `Geometry_calc.f90`** after body geometry, using `fairing_setup` + `user_fairing_diameter`
- **Update ctypes bridge**: return `fairing_diameter`, `fairing_length`, `fairing_volume` as scalars (not per-stage arrays)
- **Update Results tab**: add fairing card or section when `fairing_setup > 0`
- **Update export format**: append fairing block to `.txt` output

**Detection:**  
- Hammer-Head mode selected → fairing diameter > max body diameter → verify length/volume calc uses fairing D
- Export results → check fairing dimensions appear in `.txt`

**Phase to address:** Phase 2 (FAIR-03) — **requires Fortran data model changes first**

---

### Pitfall 6: Qt Dark Theme Title Bar / Window Frame Mismatch on Windows

**What goes wrong:**  
The existing `STYLE` QSS in `gui.py` (lines 64–238) styles the *client area* only. On Windows 10/11, the title bar and window frame remain white (system default) because:
- QSS does not affect the non-client area (title bar, borders)
- Windows 10 dark mode requires `DwmSetWindowAttribute` + `DWMWA_USE_IMMERSIVE_DARK_MODE` via WinAPI
- PyQt6 on Windows defaults to `windowsvista` style which ignores system dark mode

**Why it happens:**  
- Current app uses custom dark palette (`BG_DARK = "#0d1117"`) via QSS
- No platform-specific title bar handling exists
- User sees dark app content with blinding white title bar — "looks very bad" (Qt Forum confirmed)

**Consequences:**  
- Visual inconsistency undermines "GUI aesthetic exploration" (GUI-09) credibility
- Windows users (primary target per PROJECT.md) get poor first impression
- Cannot be fixed by QSS alone — requires `ctypes.windll.dwmapi` call

**Prevention:**  
- **Add Windows dark title bar helper** in `gui.py` `_build_ui()` or `AppWindow.__init__`:
```python
if sys.platform == "win32":
    try:
        import ctypes
        DWMWA_USE_IMMERSIVE_DARK_MODE = 20
        hwnd = int(self.winId())
        ctypes.windll.dwmapi.DwmSetWindowAttribute(
            hwnd, DWMWA_USE_IMMERSIVE_DARK_MODE,
            ctypes.byref(ctypes.c_int(1)), ctypes.sizeof(ctypes.c_int)
        )
    except Exception:
        pass  # graceful degradation
```
- **Set `QApplication.setStyle("Fusion")`** before stylesheet — Fusion respects palette fully and works cross-platform
- **Test on Windows 10 (1909+) and 11** — attribute only works on supported versions

**Detection:**  
- Launch on Windows 10/11 — title bar should be dark (`#0d1117` or close)
- Switch Windows system theme Light ↔ Dark — app title bar should follow (if using Fusion + palette)

**Phase to address:** Phase 3 (GUI-09 — GUI aesthetic exploration) — **do first** as foundation for all visual work

---

### Pitfall 7: Matplotlib Figure Background Doesn't Match Qt Dark Theme

**What goes wrong:**  
If Matplotlib `FigureCanvasQTAgg` is used for diagrams, the figure background defaults to white (`#ffffff`) while the surrounding Qt widgets use `BG_DARK = "#0d1117"`. The canvas stands out as a bright rectangle.

**Why it happens:**  
- Matplotlib `Figure` default `facecolor='white'`
- Qt stylesheet on parent widget doesn't propagate to Matplotlib's internal `Figure` object
- `FigureCanvasQTAgg` is a `QWidget` but paints via Agg backend, not Qt style system

**Consequences:**  
- Diagram looks like a "hole" in the dark UI
- User perceives it as a bug, not a feature

**Prevention:**  
- **Explicitly set figure facecolor at creation**:
```python
from matplotlib.figure import Figure
fig = Figure(facecolor=BG_DARK, edgecolor=BG_DARK)
ax = fig.add_subplot(111)
ax.set_facecolor(BG_PANEL)
ax.tick_params(colors=TEXT_PRI)
ax.xaxis.label.set_color(TEXT_PRI)
ax.yaxis.label.set_color(TEXT_PRI)
for spine in ax.spines.values():
    spine.set_edgecolor(BORDER)
```
- **Or use `QPainter`** (Pitfall 4) — avoids this entirely

**Detection:**  
- Screenshot the Vehicle Config tab — diagram background should be indistinguishable from surrounding panels

**Phase to address:** Phase 1 (VIS-01) — if Matplotlib chosen

---

### Pitfall 8: Diameter Mode + Fairing Mode Combinatorial Explosion in GUI

**What goes wrong:**  
Current Vehicle Config tab has 3 body diameter modes (Statistical, Constant, User). Adding 3 fairing modes (Constant, User, Hammer-Head) creates 9 combinations. Some are invalid or nonsensical:
- Body: User-specified (fixed D) + Fairing: Hammer-Head (fairing > body) → valid
- Body: Constant (max statistical D) + Fairing: Constant (fairing = body) → valid but redundant
- Body: Statistical (tapered) + Fairing: Hammer-Head → complex; fairing sits on top stage only?

**Why it happens:**  
- Body diameter modes apply to *all stages* (per `Geometry_calc.f90:92-104`)
- Fairing is a *single* component at the top of the stack
- No GUI validation prevents contradictory combinations
- User expects fairing to relate to *top stage* diameter, not all stages

**Consequences:**  
- User selects Body: Statistical + Fairing: Hammer-Head → unclear which stage's diameter the fairing references
- Fortran `Geometry_calc` has no concept of "top stage fairing" — it processes all stages uniformly
- Results become ambiguous; user can't predict outcome

**Prevention:**  
- **Restrict fairing modes based on body mode** in GUI:
  - Body: Statistical → Fairing: Constant (fairing = top stage statistical D) or User-specified only
  - Body: Constant → Fairing: Constant or User-specified (Hammer-Head = User-specified with D_fairing > D_body)
  - Body: User-specified → Fairing: Constant (fairing = body D) or Hammer-Head (fairing > body D)
- **Disable invalid fairing radio buttons** when body mode changes (connect `mode_buttons.buttonToggled` → `update_fairing_mode_availability()`)
- **Document the semantic**: fairing always references the *uppermost stage* (Stage 1 for 1-stage, Stage N for N-stage)
- **Add tooltip** on each fairing radio explaining the effective rule

**Detection:**  
- Try all 9 combos — verify Fortran receives coherent parameters
- Check that Hammer-Head never allows `fairing_diameter <= body_diameter` (validate in GUI + Fortran)

**Phase to address:** Phase 2 (FAIR-01/02/03) — GUI validation logic

---

## Moderate Pitfalls

### Pitfall 9: Diagram Rendering Blocks UI Thread on Large Stage Counts

**What goes wrong:**  
Drawing the rocket diagram (especially with Matplotlib) in `_run()` after the Fortran call completes adds 50–200 ms on the main thread. With the existing single-threaded architecture, this is acceptable for 1–3 stages but becomes noticeable if stage count grows or diagram complexity increases (fairing, payload, fins).

**Why it happens:**  
- `matplotlib.figure.Figure` creation + `canvas.draw()` runs on main thread
- No `QThread`/`QRunnable` used for post-processing
- Pipeline already blocks on `run_full_pipeline` (ctypes call is synchronous)

**Prevention:**  
- **Keep diagram simple**: static side-view, no animation, no interaction — single `draw()` call
- **If complexity grows**: move diagram generation to a `QRunnable` + `QThreadPool`, emit `diagram_ready` signal with pixmap/svg data
- **For now**: acceptable; monitor frame time with `QElapsedTimer`

**Phase to address:** Phase 1 (VIS-01) — monitor, defer threading to future

---

### Pitfall 10: Export Format Doesn't Include Diagram or Fairing Data

**What goes wrong:**  
`_print_results()` (lines 981–1032) exports a text summary. New fairing modes and diagram data are not included. Users who rely on `.txt` export for documentation lose the new configuration.

**Why it happens:**  
- Export logic is hardcoded to stage-by-stage mass/ratio/geometry
- No fairing fields in `results` dict from `rocket_lib.py`
- Diagram is a visual artifact, not data

**Prevention:**  
- **Extend `run_full_pipeline` return dict** to include `fairing: {diameter, length, volume}` when `fairing_setup > 0`
- **Update `_print_results()`** to append fairing block after stage loop
- **Diagram export**: add "Save Diagram" button in Vehicle Config tab → `canvas.print_figure()` or `QPainter` → PNG/SVG

**Phase to address:** Phase 2 (fairing) + Phase 1 (diagram export)

---

### Pitfall 11: QSS Style Specificity Breaks Custom Diagram Widget

**What goes wrong:**  
The global `STYLE` QSS (lines 64–238) uses broad selectors (`QWidget`, `QFrame`, `QLabel`). A custom `RocketDiagramWidget` (subclass of `QWidget`) inherits unwanted styles: borders, background, padding that interfere with `QPainter` rendering.

**Why it happens:**  
- `QWidget { background-color: #0d1117; }` applies to all widgets including custom diagram widget
- `QFrame { border: 1px solid #30363d; }` adds border around diagram area
- Custom widget needs `setAttribute(Qt.WidgetAttribute.WA_StyledBackground, True)` but also needs to *opt out* of frame/label styles

**Prevention:**  
- **Give diagram widget a unique `objectName`** (e.g., `rocketDiagramView`)
- **Add specific QSS rules** *after* global STYLE to override:
```css
QWidget#rocketDiagramView {
    background-color: #0d1117;
    border: none;
    padding: 0;
}
```
- **Or use `setStyleSheet("")` on the diagram widget** to reset, then apply only needed styles

**Phase to address:** Phase 1 (VIS-01) — when creating diagram widget

---

### Pitfall 12: Font Rendering Inconsistency Across Platforms in Diagrams

**What goes wrong:**  
Diagram labels (stage numbers, diameter values, "Stage 1", "Fairing") render differently on Windows (Segoe UI), macOS (San Francisco), Linux (DejaVu/Noto). Matplotlib uses its own font stack; Qt uses system fonts. Diagram text doesn't match surrounding GUI text.

**Why it happens:**  
- `gui.py` sets `font-family: 'Segoe UI', 'Inter', sans-serif` in QSS
- Matplotlib defaults to DejaVu Sans (bundled)
- `QPainter` uses Qt's font resolution (respects QSS `font-family`)

**Prevention:**  
- **If Matplotlib**: explicitly set `font.family` in `matplotlib.rcParams` or per-figure to match QSS:
```python
import matplotlib
matplotlib.rcParams['font.family'] = ['Segoe UI', 'Inter', 'DejaVu Sans', 'sans-serif']
```
- **If QPainter**: use `QFont(QApplication.font())` — inherits app font automatically
- **Test on all three platforms** (CI or manual)

**Phase to address:** Phase 1 (VIS-01) / Phase 3 (GUI-09)

---

## Minor Pitfalls

### Pitfall 13: Tooltip / Hover Interaction Missing on Static Diagram

**What goes wrong:**  
Users expect to hover over a stage in the diagram and see exact values (diameter, length, volume). Static `QPainter` or Matplotlib canvas without event handling provides no feedback.

**Prevention:**  
- **Matplotlib**: use `mpl_connect("motion_notify_event", on_hover)` + annotation
- **QPainter**: override `mouseMoveEvent`, map coordinates to stage geometry, show `QToolTip.showText()`
- **MVP**: skip interaction; add "Copy values" context menu instead (lower effort)

**Phase to address:** Phase 1 (VIS-01) — defer interaction to v1.2

---

### Pitfall 14: Fairing Mode "Constant" Name Collision with Body Diameter Mode "Constant"

**What goes wrong:**  
Both body diameter modes and fairing modes have a "Constant" option. In GUI radio groups, this creates ambiguity: "Constant" (body) vs "Constant" (fairing).

**Prevention:**  
- **Rename fairing modes** for clarity:
  - Body modes: "Statistical", "Constant (all stages)", "User-specified"
  - Fairing modes: "Match body", "User-specified", "Hammer-Head"
- **Group in separate QGroupBoxes** with clear titles: "BODY DIAMETER MODE" vs "FAIRING DIAMETER MODE"

**Phase to address:** Phase 2 (FAIR-01/02/03) — GUI labeling

---

### Pitfall 15: Diagram Aspect Ratio Distortion in QScrollArea

**What goes wrong:**  
Rocket diagram is tall and narrow (height ≫ width). Inside a `QScrollArea` with default policies, it may be squashed horizontally or stretched vertically, distorting the visual scale (1 m vertical ≠ 1 m horizontal).

**Prevention:**  
- **Set fixed aspect ratio** on diagram widget: `setSizePolicy(QSizePolicy.Policy.Fixed, QSizePolicy.Policy.Expanding)` + override `heightForWidth()` or use `QWidget.resizeEvent` to maintain scale
- **Or use `QGraphicsView` + `QGraphicsScene`** with `setAspectRatioMode(Qt.AspectRatioMode.KeepAspectRatio)`
- **Define diagram coordinate system**: 1 pixel = 1 cm (configurable), center horizontally

**Phase to address:** Phase 1 (VIS-01)

---

## Phase-Specific Warnings

| Phase | Topic | Likely Pitfall | Mitigation |
|-------|-------|----------------|------------|
| **Phase 1** (VIS-01) | Rocket diagram rendering | Matplotlib canvas leak / theme mismatch / stale data | Single canvas instance, explicit dark theme, connect to `_on_inputs_changed()` |
| **Phase 1** (VIS-01) | Diagram data source | Reading stale `_last_results` after input change | Guard with `hasattr(self, '_last_results')` + show placeholder |
| **Phase 2** (FAIR-01/02/03) | Fairing data model | GUI/Fortran enum divergence | Define shared constants module; extend Fortran first |
| **Phase 2** (FAIR-03) | Hammer-Head geometry | Single-diameter-per-stage assumption breaks | Add `Fairing_t` to `Rocket_t`; compute separately in `Geometry_calc` |
| **Phase 2** (FAIR-01/02/03) | Mode combinations | 9 combos, some invalid | GUI validation: disable invalid fairing modes per body mode |
| **Phase 3** (GUI-09) | Aesthetic exploration | Windows title bar stays white | `DwmSetWindowAttribute` + Fusion style; test on Win10/11 |
| **Phase 3** (GUI-09) | Theme consistency | Matplotlib figure background white | Explicit `Figure(facecolor=BG_DARK)` + axis styling |
| **Phase 3** (GUI-09) | ASCII art trap | Choosing text-based diagrams | Reject; use QPainter or Matplotlib with theme sync |

---

## Sources

- **Codebase analysis** (`.planning/codebase/ARCHITECTURE.md`, `CONCERNS.md`, `STRUCTURE.md`) — Fortran pipeline, ctypes bridge, GUI tab structure, diameter mode implementation
- **GUI source** (`SRC/gui/gui.py`) — `_build_vehicle_tab`, `_on_inputs_changed`, `_run`, `STYLE` QSS, tab switching logic
- **Fortran geometry** (`SRC/pre-simulation-calcs/Geometry_calc.f90:92-105`) — `Diameter_setup` cases 1/2/3 implementation
- **Bridge** (`SRC/interface/C_Interface.f90`, `SRC/interface/rocket_lib.py`) — `run_full_pipeline` signature, `diameter_setup_in`, `user_diameter_in`
- **Matplotlib + Qt embedding docs** (matplotlib.org) — `FigureCanvasQTAgg` lifecycle, dark theme styling, static vs dynamic canvas patterns
- **PyQt6 dark theme ecosystem** (qdarktheme, QDarkStyleSheet, pyqt-darktheme) — Fusion style requirement, Windows title bar WinAPI
- **OpenRocket architecture** (openrocket.info, GitHub) — Java Swing + core separation, real-time design view, component tree, fairing/payload modeling as separate components
- **Qt Forum / Qt 6 docs** — Windows dark mode best practices, `windowsvista` vs `Fusion` style, HiDPI scaling
- **Engineering GUI patterns** (RocketPy, REDTOP, RPA) — separate fairing/payload geometry, export formats, diagram expectations

---

## Confidence Assessment

| Area | Confidence | Notes |
|------|------------|-------|
| Rocket diagrams (VIS-01) | HIGH | Directly mapped to existing GUI tab structure, Matplotlib/Qt integration well-documented, state invalidation pattern established |
| Fairing modes (FAIR-01/02/03) | HIGH | Requires Fortran data model changes first; enum divergence is a known class of bug in this codebase (see CONCERNS.md config parser bug) |
| GUI aesthetics (GUI-09) | HIGH | Windows title bar issue is documented Qt limitation; Fusion style + WinAPI is standard solution |
| Integration pitfalls | HIGH | Based on actual codebase concerns (module globals, dual entry points, circular Makefile deps) |

---

## Gaps to Address

- [ ] **Fairing geometry math**: Exact fairing length/volume formulas for Hammer-Head mode (ogive vs conic fairing shape) — need aerospace reference or empirical correlation
- [ ] **Diagram coordinate system**: Whether to use true-scale (1:1 meter:pixel) or schematic (fixed height, variable width) — impacts `QPainter` vs Matplotlib choice
- [ ] **Fairing-to-payload clearance**: NASA geometry guide shows fairing inner diameter = outer - 2×thickness; need thickness assumption or user input
- [ ] **Export format versioning**: `.txt` results format should version-tag for fairing/diagram additions to avoid breaking downstream parsers