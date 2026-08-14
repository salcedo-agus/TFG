---
phase: 01-centralized-3-tab-gui
verified: 2026-08-14T23:30:00Z
status: human_needed
score: 22/23 must-haves verified
behavior_unverified: 0
overrides_applied: 0
human_verification:
  - test: "Run `make gui` in SRC/ (builds build/librocket.dll then launches). Confirm: splash shows first and fades with the 600 ms InOutQuad curve into the main window; the window opens to 3 styled tabs in order Results / Setup / Vehicle Configuration with Results active; selected tab renders ACCENT (#58a6ff); no trace of the old left/right split; window enforces 960x700 minimum."
    expected: "Splash-first launch, 3-tab workbench in contractual order, styled tab bar, no ghost panels."
    why_human: "Requires building librocket.dll (MinGW/TDM-GCC toolchain) and an interactive display — impossible in the verification environment (DLL absent, documented STATE.md blocker). Recorded as human_judgment item D7 in 01-01-SUMMARY."
  - test: "In Setup (make gui): confirm Orbit Height shows 500.0 by default; changing it updates the read-only 'ΔV (auto)' label, clears Results, and disables Save; Run with a valid propellant/cycle combination works; Save exports a .txt whose Delta-V line equals the label value and whose suggested filename follows staging_{n}stage_dv{dv:.1f}_pl{pl}kg.txt."
    expected: "Mission inputs editable; ΔV read-only and always consistent across label/solver/export."
    why_human: "Interactive GUI + real DLL required; recorded as human_judgment item D5 in 01-02-SUMMARY."
  - test: "In Results after Run (make gui): each card shows the 8 original metrics unchanged plus 2 new rows (Stage ΔV / Diameter; Length / Volume) all rendering '—' in dim text; the partial-state hint appears once below the cards; the app auto-switches to Results; changing an input invalidates without navigating; Save twice re-opens the dialog each time and the exported .txt is identical in structure to a pre-phase file (only the Delta-V line source differs); the minimum indicator shows ✔/✘ per the run; the window is unresponsive mid-run (blocking, expected)."
    expected: "Results surface complete: 10 metric slots per stage, placeholder semantics, auto-switch, idempotent export, verbatim indicator, blocking solver."
    why_human: "Interactive GUI + real DLL required; recorded as human_judgment item D5 in 01-03-SUMMARY."
  - test: "Run `python SRC/test_call.py` from a machine with build/librocket.dll present (phase gate smoke for the unchanged ctypes bridge)."
    expected: "Bridge smoke passes; behavior unchanged by construction (zero diff in gui.py:22-110)."
    why_human: "test_call.py imports the DLL at load — cannot execute here. Recorded as human_judgment item D6 in 01-02/01-03-SUMMARYs."
  - test: "Backstop (01-01 truth #9): at the 960px minimum window width, open the Combustion Cycle dropdown on a stage widget and confirm the 61-char cycle name 'Aproximates Engine Perfermoance Only Base On Propellant/Oxidizer' elides readably, and the 3-tab bar (with 'Vehicle Configuration') still fits without clipping."
    expected: "Dropdown readable via Qt elision; tab bar fits at 960px. (setMinimumWidth(220) is present on both combos — gui.py:345,354 — pre-existing and preserved; the visual outcome needs eyes.)"
    why_human: "Declared `verification: backstop` in 01-01-PLAN — visual rendering cannot be confirmed by grep/offscreen checks."
---

# Phase 1: Centralized 3-Tab GUI Verification Report

**Phase Goal:** Restructure the GUI into a centralized 3-tab workbench with mission inputs, results display, geometry results, and vehicle-configuration (diameter mode).
**Verified:** 2026-08-14T23:30:00Z
**Status:** human_needed
**Re-verification:** No — initial verification

## Verification Evidence Base

