---
phase: 02
slug: full-pipeline-exposure
status: verified
threats_open: 0
asvs_level: 1
created: 2026-09-06
---

# Phase 02 — Security

> Per-phase security contract: threat register, accepted risks, and audit trail.

---

## Trust Boundaries

| Boundary | Description | Data Crossing |
|----------|-------------|---------------|
| Python (rocket_lib.py) → Fortran DLL | ctypes call boundary; scalar/array buffers cross it per the argtypes contract — a mismatched signature corrupts memory instead of raising | ISP/k_s/diameter/spinbox numerics; propellant indices (1-8) |
| Repo → build/librocket.dll | DLL loaded from the local build/ dir by absolute path | Compiled binary from local source |
| GUI event loop → rocket_lib.run_full_pipeline | Untrusted-ish input (spinbox/combobox values) crosses into the Fortran DLL; scalar/array buffers per the 02-01 contract | orbit/payload/stage-count/diameter values |
| Fortran results → GUI display / export | Bridge return dict is rendered and written to a user-picked .txt path | Design numbers (masses, ΔV, geometry), label/export/filename |

---

## Threat Register

| Threat ID | Category | Component | Severity | Disposition | Mitigation | Status |
|-----------|----------|-----------|----------|-------------|------------|--------|
| T-02-01 | Tampering | build/librocket.dll load path | medium | mitigate | DLL loaded only from the locally-built repo build/ dir (rocket_lib.py:15-24, os.add_dll_directory + absolute path join; never remote/downloaded); `make all` regenerates from source | closed |
| T-02-02 | Information Disclosure | test_call.py / export output | low | accept | Smokes print design numbers to the local console only; no network path exists in the app | closed |
| T-02-03 | Tampering | argtypes ↔ bind(C) contract | high | mitigate | Single declaration point in rocket_lib.py mirrored 1:1 (23 params) against C_Interface.f90; smoke hook asserts numerics (finite/>0, v_circ formula 1e-6, volume identity, loss bounds) — contract drift crashes the smoke before GUI use (test_call.py:51-70) | closed |
| T-02-04 | Denial of Service | STAGING_LOOP convergence | low | accept | Hard-bounded (≤50 iterations, 1e-6 tolerance); single-user desktop, blocking call is the established Phase 1 contract (A6) | closed |
| T-02-05 | Tampering | propellant index into select-case | low | accept | Index is combo-derived 1..8 by construction (combo has 8 entries); min() fallback keeps all slots in-range; no user free-text input reaches Fortran | closed |
| T-02-06 | Tampering | _print_results export path | low | mitigate | Writes only to the QFileDialog-picked path (gui.py:1076); filename from numeric spinbox values + Fortran V_circ (bounded 100-2000 km → ~7.0-7.9 km/s); no free-text path construction (ASVS V5) | closed |
| T-02-07 | Tampering | stale-results display after input change | high | mitigate | _on_inputs_changed resets _last_v_circ → label "—" and disables Save; results cleared. Verified wired for orbit, payload, stage count, diameter mode, user diameter, propellant/cycle validity, AND ISP/k_s sliders (gui.py:898-901, 986-987, 1017-1018) — converged numbers can never render/export against changed inputs (ASVS V5 state integrity) | closed |
| T-02-08 | Tampering | fabricated display values (NaN/garbage from bridge) | medium | mitigate | ResultCard NaN guard (value == value, gui.py:580) renders "—" for non-finite values; 02-01 smoke asserts finite/>0 for all new keys pre-GUI | closed |
| T-02-09 | Denial of Service | blocking pipeline call on UI thread | low | accept | Established Phase 1 concurrency contract (A6): solver ≤50 iterations, single-user desktop; no threading machinery introduced | closed |
| T-02-SC | Tampering | package installs | low | accept | No new packages — ctypes (stdlib) only; PyQt6 already installed; Package Legitimacy Audit N/A | closed |

*Status: open · closed · open — below {block_on} threshold (non-blocking)*
*Severity: critical > high > medium > low — only open threats at or above workflow.security_block_on count toward threats_open*
*Disposition: mitigate (implementation required) · accept (documented risk) · transfer (third-party)*

---

## Accepted Risks Log

| Risk ID | Threat Ref | Rationale | Accepted By | Date |
|---------|------------|-----------|-------------|------|
| R-02-02 | T-02-02 | Console smoke output is single-user local; no network surface (ASVS L1) | planner + auditor | 2026-09-06 |
| R-02-04 | T-02-04 | Bisection is hard-bounded; blocking call is the established Phase-1 concurrency contract | planner + auditor | 2026-09-06 |
| R-02-05 | T-02-05 | Propellant indices are combo-derived 1..8 by construction; min() fallback bounds all slots | planner + auditor | 2026-09-06 |
| R-02-09 | T-02-09 | Single-user desktop; ≤50-iteration solver; no threading introduced | planner + auditor | 2026-09-06 |
| R-02-SC | T-02-SC | No packages added beyond stdlib ctypes and already-installed PyQt6 | planner + auditor | 2026-09-06 |

*Accepted risks do not resurface in future audit runs.*

---

## Security Audit Trail

| Audit Date | Threats Total | Closed | Open | Run By |
|------------|---------------|--------|------|--------|
| 2026-09-06 | 10 | 10 | 0 | gsd-security-auditor (L1, via /gsd-secure-phase) |

---

## Sign-Off

- [x] All threats have a disposition (mitigate / accept / transfer)
- [x] Accepted risks documented in Accepted Risks Log
- [x] `threats_open: 0` confirmed
- [x] `status: verified` set in frontmatter

**Approval:** verified 2026-09-06