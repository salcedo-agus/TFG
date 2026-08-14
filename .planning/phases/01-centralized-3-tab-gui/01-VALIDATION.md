---
phase: 01-centralized-3-tab-gui
status: gap_closure
validation_dimensions:
  - per-task automated verifies
  - differential gates vs console path
  - wave sampling
  - manual acceptance (GUI human checks)
---

# Phase 01: Centralized 3-Tab GUI — Validation Architecture

**Status:** gap_closure — plans 01-04 (G-01-2, rm_L init) and 01-05 (G-01-4, test_call import) closing the two UAT gaps.
**Modeled on:** RESEARCH.md "Validation Architecture" — no automated test framework (user-deferred); validation is acceptance/smoke-based, matching the repo's existing practice (TESTING.md).

## Validation Posture

`workflow.nyquist_validation` is absent from `.planning/config.json` → treated as enabled. However, automated tests are explicitly deferred by user decision (AGENTS.md, REQUIREMENTS.md "Out of Scope", CONTEXT Deferred Ideas) — so per-task verification in the gap-closure plans is runnable with the existing toolchain only (gfortran make targets, Python stdlib), not a test framework. Each task in 01-04 / 01-05 carries a concrete `<automated>` verify; heavier gates (console differential, GUI human check) are phase-level and documented below.

## Test Framework

| Property | Value |
|----------|-------|
| Framework | None — zero automated tests (user-deferred); manual acceptance + smoke checks |
| Config file | none |
| Quick run command | `python -m py_compile SRC/test_call.py` (syntax gate, < 5 s) |
| Fortran gate | `make all` in SRC/ (gfortran -O2 -Wall, relinks build/librocket.dll) |
| Bridge smoke | `python SRC/test_call.py` (import resolution from any CWD + finite masses) |
| GUI acceptance | `make gui` + UAT manual checklist (tests 1, 2, 3, 5) |

## How the Gap-Closure Plans Satisfy Validation

### Per-task automated verifies

- **01-05-T1 (import fix):** `python -m py_compile SRC/test_call.py`, then `python SRC/test_call.py` run from BOTH the repo root and SRC/ — the rocket_lib ModuleNotFoundError must be gone in both CWDs; the only acceptable residual failure is the documented DLL-load error (OSError naming librocket.dll — machine blocker per STATE.md, NOT an import defect).
- **01-05-T2 (docs):** PowerShell Select-String gate — `.planning\codebase\TESTING.md` no longer contains "must be run from SRC/", and the replacement line mentions both `interface/` and `build/librocket.dll`.
- **01-04-T1 (rm_L init):** `make all` in SRC/ compiles clean under -O2 -Wall and relinks build/librocket.dll; `python SRC/test_call.py` (requires 01-05's import fix) prints finite per-stage masses — m0/mp/ms/k_L real numbers, no nan/inf; stage-1 m0 strictly greater than 5427.5 (= rm_L for payload 5000).
- **01-04-T2 (default init, defense-in-depth):** `make all` recompiles the dependent cascade (Rocket_Types → Typical_Data/Staging/C_Interface) clean; `python SRC/test_call.py` output unchanged vs T1 — the default init must not alter T1's explicit assignment.

### Differential gates vs console path

- **01-04 Gate C:** `make fortran` in SRC/ — console output unchanged vs known-good pre-fix values; console-path files (Main.f90, Payload_Mass_calc.f90, Staging.f90, Typical_Data.f90, Makefile) zero-diff by construction, enforced by the plan's diff guard.
- **01-04 formula identity:** the ctypes path applies the byte-identical rm_L formula (payload + 0.0755*payload + 50, Payload_Mass_calc.f90:12/19) so console and GUI masses agree numerically.
- **01-05 zero-diff bridge:** `SRC/gui/gui.py` (gui.py:22-110) and `SRC/interface/rocket_lib.py` untouched — behavior unchanged by construction, verified by the plan's diff guard.

### Wave sampling

- **Wave 1 (01-05):** sampled per task commit — py_compile + two-CWD run for T1, Select-String gates for T2.
- **Wave 2 (01-04):** sampled per task commit — `make all` + bridge smoke after T1; identical smoke re-run after T2 (combined gate proving T2 does not alter T1's behavior).
- **End of phase:** 01-04 Gate D (GUI human check: `make gui` → Run with valid combo → Results shows real finite masses, no "—" for m0/mf/mp/ms/k_L) restores UAT Test 2's truth; the post-rebuild `python SRC/test_call.py` full pass completes UAT Test 4's truth ("Bridge smoke passes").

## Sampling Rate

- Per task commit: the task's own `<automated>` verify (all < 60 s).
- Phase gate: UAT re-test of tests 2 and 4 (the two gap sources) plus regression re-checks of tests 1, 3, 5.

## Wave 0 Gaps

- None — automated test infrastructure is explicitly deferred by user decision (AGENTS.md); do NOT add pytest/UI-test tooling in the gap-closure plans.