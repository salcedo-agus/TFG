"""
parse_typical_data.py
─────────────────────
Reads inout/Typical_Data.f90 and generates gui/typical_data_ranges.py.

Run this script whenever you update Typical_Data.f90:
    python parse_typical_data.py

The GUI imports typical_data_ranges.py at startup, so changes to the
Fortran file are picked up automatically after re-running this script.
No other files need to be edited.
"""

import re
import os
import sys
from datetime import datetime

# ── Paths ─────────────────────────────────────────────────────────────────────
# Script lives in inout/ so root SRC is one level up
SCRIPT_DIR   = os.path.dirname(os.path.abspath(__file__))
ROOT_DIR     = os.path.dirname(SCRIPT_DIR)
FORTRAN_FILE = os.path.join(SCRIPT_DIR, "Typical_Data.f90")
OUTPUT_FILE  = os.path.join(ROOT_DIR,   "gui", "typical_data_ranges.py")

# ── Regex patterns ─────────────────────────────────────────────────────────────
# Matches:  case(1) ! 1 - LIQUID HYDROGEN / LIQUID OXYGEN (LH2/LOX)
RE_PROP_CASE  = re.compile(
    r'select case \((?:first|second|third)_stage_propellant_and_oxidizer\)',
    re.IGNORECASE
)
RE_PROP_LINE  = re.compile(
    r'case\s*\((\d+)\)\s*!\s*\d+\s*-\s*(.+)',
    re.IGNORECASE
)
# Matches:  case (1) ! 1 - STAGED COMBUSTION
RE_CYCLE_CASE = re.compile(
    r'select case \((?:first|second|third)_stage_combustion_cycle\)',
    re.IGNORECASE
)
RE_CYCLE_LINE = re.compile(
    r'case\s*\((\d+)\)\s*!\s*\d+\s*-\s*(.+)',
    re.IGNORECASE
)
# Matches assignment lines like:
#   First_stage_ISP_lower = 445.6d0
RE_ASSIGN = re.compile(
    r'(?:First|Second|Third)_stage_(ISP|ks)_(lower|upper|mean)\s*=\s*([\d.]+)d0',
    re.IGNORECASE
)
# Matches "WARNING" lines (invalid combinations like electric pump for LH2)
RE_WARNING = re.compile(r'print\s*\*\s*,\s*"WARNING', re.IGNORECASE)


