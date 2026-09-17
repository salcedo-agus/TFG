# Architecture Patterns

**Domain:** Multi-stage launch vehicle design tool (TFG v1.1)
**Researched:** 2026-09-17

## Recommended Architecture

```
┌─────────────────────────────────────────────────────────────────────┐
│                        PYTHON GUI LAYER                             │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────────────────────┐  │
│  │   Results   │  │    Setup    │  │   Vehicle Configuration     │  │
│  │     Tab     │  │     Tab     │  │           Tab               │  │
│  │             │  │             │  │  ┌───────────────────────┐  │  │
│  │ ResultCard[]│  │ Mission +   │  │  │  Diameter Mode Radios │  │  │
│  │             │  │ Stage Inputs│  │  │  Fairing Mode Radios  │  │  │
│  │             │  │             │  │  │  User Diameter Inputs │  │  │
│  │             │  │             │  │  │  ───────────────────  │  │  │
│  │             │  │             │  │  │  Rocket Diagram View  │  │  │
│  │             │  │             │  │  │  (QGraphicsView)      │  │  │
│  │             │  │             │  │  └───────────────────────┘  │  │
│  └──────┬──────┘  └──────┬──────┘  └──────────────┬────────────┘  │
│         │                │                        │                │
│         └────────────────┼────────────────────────┘                │
│                          ▼                                         │
│              ┌───────────────────────┐                             │
│              │   run_full_pipeline   │  (single ctypes entry)      │
│              │   rocket_lib.py       │                             │
│              └───────────┬───────────┘                             │
└──────────────────────────┼─────────────────────────────────────────┘
                           │ ctypes
                           ▼
┌─────────────────────────────────────────────────────────────────────┐
│                      FORTRAN CORE (librocket.dll)                   │
│  ┌─────────────────────────────────────────────────────────────┐   │
│  │  run_full_pipeline (C_Interface.f90)                        │   │
│  │    ├── Payload_Mass_calculator  (sets Rocket%rm_L)          │   │
│  │    ├── orbit_speed_calculator   (sets V_circ)               │   │
│  │    ├── STAGING_LOOP             (bisection on mass ratios)  │   │
│  │    └── rocket_geometry_calculation                           │   │
│  │         ├── Body diameter: statistical / constant / user    │   │
│  │         └── NEW: Fairing diameter logic (see below)         │   │
│  └─────────────────────────────────────────────────────────────┘   │
│                          │                                          │
│         ┌────────────────┼────────────────┐                        │
│         ▼                ▼                ▼                        │
│  ┌─────────────┐ ┌─────────────┐ ┌─────────────┐                  │
│  │Rocket_Types │ │Typical_Data │ │ Geometry/   │                  │
│  │  (Stage_t,  │ │ (config,    │ │ Thrust calc │                  │
│  │  Rocket_t)  │ │  ISP/k_s    │ │             │                  │
│  └─────────────┘ └─────────────┘ └─────────────┘                  │
└─────────────────────────────────────────────────────────────────────┘
```

### Component Boundaries

| Component | Responsibility | Communicates With |
|-----------|---------------|-------------------|
| `gui.py` (MainWindow) | Tab orchestration, input validation, result display, diagram rendering | `rocket_lib.py` (ctypes), `StageInputWidget`, `ResultCard`, `RocketDiagramView` (NEW) |
| `rocket_lib.py` | ctypes bridge, data marshalling Python↔Fortran | `librocket.dll` (C_Interface), `gui.py` |
| `C_Interface.f90` | Fortran entry point, pipeline orchestration, result packing | `rocket_lib.py`, `Rocket_Types`, `Typical_Data`, `Geometry_calc` |
| `Geometry_calc.f90` | Body + fairing diameter/length/volume computation | `C_Interface`, `Rocket_Types`, `Typical_Data` (globals) |
| `Rocket_Types.f90` | Data structures (`Stage_t`, `Rocket_t`) | All Fortran modules |
| `RocketDiagramView` (NEW, Python) | SVG/Qt rocket visualization from stage geometry | `gui.py` (Vehicle tab), consumes `results["stages"]` |

