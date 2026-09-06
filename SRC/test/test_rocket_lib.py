"""Unit tests for SRC/interface/rocket_lib.py (Phase 02 full-pipeline bridge).

Runs against the real rebuilt build/librocket.dll through the ctypes wrappers,
following the contract assertions proven by the 02-01 smoke hook (test_call.py)
and extending them to untested domains (n=1/2, diameter modes 1/2/3,
statistical-vs-constant modes, orbit-height monotonicity).

Run from the repo root:
    python -m unittest discover -s SRC/test -p "test_rocket_lib.py" -v
"""

import math
import os
import sys
import unittest

_TEST_DIR  = os.path.dirname(os.path.abspath(__file__))
_SRC_DIR   = os.path.abspath(os.path.join(_TEST_DIR, ".."))
_INTERFACE = os.path.join(_SRC_DIR, "interface")
if _INTERFACE not in sys.path:
    sys.path.insert(0, _INTERFACE)

from rocket_lib import run_full_pipeline, run_staging

# Constants mirroring Orbit_calc.f90:10 (g_0, Radius from the constants module)
G_0    = 9.80665
RADIUS = 6378.0

# Smoke baseline (test_call.py): LH2/LOX, n=3, orbit 500 km, payload 5000 kg
N3_CONFIG = dict(
    n_stages=3,
    orbit_height=500.0,
    payload_mass=5000.0,
    isp_list=[400.0, 350.0, 300.0],
    ks_list=[0.10, 0.15, 0.20],
    propellant_list=[1, 1, 1],
    diameter_setup=1,
    user_diameter=2.0,
)

H2_LOX_PROP = [1, 1, 1]


def v_circ_formula(orbit_height):
    """The Orbit_calc.f90:10 formula: sqrt(g_0*R^2 / ((R + h) * 1000))."""
    return math.sqrt(G_0 * RADIUS**2 / ((RADIUS + orbit_height) * 1000.0))


class RunFullPipelineContract(unittest.TestCase):
    """The wrapper return-dict contract (02-01 D3): keys, types, stage packing."""

    def test_run_full_pipeline_contract(self):
        r = run_full_pipeline(**N3_CONFIG)
        self.assertEqual(set(r.keys()),
                         {"total_initial_mass", "minimum_found", "v_circ", "stages"})
        self.assertIsInstance(r["minimum_found"], bool)
        self.assertIsInstance(r["v_circ"], float)
        self.assertGreater(r["total_initial_mass"], N3_CONFIG["payload_mass"])
        self.assertEqual(len(r["stages"]), 3)
        for s in r["stages"]:
            self.assertEqual(set(s.keys()),
                             {"stage", "m0", "mf", "mp", "ms", "k_m", "k_s",
                              "k_L", "nu_e", "dv", "diameter", "length", "volume"})
        self.assertEqual([s["stage"] for s in r["stages"]], [1, 2, 3])

    def test_v_circ_matches_orbit_formula(self):
        r = run_full_pipeline(**N3_CONFIG)
        self.assertAlmostEqual(r["v_circ"], v_circ_formula(500.0), delta=1e-6)

    def test_sum_dv_loss_bounds(self):
        """D-03: converged loss-inclusive total sits in (v_circ, v_circ + 5)."""
        r = run_full_pipeline(**N3_CONFIG)
        sum_dv = sum(s["dv"] for s in r["stages"])
        self.assertGreater(sum_dv, r["v_circ"])
        self.assertLess(sum_dv, r["v_circ"] + 5.0)

    def test_volume_identity(self):
        """Per-stage volume == pi/4 * D^2 * L (Geometry_calc.f90:105 identity)."""
        r = run_full_pipeline(**N3_CONFIG)
        for s in r["stages"]:
            expected = math.pi * s["diameter"]**2 * s["length"] / 4.0
            self.assertAlmostEqual(s["volume"], expected, delta=1e-9,
                                   msg=f"volume identity failed for stage {s['stage']}")

    def test_geometry_finite_positive(self):
        r = run_full_pipeline(**N3_CONFIG)
        for s in r["stages"]:
            for key in ("dv", "diameter", "length", "volume"):
                self.assertTrue(math.isfinite(s[key]),
                                f"{key} not finite for stage {s['stage']}")
                self.assertGreater(s[key], 0.0,
                                   f"{key} not > 0 for stage {s['stage']}")


