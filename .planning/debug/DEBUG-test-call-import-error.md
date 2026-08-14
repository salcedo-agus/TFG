---
status: diagnosed
trigger: "UAT gap — Test 4 in .planning/phases/01-centralized-3-tab-gui/01-UAT.md: python SRC/test_call.py fails with ModuleNotFoundError: No module named 'rocket_lib'"
goal: find_root_cause_only
created: 2026-08-14T00:00:00.000Z
updated: 2026-08-14T00:00:00.000Z
---

## Current Focus

hypothesis: "test_call.py's bare `from rocket_lib import run_staging` broke when commit 72c468f moved SRC/rocket_lib.py to SRC/interface/; test_call.py was never updated (only commit ac19992 ever touched it), while gui.py got a sys.path.insert that let it survive the move"
test: "git history reconstruction (ac19992 vs 72c468f) + live reproduction of `python SRC/test_call.py`"
expecting: "error reproduces identically; git history shows test_call.py untouched since ac19992 when rocket_lib.py was a sibling in SRC/"
next_action: "DONE — root cause confirmed. Write findings + return ROOT CAUSE FOUND (diagnose-only mode)."

## Symptoms
<!-- PREFILLED from UAT. IMMUTABLE. -->

expected: Running `python test_call.py` from SRC/ exercises the ctypes bridge and prints total initial mass and per-stage masses
actual: "Running the test_call.py returns: Traceback (most recent call last): File \"C:\\Users\\agusc\\Desktop\\TFG\\TFG\\SRC\\test_call.py\", line 2, in <module> from rocket_lib import run_staging ModuleNotFoundError: No module named 'rocket_lib'"
errors: ModuleNotFoundError: No module named 'rocket_lib'
reproduction: Test 4 in .planning/phases/01-centralized-3-tab-gui/01-UAT.md
timeline: Discovered during UAT
truth: "Bridge smoke passes; behavior unchanged by construction (zero diff in gui.py:22-110)"

## Eliminated

(no hypotheses eliminated — first hypothesis confirmed on first test)

## Evidence

- timestamp: 2026-08-14T00:00:00.000Z
  checked: Live reproduction — `python SRC/test_call.py` (repo root)
  found: Exact UAT error reproduced: `File "...SRC\test_call.py", line 2, in <module> from rocket_lib import run_staging` → `ModuleNotFoundError: No module named 'rocket_lib'`
  implication: Failure is deterministic (Bohrbug) at import time, BEFORE any DLL access; reproduces from any CWD because sys.path[0] is the script's own directory (SRC/), which no longer contains rocket_lib.py

- timestamp: 2026-08-14T00:00:00.000Z
  checked: git history of SRC/test_call.py (`git log --all --oneline -- SRC/test_call.py`)
  found: Only ONE commit ever touched test_call.py: ac19992 "Added GUI". The file is byte-identical to its creation state (verified via `git show ac19992:SRC/test_call.py` — same bare import, no sys.path code)
  implication: test_call.py was never adapted to any later layout change

- timestamp: 2026-08-14T00:00:00.000Z
  checked: `git show ac19992 --stat` (creation commit, Jun 13 2026)
  found: ac19992 created SRC/gui.py, SRC/rocket_lib.py, SRC/test_call.py as SIBLINGS in SRC/. Also, original gui.py had its own inline ctypes bridge (no `import rocket_lib` anywhere — matches known duplication concern); SRC/rocket_lib.py existed solely to serve test_call.py's bare import
  implication: At creation, `python test_call.py` worked: script dir SRC/ is on sys.path[0] and contained rocket_lib.py

- timestamp: 2026-08-14T00:00:00.000Z
  checked: `git show 72c468f --stat` (reorg commit, Jun 14 2026) + `git log --diff-filter=R`
  found: 72c468f "Added presentation window. Changed organization" renamed SRC/rocket_lib.py → SRC/interface/rocket_lib.py (rename detection 52%) and SRC/gui.py → SRC/gui/gui.py, plus moved Typical_Data.f90, C_Interface.f90, Rocket_Types.f90, Staging.f90 into subdirs. test_call.py NOT in the diff
  implication: The reorganization that broke the import left test_call.py untouched — this is the introducing commit for the failure

- timestamp: 2026-08-14T00:00:00.000Z
  checked: SRC/gui/gui.py:22-29 (the "works" counterpart)
  found: gui.py:23-24 computes GUI_DIR/ROOT_DIR from __file__, then gui.py:29 does `sys.path.insert(0, os.path.join(ROOT_DIR, "interface"))` — explicit path setup that survived the move
  implication: The established in-repo pattern for importing interface/ modules exists; test_call.py simply never got it

- timestamp: 2026-08-14T00:00:00.000Z
  checked: Docs mentioning how to run test_call.py (.planning/codebase/TESTING.md:17, STRUCTURE.md, STACK.md, phase SUMMARYs)
  found: TESTING.md:17 says "must be run from SRC/ (imports rocket_lib)" — correct ONLY under the pre-72c468f layout; stale after the move. Phase SUMMARYs (01-02/01-03) assumed the gate unrun was solely due to missing build/librocket.dll and recorded it as a human_judgment blocker — the import breakage was not previously identified
  implication: Documentation and prior phase coverage describe the pre-reorg layout; the import defect is latent since Jun 14 and only surfaced when the user actually ran the gate

## Resolution

root_cause: "SRC/test_call.py:2 performs a bare `from rocket_lib import run_staging` with no sys.path setup. When the script runs, Python puts the script's own directory (SRC/) at sys.path[0], which worked only while rocket_lib.py lived in SRC/ (commit ac19992). Commit 72c468f moved rocket_lib.py to SRC/interface/ and added sys.path handling to gui.py (gui.py:29), but never touched test_call.py — so the import now resolves nothing and fails deterministically. Bohrbug, introduced by 72c468f, latent until first real run of the gate."
fix: "NONE — diagnose-only mode. Suggested direction: mirror gui.py:29 — insert SRC/interface/ onto sys.path in test_call.py before the import (e.g. `sys.path.insert(0, os.path.join(os.path.dirname(__file__), \"interface\"))`), or import via `interface.rocket_lib` with SRC/ on the path. Also note: fixing the import unblocks the next failure only if build/librocket.dll exists (pre-existing documented blocker, WINDOWS.md entry 1)."
verification: "Reproduced exact reported error on current branch (planning). Mechanism confirmed by git history (only ac19992 touched test_call.py; 72c468f is the move commit; gui.py:29 is the surviving pattern)."
files_changed: []