Evidence is NOT the SUMMARY self-checks. The SUMMARYs claim offscreen smoke counts (38/38, 17/17, 26/26, 22/22, 21/21) from scripts (`smoke_tabs.py`, `smoke_0102_t1.py`, `smoke_0102_t2.py`, `smoke_0103_t1.py`, `smoke_0103_t2.py`) that **do not exist anywhere in the repository** — they were ephemeral executor artifacts and are non-reproducible. The verifier therefore ran an **independent offscreen harness** (`verify_phase1.py`, PyQt6 6.11.0, offscreen platform, fake bridge replacing the DLL-backed `run_staging` — bridge itself zero-diff so unmocked behavior is unchanged) exercising the real widget code: **88/88 checks PASS** (87 automated + 1 confirmed by direct source read of the appended QSS block gui.py:312-320). Combined with `git diff acacf1b..HEAD` analysis, `py_compile` (OK), and full source reads.

## Goal Achievement

### Observable Truths (roadmap success criteria)

| # | Truth | Status | Evidence |
|---|-------|--------|----------|
| SC1 | App opens to three tabs: Results (central), Setup (sliders + propellant/cycle), Vehicle Configuration (diameter mode) | ✓ VERIFIED | `MainWindow._build_ui` (gui.py:736-740): `addTab` order Results/Setup/Vehicle Configuration; offscreen: count==3, labels exact, currentIndex==0 on open, not movable/closable; Setup holds stage widgets with sliders + prop/cycle combos; Vehicle holds diameter-mode radios |
| SC2 | Results tab shows per-stage masses, mass ratios, per-stage ΔV, exhaust velocity, geometry (diameter, length, volume) | ✓ VERIFIED* | ResultCard rows 0-3 (m0/mf/mp/ms/k_m/k_s/k_L/nu_e) populated from bridge dict; rows 4-5 (Stage ΔV, Diameter, Length, Volume) present with exact formatting contract. *Per-stage ΔV + geometry render "—" TEXT_DIM placeholders until Phase 2 packs them — user-approved partial population (CONTEXT/UI-SPEC:155), not a stub; Phase 2 fills rows without signature churn (offscreen-verified with a full dict: "7.62 km/s", "4.12 m", "12.35 m", "150.99 m³") |
| SC3 | Mission inputs (orbit height, payload, stage count) editable in GUI; ΔV never hand-entered | ✓ VERIFIED | orbit_height (100-2000, dec 1, step 10, default 500) + pl_spin + n_stages_spin editable; `dv_spin` zero matches repo-wide; read-only auto_dv_label (QLabel); ΔV flows from `_auto_delta_v()` to label/solver/export consistently (offscreen: label updates 7.62→7.35 km/s on orbit change; export Delta-V line == label) |
| SC4 | Vehicle Configuration offers statistical/constant/user-specified diameter; specified shows an input box | ✓ VERIFIED | 3 QRadioButtons, QButtonGroup ids 1/2/3, mode 1 default checked; diameter_spin (0.5-20, dec 2, step 0.1, default 2.00) visible iff mode 3 (offscreen: visibility contract + persistence across toggles/tab switches verified) |
| SC5 | "Save Results" export, minimum-confirmed indicator, splash screen all still work | ✓ VERIFIED | Export: real file written with header block, auto ΔV line, filename pattern `staging_3stage_dv7.6_pl5000kg.txt`, dialog re-opens per save, two saves byte-identical; indicator: GREEN "✔  Minimum confirmed" / ACCENT2 "✘  Minimum not confirmed — check your inputs" both paths exercised (offscreen), strings byte-identical to pre-phase (git show acacf1b:958-959); splash: AppWindow stack index 0 on launch, 600 ms InOutQuad fade (offscreen), zero diff in Splash/AppWindow regions |

### Must-Haves (plan truths, 23 total)

**01-01-PLAN (GUI-01, GUI-04, GUI-08) — 8 truths:**

