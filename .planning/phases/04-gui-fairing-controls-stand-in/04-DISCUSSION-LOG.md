# Phase 4: GUI Fairing Controls (Stand-in) - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-09-17
**Phase:** 4-GUI Fairing Controls (Stand-in)
**Areas discussed:** Fairing Mode UI Layout, Fairing ↔ Body Mode Constraints, Mock Fairing Data Computation, Fairing User Input Widget, Hammer-Head Body Behavior, Results Export Integration, Fairing Formulas, Diagram Coordinate System, Mock Diagram Timing

---

## Fairing Mode UI Layout

| Option | Description | Selected |
|--------|-------------|----------|
| A: Separate group box below body modes | Clear visual separation | |
| B: Side-by-side horizontal split (body left, fairing right) | Equal visual weight | ✓ |
| C: Nested — fairing appears only when certain body mode selected | Conditional visibility | |

**User's choice:** B (side-by-side)
**Notes:** Weighted 60/40 (body/fairing); fairing group hidden until body mode selected; header labels "Body" and "Fairing" above each group

---

## Fairing ↔ Body Mode Constraints

| Option | Description | Selected |
|--------|-------------|----------|
| A: Independent — any fairing + any body mode (9 combos) | Full flexibility | |
| B: Constrained — Hammer-Head requires Constant body; User-specified fairing requires User-specified body | Logical coupling | ✓ (refined) |
| C: Auto-coupled — fairing selection adjusts body mode | Strong coupling | |

**User's choice:** B (refined to detailed matrix)
**Notes:** Final constraint matrix:
- Statistical body → Constant (same), Tapered (user ≤ last stage body D)
- Constant body → Constant (same), Hammer-Head (user ≥ body D)
- User-specified body → Constant (same)
- Tapered: user-specified fairing ≤ last stage body diameter
- Hammer-Head: user-specified fairing ≥ body diameter
- FAIR-02 deferred to v2+

---

## Mock Fairing Data Computation

| Option | Description | Selected |
|--------|-------------|----------|
| A: Simple ratios | Constant: fairing = body; User: body = fairing; Hammer-Head: 1.5×body | |
| B: Port Fortran formulas | Copy ogive/conic math from Geometry_calc.f90 | ✓ |
| C: Placeholder values | Fixed offsets (fairing_D = body_D + 0.5) | |

**User's choice:** B
**Notes:** Standard aerospace formulas: ogive length = 3×D, volume ≈ 0.75×π/4×D²×L, boat-tail 5°–15° for Hammer-Head; realistic mock for diagram/export

---

## Fairing User Input Widget

| Option | Description | Selected |
|--------|-------------|----------|
| A: QDoubleSpinBox with unit suffix ("m"), visible only in User-specified fairing mode | Dedicated per-mode control | ✓ |
| B: Shared spinbox | Label changes based on mode | |
| C: Inline spinbox under each radio | Like current body User-specified | |

**User's choice:** A
**Notes:** Conditional spinbox with "m" suffix; min/max validation per constraint; tooltip on violation

---

## Hammer-Head Body Behavior

| Option | Description | Selected |
|--------|-------------|----------|
| A: Body uses mode 2 (Constant = max statistical) while fairing user-defined | Lock to Constant body | ✓ |
| B: Body uses mode 1 (Statistical) while fairing user-defined | Statistical body | |
| C: Body locks to mode 2 automatically when Hammer-Head selected | Auto-couple | |

**User's choice:** A
**Notes:** Hammer-Head = Constant body + user-specified fairing ≥ body D; no new body behavior needed

---

## Results Export Integration

| Option | Description | Selected |
|--------|-------------|----------|
| A: New section "Fairing Geometry" after stage data | Clean separation | ✓ |
| B: Extend stage rows | Add fairing columns | |
| C: Separate block at end | Separation from body data | |

**User's choice:** A
**Notes:** New "Fairing Geometry" section per stage (diameter, length, volume)

---

## Fairing Formulas (not in Fortran — new for v1.1 mock)

| Option | Description | Selected |
|--------|-------------|----------|
| A: Simple ratios | Fixed multipliers | |
| B: Port Fortran formulas | Copy ogive/conic math | ✓ |
| C: Placeholder | Fixed offsets | |

**User's choice:** B
**Notes:** Ogive length = 3×D, volume ≈ 0.75×π/4×D²×L, boat-tail 5°–15°; references NASA SP-8037, TU Delft notes

---

## Diagram Coordinate System

| Option | Description | Selected |
|--------|-------------|----------|
| True-scale | 1:1 meter:pixel (scaled to fit) | ✓ |
| Schematic | Fixed height, variable width | |

**User's choice:** True-scale

---

## Mock Diagram Timing

| Option | Description | Selected |
|--------|-------------|----------|
| Show immediately | Display mock diagram using current body + mock fairing | ✓ |
| After analysis | Only show after run completes | |

**User's choice:** Show immediately

---

## the agent's Discretion

- Exact ogive/conic formula constants in Python mock (3×D length, 0.75 volume factor, 10° boat-tail)
- Exact validation error messaging (tooltip vs inline)
- Fairing mode radio labels wording

---

## Deferred Ideas

- Fortran fairing implementation (v2+): `Fairing_t` type, `fairing_setup` enum, ogive/conic in `Geometry_calc.f90`, ctypes bridge extension
- FAIR-02 (User-specified fairing with body adjustment): deferred to v2+
- Boat-tail geometry visualization (v1.2+): diagram enhancement
- Automated tests: deferred by user
- FIX-04/05/06: out of current scope