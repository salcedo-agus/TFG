---
phase: 3
slug: bridge-correctness-fixes
# status lifecycle: draft (seeded by plan-phase) → validated (set by validate-phase §6)
# audit-milestone §5.5 distinguishes NOT-VALIDATED (draft) from PARTIAL (validated + nyquist_compliant: false) (#2117)
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-09-06
---

# Phase 3 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

**Source:** `03-RESEARCH.md` §Validation Architecture (verifies all FIX-01/02/03 behaviors below).

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | Python stdlib `unittest` (Python 3.11.1); no pytest dependency |
| **Config file** | none — discovery-based (`-p "test_*.py"`) |
| **Quick run command** | `python -m unittest discover -s SRC/test -p "test_rocket_lib.py"` (from repo root) |
| **Full suite command** | `python -m unittest discover -s SRC/test -p "test_*.py"` |
| **Estimated runtime** | ~1 second (baseline 23 tests: 0.029s + 0.641s) |

---

## Sampling Rate

- **After every task commit:** Run `python -m unittest discover -s SRC/test -p "test_rocket_lib.py"`
- **After every plan wave:** Run full suite `python -m unittest discover -s SRC/test -p "test_*.py"`
- **Before `/gsd-verify-work`:** Full suite green + `make all` clean build + negative export check + `make gui` launch smoke
- **Max feedback latency:** ~5 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 03-0X-YY | 01 | _wave_ | FIX-01 | — | rm_L from single source; bounds guard | integration | `python -m unittest discover -s SRC/test -p "test_rocket_lib.py"` | ✅ / ❌ W0 | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

> Completed by the planner (task IDs filled once PLAN.md files land). Will be reconciled at execute time.

---

## Wave 0 Requirements

- [ ] `SRC/test/test_rocket_lib.py` — D-02 conservative-bounds test added in-phase (covers FIX-01 behavioral guard); `RunStagingWrapperContract` removed in-phase (FIX-02).
- [ ] None external: framework (stdlib unittest) and both test files already exist; no new fixtures needed.

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Library path resolution has no drive-letter literal; discovery + env/CLI override + clear error | FIX-03 | Build-time behavior — Makefile `?=` expansion and `where gfortran` resolution cannot be asserted by unittest against the compiled DLL | `make clean && make all` on both gnumake variants; `MINGW_BIN=` env override probe; `MINGW_BIN=` CLI override probe; confirm error-hint without gfortran |

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 5s
- [ ] `nyquist_compliant: true` set in frontmatter (after validate-phase)

**Approval:** pending