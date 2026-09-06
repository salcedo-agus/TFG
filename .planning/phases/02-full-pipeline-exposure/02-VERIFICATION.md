---
phase: 02-full-pipeline-exposure
verified: 2026-09-06T23:01:13Z
status: passed
score: 20/20 must-haves verified
behavior_unverified: 0
overrides_applied: 0
re_verification:
  previous_status: gaps_found
  previous_score: 19/20
  gaps_closed:
    - "Invalidation contract (02-02 truth #6): ISP/k_s slider changes now route through _on_inputs_changed — closed by commit fd29b9e and independently re-verified offscreen"
  gaps_remaining:
    - "CR-01 Constant-mode ghost-stage diameter pollution for n_stages<3 (pre-existing Fortran defect, Phase 3)"
    - "WR-02 vacant geometry-table branches yielding NaN/negative (pre-existing Fortran defect, Phase 3)"
    - "WR-03 negative-thrust domain making sum(dv) < v_circ (pre-existing Fortran defect, Phase 3)"
  regressions: []
gaps:
  - truth: "Invalidation contract (02-02 truth #6): 'converged numbers are never displayed or exported against changed inputs' — ISP/k_s slider changes invalidate results"
    status: resolved
    reason: "RESOLVED by commit fd29b9e ('fix(gui): invalidate results when ISP/k_s sliders change'): in _rebuild_stage_inputs (gui.py:1018-1019) both sw.isp_slider.valueChanged and sw.ks_slider.valueChanged now connect to self._on_inputs_changed, inside the per-stage construction loop (all stage widgets), placed after widget construction so _update_ranges()'s construction-time setValue calls cannot spuriously invalidate. Independently re-verified offscreen (throwaway harness, QT_QPA_PLATFORM=offscreen): after a successful full-pipeline run establishing a stale state (cards present, _last_v_circ=7.6158, Save enabled, label '7.62 km/s'), dragging isp_slider (4143->4148) AND ks_slider (790->795) each cleared all ResultCards, reset _last_v_circ to None, restored the '— km/s' label, and disabled Save; export guard (_print_results) warns with no file dialog when _last_v_circ is None; 6 repeated drags produce exactly 1 placeholder (no accumulation). Harness exit 0, all 29 checks PASS."
    artifacts:
      - path: "SRC/gui/gui.py"
        issue: "Resolved — gui.py:1018-1019 wire both sliders through _on_inputs_changed (commit fd29b9e); gui.py:398-399 label updaters remain as intended companions"
    missing: []
  - truth: "Constant-mode (diameter_setup=2) geometry for n_stages < 3 is not polluted by ghost stage slots (code review CR-01)"
    status: failed
    reason: "Pre-existing Geometry_calc.f90 algorithm defect, reachable through the new entry. Ghost slots 2/3 always execute their select cases with Mass_vector=0 and the min(i,n_stages) propellant fallback; in Constant mode `Diameter_vector = maxval(Diameter_vector)` (line 101) includes them. Empirically confirmed: n=1 Constant forces the zero-mass stage-3 fit value 4.8378 m (or 2.4729/4.8378 ghost pair) onto the real stage; for n=2 pollution occurs whenever 4.8378 m exceeds all real stage widths. Spurious 'WARNING: without statistical data' prints also appear. NOT a must-have truth violation (no truth asserts Constant-mode correctness for n<3; the phase was explicitly prohibited from touching Geometry_calc formulas) and NOT covered by the phase's verification domains (smoke: n=3/mode 1; T3 walkthrough: n=3, modes 1/2/3 all correct). Robustness gap — record for Phase 3 / fix per user disposition."
    artifacts:
      - path: "SRC/pre-simulation-calcs/Geometry_calc.f90"
        issue: "line 101 maxval over full 3-slot vector includes zero-mass ghost slots when n_stages < 3; per-stage select cases (lines 44-90) execute unconditionally"
    missing:
      - "Bound the Constant-mode max to real stages (maxval(Diameter_vector(1:Rocket%number_of_stages))) and/or skip select cases for i > number_of_stages; add a regression probe for n=1/2 × mode 2"
  - truth: "Empty/inverted geometry-table branches never yield negative or NaN diameters/lengths/volumes without a user-facing signal (code review WR-02)"
    status: failed
    reason: "Pre-existing: vacant table branches (e.g. stage-2 CH4/LOX, stage-2 UDMH/LOX) leave Diameter/Volume = 0 → 0/0 NaN at Geometry_calc line 105; fit inversions (stage-1 LH2/LOX below ~11.6 t) give negative diameters. ResultCard NaN guard renders '—' while masses/minimum still look valid; negatives render literally. No validation in run_full_pipeline or the GUI. Affects untested input domains beyond the smoke/T3 envelope."
    artifacts:
      - path: "SRC/pre-simulation-calcs/Geometry_calc.f90"
        issue: "NaN/negative geometry from vacant/inverted regression branches, packed by C_Interface.f90:188-191"
      - path: "SRC/gui/gui.py"
        issue: "ResultCard NaN guard (line 580) renders '—' silently; no user-facing geometry-validity signal"
    missing:
      - "Per-stage geometry validity check (finite and > 0) in run_full_pipeline or a GUI-side warning surfaced to the user"
  - truth: "Converged per-stage ΔV never falls below V_circ on reachable GUI minimums (code review WR-03)"
    status: failed
    reason: "Pre-existing Thrust_calc.f90:19-21 domain: stage_thrust(1) < 0 below ~34 t, stage_thrust(2) < 0 below ~6.2 t → negative m_dot/t_burn → distorted DV_loss → converged total below orbital speed. Empirically confirmed: n=1, payload 5000 kg gives sum(dv)=6.9979 < v_circ=7.6158, physically impossible, yet total_initial_mass/minimum_found display as valid. Smoke assert domain (n=3, 5000 kg) does not enter it."
    artifacts:
      - path: "SRC/pre-simulation-calcs/Thrust_calc.f90"
        issue: "negative-thrust regression domain reachable from GUI minimums (payload 1.0 kg, orbit 100 km, n=1)"
    missing:
      - "Validation in run_full_pipeline: Rocket%stage(i)%T > 0 and sum(D_v) >= V_circ after STAGING_LOOP, surfaced as an error instead of returning garbage"
