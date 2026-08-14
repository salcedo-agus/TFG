---
status: diagnosed
trigger: "UAT gap: Run with valid combo works; results show real mass values (not null) — actual: null results for the masses"
created: 2026-08-14T00:00:00Z
updated: 2026-08-14T00:00:00Z
goal: find_root_cause_only
---

## Current Focus

hypothesis: CONFIRMED — "Rocket%rm_L is never set on the ctypes/GUI path (C_Interface.f90 skips Payload_Mass_calculator), so Staging.f90:86 multiplies m_0 by uninitialized memory → NaN masses → GUI ResultCard renders NaN as '—' (null-looking)"
test: Static differential between console path (Main.f90 → Payload_Mass_calculator → STAGING_LOOP) and ctypes path (C_Interface.f90 → STAGING direct); traced every read of rm_L and every write site; checked type default-init and Makefile init flags; traced GUI display path for NaN
expecting: rm_L written exactly once (Payload_Mass_calc.f90:19) and only reachable from Main.f90 — confirmed; no default init in Rocket_Types.f90 — confirmed; FFLAGS has no -finit-real — confirmed
next_action: None — root cause confirmed, diagnose-only mode. Return ROOT CAUSE FOUND.

## Symptoms
<!-- IMMUTABLE after gathering (pre-filled from UAT) -->

expected: Clicking Run in the Setup tab with valid inputs (orbit height, payload, stages) produces results with real mass values for each stage (m0, mp, ms, etc.)
actual: All checks go right, but running produces null results for the masses
errors: None reported (no traceback — GUI shows results but mass values are null/empty)
reproduction: Test 2 in .planning/phases/01-centralized-3-tab-gui/01-UAT.md; machine where build/librocket.dll was built via `make gui`
started: Discovered during UAT (Phase 01 — centralized 3-tab GUI)

## Eliminated
<!-- APPEND only -->

- hypothesis: "Bisection fails for the GUI's auto ΔV (7.6-7.9 km/s), producing NaN L → NaN masses"
  evidence: Bolzano_Interval_Start explicitly walks L until g(L) is IEEE-finite (Root_Finding.f90:28) — the g(L) inputs (delta_v, ISP, k_s) are all finite on BOTH paths and do not depend on rm_L. Console path shares the identical bisection and works. GUI-only failure cannot come from shared solver code.
  timestamp: 2026-08-14

- hypothesis: "ctypes marshalling bug (argtypes/pointer mismatch) returns zeros/garbage"
  evidence: C_Interface.f90 bind(C) signatures match gui.py argtypes 1:1 (15 params, pointer-passing matches no-VALUE C binding); the duplicated bridges (gui.py:80 and rocket_lib.py:45) are byte-equivalent in marshalling; console path uses the same Fortran kernel successfully.
  timestamp: 2026-08-14

- hypothesis: "_auto_delta_v math produces NaN delta_v"
  evidence: (9.80665*6378²/((6378+h)*1000))**0.5 ≈ 7.6-7.9 km/s for h=200-500 km — finite, sane circular velocity; only feeds bisection (eliminated above).
  timestamp: 2026-08-14

## Evidence
<!-- APPEND only -->

- timestamp: 2026-08-14
  checked: C_Interface.f90 (ctypes entry point, full file)
  found: Sets module global payload_mass (line 41) and Rocket%delta_v/%number_of_stages/%stage(i)%ISP/%stage(i)%k_s (lines 40-51). Calls STAGING directly. NEVER sets Rocket%rm_L, NEVER calls Payload_Mass_calculator. Result packing reads %m_0/%m_f/%m_p/%m_s/%k_m/%k_s/%k_L/%nu_e (lines 57-66); total_m0_out = Rocket%rm_0 (line 68).
  implication: The only payload plumbing on the ctypes path is the module global `payload_mass` — which STAGING never reads.

