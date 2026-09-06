# test_call.py
import os
import sys
sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), "interface"))
from rocket_lib import run_staging

results = run_staging(
    n_stages     = 3,
    delta_v      = 10.0,
    payload_mass = 5000.0,
    isp_list     = [400.0, 350.0, 300.0],
    ks_list      = [0.10,  0.15,  0.20],
)

print(f"Total initial mass: {results['total_initial_mass']:.1f} kg")
print(f"Minimum found: {results['minimum_found']}")
for s in results["stages"]:
    print(f"\n  Stage {s['stage']}")
    print(f"    m0={s['m0']:.1f} kg   mp={s['mp']:.1f} kg   ms={s['ms']:.1f} kg")
    print(f"    k_m={s['k_m']:.4f}   k_s={s['k_s']:.4f}   k_L={s['k_L']:.4f}")

# ---------------------------------------------------------------------------
# Full-pipeline smoke (run_full_pipeline) — PIPE-02 headless bridge proof
# ---------------------------------------------------------------------------
from rocket_lib import run_full_pipeline

import math

fp = run_full_pipeline(
    n_stages        = 3,
    orbit_height    = 500.0,
    payload_mass    = 5000.0,
    isp_list        = [400.0, 350.0, 300.0],
    ks_list         = [0.10,  0.15,  0.20],
    propellant_list = [1, 1, 1],          # LH2/LOX: valid geometry rows in all 3 stage tables
    diameter_setup  = 1,
    user_diameter   = 2.0,
)

print(f"\nv_circ: {fp['v_circ']:.6f} km/s")
for s in fp["stages"]:
    print(f"\n  Stage {s['stage']}")
    print(f"    dv={s['dv']:.4f} km/s   diameter={s['diameter']:.4f} m   "
          f"length={s['length']:.4f} m   volume={s['volume']:.4f} m3")

# (a) V_circ provenance: matches the Orbit_calc.f90:10 formula
g_0    = 9.80665
Radius = 6378.0
orbit_height = 500.0
v_circ_formula = math.sqrt(g_0 * Radius**2 / ((Radius + orbit_height) * 1000.0))
assert abs(fp["v_circ"] - v_circ_formula) < 1e-6, "v_circ does not match Orbit_calc formula"

# (b) per-stage dv/diameter/length/volume finite and > 0
assert all(math.isfinite(s["dv"])      and s["dv"]      > 0.0 for s in fp["stages"]), "dv not finite/>0"
assert all(math.isfinite(s["diameter"]) and s["diameter"] > 0.0 for s in fp["stages"]), "diameter not finite/>0"
assert all(math.isfinite(s["length"])   and s["length"]   > 0.0 for s in fp["stages"]), "length not finite/>0"
assert all(math.isfinite(s["volume"])   and s["volume"]   > 0.0 for s in fp["stages"]), "volume not finite/>0"

# (c) per-stage volume == pi/4 * D^2 * L identity
PI = 3.141592653589793
for s in fp["stages"]:
    assert abs(s["volume"] - PI * s["diameter"]**2 * s["length"] / 4.0) < 1e-9, \
        f"volume identity failed for stage {s['stage']}"

# (d) loss-inclusive converged total: v_circ < sum(dv) < v_circ + 5.0
sum_dv = sum(s["dv"] for s in fp["stages"])
assert fp["v_circ"] < sum_dv < fp["v_circ"] + 5.0, f"sum(dv)={sum_dv:.4f} out of (v_circ, v_circ+5)"

# (e) payload sanity + minimum_found is a bool
assert fp["total_initial_mass"] > 5000.0
assert isinstance(fp["minimum_found"], bool)

print("\nFull-pipeline smoke: ALL ASSERTIONS PASSED")