def parse_fortran(path):
    """
    Parse Typical_Data.f90 and return:
      - propellants: dict {index: name}
      - cycles:      dict {index: name}
      - data:        dict {(prop_idx, cycle_idx): (isp_lo, isp_hi, isp_mean,
                                                    ks_lo,  ks_hi,  ks_mean)}
    Only the FIRST select case block is parsed (First_stage_*) since all
    three stage blocks contain identical propellant/cycle combinations.
    """
    with open(path, "r", encoding="utf-8") as f:
        lines = f.readlines()

    propellants = {}   # {1: "LH2 / LOX", 2: "RP-1 / LOX", ...}
    cycles      = {}   # {0: "Propellant-based", 1: "Staged Combustion", ...}
    data        = {}   # {(prop, cycle): (isp_lo, isp_hi, isp_mean, ks_lo, ks_hi, ks_mean)}

    # ── State machine ──────────────────────────────────────────────────────────
    in_first_prop_select  = False   # inside the first select case (propellant)
    in_first_cycle_select = False   # inside the inner select case (cycle)
    past_first_prop       = False   # stop after first prop block is fully parsed

    current_prop  = None
    current_cycle = None
    values        = {}    # accumulates ISP/ks assignments for current (prop, cycle)
    is_invalid    = False # True when a WARNING print replaces assignments

    prop_select_depth  = 0
    cycle_select_depth = 0

    for line in lines:
        stripped = line.strip().lower()

        # ── Detect start of first propellant select block ──────────────────
        if not past_first_prop and RE_PROP_CASE.search(line):
            in_first_prop_select = True
            prop_select_depth = 1
            continue

        if not in_first_prop_select:
            continue

        # ── Track nesting depth of the propellant select block ─────────────
        if re.search(r'\bselect\s+case\b', stripped):
            prop_select_depth += 1
        if re.search(r'\bend\s+select\b', stripped):
            prop_select_depth -= 1
            if prop_select_depth == 0:
                # Flush last (prop, cycle) pair
                if current_prop is not None and current_cycle is not None:
                    _flush(data, current_prop, current_cycle, values, is_invalid)
                past_first_prop = True
                in_first_prop_select = False
                break

        # ── Propellant case line ────────────────────────────────────────────
        if prop_select_depth == 1:
            m = RE_PROP_LINE.match(line.strip())
            if m:
                idx  = int(m.group(1))
                name = _clean_name(m.group(2))
                if idx not in propellants:
                    propellants[idx] = name
                current_prop = idx
                current_cycle = None
                in_first_cycle_select = False
                continue

        # ── Detect inner cycle select block ────────────────────────────────
        if prop_select_depth >= 2 and RE_CYCLE_CASE.search(line):
            in_first_cycle_select = True
            cycle_select_depth = 1
            continue

        if not in_first_cycle_select:
            continue

        # ── Track nesting of cycle select block ────────────────────────────
        if re.search(r'\bend\s+select\b', stripped):
            cycle_select_depth -= 1
            if cycle_select_depth == 0:
                # Flush last cycle entry before leaving this inner block
                if current_prop is not None and current_cycle is not None:
                    _flush(data, current_prop, current_cycle, values, is_invalid)
                in_first_cycle_select = False
                current_cycle = None
                values = {}
                is_invalid = False
            continue

        # ── Cycle case line ────────────────────────────────────────────────
        m = RE_CYCLE_LINE.match(line.strip())
        if m and in_first_cycle_select:
            # Flush previous cycle before starting new one
            if current_cycle is not None:
                _flush(data, current_prop, current_cycle, values, is_invalid)
            idx  = int(m.group(1))
            name = _clean_name(m.group(2))
            if idx not in cycles:
                cycles[idx] = name
            current_cycle = idx
            values    = {}
            is_invalid = False
            continue

        # ── WARNING line → mark combination as invalid ─────────────────────
        if RE_WARNING.search(line):
            is_invalid = True
            continue

        # ── Assignment line ────────────────────────────────────────────────
        m = RE_ASSIGN.match(line.strip())
        if m:
            var_type = m.group(1).lower()   # "isp" or "ks"
            bound    = m.group(2).lower()   # "lower", "upper", "mean"
            value    = float(m.group(3))
            values[f"{var_type}_{bound}"] = value

    return propellants, cycles, data


def _flush(data, prop, cycle, values, is_invalid):
    """Store the accumulated values for (prop, cycle) into data dict."""
    if is_invalid:
        # Mark as explicitly invalid (None) so GUI can show a specific message
        data[(prop, cycle)] = None
        return
    isp_lo   = values.get("isp_lower", 0.0)
    isp_hi   = values.get("isp_upper", 0.0)
    isp_mean = values.get("isp_mean",  0.0)
    ks_lo    = values.get("ks_lower",  0.0)
    ks_hi    = values.get("ks_upper",  0.0)
    ks_mean  = values.get("ks_mean",   0.0)
    data[(prop, cycle)] = (isp_lo, isp_hi, isp_mean, ks_lo, ks_hi, ks_mean)