### Data Flow

```
GUI Inputs (Setup + Vehicle tabs)
    │
    ├── Mission: orbit_height, payload_mass, n_stages
    ├── Per-stage: ISP, k_s, propellant_index
    ├── Body diameter_mode: 1=statistical, 2=constant, 3=user_body
    ├── Body user_diameter (if mode 3)
    ├── Fairing mode: 1=none/body, 2=fairing_const, 3=fairing_user, 4=hammer_head
    └── Fairing user_diameter (if mode 3 or 4)
    │
    ▼
rocket_lib.run_full_pipeline()  ←─ EXTENDED with fairing params
    │
    ▼
Fortran: run_full_pipeline()
    │
    ├── Sets globals: diameter_setup, user_defined_diameter
    ├── NEW: Sets fairing globals: fairing_mode, fairing_user_diameter
    ├── Payload_Mass_calculator → Rocket%rm_L
    ├── orbit_speed_calculator → V_circ
    ├── STAGING_LOOP → stage masses, ratios, ΔV
    ├── rocket_geometry_calculation:
    │   ├── Computes body Diameter_vector[1..n] per diameter_setup
    │   ├── NEW: Computes fairing Diameter_fairing[1..n] per fairing_mode
    │   ├── Computes Length_vector = Volume * 4 / (π * Diameter²)
    │   └── Stores body Diameter, Length in Rocket%stage(i)
    │       NEW: Stores fairing_diameter in Rocket%stage(i)%FairingDiameter
    │
    ▼
Returns: {stages[{m0,mf,mp,ms,k_m,k_s,k_L,nu_e,dv, diameter, length, volume, 
                  NEW: fairing_diameter}], total_m0, v_circ, minimum_found}
    │
    ▼
GUI: ResultCard updated, NEW RocketDiagramView renders body+fairing profile
```

## Patterns to Follow

### Pattern 1: Extend ctypes Bridge with Backward-Compatible Signature
**What:** Add new optional parameters to `run_full_pipeline` at the end of argtypes; Fortran side uses `OPTIONAL` or new globals with defaults.
**When:** Adding fairing configuration without breaking existing GUI or config.txt path.
**Example:**
```python
# rocket_lib.py — extend argtypes (append only)
lib.run_full_pipeline.argtypes = [
    # ... existing 22 args ...
    ctypes.POINTER(ctypes.c_int),    # fairing_mode (NEW, appended)
    ctypes.POINTER(ctypes.c_double), # fairing_user_diameter (NEW, appended)
]
```

```fortran
! C_Interface.f90 — add OPTIONAL args or new globals with defaults
subroutine run_full_pipeline(..., fairing_mode_in, fairing_user_diameter_in) bind(C)
    integer(c_int), intent(in), optional :: fairing_mode_in
    real(c_double), intent(in), optional :: fairing_user_diameter_in
    ! Default: fairing_mode = 1 (no fairing / fairing = body)
    fairing_mode = merge(1, fairing_mode_in, present(fairing_mode_in))
```

### Pattern 2: Fairing Geometry as Stage Extension
**What:** Add `FairingDiameter` to `Stage_t` type; compute in `rocket_geometry_calculation` alongside body diameter.
**When:** Fairing diameter is per-stage (hammer-head may vary by stage) and must return to GUI for diagram.
**Example:**
```fortran
! Rocket_Types.f90
type Stage_t
    ! ... existing fields ...
    real(8) FairingDiameter  ! NEW: 0 = no fairing / same as body
end type Stage_t
```

### Pattern 3: Diagram Rendering as Separate Widget
**What:** `RocketDiagramView` (QGraphicsView-based) that takes stage geometry array and paints body + fairing outline.
**When:** Vehicle Config tab needs post-analysis visualization; keeps rendering logic out of `MainWindow`.
**Example:**
```python
# gui.py — new widget
class RocketDiagramView(QGraphicsView):
    def set_stages(self, stages: list[dict]):  # stages from results["stages"]
        # stages[i] has: diameter, length, volume, fairing_diameter
        scene = QGraphicsScene()
        y = 0
        for s in stages:
            # Draw body rectangle
            body = QGraphicsRectItem(0, y, s["diameter"]*scale, s["length"]*scale)
            # Draw fairing if different
            if s.get("fairing_diameter", 0) > s["diameter"]:
                fairing = QGraphicsPolygonItem(...)  # ogive/nose cone
            y += s["length"]*scale + gap
        self.setScene(scene)
```

