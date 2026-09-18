---
phase: 04
slug: gui-fairing-controls-stand-in
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-09-17
---

# Phase 04 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | pytest (deferred per user decision — no test infrastructure in current scope) |
| **Config file** | none — see Wave 0 |
| **Quick run command** | `pytest -x` (when implemented) |
| **Full suite command** | `pytest` (when implemented) |
| **Estimated runtime** | ~N/A seconds (tests deferred) |

---

## Sampling Rate

- **After every task commit:** N/A (tests deferred)
- **After every plan wave:** N/A (tests deferred)
- **Before `/gsd-verify-work`:** Manual verification per UAT criteria in CONTEXT.md
- **Max feedback latency:** N/A (tests deferred)

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 04-01-01 | 04 | 1 | FAIR-01 | T-04-01 / — | Constant mode: fairing D = body D enforced | unit | `pytest tests/test_fairing_geometry.py::test_constant_mode` | ❌ Wave 0 | ⬜ pending |
| 04-01-02 | 04 | 1 | FAIR-03 | T-04-02 / — | Hammer-Head: fairing D ≥ body D enforced | unit | `pytest tests/test_fairing_geometry.py::test_hammerhead_constraint` | ❌ Wave 0 | ⬜ pending |
| 04-02-01 | 04 | 1 | FAIR-04 | — / — | Fairing geometry (D/L/V) in .txt export | integration | `pytest tests/test_export.py::test_fairing_section` | ❌ Wave 0 | ⬜ pending |
| 04-02-02 | 04 | 1 | FAIR-04 | — / — | Fairing geometry (D/L/V) per stage in export | integration | `pytest tests/test_export.py::test_fairing_per_stage` | ❌ Wave 0 | ⬜ pending |
| 04-03-01 | 04 | 1 | VIS-01 | — / — | Diagram renders stages + fairing geometry | manual | N/A — visual verification | ❌ Wave 0 | ⬜ pending |
| 04-03-02 | 04 | 1 | VIS-02 | — / — | Zoom/pan/PNG export works | manual | N/A — visual verification | ❌ Wave 0 | ⬜ pending |
| 04-03-03 | 04 | 1 | VIS-03 | — / — | Diagram updates on input change | manual | N/A — visual verification | ❌ Wave 0 | ⬜ pending |
| 04-04-01 | 04 | 1 | GUI-09 | — / — | qt-material theme applied | manual | N/A — visual verification | ❌ Wave 0 | ⬜ pending |
| 04-04-02 | 04 | 1 | GUI-10 | — / — | Dark title bar on Windows | manual | N/A — visual verification | ❌ Wave 0 | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] `tests/test_fairing_geometry.py` — covers FAIR-01/03 mock computations (ogive length = 3×D, volume ≈ 0.75×cylinder, boat-tail 10°)
- [ ] `tests/test_constraints.py` — covers D-04 matrix validation (fairing ≤ body for Tapered, fairing ≥ body for Hammer-Head)
- [ ] `tests/test_diagram.py` — covers VIS-01/02/03 rendering (QGraphicsView zoom/pan/export)
- [ ] `tests/test_export.py` — covers FAIR-04 export format (Fairing Geometry section per stage)
- [ ] Framework install: `pip install pytest pytest-qt` — if tests enabled later

*(Tests explicitly deferred by user — Wave 0 gaps documented for future enablement)*

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Diagram renders body + fairing geometry correctly (ogive profile for Hammer-Head) | VIS-01 | Visual rendering cannot be unit tested | Run GUI, select each body/fairing combo, verify diagram shows correct profiles |
| Zoom (mouse wheel) and pan (drag) work smoothly | VIS-02 | Interaction behavior | Run GUI, mouse wheel to zoom, drag to pan, verify no lag/artifacts |
| PNG export produces valid image matching diagram | VIS-02 | File output visual check | Click export button, open PNG, verify matches on-screen diagram |
| qt-material dark_teal theme applied consistently across all tabs | GUI-09 | Theme application is visual | Run GUI, verify dark theme on Results/Setup/Vehicle tabs |
| Windows 10/11 title bar is dark when dark theme active | GUI-10 | WinAPI behavior not testable in CI | Run GUI on Windows, toggle theme, verify title bar color changes |

*If none: "All phase behaviors have automated verification."*

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < N/A s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending

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