- timestamp: 2026-08-14
  checked: Staging.f90 lines 80-108 (mass computation)
  found: Line 86: `Rocket%stage(1)%m_0 = Rocket%rm_L * Rocket%stage(1)%m_0` — scales all stage masses by rm_L. Line 106: last stage `%m_L = Rocket%rm_L`. Downstream lines 90-123 propagate m_0 → m_p, m_s, m_f, k_L, m_i, rm_0.
  implication: Every mass output depends on rm_L; if rm_L is uninitialized, ALL mass outputs are corrupted — exactly matching "null results for the masses".

- timestamp: 2026-08-14
  checked: Rocket_Types.f90:31 + Makefile FFLAGS
  found: `real(8) rm_L` has NO default initialization (`= 0.d0` absent); FFLAGS = `-O2 -Wall` with no -finit-real / -finit-local-zero. gfortran derived-type components without init are undefined memory.
  implication: rm_L holds stack garbage — most commonly NaN bit patterns (explains "null" rendering) or random magnitudes.

- timestamp: 2026-08-14
  checked: gui.py ResultCard.add_metric (lines 569-584) + _run (1066-1129)
  found: Line 573: `if isinstance(value, (int, float)) and value == value:` — NaN fails `value == value` → renders "—" em-dash in TEXT_DIM (comment: "never a fabricated number"). Summary label formats `total_initial_mass` with `:,.1f` → "nan". k_m/k_s/nu_e rows unaffected (finite).
  implication: NaN masses are displayed as "—" — the user-visible "null results". Predicted card signature: m₀/m_f/m_p/m_s/k_L all "—", k_m/k_s/ν_e real numbers.

- timestamp: 2026-08-14
  checked: Main.f90 (console path) + Payload_Mass_calc.f90 + grep rm_L across SRC
  found: Main.f90:11 `call Payload_Mass_calculator(Rocket)` BEFORE staging; Payload_Mass_calc.f90:19 `Rocket%rm_L = payload_mass + m_adapter` (m_adapter = 0.0755*payload_mass + 50). Grep: rm_L written in exactly ONE place — Payload_Mass_calc.f90:19 — and read at Staging.f90:86,106. STAGING_LOOP itself never sets it.
  implication: Console path initializes rm_L; ctypes path cannot, since Payload_Mass_calculator is unreachable from C_Interface.f90. Differential confirmed — GUI-only failure, matches known CONCERNS entry.

- timestamp: 2026-08-14
  checked: gui.py imports + bridge duplication
  found: gui.py defines its OWN run_staging at module level (line 80) and _run (line 1091) calls it; `import rocket_lib` appears NOWHERE in gui.py (interface/ is on sys.path but unused). Both bridge copies are marshalling-identical.
  implication: Duplication is a maintainability concern (known CONCERNS entry), NOT the cause of null masses — but any fix must be applied to BOTH copies in lockstep.

- timestamp: 2026-08-14
  checked: knowledge base (.planning/debug/knowledge-base.md)
  found: No prior resolved sessions (file absent); no MemPalace match to test. The codebase map CONCERNS entry ("Rocket%rm_L never set on the ctypes/GUI path, read at Staging.f90:86") served as the initial hypothesis candidate and was confirmed by direct reading.
  implication: Known-concern entry validated as the root cause.

## Resolution
<!-- OVERWRITE as understanding evolves -->

root_cause: "Rocket%rm_L (payload mass) is never initialized on the ctypes/GUI path. C_Interface.f90:run_staging (lines 40-54) builds Rocket with only delta_v/ISP/k_s and calls STAGING directly — the only write site of rm_L is Payload_Mass_calculator (Payload_Mass_calc.f90:19), reachable only from the console path (Main.f90:11). rm_L has no default initialization (Rocket_Types.f90:31) and the build has no -finit-real flag, so Staging.f90:86 (`m_0 = rm_L * product`) and :106 multiply/add uninitialized stack memory → NaN propagates to m_0/m_p/m_s/m_f/k_L/m_i/rm_0. The GUI's ResultCard NaN guard (gui.py:573 `value == value`) renders those as '—' placeholders — the user-visible 'null results for the masses'. k_m/k_s/nu_e stay real because they depend only on the (finite) bisection inputs."
fix: (empty — diagnose-only mode)
verification: (empty)
files_changed: []