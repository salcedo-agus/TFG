---
status: complete
phase: 01-centralized-3-tab-gui
source: [01-VERIFICATION.md]
started: 2026-08-14T23:30:00Z
updated: 2026-08-14T23:55:00Z
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
  artifacts: []  # Filled by diagnosis
  missing: []   # Filled by diagnosis
- gap_id: G-01-4
  truth: "Bridge smoke passes; behavior unchanged by construction (zero diff in gui.py:22-110)"
  status: failed
  reason: "User reported: Running the test_call.py returns: Traceback (most recent call last): File \"C:\\Users\\agusc\\Desktop\\TFG\\TFG\\SRC\\test_call.py\", line 2, in <module> from rocket_lib import run_staging ModuleNotFoundError: No module named 'rocket_lib'"
  severity: blocker
  test: 4
  artifacts: []  # Filled by diagnosis
  missing: []   # Filled by diagnosis