behavior_unverified_items: []
human_verification: []
---

# Phase 2: Full Pipeline Exposure — Verification Report

**Phase Goal:** Expose the complete Fortran pipeline to the GUI through a single ctypes entry point, reusing existing Fortran modules (no physics reimplementation in Python).
**Verified:** 2026-09-06T23:01:13Z
**Status:** passed — WR-01 invalidation gap closed (fd29b9e, independently re-verified); 3 pre-existing Fortran robustness gaps (CR-01/WR-02/WR-03) recorded for Phase 3, outside this phase's scope
**Re-verification:** Yes — after gap closure (WR-01 fixed in commit fd29b9e)

## Goal Achievement

### Observable Truths

Roadmap success criteria (the contract):

| # | Truth | Status | Evidence |
|---|-------|--------|----------|
| SC-1 | A single ctypes function runs the full pipeline: orbit → payload → staging → thrust → geometry | ✓ VERIFIED | `run_full_pipeline` bind(C) entry (C_Interface.f90:104-221) is the ONLY new entry; ctypes smoke (`python SRC/test_call.py`) re-run independently — exit 0, all assertions pass; thrust runs inside STAGING_LOOP (Stage_Optimization_Loop.f90:36) |
| SC-2 | GUI results populate from the full pipeline, not just the staging solver | ✓ VERIFIED | gui.py:1141-1150 `_run` calls `rocket_lib.run_full_pipeline`; ResultCard rows read `data.get("dv"/"diameter"/"length"/"volume")` (gui.py:607-610); offscreen harness re-run — 3 cards with finite/>0 values, hint absent |
| SC-3 | All pipeline results reused via existing Fortran modules — no duplicated physics in Python | ✓ VERIFIED | Payload_Mass_calculator (rm_L, C_Interface.f90:169), orbit_speed_calculator (V_circ, :171), STAGING_LOOP (:173), rocket_geometry_calculation (:175) all called; `_auto_delta_v` Python V_circ mirror deleted (0 grep matches); only arithmetic added is the D/L volume identity in Fortran |

