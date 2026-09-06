---
phase: 1
slug: centralized-3-tab-gui
status: verified
threats_open: 0
asvs_level: 1
created: 2026-08-15
---

# Phase 1 — Security

> Per-phase security contract: threat register, accepted risks, and audit trail.

---

## Trust Boundaries

| Boundary | Description | Data Crossing |
|----------|-------------|---------------|
| GUI -> filesystem (Save Results) | User picks path via native dialog; app writes text export to exact path | File path + numeric spinbox-derived filename; no free-text input |
| GUI -> librocket.dll (ctypes) | DLL loaded at import from build/ (gui.py:57); MinGW path hardcoded (FIX-03 -> Phase 3) | Compiled Fortran solver call with numeric args only |
| GUI numeric inputs | Spinboxes only; no free-text entry in the app | Structured numeric values (height, payload, ISP, k_s) |
| GUI -> Fortran bridge (run_staging) | Spinbox values cross into ctypes call and export filename | Numeric payload/delta-v/ISP/k_s values |
| GUI inputs -> Phase 2 | Stored diameter_mode int 1/2/3 + diameter value, handoff state, not wired to Fortran this phase | Integer mode + float diameter |
| test_call.py -> interface/rocket_lib.py | Import path constructed from `__file__` (repo-local); no user input involved | Python import resolution |
| rocket_lib.py -> build/librocket.dll | Module-level ctypes.CDLL load; DLL provenance not validated (FIX-03, Phase 3) | Compiled Fortran shared library load |
| Fortran solver internal state | Rocket_t struct contents (incl. rm_L) flow into Staging.f90 mass computation | Struct member values from GUI |
| GUI display <- bridge dict | Untrusted-ish data source: cards format whatever run_staging returns | Bridge dict output from Fortran |

---

## Threat Register

| Threat ID | Category | Component | Severity | Disposition | Mitigation | Status |
|-----------|----------|-----------|----------|-------------|------------|--------|
| T-01-01 | Tampering | _print_results export path | low | mitigate | Writes only to the path returned by QFileDialog.getSaveFileName; default filename built from validated numeric spinbox values only; no free-text path input exists anywhere in the GUI (ASVS V5) | closed |
| T-01-02 | Tampering | ctypes DLL load (gui.py:57) | medium | accept | Hardcoded MinGW search + DLL load are FIX-03 (Phase 3); Phase 1 must NOT modify gui.py:22-59. Guard note: future phase validates DLL provenance before load | closed |
| T-01-03 | Denial of Service | blocking solver call (_run) | low | accept | Solver is fast (bisection, <=50 iterations); blocking is deliberate (A6); no QThread wiring this phase; single-user local app | closed |
| T-01-SC | Tampering | package installs | low | accept | No new packages — PyQt6 6.11.0 already installed; Package Legitimacy Audit N/A (RESEARCH:289) | closed |
| T-02-01 | Tampering | orbit_height / diameter_spin bounds | low | mitigate | Ranges enforced at construction (100-2000 km; 0.5-20 m; ASVS V5); GUI has zero free-text numeric inputs; no eval/exec of user data anywhere | closed |
| T-02-02 | Tampering | _auto_delta_v() interim physics mirror | low | accept | One-line V_circ duplicate of Orbit_calc.f90:9-10 with constants cited from Typical_Data.f90:3-5; documented interim, removed at PIPE-01 (Phase 2); drift risk bounded by the docstring marker | closed |
| T-02-03 | Tampering | ctypes DLL load (gui.py:57) | medium | accept | FIX-03 (Phase 3) removes the hardcoded MinGW resolution; Phase 1 does not touch gui.py:22-59 (diff guard) | closed |
| T-02-SC | Tampering | package installs | low | accept | No new packages; PyQt6 6.11.0 already installed; Package Legitimacy Audit N/A | closed |
| T-03-01 | Tampering | _print_results export path | low | mitigate | Writes only to the QFileDialog-picked path; default name from numeric spinbox values; no free-text path construction; idempotent (dialog re-opens per save, ASVS V5) | closed |
| T-03-02 | Denial of Service | blocking solver call | low | accept | Deliberate (A6): fast solver, single-user desktop; no spinner/skeleton exists or is intended (UI-SPEC loading row) | closed |
| T-03-03 | Tampering | placeholder integrity | low | mitigate | "-" placeholders via data.get() defaults; no Python-side ΔV/geometry computation (PIPE-02); prevents fabricated results from being mistaken for physics output | closed |
| T-03-04 | Tampering | ctypes DLL load (gui.py:57) | medium | accept | FIX-03 (Phase 3) — guard note only; Phase 1 diff guard keeps gui.py:22-59 untouched | closed |
| T-03-SC | Tampering | package installs | low | accept | No new packages; PyQt6 already installed; Package Legitimacy Audit N/A | closed |
| T-01-04-01 | Information Disclosure | uninitialized Rocket%rm_L read at Staging.f90:86/106 (ctypes path) | medium | mitigate | rm_L assigned before call STAGING with the console-identical formula; default-init = 0.d0 on the component so any future path that forgets it degrades to 0, never undefined stack bytes | closed |
| T-01-04-02 | Tampering | payload_mass module global (shared console/ctypes value source) | low | accept | Single-process local app; written only from the run_staging entry (C_Interface.f90:41) with GUI spinbox values; no untrusted input surface (no free-text input exists) | closed |
| T-01-04-03 | Denial of Service | NaN propagation into GUI render path | low | mitigate | Root cause eliminated (defined rm_L); gui.py:573 NaN guard remains as display-level backstop | closed |
| T-01-04-SC | Tampering | package installs | low | accept | No new packages — gfortran and PyQt6 already installed; Package Legitimacy Audit N/A | closed |
| T-01-05-01 | Tampering | test_call.py sys.path.insert | low | mitigate | Insert only the repo-local interface/ dir derived from __file__ (gui.py:29 pattern); no environment/CWD-derived path component, so no path-injection surface | closed |
| T-01-05-02 | Tampering | ctypes DLL load (rocket_lib.py:22) | medium | accept | Pre-existing documented machine blocker (DLL absent at rest); same acceptance as T-01-02 (plan 01-01) — provenance validation deferred to FIX-03 (Phase 3) | closed |

