# Phase 2: Full Pipeline Exposure - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-08-15
**Phase:** 2-full-pipeline-exposure
**Areas discussed:** ΔV computation & label source

---

## ΔV computation & label source

### Question 1: What should the Setup label / export line / filename display?

| Option | Description | Selected |
|--------|-------------|----------|
| Converged staging ΔV | Rocket%delta_v after STAGING_LOOP converges (V_circ + DV_loss losses); label, Results, export all shift together | |
| V_circ on label, converged internally | Label stays pure V_circ (matches current GUI); solver converges internally with losses; label ≠ staged ΔV | ✓ |

**User's choice:** V_circ on label, converged internally
**Notes:** User preferred keeping the display contract the GUI already UAT-verified rather than changing what the user sees in Setup.

### Question 2: Should ctypes run full STAGING_LOOP?

| Option | Description | Selected |
|--------|-------------|----------|
| Yes — STAGING_LOOP | Full physics: thrust + DV_loss iteration to 1e-6 convergence, matches console path | ✓ |
| No — keep single STAGING | Fastest but loses gravity/atmo loss iteration | |

**User's choice:** Yes — use STAGING_LOOP
**Notes:** Chose the recommended option; the single-solve stub is replaced.

### Question 3: What should the exported Delta-V line / filename use?

| Option | Description | Selected |
|--------|-------------|----------|
| Export V_circ, matching label | Keeps UAT-verified contract (label == Delta-V line == filename); only per-stage Results rows show converged losses | ✓ |
| Export converged ΔV | Export reflects real losses while label differs | |

**User's choice:** Export V_circ, matching label
**Notes:** Consistent with Q1 — the export contract stays unified with the label.

### Question 4: Per-stage ΔV source for Results rows?

| Option | Description | Selected |
|--------|-------------|----------|
| Per-stage from converged run | From converged STAGING_LOOP output, loss-inclusive, internally consistent | ✓ |
| Per-stage proportional to V_circ | Matches label rather than physics | |

**User's choice:** Per-stage from converged run
**Notes:** Physics wins for the per-stage rows; only the top-level label/export keep V_circ.

### Question 5: Where does the label's V_circ value come from?

| Option | Description | Selected |
|--------|-------------|----------|
| From Fortran orbit calc | Pipeline exposes orbit_speed_calculator's V_circ; _auto_delta_v() mirror removed as planned | ✓ |
| Keep the Python mirror | Same value, duplicated source | |

**User's choice:** From Fortran orbit calc
**Notes:** Single source of truth; honors the "marked for removal" note on gui.py:1002.

---

## the agent's Discretion

- bind(C) signature layout for the full-pipeline entry (parameter/array packing)
- Replace vs keep alongside `run_staging`; dedup (FIX-02) is Phase 3 but GUI wiring may remove the inline duplicate naturally
- Whether thrust metrics surface in the GUI or only drive the loop
- How Vehicle Configuration diameter mode/value flows into `rocket_geometry_calculation`
- ISP/k_s source for the pipeline (sliders vs propellant/ox tables) — unresolved this session, noted as deferred

## Deferred Ideas

- **ISP/k_s authority (sliders vs tables)** — unresolved; relevant given FIX-05 (Soyuz TEST CASE override, Typical_Data.f90:824-832)
- FIX-02 bridge dedup → Phase 3
- FIX-03 hardcoded MinGW path → Phase 3