Plan 02-01 must-haves (PIPE-02):

| # | Truth | Status | Evidence |
|---|-------|--------|----------|
| 1 | Single new bind(C) entry `run_full_pipeline` exported; only new entry | ✓ VERIFIED | C_Interface.f90:104-221; git diff d6538d8→0566f41 additive-only; smoke run loads and calls it |
| 2 | D-02: console call order reproduced exactly (payload → orbit → STAGING_LOOP → geometry) | ✓ VERIFIED | C_Interface.f90:169-175 matches Main.f90:11-17; orbit_speed_calculator at :171 precedes STAGING_LOOP at :173 (V_circ read at Stage_Optimization_Loop.f90:24) |
| 3 | D-03: dv_out(i) = Rocket%stage(i)%D_v (converged); smoke asserts v_circ < sum(dv) < v_circ+5 | ✓ VERIFIED (behavioral) | C_Interface.f90:187; smoke re-run: sum(dv)=10.0353 ∈ (7.6158, 12.6158) |
| 4 | All pipeline-read globals seeded from args (min(i,n) propellant fallback) | ✓ VERIFIED | C_Interface.f90:146-157; cross-checked reads: STAGING_LOOP (number_of_stages/V_circ/orbit_height), Orbit_calc (orbit_height), Payload_Mass_calc (payload_mass), Geometry_calc (propellant ints, diameter_setup, user_defined_diameter) |
| 5 | PIPE-02 (no physics reimplementation): rm_L via Payload_Mass_calculator; V_circ from orbit_speed_calculator | ✓ VERIFIED | C_Interface.f90:169/171; Payload_Mass_calc.f90:19 sets Rocket%rm_L; V_circ set at Orbit_calc.f90:10, never hand-assigned |
| 6 | Geometry store-back wiring only; volume via pi/4·D²·L identity | ✓ VERIFIED | Geometry_calc.f90:107-111 store-back; C_Interface.f90:190-191 volume identity; diff additive-only (6 lines), zero formula changes |
| 7 | run_staging + Makefile byte-untouched | ✓ VERIFIED | git diff d6538d8→0566f41: only `use constants` header + appended subroutine; no Makefile change in any phase commit |
| 8 | rocket_lib.py wrapper + argtypes 1:1 with bind(C) signature; return dict contract | ✓ VERIFIED | rocket_lib.py:45-70 (23 params, order matches C_Interface.f90); dict keys total_initial_mass/minimum_found/v_circ/stages[].dv/diameter/length/volume |
| 9 | test_call.py smoke hook with five assertion groups | ✓ VERIFIED (behavioral) | test_call.py:29-71; re-run independently — ALL ASSERTIONS PASSED (v_circ formula 1e-6, finite/>0, volume identity 1e-9, loss bound, payload/bool) |

Plan 02-02 must-haves (PIPE-01):

