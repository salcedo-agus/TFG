"""
fairing_geometry.py
───────────────────────────────────────────────────────
Python-side mock fairing geometry computation for GUI integration validation.
No Fortran changes — fairing data is mocked in Python for Phase 4 (v1.1).
Replaced by Fortran implementation in v2+.
"""

import math


# D-07 constants (agent's discretion) — standard aerospace formulas
OGIVE_CALIBER = 3.0      # L/D ratio for tangent ogive fairing
VOLUME_FACTOR = 0.75     # Fairing volume ≈ 0.75 × cylinder volume
BOAT_TAIL_DEG = 10.0     # Hammer-Head boat-tail angle


def _ogive_coords(diameter: float, length: float) -> list[tuple[float, float]]:
    """
    Generate ogive profile coordinates (right half, from tip to base).

    Args:
        diameter: Fairing diameter in meters
        length: Ogive length in meters

    Returns:
        List of (x, y) coordinates from tip (0,0) to base (L, R)
    """
    R = diameter / 2
    L = length
    coords = [(0.0, 0.0)]  # tip
    for i in range(1, 21):  # 20 segments
        x = L * i / 20
        y = R * math.sqrt(max(0.0, 1.0 - (x / L)**2))
        coords.append((x, y))
    return coords


def _boat_tail_coords(fairing_d: float, body_d: float, angle_deg: float) -> tuple[list[tuple[float, float]], float]:
    """
    Generate boat-tail transition coordinates.

    Args:
        fairing_d: Fairing diameter in meters
        body_d: Body diameter in meters
        angle_deg: Boat-tail angle in degrees

    Returns:
        Tuple of (coords, bt_length) where coords is list of (x, y) from
        ogive base to body radius, and bt_length is the axial length.
    """
    bt_angle = math.radians(angle_deg)
    bt_length = (fairing_d - body_d) / 2 / math.tan(bt_angle)
    # Single point at the body radius
    coords = [(bt_length, body_d / 2)]
    return coords, bt_length


def compute_fairing_geometry(body_diameter: float, fairing_mode: int,
                             fairing_diameter: float | None = None) -> dict:
    """
    Compute fairing geometry from body diameter and fairing mode.

    Args:
        body_diameter: Body diameter in meters
        fairing_mode: 1=Constant, 2=Tapered, 3=Hammer-Head
        fairing_diameter: User-specified fairing diameter (for modes 2 and 3)

    Returns:
        dict with keys:
            diameter, length, volume, ogive_length, boat_tail_angle, coords
    """
    # Determine fairing diameter per mode (D-04 constraint matrix)
    if fairing_mode == 1:  # Constant: fairing = body
        fairing_d = body_diameter
    elif fairing_mode == 2:  # Tapered: fairing ≤ body (user-specified)
        fairing_d = fairing_diameter or body_diameter
    elif fairing_mode == 3:  # Hammer-Head: fairing > body (user-specified)
        fairing_d = fairing_diameter or body_diameter
    else:
        fairing_d = body_diameter

    ogive_length = OGIVE_CALIBER * fairing_d
    cylinder_length = ogive_length  # simplified: fairing ≈ ogive only
    cylinder_vol = math.pi / 4 * fairing_d**2 * cylinder_length
    volume = VOLUME_FACTOR * cylinder_vol

    # Diagram coordinates (true-scale 1m=1px, origin at fairing tip, Y-up)
    # Ogive profile using helper
    coords = _ogive_coords(fairing_d, ogive_length)

    # Add boat-tail for Hammer-Head
    bt_length = 0.0
    if fairing_mode == 3:
        bt_coords, bt_length = _boat_tail_coords(fairing_d, body_diameter, BOAT_TAIL_DEG)
        # Offset boat-tail coords by ogive length
        coords.extend([(ogive_length + x, y) for x, y in bt_coords])

    return {
        "diameter": fairing_d,
        "length": ogive_length + bt_length,
        "volume": volume,
        "ogive_length": ogive_length,
        "boat_tail_angle": BOAT_TAIL_DEG if fairing_mode == 3 else 0.0,
        "coords": coords,
    }


def compute_fairing_geometry_per_stage(body_diameters: list[float], fairing_mode: int,
                                        fairing_diameter: float | None = None) -> list[dict]:
    """
    Compute fairing geometry for each stage based on body diameters.

    For Phase 4 mock: same fairing geometry for all stages (per PLAN done criteria).
    """
    if not body_diameters:
        return []

    # Use the max body diameter for fairing (constant mode) or first stage
    body_d = max(body_diameters)
    fairing = compute_fairing_geometry(body_d, fairing_mode, fairing_diameter)

    # Return same fairing data for each stage (mock behavior per FAIR-04)
    return [fairing.copy() for _ in body_diameters]


if __name__ == "__main__":
    # Quick self-test
    r = compute_fairing_geometry(2.0, 1)
    print(f"Constant mode (body=2.0): {r}")
    assert r['diameter'] == 2.0
    assert abs(r['ogive_length'] - 6.0) < 0.01
    assert r['volume'] > 0
    print("OK: Constant mode test passed")

    # Test Tapered mode
    r = compute_fairing_geometry(2.0, 2, 1.5)
    print(f"Tapered mode (body=2.0, fairing=1.5): {r}")
    assert r['diameter'] == 1.5
    assert abs(r['ogive_length'] - 4.5) < 0.01
    assert r['boat_tail_angle'] == 0.0
    print("OK: Tapered mode test passed")

    # Test Hammer-Head mode
    r = compute_fairing_geometry(2.0, 3, 3.0)
    print(f"Hammer-Head mode (body=2.0, fairing=3.0): {r}")
    assert r['diameter'] == 3.0
    assert r['boat_tail_angle'] == 10.0
    assert len(r['coords']) > 20  # ogive (21) + boat-tail (1)
    print("OK: Hammer-Head mode test passed")

    # Test helper functions
    ogive = _ogive_coords(2.0, 6.0)
    assert len(ogive) == 21
    assert ogive[0] == (0.0, 0.0)
    assert abs(ogive[-1][0] - 6.0) < 0.01
    assert abs(ogive[-1][1] - 0.0) < 0.01  # base of ogive is at y=0
    print("OK: _ogive_coords test passed")

    bt_coords, bt_len = _boat_tail_coords(3.0, 2.0, 10.0)
    assert len(bt_coords) == 1
    assert abs(bt_coords[0][1] - 1.0) < 0.01  # body_d/2 = 1.0
    print("OK: _boat_tail_coords test passed")

    print("\\nAll tests passed!")