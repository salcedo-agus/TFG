# AGENTS.md

Project-level instructions loaded automatically by opencode at the start of every session.

## Project

**TFG** — Fortran 90/2008 (gfortran) computational core + Python 3.11 / PyQt6 GUI for
multi-stage space launcher design. Bridged via ctypes (`librocket.dll`).
Standalone desktop app; no external APIs, no databases. Build: single `SRC/Makefile`.

Pipeline (`SRC/Main.f90:8-17`): config → pre-staging (orbit, payload) → staging solver
(bisection on mass ratios) → pre-simulation (thrust, geometry).

## Git / branch conventions (IMPORTANT)

- **GSD planning artifacts (`.planning/`) live ONLY on the `planning` branch.**
  `.planning/` is tracked there (commit_docs=true) and must stay untracked on all
  source branches (do NOT `git add` it on source branches; do not re-add it to
  `.gitignore` — a `.gitignore` entry blocks gsd-tools' own `commit` command even
  on the `planning` branch).
- Source work happens on **`dev_GUI`** and **`dev_pre_simulation`**.
- GSD workflows (new-project, plan, execute, verify) are run from the **`planning`** branch.
- **Never commit `.planning/` to a source branch.**
- **Never push to GitHub unless the user explicitly asks.** All commits stay local; the user controls pushes.

## GSD workflow context

- Repo is brownfield; codebase map already exists under `.planning/codebase/`
  (STACK, ARCHITECTURE, STRUCTURE, CONVENTIONS, TESTING, INTEGRATIONS, CONCERNS).
- GSD tools shim: `node "C:\Users\agusc\.config\opencode\gsd-core\bin\gsd-tools.cjs"`.
- **`node` is NOT on PATH** in the default PowerShell — prepend
  `$env:ProgramFiles\nodejs` to `$env:Path` before invoking node.
- On Windows, `gsd-tools` `--files` globs are NOT shell-expanded by PowerShell —
  pass explicit file paths, not `*.md` globs.

## Current priorities (user decisions)

- Updating the **GUI / Python side**: the full Fortran pipeline is exposed to the GUI;
  bridge consolidated to the single `run_full_pipeline` ctypes entry (`run_staging`
  removed at every layer — `C_Interface.f90`, `rocket_lib.py`, `gui.py`, tests).
- **Phase 3 bridge-correctness fixes are done** (FIX-01/02/03): `Rocket%rm_L` is
  initialized on the ctypes path; the duplicated bridge is gone; the Makefile
  discovers MinGW at build time via `?=` + `where gfortran` (no hardcoded path).
- **Automated tests are deferred** — not part of the current work, leave for future sessions.
- Planning artifacts live on the `planning` branch (see above).

## Known codebase issues (see `.planning/codebase/CONCERNS.md` on the planning branch)

- Config parser writes stage-2/3 combustion cycles into `first_stage_combustion_cycle`
  (`SRC/inout/Typical_Data.f90:924-930`).
- Hardcoded Soyuz TEST CASE overrides all ISP/k_s tables in the Fortran path
  (`SRC/inout/Typical_Data.f90:824-832`).
- Zero automated tests.