| # | Truth | Status | Evidence |
|---|-------|--------|----------|
| 1 | PIPE-01: `_run` calls `rocket_lib.run_full_pipeline(...)`; `delta_v=` gone | ✓ VERIFIED | gui.py:1141-1150; `_auto_delta_v()` feed removed |
| 2 | D-03/PIPE-01: every ResultCard renders real dv/diameter/length/volume; hint absent after run | ✓ VERIFIED (behavioral) | ResultCard gui.py:607-610; wrapper packs all four keys → hint condition (gui.py:1183-1187) never fires; harness re-run: 3 cards finite/>0 |
| 3 | D-04: `_auto_delta_v` deleted — zero matches | ✓ VERIFIED | grep across gui.py: 0 matches; git diff shows method deleted |
| 4 | D-01/D-04: label '— km/s' pre-run / after input change; f'{_last_v_circ:.2f} km/s' after run | ✓ VERIFIED (behavioral) | gui.py:876 init, 1055-1061 renderer, 1200 set; harness T2(b)/(c) re-run green |
| 5 | D-05: export uses _last_v_circ for Delta-V line AND filename | ✓ VERIFIED | gui.py:1069/1072/1085; harness T2(b) label==export source green |
| 6 | Invalidation: _on_inputs_changed resets _last_v_circ, refreshes label, disables Save | ✓ VERIFIED | Mechanic verified (gui.py:1048-1053) AND ISP/k_s slider changes now route through it — gui.py:1018-1019 connect isp_slider.valueChanged and ks_slider.valueChanged to _on_inputs_changed (commit fd29b9e, inside the per-stage construction loop). WR-01 re-verified: after a run establishing stale state (cards present, _last_v_circ=7.6158, Save enabled, label '7.62 km/s'), dragging isp_slider (4143→4148) and ks_slider (790→795) EACH cleared all ResultCards, reset _last_v_circ to None, restored '— km/s', disabled Save — harness exit 0, 29/29 checks PASS |
| 7 | Bridge failure handling verbatim (QMessageBox.critical 'Fortran Error' + early return) | ✓ VERIFIED | gui.py:1212-1213; validation warning pre-check at :1131-1138 unchanged |
| 8 | Duplication guard: single `import rocket_lib`; inline `_lib`/run_staging twin byte-untouched | ✓ VERIFIED | gui.py:30 single import; git diff confirms lines 20-111 region changed only by the import; harness static gate 'bridge block byte-identical' green |

**Score:** 20/20 truths verified. 0 behavior-unverified.

### Required Artifacts

| Artifact | Expected | Status | Details |
| -------- | -------- | ------ | ------- |
| `SRC/interface/C_Interface.f90` | `run_full_pipeline` bind(C) entry | ✓ VERIFIED | exports globals seeding, pipeline sequence, packing incl. dv/diameter/length/volume, eq-26 check, deallocate; additive-only diff |
| `SRC/pre-simulation-calcs/Geometry_calc.f90` | store-back loop persisting Diameter/Length | ✓ VERIFIED | lines 107-111; 6-line additive diff, zero formula changes |
| `SRC/interface/rocket_lib.py` | `run_full_pipeline` argtypes + wrapper | ✓ VERIFIED | 23-param argtypes mirroring signature; wrapper returns contract dict; run_staging block untouched |
| `SRC/test_call.py` | full-pipeline smoke block with assertions | ✓ VERIFIED | 5 assertion groups; re-run exit 0 |
| `SRC/gui/gui.py` | full-pipeline GUI wiring | ✓ VERIFIED | import rocket_lib, _run swap, _last_v_circ chain, _auto_delta_v deleted, diameter invalidation, shared Run button; inline twin untouched |

### Key Link Verification

| From | To | Via | Status | Details |
| ---- | --- | --- | ------ | ------- |
| C_Interface.f90 bind(C) signature | rocket_lib.py argtypes | 23 params, same order | ✓ WIRED | cross-checked 1:1; smoke + harness prove no segfault/mismatch |
| Module-global seeding | Orbit_calc / STAGING_LOOP / Geometry_calc reads | globals set before calls | ✓ WIRED | V_circ set at :171 before read at Stage_Optimization_Loop.f90:24; smoke V_circ matches formula |
| Geometry_calc store-back | packed diameter/length/volume | Rocket%stage persistence | ✓ WIRED | smoke volume identity 1e-9 + finite/>0 asserts pass |
| test_call.py assertions | freshly rebuilt build/librocket.dll | `make all` rebuild | ✓ WIRED | smoke run loads build/librocket.dll (exists, current — contains run_full_pipeline) |
| wrapper dict keys | ResultCard data.get('dv'|'diameter'|'length'|'volume') | key names fixed in 02-01 | ✓ WIRED | harness: 3 cards populated |
| results['v_circ'] | _last_v_circ → label + export + filename | single source | ✓ WIRED | harness T2(b): label == export source |
| propellant indices (combos) | Geometry_calc select-case tables | min(i,n) fallback | ✓ WIRED | integers 1..5 used by smoke/harness; valid rows for LH2/LOX |
| hint condition | wrapper packing all four keys | hint self-disables | ✓ WIRED | harness: hint absent after run |