class RunFullPipelineVariantDomains(unittest.TestCase):
    """Untested-by-smoke domains: stage counts and diameter modes."""

    def _baseline(self, **overrides):
        cfg = dict(N3_CONFIG, **overrides)
        return run_full_pipeline(**cfg)

    def test_stage_counts(self):
        """Contract holds for n=1 and n=2 (conservative: counts + sanity only —
        WR-03 makes physics bounds invalid on those domains until Phase 3)."""
        for n in (1, 2):
            r = self._baseline(n_stages=n,
                               isp_list=[400.0] * n,
                               ks_list=[0.10] * n,
                               propellant_list=[1] * n)
            self.assertEqual(len(r["stages"]), n)
            self.assertEqual([s["stage"] for s in r["stages"]], list(range(1, n + 1)))
            self.assertIsInstance(r["minimum_found"], bool)
            self.assertGreater(r["total_initial_mass"], 0.0)
            for s in r["stages"]:
                self.assertEqual(set(s.keys()),
                                 {"stage", "m0", "mf", "mp", "ms", "k_m", "k_s",
                                  "k_L", "nu_e", "dv", "diameter", "length", "volume"})

    def test_diameter_mode_user(self):
        """Mode 3: every stage takes the user-specified diameter."""
        r = self._baseline(diameter_setup=3, user_diameter=3.5)
        for s in r["stages"]:
            self.assertAlmostEqual(s["diameter"], 3.5, delta=1e-6,
                                   msg=f"user diameter not applied for stage {s['stage']}")

    def test_diameter_modes_distinct_at_n3(self):
        """n=3: mode 1 fits each stage statistically; mode 2 (Constant) takes the
        widest statistical diameter for all stages (no ghost slots at n=3, so
        CR-01's maxval pollution cannot corrupt the expected relation)."""
        stat = self._baseline(diameter_setup=1)
        const = self._baseline(diameter_setup=2)
        stat_d = [s["diameter"] for s in stat["stages"]]
        const_d = [s["diameter"] for s in const["stages"]]
        self.assertTrue(all(math.isfinite(d) and d > 0 for d in const_d))
        for d in const_d:
            self.assertAlmostEqual(d, max(stat_d), delta=1e-6,
                                   msg=f"constant mode diameter {d} != max(statistical) {max(stat_d)}")

    def test_v_circ_monotonic_with_height(self):
        """Lower orbits demand higher circular velocity; both match the formula."""
        low = self._baseline(orbit_height=100.0)
        high = self._baseline(orbit_height=2000.0)
        self.assertGreater(low["v_circ"], high["v_circ"])
        self.assertAlmostEqual(low["v_circ"], v_circ_formula(100.0), delta=1e-6)
        self.assertAlmostEqual(high["v_circ"], v_circ_formula(2000.0), delta=1e-6)


class RunStagingWrapperContract(unittest.TestCase):
    """Legacy run_staging wrapper regression companion (FIX-02 dedup debt)."""

    def test_run_staging_contract(self):
        r = run_staging(
            n_stages=3, delta_v=10.0, payload_mass=5000.0,
            isp_list=[400.0, 350.0, 300.0], ks_list=[0.10, 0.15, 0.20],
        )
        self.assertEqual(set(r.keys()), {"total_initial_mass", "minimum_found", "stages"})
        self.assertIsInstance(r["minimum_found"], bool)
        self.assertGreater(r["total_initial_mass"], 5000.0)
        self.assertEqual(len(r["stages"]), 3)
        for s in r["stages"]:
            self.assertEqual(set(s.keys()),
                             {"stage", "m0", "mf", "mp", "ms", "k_m", "k_s", "k_L", "nu_e"})
            for key in ("m0", "mf", "mp", "ms", "k_m", "k_s", "k_L", "nu_e"):
                self.assertTrue(math.isfinite(s[key]), f"{key} not finite stage {s['stage']}")


if __name__ == "__main__":
    unittest.main()