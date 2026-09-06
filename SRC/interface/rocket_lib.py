"""
rocket_lib.py  -  Python bridge to the Fortran staging solver.
Lives in:  interface/
DLL lives in:  build/
"""

import ctypes
import sys
import os

# interface/ is one level below SRC root
INTERFACE_DIR = os.path.dirname(os.path.abspath(__file__))
ROOT_DIR      = os.path.dirname(INTERFACE_DIR)
# build/ sits one level above SRC/, so two levels above interface/
BUILD_DIR     = os.path.join(ROOT_DIR, "..", "build")

if sys.platform == "win32":
    os.add_dll_directory(BUILD_DIR)
    mingw_bin = os.environ.get("MINGW_BIN", r"C:\TDM-GCC-64\bin")
    if os.path.isdir(mingw_bin):
        os.add_dll_directory(mingw_bin)
    lib = ctypes.CDLL(os.path.join(BUILD_DIR, "librocket.dll"))
else:
    lib = ctypes.CDLL(os.path.join(BUILD_DIR, "librocket.so"))

lib.run_staging.restype = None
lib.run_staging.argtypes = [
    ctypes.POINTER(ctypes.c_int),    # n_stages
    ctypes.POINTER(ctypes.c_double), # delta_v
    ctypes.POINTER(ctypes.c_double), # payload_mass
    ctypes.POINTER(ctypes.c_double), # isp_in      (array)
    ctypes.POINTER(ctypes.c_double), # ks_in       (array)
    ctypes.POINTER(ctypes.c_double), # m0_out      (array)
    ctypes.POINTER(ctypes.c_double), # mf_out      (array)
    ctypes.POINTER(ctypes.c_double), # mp_out      (array)
    ctypes.POINTER(ctypes.c_double), # ms_out      (array)
    ctypes.POINTER(ctypes.c_double), # km_out      (array)
    ctypes.POINTER(ctypes.c_double), # ks_out      (array)
    ctypes.POINTER(ctypes.c_double), # kl_out      (array)
    ctypes.POINTER(ctypes.c_double), # nu_e_out    (array)
    ctypes.POINTER(ctypes.c_double), # total_m0_out
    ctypes.POINTER(ctypes.c_int),    # minimum_found_out
]

lib.run_full_pipeline.restype = None
lib.run_full_pipeline.argtypes = [
    ctypes.POINTER(ctypes.c_int),    # n_stages
    ctypes.POINTER(ctypes.c_double), # orbit_height
    ctypes.POINTER(ctypes.c_double), # payload_mass
    ctypes.POINTER(ctypes.c_double), # isp(n)
    ctypes.POINTER(ctypes.c_double), # ks(n)
    ctypes.POINTER(ctypes.c_int),    # propellant(n)
    ctypes.POINTER(ctypes.c_int),    # diameter_setup
    ctypes.POINTER(ctypes.c_double), # user_diameter
    ctypes.POINTER(ctypes.c_double), # m0(n)
    ctypes.POINTER(ctypes.c_double), # mf(n)
    ctypes.POINTER(ctypes.c_double), # mp(n)
    ctypes.POINTER(ctypes.c_double), # ms(n)
    ctypes.POINTER(ctypes.c_double), # km(n)
    ctypes.POINTER(ctypes.c_double), # ks_out(n)
    ctypes.POINTER(ctypes.c_double), # kl(n)
    ctypes.POINTER(ctypes.c_double), # nu_e(n)
    ctypes.POINTER(ctypes.c_double), # dv(n)
    ctypes.POINTER(ctypes.c_double), # diameter(n)
    ctypes.POINTER(ctypes.c_double), # length(n)
    ctypes.POINTER(ctypes.c_double), # volume(n)
    ctypes.POINTER(ctypes.c_double), # total_m0
    ctypes.POINTER(ctypes.c_double), # v_circ
    ctypes.POINTER(ctypes.c_int),    # minimum_found
]