### Data-Flow Trace (Level 4)

| Artifact | Data Variable | Source | Produces Real Data | Status |
| -------- | ------------- | ------ | ------------------ | ------ |
| run_full_pipeline | v_circ_out | Fortran `V_circ` global (Orbit_calc.f90:10) | Yes — formula-verified 7.615769 | ✓ FLOWING |
| run_full_pipeline | dv_out | Rocket%stage(i)%D_v (Staging.f90:141, converged) | Yes — sum bounds hold | ✓ FLOWING |
| run_full_pipeline | diameter/length_out | Geometry_calc store-back (real regressions) | Yes — finite/>0, real magnitudes | ✓ FLOWING |
| run_full_pipeline | volume_out | pi/4·D²·L identity on stored values | Yes — identity assert 1e-9 | ✓ FLOWING |
| GUI label/export | _last_v_circ | results['v_circ'] from wrapper | Yes — Fortran-origin, no Python physics | ✓ FLOWING |

### Behavioral Spot-Checks

| Behavior | Command | Result | Status |
| -------- | ------- | ------ | ------ |
| Full bridge chain (payload→orbit→STAGING_LOOP→geometry) | `python SRC/test_call.py` (independent re-run) | exit 0, ALL ASSERTIONS PASSED; v_circ=7.615769, sum_dv=10.0353 | ✓ PASS |
| DLL exports new entry (DLL current) | loaded + called run_full_pipeline via ctypes in smoke | success | ✓ PASS |
| GUI wiring: run, cards, label chain, invalidation, run-button tabs | `phase02_t3_harness.py` (offscreen, re-run) | exit 0 — static gates + T1/T2 + GATE A/B/C all green | ✓ PASS |
| py_compile of all modified Python | `python -m py_compile gui.py rocket_lib.py test_call.py` | clean | ✓ PASS |

### Probe Execution

| Probe | Command | Result | Status |
| ----- | ------- | ------ | ------ |
| CR-01 ghost-stage pollution (n=1, n=2, n=3 × modes 1/2) | `python phase02_cr01_probe.py` (temp, independent) | n=1 Constant: real stage forced to ghost 4.8378 m (pollution CONFIRMED); n=3 Constant: correct max of real stages (5.1142); WR-03 visible: n=1 sum_dv=6.9979 < v_circ=7.6158 | FAILED (defects confirmed — see gaps) |

### Requirements Coverage

| Requirement | Source Plan | Description | Status | Evidence |
| ----------- | ---------- | ----------- | ------ | -------- |
| PIPE-02 | 02-01 | Fortran interface exposes bindings to run full pipeline from Python (single ctypes entry), reusing modules, no physics reimplementation | ✓ SATISFIED | single run_full_pipeline entry; 4 modules called; no Python physics; smoke green |
| PIPE-01 | 02-02 | GUI drives full pipeline: orbit → payload → staging → thrust → geometry | ✓ SATISFIED | _run → rocket_lib.run_full_pipeline with all mission/config inputs; cards populate; harness green; T3 user-approved |

No orphaned requirements: REQUIREMENTS.md maps only PIPE-01/PIPE-02 to Phase 2, both claimed and both satisfied.

### Anti-Patterns Found

