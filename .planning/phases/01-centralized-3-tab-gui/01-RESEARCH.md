# Phase 1 Research: Centralized 3-Tab GUI

**Researched:** 2026-08-14
**Domain:** PyQt6 desktop GUI restructuring (GUI/Python only — no Fortran changes)
**Confidence:** HIGH (all in-repo claims verified by reading source this session)

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions
- **D-01:** Centralized 3-tab interface, not scattered panels. Three tabs: Results (central), Setup, Vehicle Configuration.
- **D-02:** Tab order: Results tab first (the central/home surface), then Setup, then Vehicle Configuration.
- **D-03:** Shows per-stage rocket and stage masses: m0, mf, mp, ms
- **D-04:** Shows per-stage mass ratios k_m, k_s, k_L and exhaust velocity
- **D-05:** Shows per-stage ΔV
- **D-06:** Shows geometry results per stage: diameter, length, volume
- **D-07:** Retains the existing "Save Results" export and the minimum-confirmed indicator
- **D-08:** Keeps the sliders and propellant + combustion-cycle selectors exactly as they are today — relocated into this tab, not redesigned
- **D-09:** Holds the new mission inputs: orbit height (km), payload mass (kg), stage count
- **D-10:** ΔV is computed internally by the pipeline — the user does NOT enter ΔV by hand
- **D-11:** Offers three diameter modes: statistically-determined, constant, and user-specified
- **D-12:** User-specified mode exposes a box where the user enters the diameter value
- **D-13:** Splash screen is preserved as-is
- **D-14:** config.txt remains a separate input path — the GUI is independent of it (user decision)

### the agent's Discretion
- Exact widget styling/spacing/typography of the tabs
- Layout of results within the Results tab (table vs cards vs grouped fields)
- How to reflect pipeline outputs the Fortran side does not yet expose (results may be partially populated pending Phase 2 pipeline wiring — this phase focuses on the tab shell and data surface)
- QThread/worker patterns for running the solver without freezing the UI

### Deferred Ideas (OUT OF SCOPE)
- Wiring the full pipeline (orbit → payload → staging → thrust → geometry) — Phase 2 (results tab may show only what the staging path already provides until then)
- Correctness fixes (rm_L init, dedup bridge, MinGW path) — Phase 3
- Automated tests — deferred to a future session (user decision)
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| GUI-01 | App opens to a centralized 3-tab interface (Results central, Setup, Vehicle Configuration) | Current `MainWindow` is a left-input/right-results split (`gui.py:712-815`) — the exact widget inventory to relocate is mapped in "Widget → Tab Mapping" |
| GUI-02 | Results tab shows per-stage m0, mf, mp, ms, k_m, k_s, k_L, per-stage ΔV, exhaust velocity | `run_staging` returns m0/mf/mp/ms/k_m/k_s/k_L/nu_e today; per-stage ΔV is computed in Fortran (`Staging.f90:140-142`) but NOT packed by `C_Interface.f90` → placeholder until Phase 2 (see "Results Data Availability Matrix") |
| GUI-03 | Results tab shows geometry per stage (diameter, length, volume) | Geometry computed in `Geometry_calc.f90` but stored in locals, never written to `Rocket` → placeholder until Phase 2 on ALL paths |
| GUI-04 | Retains "Save Results" export + minimum-confirmed indicator | `_print_results` (`gui.py:864-907`) and `min_label` (`gui.py:957-963`) — reuse verbatim, move to Results tab; export header depends on `dv_spin` which D-10 removes (see Pitfall 5) |
| GUI-05 | Mission inputs in GUI (orbit height, payload mass, stage count); ΔV not hand-entered | Mission group exists (`gui.py:742-768`); `dv_spin` must be REMOVED; orbit_height/payload_mass/number_of_stages map to Fortran module globals (`Typical_Data.f90:37-39`); interim ΔV feeding `run_staging` needs a decision (Open Question 1) |
| GUI-06 | Vehicle Configuration tab offers statistically-determined, constant, user-specified diameter modes | Semantics mirror `diameter_setup` 1/2/3 (`Typical_Data.f90:803-813`, `Geometry_calc.f90:92-104`) — verbatim semantics in "Diameter Modes" |
| GUI-07 | User-specified mode exposes an input box for the diameter value | Mirrors `user_defined_diameter` (`Typical_Data.f90:50`, config key `Typical_Data.f90:936-938`) |
| GUI-08 | Launch splash screen is preserved | `AppWindow` + `SplashScreen` + fade (`gui.py:582-700`, `990-1019`) — untouched; only `MainWindow` content changes |
</phase_requirements>

## Summary

The current GUI (`SRC/gui/gui.py`, 1028 lines) is a splash → `QStackedWidget` → `MainWindow` with a fixed 420px left input panel and a right results panel. The phase restructures only `MainWindow`'s content: replace the left/right split with a `QTabWidget` of three tabs (Results first per D-02, then Setup, then Vehicle Configuration). The Setup tab is a near-verbatim relocation of the existing left panel (mission inputs + `StageInputWidget` sliders/selectors + Run button) minus the ΔV spinbox (D-10). The Results tab reuses the summary/minimum-indicator/`ResultCard`/Save-Results machinery with added per-stage ΔV and geometry fields. The Vehicle Configuration tab is a new, pure-GUI widget mirroring the Fortran `diameter_setup` modes 1/2/3 and `user_defined_diameter`.