### Pattern 4: Diameter/Fairing Mode Separation in GUI
**What:** Vehicle tab has two radio groups: "Body Diameter Mode" (existing 3) + "Fairing Mode" (NEW 4).
**When:** User must configure body and fairing independently; hammer-head requires both.
**Example:**
```python
# gui.py — _build_vehicle_tab()
# Body diameter mode (existing)
self.body_mode_group = QButtonGroup()
# 1: Statistical, 2: Constant, 3: User-specified body

# Fairing mode (NEW)
self.fairing_mode_group = QButtonGroup()
# 1: None (fairing = body), 2: Constant (fairing = body), 
# 3: User-specified fairing (body adjusts), 4: Hammer-Head
```

## Anti-Patterns to Avoid

### Anti-Pattern 1: Overloading `diameter_setup` for Fairing
**What:** Reusing the existing `diameter_setup` (1/2/3) to encode fairing modes.
**Why bad:** Conflates body sizing with fairing sizing; breaks config.txt compatibility; makes hammer-head impossible (needs both body mode + fairing mode).
**Instead:** Separate `fairing_mode` global + ctypes parameter; body and fairing configured independently.

### Anti-Pattern 2: Computing Fairing in Python Only
**What:** Send body diameter to GUI, compute fairing diameter in Python for display only.
**Why bad:** Fairing affects vehicle geometry (length, volume, mass) which must feed back into staging solver for consistency; Fortran owns the physics pipeline.
**Instead:** Compute fairing geometry in Fortran `rocket_geometry_calculation`; return `FairingDiameter` per stage.

### Anti-Pattern 3: Matplotlib Embedding for Simple Diagrams
**What:** Embed `matplotlib.figure` in Qt via `FigureCanvasQTAgg` for rocket diagram.
**Why bad:** Heavy dependency; slow startup; overkill for 2D schematic; clashes with dark QSS theme.
**Instead:** Use `QGraphicsView` + `QGraphicsScene` with `QGraphicsRectItem`/`QGraphicsPolygonItem` — native, fast, themeable, no extra deps.

### Anti-Pattern 4: Rebuilding Vehicle Tab on Every Run
**What:** Clear and rebuild the Vehicle Config tab layout after analysis to show diagram.
**Why bad:** Loses user's mode selections; flicker; violates "widgets never rebuilt" pattern established in Phase 1.
**Instead:** Add `RocketDiagramView` as a permanent widget (hidden until results exist); call `set_stages(results["stages"])` on successful run.

## Scalability Considerations

| Concern | Current (3 stages) | With Fairing + Diagrams |
|---------|-------------------|------------------------|
| ctypes args | 22 pointers | 24 pointers (append-only) |
| Fortran globals | ~15 | +2 (fairing_mode, fairing_user_diameter) |
| Stage_t size | 24 fields | 25 fields (+FairingDiameter) |
| GUI widgets | ~50 | +1 QGraphicsView + 4 fairing radios |
| Diagram render | N/A | O(n_stages) — trivial (< 1ms) |

No architectural scaling concerns — all changes are additive and local.

## Sources

- `SRC/gui/gui.py` — MainWindow, tabs, Vehicle Config tab, ctypes call site
- `SRC/interface/rocket_lib.py` — ctypes bridge signature, result dict structure
- `SRC/interface/C_Interface.f90` — Fortran entry point, pipeline order, result packing
- `SRC/pre-simulation-calcs/Geometry_calc.f90` — Diameter_setup logic (cases 1/2/3), Volume/Length computation
- `SRC/staging/Rocket_Types.f90` — Stage_t, Rocket_t type definitions
- `SRC/inout/Typical_Data.f90` — Config parser, diameter_setup/user_defined_diameter globals, combustion cycle bug (lines 924-930)