| File | Line | Pattern | Severity | Impact |
| ---- | ---- | ------- | -------- | ------ |
| gui.py | 398-399 vs 1018-1019 | ISP/k_s slider label updaters (398-399) now accompanied by invalidation wiring (1018-1019, commit fd29b9e) | ℹ️ Info | WR-01 RESOLVED — sliders invalidate results exactly like orbit/payload/stage/diameter changes; no residual warning |
| Geometry_calc.f90 | 101 | `maxval` over full 3-slot vector includes zero-mass ghost slots for n<3 (CR-01) | 🛑 Critical (untested domain) | Silently wrong diameters/lengths/volumes in Constant mode when n_stages < 3; pre-existing algorithm defect, newly reachable |
| Geometry_calc.f90 | 27-90, 105 | vacant/inverted table branches → NaN/negative geometry (WR-02) | ⚠️ Warning | 0/0 NaN renders '—' silently; negatives render literally; no validation |
| Thrust_calc.f90 | 19-21 | negative-thrust domain below 34 t / 6.2 t (WR-03) | ⚠️ Warning | converged ΔV below V_circ — physically impossible, no error surfaced |
| gui.py | 20-111, 459 | dead inline bridge twin + unused `_get_data` | ℹ️ Info | deliberate Phase 3 FIX-02 debt (IN-01); no defect |
| gui.py | 1199/1207 | duplicated `_last_results = results` | ℹ️ Info | harmless redundancy (IN-02) |

No TBD/FIXME/XXX markers in any phase-modified file. No stubs: the '— km/s' label and empty-state placeholder are designed partial-state idioms; the hint code is inert-but-guarding by design.

### Human Verification Required

None pending. The plan's blocking human gate (02-02-T3 interactive walkthrough) was completed and approved by the user on 2026-09-06, with two follow-ups (diameter-config invalidation, Run-button tab visibility) implemented in commits 51a5695/3e7eab2 and independently re-verified offscreen in this verification (GATE A/B/C green).

### Gaps Summary

**The phase goal is achieved:** the complete Fortran pipeline is exposed through exactly one new ctypes entry (`run_full_pipeline`), the GUI drives it end-to-end, results populate with real converged ΔV + geometry, and all physics remains in the reused Fortran modules (the Python `_auto_delta_v` mirror is gone). Roadmap SC 1-3 and requirements PIPE-01/PIPE-02 are satisfied; the bridge is behaviorally proven by an independent smoke re-run and an independent offscreen harness re-run.

**WR-01 — invalidation contract — RESOLVED (no longer gating).** 02-02 truth #6 asserts "converged numbers are never displayed or exported against changed inputs." Commit fd29b9e connects `isp_slider.valueChanged` and `ks_slider.valueChanged` through `_on_inputs_changed` (gui.py:1018-1019). Independently re-verified offscreen against a real post-run stale state: dragging each slider clears all ResultCards, resets `_last_v_circ` to None, restores '— km/s', and disables Save; the export guard warns with no file dialog; repeated drags accumulate no placeholders. Harness exit 0, 29/29 checks PASS.

**Three pre-existing Fortran robustness gaps on untested input domains (recorded for Phase 3 / fix; non-gating, outside this phase's scope):**
1. **CR-01 — ghost-stage diameter pollution** (Critical, empirically confirmed at n=1 × Constant mode): pre-existing Geometry_calc.f90 defect; the phase was explicitly prohibited from touching those formulas. Bound `maxval` to real stages and/or skip ghost select cases.
2. **WR-02 — NaN/negative geometry** from vacant/inverted regression branches: add per-stage geometry validation in `run_full_pipeline`.
3. **WR-03 — negative-thrust domain** below ~34 t stage-1 mass: `sum(dv) < v_circ` empirically observed at n=1; validate `T > 0` and `sum(D_v) >= V_circ` after STAGING_LOOP.

The three remaining gaps are pre-existing Fortran defects outside this phase's scope; none are covered by Phase 3's roadmap criteria (FIX-01/02/03), so none qualify for the deferred list; the user's disposition for CR-01 (and by extension WR-02/WR-03) is to record as robustness gaps for Phase 3/fix.

---

_Verified: 2026-09-06T23:01:13Z_
_Verifier: the agent (gsd-verifier)_