The ctypes bridge (`run_staging`) already returns m0/mf/mp/ms/k_m/k_s/k_L/nu_e, total initial mass, and the minimum-found flag — enough to populate the Results tab for 7 of the 10 required metrics today. Per-stage ΔV is computed by Fortran but not exported; geometry (diameter/length/volume) is computed but never stored anywhere reachable — both must render as placeholders pending Phase 2 wiring (explicitly allowed by the user's discretion note). Key risks: the DLL is loaded at import time (GUI cannot start without `build/librocket.dll`, which is currently MISSING in `build/` — `make gui` builds it), the solver call is blocking on the UI thread, and the global QSS rule paints every `QWidget` dark, so tab-bar/pane styling must be added explicitly.

**Primary recommendation:** Single-file restructuring of `gui.py` — add `QTabWidget` import, build three tab pages, relocate existing widgets without redesign (D-08), keep `AppWindow`/`SplashScreen`/`STYLE` untouched, keep the local `run_staging` bridge as-is (dedup is FIX-02/Phase 3), and do NOT touch any Fortran file (phase boundary: GUI/Python-only).

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Tab shell + widget layout | API / Desktop client (PyQt6) | — | All GUI; no backend change in this phase |
| Mission input collection (orbit height, payload mass, stage count) | API / Desktop client | — | Values stored as GUI widget state; passed to bridge on Run (Phase 1) and to full pipeline (Phase 2) |
| Staging solver results | Fortran core (via ctypes) | API / Desktop client (display only) | Physics stays in Fortran — Python only formats returned dicts; PIPE-02 forbids Python physics reimplementation |
| Per-stage ΔV, geometry | Fortran core (computed but unexported) | — | Placeholder in GUI until Phase 2 packs them (GUI-02/GUI-03 partial population is user-approved) |
| Diameter mode semantics | API / Desktop client (mirror only) | Fortran core (source of semantics) | GUI mirrors `diameter_setup` 1/2/3; no Fortran change this phase |
| Results export + minimum indicator | API / Desktop client | — | Pure GUI feature, relocated |

## Domain Research

### Current GUI structure (`SRC/gui/gui.py` — read in full this session)

**Class hierarchy (all in one file):**

| Class | Lines | Role |
|-------|-------|------|
| `NoScrollComboBox(QComboBox)` | 315-317 | Wheel-scroll guard for combo boxes |
| `StageInputWidget(QGroupBox)` | 319-528 | Per-stage propellant combo + cycle combo + ISP slider + k_s slider; `validity_changed` signal; `get_values()` → `(isp, k_s, has_data)` |
| `ResultCard(QFrame)` | 532-577 | Per-stage metric card: 8 metrics (m0, mf, mp, ms, k_m, k_L, k_s, nu_e) in a 2-column grid |
| `SplashScreen(QWidget)` | 582-700 | Full-screen dark splash: logo placeholder, title, LAUNCH button, `launch_requested` signal |
| `MainWindow(QMainWindow)` | 704-985 | Left input panel (420px `QScrollArea`) + right results panel (`QScrollArea`) — **this is what becomes the 3-tab shell** |
| `AppWindow(QMainWindow)` | 990-1019 | `QStackedWidget`: index 0 = splash, index 1 = `MainWindow`; fade via `QGraphicsOpacityEffect` + `QPropertyAnimation` (600 ms, InOutQuad) |
| entry point | 1023-1028 | `QApplication` + `app.setStyleSheet(STYLE)` + `AppWindow` |

**Key facts:**
- **No `QTabWidget` anywhere today** — imports include `QStackedWidget` but not `QTabWidget` (`gui.py:9-15`). The new shell needs `from PyQt6.QtWidgets import QTabWidget`.
- **Solver calls are blocking.** `_run` (`gui.py:909-985`) calls the local `run_staging` synchronously on the UI thread inside `try/except` → `QMessageBox.critical` (`gui.py:933-943`). `QThread` is imported at `gui.py:16` but **never used** (dead import; the only `.start()` in the file is the splash fade animation at line 1019). [VERIFIED: SRC/gui/gui.py:16, 1019 — grep found no other QThread/QTimer usage]
- **Signal/slot wiring style:** plain `connect` on widget signals; `validity_changed` (custom `pyqtSignal`, `gui.py:320`) fans out to `_update_run_button` + `_on_inputs_changed` (`gui.py:833-834`); spinbox `valueChanged` → `_on_inputs_changed` (`gui.py:817-819`). `_on_inputs_changed` clears results and disables Save (`gui.py:859-862`).
- **Styling:** single global QSS string `STYLE` applied to `QApplication` (`gui.py:147-312`), dark GitHub-style palette with named color constants (`gui.py:134-146`). First rule is the blanket selector:
  ```css
  QMainWindow, QWidget { background-color: #0d1117; color: #e6edf3; ... }
  ```
  [VERIFIED: SRC/gui/gui.py:147-153] — consequence: un-styled `QTabBar`/`QTabWidget::pane` inherit dark background with default (light-on-dark OK for text, but selected-tab contrast and pane border need explicit rules; see Pitfall 1).
- **Run-button readiness:** `run_btn` uses `setProperty("ready", bool)` + `unpolish`/`polish` (`gui.py:787-793`, `853-857`) — enabled only when every stage has ISP/k_s data.
- **Text language: English** throughout the GUI (`gui.py` labels: "ROCKET STAGING", "ΔV (km/s)", "Propellant / Oxidizer", "Minimum confirmed", etc.). Fortran internals mix Spanish comments — irrelevant to GUI text.
- **Duplicate bridge:** `run_staging` is defined BOTH locally (`gui.py:80-110`) and in `rocket_lib.py:45-88`. `gui.py` adds `interface/` to `sys.path` (`gui.py:29`) but does not import from it. Dedup is FIX-02 → **Phase 3**; Phase 1 keeps the local copy (phase-boundary respect, zero behavior change).

### PyQt6 patterns in use (applicable to the new tabs)

- **Container pattern:** `QScrollArea` + inner `QWidget` + `QVBoxLayout` with `addStretch()` bookends (`gui.py:720-727`, `803-815`). The Results tab can reuse this exact pattern.
- **Dynamic rebuild:** `_rebuild_stage_inputs(n)` deletes widgets with `removeWidget` + `deleteLater()` and recreates `StageInputWidget`s (`gui.py:825-838`) when `n_stages_spin` changes — must keep working inside the Setup tab.
- **Empty-state pattern:** `_show_empty_state()` inserts a placeholder `QLabel` at layout index 0; `_clear_results()` drains the layout (`gui.py:840-851`).
- **QTabWidget/QTabBar QSS selectors** (standard Qt stylesheet examples, corroborated by community sources): `QTabWidget::pane`, `QTabWidget::tab-bar:top`, `QTabBar::tab`, `QTabBar::tab:selected`, `QTabBar::tab:!selected`, `QTabBar::tab:!selected:hover`, `QTabBar::tab:top:!selected { margin-top: 3px; }`. [CITED: doc.qt.io stylesheet-examples; stackoverflow.com/questions/38369015; gist.github.com/espdev/4f1565b18497a42d317cdf2531b7ef05]
- **QTabWidget core API** (`addTab`, `setCurrentIndex`, `currentChanged`) is stable, long-standing Qt API. [ASSUMED]
- **No external styling library** is used (hand-rolled QSS). Keep that pattern — do not introduce QDarkStyleSheet etc. for one tab bar.

## Implementation Approaches

### Widget → Tab mapping (concrete, from current code)

| Current location (`gui.py`) | Widgets | Destination tab |
|---|---|---|
| `left_layout` title/subtitle (732-739) | "ROCKET STAGING" header | Drop or move to Setup tab header (discretion) |
| Mission group (742-768) | `dv_spin` (747-752), `pl_spin` (755-760), `n_stages_spin` (763-766) | Setup tab — **`dv_spin` REMOVED per D-10**, replaced by internal ΔV (Open Question 1); `pl_spin` (payload mass) and `n_stages_spin` (stage count) stay, plus NEW `orbit_height` spinbox (D-09) |
| `stages_container` (772-777) + `StageInputWidget`s (831-836) | propellant/cycle combos + ISP/k_s sliders | Setup tab, verbatim (D-08) |
| `run_btn` (780-795) | "▶ Run Staging Analysis" | Setup tab (primary action stays next to inputs) — placement discretion |
| `print_btn` (783-786, 864-907) | "⬇ Save Results" + `_print_results` | Results tab (D-07: "retained in Results tab") |
| `right_layout` summary (948-955) | "Total Initial Mass" header | Results tab |
| `min_label` (957-963) | "✔ Minimum confirmed" / "✘ Minimum not confirmed — check your inputs" | Results tab (D-07) |
| `ResultCard` (969-971, class at 532-577) | per-stage cards | Results tab — extended with ΔV + diameter/length/volume fields (GUI-02/03) |
| `_show_empty_state` (840-845) | "Run the analysis to see results here." | Results tab |

**Recommended shell structure (discretion area, satisfies D-01/D-02):**

```python
class MainWindow(QMainWindow):
    def _build_ui(self):
        self.tabs = QTabWidget()
        self.setCentralWidget(self.tabs)
        self.tabs.addTab(self._build_results_tab(),  "Results")            # index 0 (central, D-02)
        self.tabs.addTab(self._build_setup_tab(),    "Setup")
        self.tabs.addTab(self._build_vehicle_tab(),  "Vehicle Configuration")
```

(One file, `gui.py`, matching the existing single-file convention — CONVENTIONS.md.)

### Results data availability matrix (GUI-02/03 field-by-field)

`run_staging` (`gui.py:80-110` — identical in `rocket_lib.py:45-88`) returns:

```python
return {
    "total_initial_mass": total_m0.value,
    "minimum_found": bool(min_found.value),
    "stages": [
        {"stage": i+1, "m0": m0[i], "mf": mf[i], "mp": mp[i],
         "ms": ms[i], "k_m": km[i], "k_s": ks_o[i],
         "k_L": kl[i], "nu_e": nu_e[i]}
        for i in range(n_stages)
    ]
}
```
[VERIFIED: SRC/gui/gui.py:101-110 and SRC/interface/rocket_lib.py:71-88]

| GUI-02/03 metric | Available today? | Source path |
|---|---|---|
| m0, mf, mp, ms (per stage) | ✅ YES | packed `C_Interface.f90:57-66` from `Rocket%stage%m_0/m_f/m_p/m_s` |
| k_m, k_s, k_L (per stage) | ✅ YES | packed `C_Interface.f90:62-64` |
| nu_e (exhaust velocity) | ✅ YES | packed `C_Interface.f90:65` (computed `Staging.f90:59`: `nu_e = ISP * g_0 / 1000` [km/s]) |
| total initial mass | ✅ YES | `C_Interface.f90:68` (`Rocket%rm_0`) |
| minimum-confirmed flag | ✅ YES | eq-26 check `C_Interface.f90:70-90` → `minimum_found_out` |
| **per-stage ΔV** | ⚠️ COMPUTED BUT NOT EXPORTED | `Staging.f90:139-142`: `rocket%stage(i)%D_v = rocket%stage(i)%nu_e * log(rocket%stage(i)%m_0/rocket%stage(i)%m_f)` — `D_v` is a `Stage_t` field (`Rocket_Types.f90:19`) but `C_Interface` never packs it. Exposing it requires a Fortran change → Phase 2 (PIPE-02). **Phase 1: placeholder ("—", pending Phase 2) — or 1-line Python derivation `nu_e*ln(m0/mf)` as interim (Open Question 2).** |
| **geometry: diameter, length, volume** | ❌ NOT AVAILABLE ON ANY PATH | `Geometry_calc.f90:7-9` computes `Diameter_vector`/`Volume_vector`/`Longitud_vector` as **subroutine locals**; the `Stage_t` fields `Diameter`/`Length` (`Rocket_Types.f90:22-23`) are never assigned; `Volume` has no field at all. Even `Main.f90:19-29` prints no geometry. Not reachable without Fortran changes → **Phase 1: placeholders only.** |

### Diameter modes (Vehicle Configuration tab) — verbatim Fortran semantics

Module globals (`Typical_Data.f90:49-50`):
```fortran
    integer diameter_setup
    real(8) user_defined_diameter
```
[VERIFIED: SRC/inout/Typical_Data.f90:49-50]

Config keys parsed by `load_config` (`Typical_Data.f90:932-938`):
```fortran
        case ("diameter_setup")
            read(value, *, iostat=ios) diameter_setup
            ...
        case ("user_defined_diameter")
            read(value, *, iostat=ios) user_defined_diameter
```
[VERIFIED: SRC/inout/Typical_Data.f90:932-938]

Mode validation (`Typical_Data.f90:802-813`):
```fortran
    !===== DIAMETER CONFIG CHECK =========
    select case (diameter_setup)
    case(1) 
        print*, "Diameter setup: Statistically Determined"
    case(2)
        print*, "Diameter setup: Constant"
    case(3)
        print*, "Diameter setup: Fairing Requirement"
    case default
        print*, "WARNING: unknown Diameter setup"
        stop
    end select 
```
[VERIFIED: SRC/inout/Typical_Data.f90:803-813]

Effect on geometry (`Geometry_calc.f90:92-105`):
```fortran
    select case (Diameter_setup)
    case(1) ! 1 - Statistically determined
        if (number_of_stages > 1) then
            do i=1,number_of_stages-1
                check_diameter = Diameter_vector(i+1) - Diameter_vector(i)
                if (check_diameter > 0.d0) Diameter_vector(i) = Diameter_vector(i+1)
            end do
        end if
    case(2) ! 2 - Constant 
        Diameter_vector = maxval(Diameter_vector)
    case(3) ! 3 - Fairing requirement   
        Diameter_vector = User_defined_diameter
    end select
    Longitud_vector = Volume_vector * 4.d0 / (pi * Diameter_vector**2.d0)
```
[VERIFIED: SRC/pre-simulation-calcs/Geometry_calc.f90:92-105]

**Mode semantics for the tab:**
- **Mode 1 — Statistically determined:** each stage's diameter from propellant-specific regression curves on stage initial mass `m_i` (in metric tons, `Geometry_calc.f90:14-17`); then a monotonicity pass: a stage whose neighbor above is wider is widened to match (`case(1)` loop). Statistical curves exist only for some propellants (e.g., LH2/LOX, RP1/LOX, UDMH/N2O4, Aerozine50/N2O4); CH4/LOX etc. print "WARNING: without statistical data on the geometry" and leave vectors at 0 (`Geometry_calc.f90:27-29, 51-52`).
- **Mode 2 — Constant:** all stages take `maxval(Diameter_vector)` (the widest statistical stage).
- **Mode 3 — Fairing requirement (CONTEXT D-11 calls this "user-specified"):** all stages take `User_defined_diameter` — the user-entered value. Note the label mismatch: Fortran/config.txt say "Fairing requirement", CONTEXT says "user-specified" — GUI label per CONTEXT (D-11/D-12); semantics identical. This is the mode with the input box (D-12). The input box maps to the `user_defined_diameter` config key (`config.txt:38`: `User_defined_diameter = 2.d0`).

**Recommended widget:** a mode selector (`QComboBox` or `QRadioButton`s) with 3 entries + a `QDoubleSpinBox` (units: m, sensible range e.g. 0.5–20 m — discretion) that is enabled only when mode 3 is selected. Mode value stored as an int 1/2/3 matching the Fortran enum (so Phase 2 can pass it straight to the pipeline).

### Mission inputs → Fortran globals mapping (Phase 2 anticipation)

Module globals the Fortran expects (`Typical_Data.f90:36-39`):
```fortran
    real(8) V_circ
    real(8) orbit_height
    real(8) payload_mass
    integer number_of_stages
```
[VERIFIED: SRC/inout/Typical_Data.f90:37-39]

Current ctypes path sets only two of them (`C_Interface.f90:39-42`):
```fortran
    ! --- Set module-level globals used by STAGING ---
    Rocket%delta_v          = delta_v_in
    payload_mass     = payload_mass_in
    number_of_stages = n_stages
```
[VERIFIED: SRC/interface/C_Interface.f90:40-42]

- **payload_mass (kg)** — GUI `pl_spin` → `run_staging(payload_mass=...)` → module global `payload_mass` ✅ wired today.
- **number_of_stages** — GUI `n_stages_spin` (range 1–3, `gui.py:764`) → module global `number_of_stages` ✅ wired today.
- **orbit_height (km)** — GUI field is NEW. Not consumed on the ctypes path today. In the standalone path, `orbit_speed_calculator` (`Orbit_calc.f90:9-10`) turns it into `V_circ`:
  ```fortran
  r = Radius + orbit_height
  V_circ = sqrt(g_0*Radius**2.d0 / (r * 1000.d0))
  ```
  [VERIFIED: SRC/pre-staging-calcs/Orbit_calc.f90:9-10] with constants `g_0 = 9.80665d0`, `Radius = 6378.d0` [VERIFIED: SRC/inout/Typical_Data.f90:3-5], and `STAGING_LOOP` (`Stage_Optimization_Loop.f90:24-26, 88`) derives the mission ΔV from `V_circ` + losses. **Phase 2 (PIPE-01) wires orbit_height → V_circ → ΔV → STAGING_LOOP; Phase 1 only collects the field.**
- **ΔV** — `run_staging` still requires `delta_v` as an input in Phase 1 (D-10 removes the user field, so the GUI must supply an interim value internally — Open Question 1).

### Code example — tab shell skeleton (pattern to follow)

```python
from PyQt6.QtWidgets import QTabWidget  # add to existing imports (gui.py:9-15)

# inside MainWindow._build_ui, replacing the left/right split (gui.py:712-815):
self.tabs = QTabWidget()
self.setCentralWidget(self.tabs)
self.tabs.addTab(self._build_results_tab(), "Results")   # index 0 — central/home
self.tabs.addTab(self._build_setup_tab(),   "Setup")
self.tabs.addTab(self._build_vehicle_tab(), "Vehicle Configuration")
```

QSS additions to `STYLE` (dark palette already defined; standard selectors):
```css
QTabWidget::pane { background: #0d1117; border: 1px solid #30363d; }
QTabBar::tab { background: #161b22; color: #8b949e; padding: 8px 24px;
               border: 1px solid #30363d; border-bottom: none; }
QTabBar::tab:selected { background: #1c2128; color: #58a6ff; }
QTabBar::tab:!selected:hover { color: #e6edf3; }
```
[ASSUMED selectors per standard Qt stylesheet examples; palette values [VERIFIED: SRC/gui/gui.py:134-146]]

### Standard stack

| Library | Version (verified) | Purpose | Why standard |
|---------|-------------------|---------|--------------|
| PyQt6 | 6.11.0 (Qt 6.11.0, Python 3.11.1) | GUI framework | Already the project's only external Python dependency (`STACK.md`); no new packages needed |

**No packages to install.** This phase is a pure restructuring of existing code. Package Legitimacy Audit: N/A — no new external packages; PyQt6 is already installed on the machine (verified above). The only "dependency" is `librocket.dll`, which is a build artifact, not a package.

### Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Tab container | Custom panel-switching widgets | Built-in `QTabWidget` | Standard Qt widget, matches QSS styling, zero maintenance |
| Physics (ΔV, geometry) | Python-side recomputation of staging/geometry | Fortran pipeline (Phase 2) / placeholders now | PIPE-02 explicitly forbids physics reimplementation in Python; geometry isn't even stored on the Fortran side yet |
| Config parsing | Reading config.txt in the GUI | Nothing — GUI stays independent (D-14) | Locked user decision: config.txt is a separate path |
| ctypes bridge | A third copy of `run_staging` | Existing local copy (`gui.py:80`) until Phase 3 dedup | Two copies already drift-prone (CONCERNS); adding a third is worse |

**Key insight:** the hardest part of this phase is *not* building new UI — it is **not breaking** the delicate input→validity→run→results wiring while relocating widgets across tabs. Reuse beats redesign (D-08).

## Dependencies & Risks

### Startup dependency: DLL is required at import time (HIGH risk for validation runs)

`gui.py` loads the DLL at **module import** (`gui.py:31-59`): `os.add_dll_directory(BUILD_DIR)` (line 33), MinGW candidate search (lines 38-45), then `_lib = ctypes.CDLL(os.path.join(BUILD_DIR, "librocket.dll"))` (line 57). If `build/librocket.dll` is absent, `import gui` raises `FileNotFoundError` before any window appears.

**Verified state on this machine:** `build/librocket.dll` **does not exist** (only `.o`/`.mod` artifacts present). The build is done by `make all` / `make gui` (`SRC/Makefile:87, 165-175, 201-204`); `make gui` builds the DLL then launches the GUI (`$(PYTHON) $(GUI_DIR)/gui.py`).

**Consequence:** every GUI validation run must start with a build. `python SRC/gui/gui.py` alone will crash.

### Hardcoded MinGW path (Phase 3 concern — do NOT fix here)

- `gui.py:38-45` searches `MINGW_BIN` env var then `C:\TDM-GCC-64\bin`, `C:\msys64\mingw64\bin`, `C:\msys64\ucrt64\bin`, `C:\mingw64\bin`, `C:\mingw\bin` — with a printed WARNING if nothing found (`gui.py:52-55`).
- `rocket_lib.py:19` defaults to `r"C:\TDM-GCC-64\bin"` if `MINGW_BIN` unset.
- `SRC/Makefile:52` hardcodes `MINGW_BIN := C:/TDM-GCC-64/bin` for runtime DLL copying.
- On this machine `C:\TDM-GCC-64\bin` **exists** (verified), so the current search works. FIX-03 (Phase 3) will remove the hardcode — Phase 1 must not change this resolution logic.

### Result availability dependency (what stays empty until Phase 2)

- ✅ Today: m0/mf/mp/ms, k_m/k_s/k_L, nu_e, total_initial_mass, minimum_found.
- ⚠️ Placeholder (Phase 1): per-stage ΔV — computed in Fortran (`Staging.f90:140-142`) but not packed by `C_Interface` (needs a Fortran change → Phase 2).
- ❌ Placeholder (Phase 1): geometry diameter/length/volume — computed in `Geometry_calc.f90` locals, never stored in `Rocket`; unreachable from any path until Phase 2 rework.

### Known correctness caveat (do not fix in this phase)

`Rocket%rm_L` is never set on the ctypes path (`C_Interface.f90:40-54` sets globals but not `Rocket%rm_L`; `Staging.f90:86` reads it: `Rocket%stage(1)%m_0 = Rocket%rm_L * Rocket%stage(1)%m_0`). Results may be garbage on the GUI path. FIX-01 → Phase 3. Phase 1 merely *displays* what the bridge returns — no Fortran edits (phase boundary).

### Solver responsiveness

`_run` blocks the UI thread during the ctypes call (`gui.py:933-943`). The solver is fast (bisection + ≤50 ΔV iterations), but the unconditional Fortran `print*` spam (CONCERNS: `Root_Finding.f90:63`, `Staging.f90:57`, `Stage_Optimization_Loop.f90:43`) goes to the GUI's stdout. QThread is a discretion item — recommendation: keep blocking (matches existing behavior; worker thread adds complexity with zero user-visible benefit at this speed); remove or keep the dead `QThread` import at the planner's discretion.

### Common Pitfalls

1. **Un-styled tab bar breaks the dark theme.** The blanket rule `QMainWindow, QWidget { background-color: #0d1117; ... }` (`gui.py:148-153`) applies to `QTabWidget` and its pane; without explicit `QTabBar::tab` / `QTabWidget::pane` rules the tabs render with default palette contrast. **Avoid:** add the QSS block shown in the code example to `STYLE`.
2. **`dv_spin` removal breaks `_print_results`.** The export header reads `self.dv_spin.value()` twice (`gui.py:869, 885`) and the default filename too (`gui.py:872`). **Avoid:** replace with the internally computed ΔV (Open Question 1) and adjust filename accordingly.
3. **Cross-tab invalidation lost during relocation.** `_on_inputs_changed` (`gui.py:859-862`) clears Results-tab content when Setup-tab inputs change. Keep these connections intact across tabs (signals are tab-agnostic — only the layout moves).
4. **`n_stages_spin` rebuild scope.** `_rebuild_stage_inputs` (`gui.py:825-838`) deletes and recreates stage widgets; it must operate on the Setup tab's container. Note the duplicated `self._last_results = results` at `gui.py:980, 983` — harmless, can be cleaned.
5. **Partial-population UX.** ΔV and geometry show "—" until Phase 2 (user-approved). **Avoid:** a Results tab that looks broken — add a subtle "pending pipeline wiring (Phase 2)" hint label (discretion), mirroring the existing "No data for this combination yet" pattern (`gui.py:481`).
6. **Running the GUI without building.** `python gui.py` without `build/librocket.dll` crashes at import (`gui.py:57`). **Avoid:** always validate via `make gui` or after `make all`.
7. **Stage-input rebuild resets slider values.** `_rebuild_stage_inputs` creates fresh `StageInputWidget`s; changing stage count discards per-stage slider selections (existing behavior — preserved as-is, D-08).
8. **Vehicle Configuration tab is decoupled.** It has no Run dependency — diameter mode only matters when geometry runs (Phase 2). Store mode 1/2/3 + diameter value on the MainWindow (or a small data holder) so Phase 2 can read them; don't wire them into `run_staging` now.

## Validation Architecture

> `workflow.nyquist_validation` is absent from `.planning/config.json` → treated as enabled. However, automated tests are explicitly deferred by user decision (AGENTS.md, REQUIREMENTS.md "Out of Scope", CONTEXT Deferred Ideas) — validation below is manual/acceptance-based, matching the repo's existing practice (TESTING.md).

### Test Framework

| Property | Value |
|----------|-------|
| Framework | None — zero automated tests (user-deferred); manual acceptance + smoke checks |
| Config file | none |
| Quick run command | `python -m py_compile SRC/gui/gui.py` (syntax gate, < 5 s) |
| Full suite command | `make gui` (builds `build/librocket.dll` + launches GUI) followed by the manual acceptance checklist |

### Phase Requirements → Acceptance Checks (manual)

| Req ID | Behavior | Check | Command |
|--------|----------|-------|---------|
| GUI-08 | Splash preserved | Splash shows first; LAUNCH fades into tabbed window | `make gui` |
| GUI-01 | 3 tabs, Results first | Window shows "Results" (active) / "Setup" / "Vehicle Configuration" tab bar | `make gui` |
| GUI-02 | Results surface | After Run: per-stage m0/mf/mp/ms/k_m/k_s/k_L/nu_e populated; ΔV field present (placeholder "—" acceptable) | `make gui` → click Run |
| GUI-03 | Geometry surface | Diameter/Length/Volume fields present per stage (placeholder until Phase 2) | `make gui` |
| GUI-04 | Export + indicator | "✔ Minimum confirmed" logic unchanged; Save Results writes a .txt with the same content as today (minus the removed ΔV input line) | run → Save → inspect file |
| GUI-05 | Mission inputs | Orbit height / payload mass / stage count editable in Setup; NO ΔV input anywhere in the UI | visual |
| GUI-06 | Diameter modes | 3 modes selectable; mode 3 ("user-specified") reveals the diameter input box; modes 1/2 hide it | visual |
| GUI-07 | Diameter input box | Value persists in the widget; passes to the stored config holder | visual |
| GUI-08 | Splash preserved | (same as GUI-08 above) | — |

### Sampling Rate
- Per task commit: `python -m py_compile SRC/gui/gui.py`
- Phase gate: full `make gui` + acceptance checklist + manual smoke run of `SRC/test_call.py` (unchanged bridge behavior)

### Wave 0 Gaps
- None — automated test infrastructure is explicitly deferred by user decision (AGENTS.md: "Automated tests are deferred — not part of the current work"); do NOT add pytest/UI-test tooling in this phase.

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| Python | GUI runtime | ✓ | 3.11.1 (`AppData\Local\Programs\Python\Python311`) | — |
| PyQt6 | GUI framework | ✓ | 6.11.0 (Qt 6.11.0) | — |
| gfortran (TDM-GCC-64) | building `librocket.dll` | ✓ | 10.3.0 | — |
| GNU make | `make gui` / `make all` | ✓ | chocolatey `make.exe` (also `mingw32-make.exe` in TDM bin) | `mingw32-make` |
| MinGW runtime DLLs (`libgfortran_64-5.dll` etc.) | DLL load at GUI import | ✓ (via `C:\TDM-GCC-64\bin`, exists; copied into `build/` by Makefile:168-174) | — | `MINGW_BIN` env var |
| `build/librocket.dll` | GUI import (`gui.py:57`) | ✗ (missing — only `.o`/`.mod` present) | — | **Not a blocker**: `make gui`/`make all` builds it; planner MUST include a build step before any GUI run |

**Missing dependencies with no fallback:** none (the only missing item is a build artifact with a one-command build path).

**Missing dependencies with fallback:** `build/librocket.dll` — build first via `make gui` (or `mingw32-make gui`).

Step 2.6 note: `node` is not on PATH in default PowerShell — required only for gsd-tools, not for the GUI itself (AGENTS.md documents the workaround).

## Security Domain

> `security_enforcement` absent from config → enabled. This is an offline, single-user desktop app with no network, no auth, no database, no secrets (CONCERNS.md "Security Considerations": none present).

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | no | N/A — no users, no accounts, offline desktop app |
| V3 Session Management | no | N/A |
| V4 Access Control | no | N/A — single-user local app |
| V5 Input Validation | yes | Widget-level constraints: `QDoubleSpinBox` ranges (payload 1.0–1,000,000 kg at `gui.py:756`; new orbit-height spinbox; diameter box), `QSpinBox` 1–3 stages (`gui.py:764`); no free-text input in the GUI (config.txt is NOT read by the GUI per D-14) |
| V6 Cryptography | no | N/A — no secrets, no encryption needs |

**Known threat patterns:** none material — the only external input surface (config.txt) is consumed by the Fortran standalone path, not the GUI. Keep new spinbox ranges bounded; no `eval`/`exec` on any user input (existing code already uses typed widgets only).

## Key Sources

### Primary (HIGH confidence — read in full this session)
- `SRC/gui/gui.py` (1028 lines) — entire widget inventory, splash, styling, bridge duplication, save/export, minimum indicator; line-referenced throughout this document.
- `SRC/interface/rocket_lib.py` (88 lines) — ctypes wrapper, argtypes, return dict.
- `SRC/interface/C_Interface.f90` (96 lines) — `run_staging` bind(C): globals set (40-42), arrays packed (57-66), eq-26 minimum check (70-90).
- `SRC/inout/Typical_Data.f90` — module globals (36-50), constants (3-5), diameter config check (802-813), config keys (855-947), Soyuz TEST CASE (824-832).
- `SRC/pre-simulation-calcs/Geometry_calc.f90` (106 lines) — statistical curves, diameter mode application (92-105), locals-only storage (⇒ geometry unavailable).
- `SRC/staging/Staging.f90` — per-stage `D_v` computation (139-142), `rm_L` read (86), nu_e (59).
- `SRC/staging/Rocket_Types.f90` — `Stage_t`/`Rocket_t` fields (D_v:19, Diameter:22, Length:23, rm_L:31).
- `SRC/staging/Stage_Optimization_Loop.f90` — ΔV iteration from `V_circ`/`orbit_height` (24-45, 88).
- `SRC/pre-staging-calcs/Orbit_calc.f90` — `V_circ` formula (9-10).
- `SRC/Main.f90` — standalone pipeline (8-17), printed surface (19-29, no geometry).
- `SRC/gui/typical_data_ranges.py` — `PROPELLANTS` (12), `CYCLES` (23), `TYPICAL_DATA_BY_STAGE = [None, STAGE_1, STAGE_2, STAGE_3]` (236).
- `SRC/config.txt` — canonical key names incl. `Diameter_setup` / `User_defined_diameter` (33-38).
- `SRC/Makefile` — `gui` target (201-204), hardcoded `MINGW_BIN` (52), runtime DLL copy (168-174).
- `SRC/test_call.py` — manual bridge smoke test.
- Planning: `01-CONTEXT.md` (D-01..D-14), `REQUIREMENTS.md` (GUI-01..08), `ROADMAP.md` (Phase 1), `ARCHITECTURE.md`, `STRUCTURE.md`, `CONVENTIONS.md`, `INTEGRATIONS.md`, `CONCERNS.md`, `STACK.md`, `TESTING.md`, `AGENTS.md`.

### Secondary (MEDIUM confidence)
- Qt stylesheet examples (QTabWidget/QTabBar selectors) — doc.qt.io; corroborated by stackoverflow.com/questions/38369015 and gist.github.com/espdev/4f1565b18497a42d317cdf2531b7ef05 (QSS selector syntax only; palette values are from the repo's own `STYLE`).

### Tertiary (LOW confidence)
- None — no external packages or unverifiable claims are relied upon.

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | PyQt6 `QTabWidget` API (`addTab`/`setCurrentIndex`/`currentChanged`) is stable and behaves as documented | Implementation Approaches | Low — Qt-stable API; compile/run check catches anything unusual in 5 s |
| A2 | The `QTabWidget::pane` / `QTabBar::tab[:selected|:hover]` QSS selectors apply as shown under Qt 6.11 | Domain Research (styling) | Low — visual only; adjustable at execution time |
| A3 | Interim ΔV feeding `run_staging` should be computed in Python from orbit height (1-line V_circ formula, `Orbit_calc.f90:9-10`) rather than a fixed placeholder constant | Open Question 1 | Medium — duplicates 1 line of physics temporarily; PIPE-02 purists may prefer a constant; needs discuss-phase confirmation |
| A4 | Mode-3 label "user-specified" (CONTEXT D-11) maps to Fortran mode 3 "Fairing requirement" (`Typical_Data.f90:809`) | Diameter Modes | Low — semantics identical (`Diameter_vector = User_defined_diameter`); only the label differs |
| A5 | Keeping the local `run_staging` copy in `gui.py` during Phase 1 (dedup deferred to FIX-02/Phase 3) | Dependencies & Risks | Low — duplicated code persists 2 phases; zero behavior change either way |
| A6 | Solver stays fast enough that blocking on the UI thread remains acceptable in Phase 1 | Dependencies & Risks | Low — existing behavior unchanged; QThread can be added later without layout impact |

## Open Questions (RESOLVED)

1. **Interim ΔV value while the pipeline is unwired (Phase 1).** D-10 removes the ΔV input, but `run_staging` requires `delta_v`.
   - What we know: `orbit_height` → `V_circ = sqrt(g_0*Radius²/(r·1000))` with `g_0=9.80665`, `Radius=6378` (`Orbit_calc.f90:9-10`, `Typical_Data.f90:3-5`); the full loss-inclusive ΔV only exists in `STAGING_LOOP` (Phase 2).
   - Options: (a) compute `V_circ` in Python from the orbit-height field (1-line interim duplicate, marked for removal in Phase 2); (b) pass a fixed placeholder constant (e.g. 10.0 as today's default); (c) show a read-only "ΔV (auto)" label either way.
   - Recommendation: (a) + (c) — makes the mission inputs real now and Phase-2-swappable; flag in discuss phase since it touches the "no physics in Python" principle (PIPE-02 binds Phase 2 formally).
   - RESOLVED: option (a) + (c) adopted — `_auto_delta_v()` interim, marked for Phase 2 removal (01-02-T1).
2. **Per-stage ΔV display in Phase 1: placeholder vs Python-derived.** `D_v = nu_e·ln(m0/mf)` (`Staging.f90:141`) is derivable from already-returned values.
   - Recommendation: placeholder "—" (user-approved partial population) unless the user prefers the interim derivation; document the choice in the plan.
   - RESOLVED: placeholder "—" (user-approved partial population), rendered in 01-03-T1.
3. **QThread for the solver call.** Discretion item. Recommendation: keep blocking (existing behavior, fast solver); remove the dead `QThread` import or leave it — planner's call.
   - RESOLVED: keep blocking per A6; no threading machinery this phase (01-01-T1).
4. **Results layout: cards vs table.** Discretion item. Recommendation: keep `ResultCard` grid (existing pattern) and add the 3 new fields (ΔV, diameter, length, volume) as extra grid rows — smallest diff, consistent look.
   - RESOLVED: ResultCard grid kept, extended by 2 rows (01-03-T1).