def _clean_name(raw):
    """Tidy up propellant/cycle name extracted from Fortran comment."""
    # Remove trailing parenthetical notes like "(LH2/LOX)"
    name = re.sub(r'\(.*?\)', '', raw).strip()
    # Title-case with some special replacements
    name = name.title()
    name = name.replace("Lh2", "LH2").replace("Lox", "LOX")
    name = name.replace("Rp1", "RP-1").replace("Rp-1", "RP-1")
    name = name.replace("Ch4", "CH4").replace("Udmh", "UDMH")
    name = name.replace("N2O4", "N2O4").replace("Ak271", "AK-271")
    name = name.replace("Mh", "MH").replace("Wfna", "WFNA")
    name = name.replace("Ak-271", "AK-271")
    return name.strip(" -")


def write_output(path, propellants, cycles, data):
    """Write the generated typical_data_ranges.py file."""
    timestamp = datetime.now().strftime("%Y-%m-%d %H:%M:%S")

    lines = []
    lines.append(f'"""')
    lines.append(f'typical_data_ranges.py')
    lines.append(f'{"─" * 55}')
    lines.append(f'AUTO-GENERATED by parse_typical_data.py on {timestamp}')
    lines.append(f'DO NOT EDIT MANUALLY.')
    lines.append(f'')
    lines.append(f'To update values:')
    lines.append(f'  1. Edit inout/Typical_Data.f90')
    lines.append(f'  2. Run: python parse_typical_data.py')
    lines.append(f'"""')
    lines.append(f'')

    # PROPELLANTS list (sorted by index)
    lines.append('PROPELLANTS = [')
    for idx in sorted(propellants):
        lines.append(f'    "{propellants[idx]}",  # index {idx}')
    lines.append(']')
    lines.append('')

    # CYCLES list (sorted by index)
    lines.append('CYCLES = [')
    for idx in sorted(cycles):
        lines.append(f'    "{cycles[idx]}",  # index {idx}')
    lines.append(']')
    lines.append('')

    # TYPICAL_DATA dict
    lines.append('# Key: (propellant_index, cycle_index)')
    lines.append('# Value: (isp_lower, isp_upper, isp_mean, ks_lower, ks_upper, ks_mean)')
    lines.append('# Value is None for explicitly invalid combinations.')
    lines.append('TYPICAL_DATA = {')
    for prop_idx in sorted(propellants):
        lines.append(f'    # {propellants[prop_idx]}')
        for cycle_idx in sorted(cycles):
            val = data.get((prop_idx, cycle_idx))
            if val is None:
                lines.append(f'    ({prop_idx}, {cycle_idx}): None,  # invalid combination')
            elif val == (0.0, 0.0, 0.0, 0.0, 0.0, 0.0):
                lines.append(f'    ({prop_idx}, {cycle_idx}): (0.0, 0.0, 0.0,  0.0, 0.0, 0.0),  # no data yet')
            else:
                isp_lo, isp_hi, isp_mean, ks_lo, ks_hi, ks_mean = val
                lines.append(
                    f'    ({prop_idx}, {cycle_idx}): '
                    f'({isp_lo}, {isp_hi}, {isp_mean},  '
                    f'{ks_lo}, {ks_hi}, {ks_mean}),'
                )
        lines.append('')
    lines.append('}')
    lines.append('')

    with open(path, "w", encoding="utf-8") as f:
        f.write("\n".join(lines))


def main():
    print(f"Reading:  {FORTRAN_FILE}")
    if not os.path.exists(FORTRAN_FILE):
        print(f"ERROR: File not found: {FORTRAN_FILE}")
        sys.exit(1)

    propellants, cycles, data = parse_fortran(FORTRAN_FILE)

    print(f"  Found {len(propellants)} propellants: {list(propellants.values())}")
    print(f"  Found {len(cycles)} cycles:      {list(cycles.values())}")
    print(f"  Found {len(data)} (prop, cycle) combinations")

    os.makedirs(os.path.dirname(OUTPUT_FILE), exist_ok=True)
    write_output(OUTPUT_FILE, propellants, cycles, data)
    print(f"Written:  {OUTPUT_FILE}")
    print("Done. Re-run this script any time you update Typical_Data.f90.")


if __name__ == "__main__":
    main()
