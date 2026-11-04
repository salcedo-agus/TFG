"""
subsystem_plots.py
──────────────────
Reads a Subsystems.txt file (the format written by the rocket sizing code)
and draws a figure similar to the Atlas V 401 mass-breakdown chart:

    * one pie per stage:  Propellants vs Dry mass
    * one pie per stage:  Dry-mass breakdown (tanks, structure, avionics, ...)
    * a side-view drawing of the rocket, to scale, with connectors to the pies

Usage (command line):
    python subsystem_plots.py Subsystems.txt -o subsystems.png
    python subsystem_plots.py Subsystems.txt --show

Usage (from Python / the GUI):
    from subsystem_plots import plot_subsystems
    fig = plot_subsystems("Subsystems.txt", save_path="subsystems.png")
"""

import argparse
import math
import re

import matplotlib
import matplotlib.pyplot as plt
import numpy as np
from matplotlib.patches import Polygon, Rectangle, ConnectionPatch

# ── Colours ──────────────────────────────────────────────────────────────────
PROP_COLOR = "#b9c1de"
DRY_COLOR = "#1f5f99"
DETAIL_COLORS = [
    "#6a82aa",  # tanks
    "#9aa8c8",  # unpressurized structure
    "#1f5f99",  # avionics
    "#d9dde9",  # wiring
    "#4b6a96",  # engine
    "#c6ccdf",  # other / unaccounted
]
STAGE_FILL = ["#c9cfe3", "#aab5d3", "#8c9bc4"]
LINE_COLOR = "#222222"


# ── Parsing ──────────────────────────────────────────────────────────────────
def _to_value(raw):
    raw = raw.strip()
    if raw in ("T", "F"):
        return raw == "T"
    if raw in ("~", ""):
        return None  # value not available
    try:
        return float(raw)
    except ValueError:
        return raw


def parse_subsystems(path):
    """Return a list of dicts, one per stage, ordered as in the file."""
    with open(path, "r", encoding="utf-8") as f:
        text = f.read()

    stages = []
    current = None
    for line in text.splitlines():
        s = line.strip()
        if not s:
            continue
        if s.startswith("=") and "SUB-SYSTEMS" in s.upper():
            current = {}
            stages.append(current)
            continue
        if current is None:
            continue
        m = re.match(r"Stage\s+N\s+(\d+)", s, re.IGNORECASE)
        if m:
            current["stage"] = int(m.group(1))
            continue
        if ":" in s:
            key, val = s.split(":", 1)
            current[key.strip()] = _to_value(val)
    return [st for st in stages if "stage" in st]


# ── Mass bookkeeping ─────────────────────────────────────────────────────────
def _g(st, key):
    v = st.get(key)
    return v if isinstance(v, (int, float)) else None


def dry_mass_breakdown(st):
    """
    Split the structure (dry) mass into named slices.
    Anything not covered by the listed components goes into a remainder slice
    ('Engine' when the engine mass is unknown, otherwise 'Other').
    Returns (labels, values, note).
    """
    dry = _g(st, "Structure mass") or 0.0

    tanks = sum(_g(st, k) or 0.0 for k in (
        "Fuel tank mass", "Fuel tank insulation mass",
        "Oxidizer tank mass", "Oxidizer tank insulation mass"))
    unpr = _g(st, "Unpr. str. mass") or 0.0
    avio = _g(st, "Avionics mass") or 0.0
    wire = _g(st, "Wiring mass") or 0.0
    engine = _g(st, "Engine mass")

    labels = ["Tanks & insulation", "Unpressurized structure",
              "Avionics & electrical", "Wiring"]
    values = [tanks, unpr, avio, wire]
    if engine is not None:
        labels.append("Engine")
        values.append(engine)

    listed = sum(values)
    rest = dry - listed
    note = None
    if rest > 1e-6:
        labels.append("Engine / feed system / other" if engine is None else "Other")
        values.append(rest)
    elif rest < -1e-6:
        note = (f"Stage {st['stage']}: listed components ({listed:,.0f} kg) exceed the "
                f"structure mass ({dry:,.0f} kg) by {-rest:,.0f} kg; "
                "pie shows proportions of the listed components.")

    keep = [(l, v) for l, v in zip(labels, values) if v > 0]
    return [k[0] for k in keep], [k[1] for k in keep], note