*Status: open · closed · open — below high threshold (non-blocking)*
*Severity: critical > high > medium > low — only open threats at or above workflow.security_block_on count toward threats_open*
*Disposition: mitigate (implementation required) · accept (documented risk) · transfer (third-party)*

---

## Accepted Risks Log

| Risk ID | Threat Ref | Rationale | Accepted By | Date |
|---------|------------|-----------|-------------|------|
| AR-01-01 | T-01-02 | DLL provenance not validated this phase; gui.py:22-59 untouched per diff guard; FIX-03 (Phase 3) adds validation | phase plan threat model | 2026-08-15 |
| AR-01-02 | T-01-03 | Solver is fast (bisection, ≤50 iterations); blocking is deliberate design (A6); single-user local desktop app, no QThread this phase | phase plan threat model | 2026-08-15 |
| AR-01-03 | T-01-SC | No new packages introduced; PyQt6 6.11.0 already installed; Package Legitimacy Audit N/A | phase plan threat model | 2026-08-15 |
| AR-01-04 | T-02-02 | One-line V_circ duplicate of Orbit_calc.f90:9-10 with constants cited from Typical_Data.f90:3-5; documented interim, removed at PIPE-01 (Phase 2) | phase plan threat model | 2026-08-15 |
| AR-01-05 | T-02-03 | FIX-03 (Phase 3) removes hardcoded MinGW resolution; Phase 1 does not touch gui.py:22-59 (diff guard) | phase plan threat model | 2026-08-15 |
| AR-01-06 | T-02-SC | No new packages; PyQt6 6.11.0 already installed; Package Legitimacy Audit N/A | phase plan threat model | 2026-08-15 |
| AR-01-07 | T-03-02 | Deliberate (A6): fast solver, single-user desktop; no spinner/skeleton exists or is intended (UI-SPEC loading row) | phase plan threat model | 2026-08-15 |
| AR-01-08 | T-03-04 | FIX-03 (Phase 3); Phase 1 diff guard keeps gui.py:22-59 untouched | phase plan threat model | 2026-08-15 |
| AR-01-09 | T-03-SC | No new packages; PyQt6 already installed; Package Legitimacy Audit N/A | phase plan threat model | 2026-08-15 |
| AR-01-10 | T-01-04-02 | Single-process local app; written only from run_staging entry with GUI spinbox values; no untrusted input surface | phase plan threat model | 2026-08-15 |
| AR-01-11 | T-01-04-SC | No new packages — gfortran and PyQt6 already installed; Package Legitimacy Audit N/A | phase plan threat model | 2026-08-15 |
| AR-01-12 | T-01-05-02 | Pre-existing documented machine blocker; provenance validation deferred to FIX-03 (Phase 3) | phase plan threat model | 2026-08-15 |

*Accepted risks do not resurface in future audit runs.*

---

## Security Audit Trail

| Audit Date | Threats Total | Closed | Open | Run By |
|------------|---------------|--------|------|--------|
| 2026-08-15 | 19 | 19 | 0 | opencode/gsd-secure-phase (L1 short-circuit) |

---

## Sign-Off

- [x] All threats have a disposition (mitigate / accept / transfer)
- [x] Accepted risks documented in Accepted Risks Log
- [x] `threats_open: 0` confirmed
- [x] `status: verified` set in frontmatter

**Approval:** verified 2026-08-15
