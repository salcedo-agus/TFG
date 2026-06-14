# test_call.py
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