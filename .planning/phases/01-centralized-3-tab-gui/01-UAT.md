---
status: diagnosed
phase: 01-centralized-3-tab-gui
source: [01-VERIFICATION.md]
started: 2026-08-14T23:30:00Z
updated: 2026-08-15T00:05:00Z
---

## Current Test

[testing complete]

## Tests

### 1. Full GUI walkthrough — shell & splash
expected: Run `make gui` in SRC/ (builds build/librocket.dll, then launches). Confirm splash shows first and fades (600 ms InOutQuad) into the window; 3 styled tabs in order Results / Setup / Vehicle Configuration, Results active; selected tab ACCENT; no old left/right split; 960x700 minimum enforced.
result: pass

### 2. Mission-inputs walkthrough
expected: In Setup: Orbit Height default 500.0; changing it updates the read-only "ΔV (auto)" label, clears Results, disables Save; Run with a valid combo works; Save exports a .txt whose Delta-V line equals the label and whose suggested filename follows `staging_{n}stage_dv{dv:.1f}_pl{pl}kg.txt`.
result: issue
reported: "All the checks went right, but when running I get null results for the masses"
severity: major

### 3. Results-surface walkthrough
expected: After Run: 8 original metrics unchanged + 2 new rows (Stage ΔV / Diameter; Length / Volume) all rendering "—" in dim text; partial-state hint appears once below cards; app auto-switches to Results; input change invalidates without navigating; Save twice re-opens the dialog each time, exported .txt identical in structure to a pre-phase file (only the Delta-V line source differs); minimum indicator ✔/✘ per run; window unresponsive mid-run (blocking, expected).
result: pass

### 4. Phase gate `python SRC/test_call.py`
expected: Bridge smoke passes; behavior unchanged by construction (zero diff in gui.py:22-110). Run on a machine with build/librocket.dll present.
result: issue
reported: "Running the test_call.py returns: Traceback (most recent call last): File \"C:\\Users\\agusc\\Desktop\\TFG\\TFG\\SRC\\test_call.py\", line 2, in <module> from rocket_lib import run_staging ModuleNotFoundError: No module named 'rocket_lib'"
severity: blocker

### 5. Backstop — combo readability & tab-bar fit at 960px
expected: At the 960px minimum window width, open the Combustion Cycle dropdown and confirm the 61-char cycle name 'Aproximates Engine Perfermoance Only Base On Propellant/Oxidizer' elides readably; the 3-tab bar (with 'Vehicle Configuration') fits without clipping.
result: pass

## Summary

total: 5
passed: 3
issues: 2
pending: 0
skipped: 0
blocked: 0

## Gaps

- gap_id: G-01-2
  truth: "Run with a valid combo works; results show real mass values (not null)"
  status: failed
  reason: "User reported: All the checks went right, but when running I get null results for the masses"
  severity: major
  test: 2
  root_cause: "Rocket%rm_L (payload mass) is never initialized on the ctypes/GUI path: C_Interface.f90:run_staging sets %delta_v/%number_of_stages/%ISP/%k_s but not %rm_L; the only write site is Payload_Mass_calculator (Payload_Mass_calc.f90:19), reachable only from the console path (Main.f90:11). Staging.f90:86 multiplies uninitialized stack memory into every mass; GUI renders the resulting NaN as '—' (gui.py:573 NaN guard), appearing as null masses."
  artifacts:
    - path: "SRC/interface/C_Interface.f90"
      issue: "run_staging (lines 40-54) never sets Rocket%rm_L / never calls Payload_Mass_calculator; sets the payload_mass module global that STAGING never reads"
    - path: "SRC/staging/Staging.f90"
      issue: "line 86/106 read uninitialized Rocket%rm_L, poisoning m_0/m_p/m_s/m_f/k_L/m_i/rm_0"
    - path: "SRC/pre-staging-calcs/Payload_Mass_calc.f90"
      issue: "line 19 is the only rm_L write site, unreachable from the ctypes path"
    - path: "SRC/staging/Rocket_Types.f90"
      issue: "rm_L has no default initialization (no = 0.d0)"
  missing:
    - "Set Rocket%rm_L from the payload_mass module global before call STAGING in C_Interface.f90 (or mirror console path via Payload_Mass_calculator, adding PAF mass)"
    - "Optional defense-in-depth: default-init rm_L = 0.d0 in Rocket_Types.f90"
  debug_session: ".planning/debug/DEBUG-null-masses-on-run.md"
- gap_id: G-01-4
  truth: "Bridge smoke passes; behavior unchanged by construction (zero diff in gui.py:22-110)"
  status: failed
  reason: "User reported: Running the test_call.py returns: Traceback (most recent call last): File \"C:\\Users\\agusc\\Desktop\\TFG\\TFG\\SRC\\test_call.py\", line 2, in <module> from rocket_lib import run_staging ModuleNotFoundError: No module named 'rocket_lib'"
  severity: blocker
  test: 4
  root_cause: "test_call.py:2 does a bare 'from rocket_lib import run_staging' with no sys.path setup. Commit 72c468f ('Changed organization') moved rocket_lib.py from SRC/ to SRC/interface/ and added sys.path.insert(0, interface) to gui.py (gui.py:29), but test_call.py was never updated, so the bare import now fails deterministically from any CWD."
  artifacts:
    - path: "SRC/test_call.py"
      issue: "line 2 stale bare import; missing the sys.path insert that gui.py:29 has"
    - path: "SRC/interface/rocket_lib.py"
      issue: "module moved by 72c468f; target of the broken import (not itself defective)"
    - path: ".planning/codebase/TESTING.md"
      issue: "line 17 run instructions describe the pre-reorg layout (stale)"
  missing:
    - "Mirror gui.py pattern in test_call.py: sys.path.insert(0, os.path.join(os.path.dirname(__file__), 'interface')) before the import (or import from interface.rocket_lib)"
  debug_session: ".planning/debug/DEBUG-test-call-import-error.md"