def run_staging(n_stages, delta_v, payload_mass, isp_list, ks_list):
    """Call the Fortran STAGING solver. Returns a dict with results."""
    n  = ctypes.c_int(n_stages)
    dv = ctypes.c_double(delta_v)
    pl = ctypes.c_double(payload_mass)

    isp  = (ctypes.c_double * n_stages)(*isp_list)
    ks   = (ctypes.c_double * n_stages)(*ks_list)
    m0   = (ctypes.c_double * n_stages)()
    mf   = (ctypes.c_double * n_stages)()
    mp   = (ctypes.c_double * n_stages)()
    ms   = (ctypes.c_double * n_stages)()
    km   = (ctypes.c_double * n_stages)()
    ks_o = (ctypes.c_double * n_stages)()
    kl   = (ctypes.c_double * n_stages)()
    nu_e = (ctypes.c_double * n_stages)()
    total_m0  = ctypes.c_double()
    min_found = ctypes.c_int()

    lib.run_staging(
        ctypes.byref(n), ctypes.byref(dv), ctypes.byref(pl),
        isp, ks,
        m0, mf, mp, ms, km, ks_o, kl, nu_e,
        ctypes.byref(total_m0), ctypes.byref(min_found)
    )

    return {
        "total_initial_mass": total_m0.value,
        "minimum_found":      bool(min_found.value),
        "stages": [
            {
                "stage": i + 1,
                "m0":    m0[i],
                "mf":    mf[i],
                "mp":    mp[i],
                "ms":    ms[i],
                "k_m":   km[i],
                "k_s":   ks_o[i],
                "k_L":   kl[i],
                "nu_e":  nu_e[i],
            }
            for i in range(n_stages)
        ]
    }

def run_full_pipeline(n_stages, orbit_height, payload_mass, isp_list, ks_list,
                      propellant_list, diameter_setup, user_diameter):
    """Call the Fortran full-pipeline entry (payload -> orbit -> staging ->
    geometry). Returns a dict with masses, ratios, per-stage dv and geometry."""
    n  = ctypes.c_int(n_stages)
    oh = ctypes.c_double(orbit_height)
    pl = ctypes.c_double(payload_mass)
    ds = ctypes.c_int(diameter_setup)
    ud = ctypes.c_double(user_diameter)

    isp  = (ctypes.c_double * n_stages)(*isp_list)
    ks   = (ctypes.c_double * n_stages)(*ks_list)
    prop = (ctypes.c_int * n_stages)(*propellant_list)
    m0   = (ctypes.c_double * n_stages)()
    mf   = (ctypes.c_double * n_stages)()
    mp   = (ctypes.c_double * n_stages)()
    ms   = (ctypes.c_double * n_stages)()
    km   = (ctypes.c_double * n_stages)()
    ks_o = (ctypes.c_double * n_stages)()
    kl   = (ctypes.c_double * n_stages)()
    nu_e = (ctypes.c_double * n_stages)()
    dv   = (ctypes.c_double * n_stages)()
    diam = (ctypes.c_double * n_stages)()
    leng = (ctypes.c_double * n_stages)()
    vol  = (ctypes.c_double * n_stages)()
    total_m0  = ctypes.c_double()
    v_circ    = ctypes.c_double()
    min_found = ctypes.c_int()

    lib.run_full_pipeline(
        ctypes.byref(n), ctypes.byref(oh), ctypes.byref(pl),
        isp, ks, prop,
        ctypes.byref(ds), ctypes.byref(ud),
        m0, mf, mp, ms, km, ks_o, kl, nu_e, dv, diam, leng, vol,
        ctypes.byref(total_m0), ctypes.byref(v_circ), ctypes.byref(min_found)
    )

    return {
        "total_initial_mass": total_m0.value,
        "minimum_found":      bool(min_found.value),
        "v_circ":             v_circ.value,
        "stages": [
            {
                "stage": i + 1,
                "m0":    m0[i],
                "mf":    mf[i],
                "mp":    mp[i],
                "ms":    ms[i],
                "k_m":   km[i],
                "k_s":   ks_o[i],
                "k_L":   kl[i],
                "nu_e":  nu_e[i],
                "dv":    dv[i],
                "diameter": diam[i],
                "length":   leng[i],
                "volume":   vol[i],
            }
            for i in range(n_stages)
        ]
    }