# ── Drawing helpers ──────────────────────────────────────────────────────────
def _annotated_pie(ax, values, labels, colors, startangle=90, min_label_pct=0.0,
                   fontsize=8):
    """Pie with labels placed outside on leader lines."""
    total = float(sum(values))
    wedges, _ = ax.pie(values, colors=colors, startangle=startangle,
                       counterclock=False,
                       wedgeprops=dict(edgecolor="white", linewidth=0.6))
    items = {1: [], -1: []}
    for w, v, lab in zip(wedges, values, labels):
        pct = 100.0 * v / total
        if pct < min_label_pct:
            continue
        ang = math.radians((w.theta2 + w.theta1) / 2.0)
        x, y = math.cos(ang), math.sin(ang)
        side = 1 if x >= 0 else -1
        items[side].append([x, y, 1.3 * y, lab, pct])
    gap = 0.30
    for side, lst in items.items():
        lst.sort(key=lambda it: -it[1])          # top -> bottom
        prev = 9.0
        for it in lst:                           # enforce spacing, keep order
            it[2] = min(it[2], prev - gap)
            prev = it[2]
        for x, y, ty, lab, pct in lst:
            ax.annotate(
                f"{lab}\n{pct:.1f}%", xy=(0.97 * x, 0.97 * y),
                xytext=(1.3 * side, ty),
                ha="left" if side == 1 else "right", va="center",
                fontsize=fontsize,
                arrowprops=dict(arrowstyle="-", color="#555555", lw=0.7),
            )
    ax.set_aspect("equal")


def _draw_rocket(ax, stages, scale_pad=0.05):
    """
    Side view, nose to the left, upper stage on the left, first stage on the
    right (same orientation as the Atlas V figure).
    Returns {stage_number: x_centre}.
    """
    order = sorted(stages, key=lambda s: s["stage"], reverse=True)  # top → bottom
    diam_max = max(_g(s, "Diameter") or 1.0 for s in stages)
    nose_len = 1.6 * diam_max

    x = 0.0
    # Payload fairing (ogive)
    t = np.linspace(0, 1, 60)
    top_r = (_g(order[0], "Diameter") or diam_max) / 2.0
    ys = top_r * np.sqrt(2 * t - t ** 2)
    xs = t * nose_len
    poly = np.vstack([np.column_stack([xs, ys]),
                      np.column_stack([xs[::-1], -ys[::-1]])])
    ax.add_patch(Polygon(poly, closed=True, facecolor="#e4e7f1",
                         edgecolor=LINE_COLOR, lw=1.0))
    ax.text(nose_len * 0.55, 0, "Payload", ha="center", va="center",
            fontsize=8, color="#333333")
    x = nose_len

    centres = {}
    for i, st in enumerate(order):
        L = _g(st, "Length") or 1.0
        D = _g(st, "Diameter") or diam_max
        fill = STAGE_FILL[min(i, len(STAGE_FILL) - 1)]
        ax.add_patch(Rectangle((x, -D / 2), L, D, facecolor=fill,
                               edgecolor=LINE_COLOR, lw=1.0))

        # Tank domes / separators as simple internal lines: oxidizer fraction
        ox_v = _g(st, "Oxidizer tank volume")
        fu_v = _g(st, "Fuel tank volume")
        if ox_v and fu_v:
            frac_ox = ox_v / (ox_v + fu_v)
            # oxidizer tank assumed forward (towards payload / left)
            xsep = x + frac_ox * L
            ax.plot([xsep, xsep], [-D / 2, D / 2], color=LINE_COLOR, lw=0.8,
                    ls="--")
            ax.text(x + frac_ox * L / 2, 0, "Ox", ha="center", va="center",
                    fontsize=7, color="#333333")
            ax.text(x + frac_ox * L + (1 - frac_ox) * L / 2, 0, "Fuel",
                    ha="center", va="center", fontsize=7, color="#333333")

        ax.text(x + L / 2, D / 2 + 0.12 * diam_max, f"Stage {st['stage']}",
                ha="center", va="bottom", fontsize=9, fontweight="bold")
        centres[st["stage"]] = (x + L / 2, D / 2)
        x += L

        # Interstage gap marker between stages
        if i < len(order) - 1:
            ax.plot([x, x], [-D / 2, D / 2], color=LINE_COLOR, lw=1.6)

    # Engine bell on the first stage
    st1 = order[-1]
    D1 = _g(st1, "Diameter") or diam_max
    bell_len = 0.55 * D1
    bell = np.array([[x, -0.18 * D1], [x + bell_len, -0.36 * D1],
                     [x + bell_len, 0.36 * D1], [x, 0.18 * D1]])
    ax.add_patch(Polygon(bell, closed=True, facecolor="#555555",
                         edgecolor=LINE_COLOR, lw=1.0))
    x += bell_len

    ax.set_xlim(-scale_pad * x, x * (1 + scale_pad))
    half = diam_max / 2.0 * 1.55
    ax.set_ylim(-half, half)
    ax.set_aspect("equal")
    ax.axis("off")
    return centres