| # | Truth | Status | Evidence |
|---|-------|--------|----------|
| T1 | 3 tabs contractual order, labels exact, not movable/closable/renamable | ✓ VERIFIED | gui.py:736-740; offscreen checks |
| T2 | Tab-bar/radio QSS appended to STYLE, palette constants only, existing rules untouched | ✓ VERIFIED | Diff shows single append at old line 309 (guipy:312-320) — block matches UI-SPEC:88-98 exactly; source read confirms only `{BG_DARK}`…`{ACCENT}` interpolations; all other STYLE hunks zero |
| T3 | Each tab page QScrollArea + setWidgetResizable(True) + stretch bookends; min size 960x700 on MainWindow + AppWindow | ✓ VERIFIED | gui.py:748-756, 771-778, 866-873, 848/933/756 addStretch; setMinimumSize at 731, 1156; offscreen min-size check |
| T4 | Setup tab verbatim relocation; stage rebuild exactly n (1-3), no zero-stage state | ✓ VERIFIED | gui.py:769-858; offscreen 1→3 rebuild; n_stages_spin range 1-3 (814) |
| T5 | run_btn ready-property dim/undim; print_btn disabled until first successful run | ✓ VERIFIED | gui.py:839-845, 986-990 (unpolish/polish), 763; offscreen pre-run disabled, enabled after run |
| T6 | Results empty state at layout index 0; render order summary→indicator→divider→cards; Save enabled; captures | ✓ VERIFIED | gui.py:967-972, 1093-1137; offscreen: empty state text at index 0, order, 3 cards, `_last_results`/`_last_configs` captured |
| T7 | "Missing Data" + "Fortran Error" modals preserved | ✓ VERIFIED | gui.py:1070-1075, 1086-1088; source scan; diff shows no hunks in the validation block beyond the ΔV-arg swap |
| T8 | Splash preserved: stack + 600 ms InOutQuad fade; splash first | ✓ VERIFIED | Diff guard: zero hunks in original ranges 582-700 (SplashScreen) and 990-1019 (AppWindow); offscreen: stack index 0, duration 600, InOutQuad |
| T9 | Backstop: combo readability + tab-bar fit at 960px | ⚠️ HUMAN | setMinimumWidth(220) present on both combos (gui.py:345,354 — pre-existing); visual outcome requires human (see Human Verification #5) |

**01-02-PLAN (GUI-05, GUI-06, GUI-07) — 7 truths:**

| # | Truth | Status | Evidence |
|---|-------|--------|----------|
| T10 | Mission grid rows 0-3: orbit height contract; payload/stages verbatim; read-only "ΔV (auto)" {:.2f} km/s TEXT_SEC 12px | ✓ VERIFIED | gui.py:796-822; offscreen: all widget-contract checks + label "7.62 km/s" @500 km |
| T11 | `dv_spin` fully removed — no ΔV input anywhere | ✓ VERIFIED | `git grep dv_spin` → zero matches; offscreen: no `dv_spin` attribute |
| T12 | Auto-ΔV feeds label, run_staging delta_v, export header/filename; updates on orbit change | ✓ VERIFIED | gui.py:820/1007/1081/1014/1017/1030; offscreen: label update + export Delta-V line == label + filename pattern |
| T13 | `_auto_delta_v()` mirrors Orbit_calc.f90:9-10 (g_0=9.80665, R=6378.0), marked interim; no other physics duplication | ✓ VERIFIED | gui.py:997-1003 (docstring interim, PIPE-01); repo grep: 9.80665/6378 only at gui.py:1001; math independently recomputed (7.62 km/s @500 km matches) |
| T14 | Vehicle tab: 3 mutually-exclusive radios with helper lines; mode 1 default checked; ids 1/2/3 | ✓ VERIFIED | gui.py:887-911, 895-901; offscreen: labels exact, ids, default state, exclusivity |
| T15 | Diameter box visible only in mode 3; value persists across toggles/tab switches | ✓ VERIFIED | gui.py:917-930; offscreen: hidden/visible transitions, 5.55 persists across toggles + tab switch |
| T16 | Mode int + diameter value stored as MainWindow state; NOT wired into run_staging | ✓ VERIFIED | gui.py:900, 944-950; offscreen source scan: run_staging call (1079-1085) carries no diameter args |

**01-03-PLAN (GUI-02, GUI-03, GUI-04) — 8 truths:**

| # | Truth | Status | Evidence |
|---|-------|--------|----------|
| T17 | ResultCard: 8 legacy metrics + 2 new rows (Stage ΔV/Diameter; Length/Volume) | ✓ VERIFIED | gui.py:585-598; offscreen: all 4 new row labels + ≥4 "—" glyphs per card |
| T18 | Formatting contract via fmt-aware add_metric, legacy default keeps rows 0-3 byte-identical | ✓ VERIFIED | gui.py:569-583 (two-branch formatter: `fmt % value` / `{value:{fmt.lstrip(':')}}`); offscreen: legacy "1,000.0 kg" byte-identical; %.2f rows exact |
| T19 | Missing values render "—" TEXT_DIM via .get(); hint once below cards; absent pre-run | ✓ VERIFIED | gui.py:572-575, 595-598, 1121-1128; offscreen: hint once after run, absent pre-run and after invalidation |
| T20 | Auto-switch to tab 0 after successful Run; invalidation never navigates | ✓ VERIFIED | gui.py:1141 (after setEnabled(True) at 1138); offscreen: index 0 after run; stays after invalidation |
| T21 | Export contract: header block, auto ΔV line, filename pattern, dialog per save, idempotent | ✓ VERIFIED | gui.py:1014-1052; offscreen: real file written, header "ROCKET STAGING RESULTS", `Delta-V: 7.62 km/s`, filename pattern, 2 dialog calls, identical content across saves |
| T22 | Minimum indicator verbatim (messages, colors, minimum_found source) | ✓ VERIFIED | gui.py:1102-1108; strings byte-identical to acacf1b:958-959; offscreen both GREEN ✔ and ACCENT2 ✘ paths |
| T23 | Blocking solver, no threading machinery | ✓ VERIFIED | `_run` source scan: no QThread; try/except around blocking run_staging (1078-1088); QThread import deliberately dead (A6) |

**Score:** 22/23 truths verified (1 backstop routed to human). Roadmap success criteria: 5/5.

### Required Artifacts

| Artifact | Expected | Status | Details |
| -------- | ----------- | ------ | ------- |
| `SRC/gui/gui.py` — QTabWidget central widget, 3 tab pages (0/1/2) | GUI-01 shell | ✓ VERIFIED | gui.py:736-740; offscreen instantiated |
| `SRC/gui/gui.py` — Setup tab (header/mission/stages_container/run_btn) | GUI-05 inputs | ✓ VERIFIED | gui.py:769-858 |
| `SRC/gui/gui.py` — Results tab (render surface + print_btn) | GUI-02/03/04 surface | ✓ VERIFIED | gui.py:746-767 + render path 1090-1147 |
| `SRC/gui/gui.py` — Vehicle tab (radios + helpers + diameter_spin) | GUI-06/07 | ✓ VERIFIED | gui.py:860-935 |
| `SRC/gui/gui.py` — `_auto_delta_v()`/`_update_auto_dv_label()` | GUI-05 internal ΔV | ✓ VERIFIED | gui.py:997-1007 |
| `SRC/gui/gui.py` — ResultCard rows 4-5 + hint + auto-switch | GUI-02/03/04 | ✓ VERIFIED | gui.py:569-598, 1121-1141 |

### Key Link Verification

| From | To | Via | Status | Details |
| ---- | --- | --- | ------ | ------- |
| StageInputWidget `validity_changed` | `_update_run_button` + `_on_inputs_changed` | signal connect in `_rebuild_stage_inputs` (960-961) | ✓ WIRED | Cross-tab invalidation works (offscreen: input change clears Results, disables Save) |
| `_rebuild_stage_inputs` | Setup tab `stages_layout` | attribute reference (830-833, 952-963) | ✓ WIRED | 1→3 rebuild offscreen-verified |
| `_print_results` | `_last_configs`/`_last_results` | capture in `_run` success path (1130-1137) | ✓ WIRED | Export contains per-stage propellant/cycle + metrics |
| `orbit_height.valueChanged` | `_on_inputs_changed` + `_update_auto_dv_label` | fan-out (854-855) | ✓ WIRED | Label updates + invalidation offscreen-verified |
| `_auto_delta_v()` | `run_staging` delta_v + export header/filename | 1081 / 1014,1017,1030 | ✓ WIRED | Consistency offscreen-verified |
| `mode_user.toggled` | `diameter_spin.setVisible` | 930 | ✓ WIRED | Visibility contract offscreen-verified |
| `mode_buttons.buttonToggled` | `self.diameter_mode` | `_on_mode_toggled` (931, 944-950) | ✓ WIRED | Mode int 1/2/3 transitions offscreen-verified |
| ResultCard `.get()` defaults | Phase 2 bridge dict keys (dv/diameter/length/volume) | 595-598 | ✓ WIRED | Signature-stable handoff demonstrated with full dict |
| Render block → `results_layout`; `print_btn.setEnabled(True)` + `setCurrentIndex(0)` | same success path | 1090-1141 | ✓ WIRED | Offscreen-verified |

### Data-Flow Trace (Level 4)

| Artifact | Data Variable | Source | Produces Real Data | Status |
| -------- | ------------- | ------ | ------------------ | ------ |
| ResultCard rows 0-3 | m0/mf/mp/ms/k_m/k_s/k_L/nu_e | `run_staging()` bridge dict ← ctypes ← Fortran (gui.py:101-110, unchanged) | ✓ real bridge values | ✓ FLOWING |
| ResultCard rows 4-5 | dv/diameter/length/volume | bridge dict keys (absent in Phase 1) → designed "—" placeholder | designed partial state (Phase 2) | ✓ FLOWING (as designed) |
| ΔV (auto) label + export ΔV | `_auto_delta_v()` | orbit_height + interim V_circ mirror | real computed value (7.62 @500 km, physics-verified vs Fortran) | ✓ FLOWING |
| Export file | `_last_results`/`_last_configs` | captured run state | real file verified on disk | ✓ FLOWING |
| diameter_mode/diameter_spin | MainWindow state | user selection | stored for Phase 2 handoff (not wired to Fortran — by design, Pitfall 8) | ✓ FLOWING |

No static returns, hardcoded literals, or mock data sources in any rendered value.

### Behavioral Spot-Checks

| Behavior | Command | Result | Status |
| -------- | ------- | ------ | ------ |
| Module compiles | `python -m py_compile SRC/gui/gui.py` | PY_COMPILE_OK | ✓ PASS |
| Tab shell + mission grid + vehicle tab + render + export + splash (88 checks, independent harness with fake bridge — bridge itself zero-diff) | `python verify_phase1.py` (QT_QPA_PLATFORM=offscreen, PyQt6 6.11.0) | 88/88 PASS | ✓ PASS |
| `dv_spin` removed | `git grep dv_spin HEAD -- SRC/gui/gui.py` | exit 1, no matches | ✓ PASS |
| No ghost panels | `git grep -E "left_layout|right_layout|root_layout" HEAD -- SRC/gui/gui.py` | no matches | ✓ PASS |
| Diff guard (DLL load 22-59, bridge 80-110, `_load_data` 114-130, Splash 582-700, AppWindow 990-1019, entry 1023-1028) | `git diff acacf1b..HEAD -- SRC/gui/gui.py` | 15 hunks, none in guarded ranges | ✓ PASS |
| Indicator strings byte-identical | `git show acacf1b:SRC/gui/gui.py` vs current | "✔  Minimum confirmed" / "✘  Minimum not confirmed — check your inputs" identical | ✓ PASS |
| No config.txt reads (D-14) | grep config in gui.py | comments only, no file I/O | ✓ PASS |
| No physics duplication (PIPE-02) | grep 9.80665/6378 | only `_auto_delta_v` (gui.py:1001) | ✓ PASS |
| Debt markers in phase diff | grep TBD/FIXME/XXX in diff | none | ✓ PASS |

### Probe Execution

No probe scripts exist in the repo (`scripts/*/tests/probe-*.sh` — none; not applicable to this GUI phase). The plans' verification gates were `py_compile` (executed: PASS) plus the DLL-dependent `test_call.py`/`make gui` (unrunnable here — human items below). The SUMMARYs' claimed offscreen smoke scripts are absent from the repository; the verifier's own harness substitutes independent evidence (88/88 PASS).

### Requirements Coverage

| Requirement | Source Plan | Description | Status | Evidence |
| ----------- | ---------- | ----------- | ------ | -------- |
| GUI-01 | 01-01 | 3-tab workbench (Results central / Setup / Vehicle Configuration) | ✓ SATISFIED | T1-T3; SC1 |
| GUI-02 | 01-03 | Per-stage m0/mf/mp/ms, ratios, ΔV, exhaust velocity | ✓ SATISFIED | T17-T19; SC2 (ΔV field present, "—" until Phase 2 by user approval) |
| GUI-03 | 01-03 | Per-stage geometry (diameter, length, volume) | ✓ SATISFIED | T17-T19; SC2 (fields present, "—" until Phase 2) |
| GUI-04 | 01-01, 01-03 | Save Results export + minimum-confirmed indicator retained | ✓ SATISFIED | T5-T7, T21-T23; SC5 |
| GUI-05 | 01-02 | Mission inputs in GUI; ΔV computed internally | ✓ SATISFIED | T10-T13; SC3 |
| GUI-06 | 01-02 | Three diameter modes (statistical/constant/user-specified) | ✓ SATISFIED | T14; SC4 |
| GUI-07 | 01-02 | User-specified mode exposes diameter input box | ✓ SATISFIED | T15; SC4 |
| GUI-08 | 01-01 | Splash screen preserved | ✓ SATISFIED | T8; diff guard; SC5 |

All 8 requirement IDs accounted for — no orphans, none unclaimed. (REQUIREMENTS.md traceability table also marks all GUI-01..08 Complete, consistent with implementation.)

### Anti-Patterns Found

| File | Line | Pattern | Severity | Impact |
| ---- | ---- | ------- | -------- | ------ |
| SRC/gui/gui.py | 1078-1147 | Render block outside the try/except (REVIEW WR-01) | ⚠️ Warning | Advisory: no crash path under the current bridge contract; would matter if Phase 2 changes the dict contract. No phase-goal impact. |
| SRC/gui/gui.py | 1010, 1036 | `_print_results` guard asymmetry (REVIEW WR-02) | ⚠️ Warning | Advisory: `_last_configs` unguarded + silent zip truncation — unreachable today (same success path). Phase 2 should snapshot both. |
| SRC/gui/gui.py | 569-583, 1121-1125 | `add_metric` None-guard only covers None (REVIEW WR-03) | ⚠️ Warning | Advisory: non-numeric Phase 2 values would crash the card render; NaN would render "nan". Current Phase 1 dict keys are all numeric-or-absent. |
| SRC/gui/gui.py | 318-320 | Radio indicator QSS renders accent square (REVIEW IN-08) | ℹ️ Info | Cosmetic (missing border-radius on indicator). |
| SRC/gui/gui.py | 917-926 | Diameter label visible in modes 1/2 while spinbox hidden (REVIEW IN-04) | ℹ️ Info | Minor UX wart; contract (box visibility) is satisfied. |
| SRC/gui/gui.py | 585-592 | Legacy card rows 1-decimal vs UI-SPEC %.4f ratio contract (REVIEW IN-05) | ℹ️ Info | Spec/plan conflict resolved by plan truth #2 (byte-identical legacy); spec amendment recommended for Phase 2. |

No TBD/FIXME/XXX markers in the phase diff; no stub/empty implementations; "—" placeholders and `_auto_delta_v` are user-approved designed states, not stubs. All REVIEW.md findings are advisory (0 critical) — none block the phase goal.

### Human Verification Required

**1. Full GUI walkthrough — shell & splash (01-01 coverage D7)**
**Test:** Run `make gui` in SRC/ (builds build/librocket.dll, then launches). Confirm splash shows first and fades (600 ms InOutQuad) into the window; 3 styled tabs in order Results / Setup / Vehicle Configuration, Results active; selected tab ACCENT; no old split; 960x700 minimum enforced.
**Expected:** Splash-first launch, contractual tab order, styled tab bar, no ghost panels.
**Why human:** Needs the MinGW/TDM-GCC DLL build and an interactive display — impossible here (DLL absent; STATE.md blocker).

**2. Mission-inputs walkthrough (01-02 coverage D5)**
**Test:** In Setup: Orbit Height default 500.0; changing it updates the read-only "ΔV (auto)" label, clears Results, disables Save; Run with a valid combo works; Save exports a .txt whose Delta-V line equals the label and whose suggested filename follows `staging_{n}stage_dv{dv:.1f}_pl{pl}kg.txt`.
**Expected:** Mission inputs editable; ΔV read-only and consistent across label/solver/export.
**Why human:** Interactive GUI + real DLL required.

**3. Results-surface walkthrough (01-03 coverage D5)**
**Test:** After Run: 8 original metrics unchanged + 2 new rows all "—" in dim text; hint once below cards; app auto-switches to Results; input change invalidates without navigating; Save twice re-opens the dialog each time, exported .txt identical in structure to a pre-phase file; minimum indicator ✔/✘; window unresponsive mid-run (blocking, expected).
**Expected:** Complete results surface with placeholder semantics, auto-switch, idempotent export, verbatim indicator.
**Why human:** Interactive GUI + real DLL required.

**4. Phase gate `python SRC/test_call.py` (01-02/01-03 coverage D6)**
**Test:** Run on a machine with build/librocket.dll present.
**Expected:** Bridge smoke passes (bridge code zero-diff, so behavior unchanged by construction).
**Why human:** test_call.py imports the DLL at load; cannot execute here.

**5. Backstop — combo readability & tab-bar fit at 960px (01-01 truth #9)**
**Test:** At 960px min width, open the Combustion Cycle dropdown; confirm the 61-char cycle name elides readably and the tab bar fits without clipping.
**Expected:** Readable dropdown (setMinimumWidth(220) verified present — gui.py:345,354) and tab-bar fit.
**Why human:** Declared `verification: backstop`; visual outcome needs eyes.

### Gaps Summary

**No gaps found.** All 23 plan truths resolve VERIFIED except the single declared backstop (routed to human); all 5 roadmap success criteria are achieved (SC2 with the user-approved "—" placeholder caveat for per-stage ΔV/geometry pending Phase 2). All 8 requirements (GUI-01..08) are satisfied. The 3 REVIEW.md warnings are advisory robustness items for Phase 2, explicitly non-blocking. The `make gui` walkthroughs, the `test_call.py` gate, and the backstop visual check could not run in this environment (no build/librocket.dll, no interactive display) — the executors recorded them as human_judgment items; they are surfaced above and drive the `human_needed` status. Automated/offscreen evidence is complete and independently reproduced (88/88 harness checks + diff guards + source reads).

---

_Verified: 2026-08-14T23:30:00Z_
_Verifier: the agent (gsd-verifier)_