# ── Main entry point ─────────────────────────────────────────────────────────
def plot_subsystems(path, save_path=None, show=False, title=None, dpi=200):
    stages = parse_subsystems(path)
    if not stages:
        raise ValueError(f"No stage blocks found in {path}")

    order = sorted(stages, key=lambda s: s["stage"], reverse=True)  # left → right
    n = len(order)

    fig = plt.figure(figsize=(7.0 * n + 1.5, 12))
    gs = fig.add_gridspec(3, n, height_ratios=[1.0, 1.35, 0.9],
                          hspace=0.40, wspace=0.9,
                          left=0.04, right=0.96, top=0.93, bottom=0.04)
    ax_rocket = fig.add_subplot(gs[2, :])
    centres = _draw_rocket(ax_rocket, stages)

    diam_ref = max(_g(s_, "Diameter") or 1.0 for s_ in stages)
    notes = []
    for col, st in enumerate(order):
        m_total = _g(st, "Initial stage mass") or 0.0
        m_prop = _g(st, "Propellant mass") or 0.0
        m_dry = _g(st, "Structure mass") or 0.0
        if m_total <= 0:
            m_total = m_prop + m_dry
        prop_pct = 100 * m_prop / m_total
        dry_pct = 100 * m_dry / m_total

        # Top pie: propellants vs dry mass
        ax_top = fig.add_subplot(gs[0, col])
        ax_top.pie([m_prop, m_dry], colors=[PROP_COLOR, DRY_COLOR], startangle=100,
                   counterclock=False,
                   wedgeprops=dict(edgecolor="white", linewidth=0.6))
        ax_top.text(0, -0.28, "Propellants", ha="center", va="center", fontsize=10)
        ax_top.text(0, -0.50, f"{prop_pct:.1f}%", ha="center", va="center",
                    fontsize=10, fontweight="bold")
        ax_top.annotate(f"Dry mass {dry_pct:.1f}%", xy=(0.75, -0.55),
                        xytext=(1.25, -0.95), fontsize=10, ha="left",
                        arrowprops=dict(arrowstyle="-", color="#555555", lw=0.8))
        ax_top.set_title(f"Stage {st['stage']}  –  {m_total:,.0f} kg",
                         fontsize=11, fontweight="bold", pad=10)
        ax_top.set_aspect("equal")

        # Bottom pie: dry-mass breakdown
        labels, values, note = dry_mass_breakdown(st)
        if note:
            notes.append(note)
        ax_det = fig.add_subplot(gs[1, col])
        _annotated_pie(ax_det, values, labels,
                       colors=DETAIL_COLORS[:len(values)] if len(values) <= len(DETAIL_COLORS)
                       else None, fontsize=8)
        ax_det.set_title(f"Dry mass breakdown ({m_dry:,.0f} kg)", fontsize=9,
                         color="#444444", pad=14)

        # Connector: detail pie → stage on the rocket drawing
        xc, rtop = centres[st["stage"]]
        con = ConnectionPatch(xyA=(0.5, 0.0), coordsA=ax_det.transAxes,
                              xyB=(xc, rtop + 0.42 * diam_ref), coordsB=ax_rocket.transData,
                              color="#666666", lw=0.8, ls="-")
        fig.add_artist(con)

    fig.suptitle(title or "Subsystem mass breakdown", fontsize=15,
                 fontweight="bold")
    if notes:
        fig.text(0.5, 0.005, "  |  ".join(notes), ha="center", va="bottom",
                 fontsize=7, color="#a33")
        for n_ in notes:
            print("WARNING:", n_)

    if save_path:
        fig.savefig(save_path, dpi=dpi, facecolor="white", bbox_inches="tight")
        print(f"Saved: {save_path}")
    if show:
        plt.show()
    return fig


def main():
    ap = argparse.ArgumentParser(description="Plot subsystem masses from Subsystems.txt")
    ap.add_argument("file", help="path to Subsystems.txt")
    ap.add_argument("-o", "--output", default=None, help="output image (png/pdf/svg)")
    ap.add_argument("--show", action="store_true", help="open an interactive window")
    ap.add_argument("--title", default=None)
    args = ap.parse_args()

    if not args.show:
        matplotlib.use("Agg")
    out = args.output or (None if args.show else "subsystems.png")
    plot_subsystems(args.file, save_path=out, show=args.show, title=args.title)


if __name__ == "__main__":
    main()
