"""
Rocket Staging GUI
Reads ISP and k_s ranges from typical_data_ranges.py (mirrored from Typical_Data.f90).
All range values should be edited there, not here.
"""

import sys
import os
from PyQt6.QtWidgets import (
    QApplication, QMainWindow, QWidget, QVBoxLayout, QHBoxLayout,
    QGridLayout, QLabel, QSpinBox, QDoubleSpinBox, QComboBox,
    QSlider, QPushButton, QScrollArea, QFrame, QSizePolicy,
    QGroupBox, QMessageBox, QStackedWidget, QGraphicsOpacityEffect
)
from PyQt6.QtCore import Qt, QThread, pyqtSignal, QPropertyAnimation, QEasingCurve
from PyQt6.QtGui import QFont, QPalette, QColor

# ── Fortran bridge ────────────────────────────────────────────────────────────
import ctypes

# gui.py lives in gui/  →  root SRC is one level up
GUI_DIR  = os.path.dirname(os.path.abspath(__file__))
ROOT_DIR = os.path.dirname(GUI_DIR)
# build/ sits one level above SRC/, so two levels above gui/
BUILD_DIR = os.path.join(ROOT_DIR, "..", "build")

# Make sure interface/ is on the path so rocket_lib can be imported if needed
sys.path.insert(0, os.path.join(ROOT_DIR, "interface"))

if sys.platform == "win32":
    # Add build/ so Python finds librocket.dll
    os.add_dll_directory(os.path.abspath(BUILD_DIR))

    # Find MinGW runtime DLLs. Priority:
    #   1. MINGW_BIN environment variable (set this in your PowerShell profile)
    #   2. Common installation locations as fallback
    _MINGW_CANDIDATES = [
        os.environ.get("MINGW_BIN", ""),   # user-set env var
        r"C:\TDM-GCC-64\bin",              # TDM-GCC default
        r"C:\msys64\mingw64\bin",          # MSYS2 default
        r"C:\msys64\ucrt64\bin",           # MSYS2 UCRT variant
        r"C:\mingw64\bin",                 # standalone MinGW
        r"C:\mingw\bin",                   # standalone MinGW (alt)
    ]
    _mingw_found = False
    for _candidate in _MINGW_CANDIDATES:
        if _candidate and os.path.isdir(_candidate):
            os.add_dll_directory(_candidate)
            _mingw_found = True
            break
    if not _mingw_found:
        print("WARNING: MinGW bin directory not found. Set the MINGW_BIN environment")
        print("         variable to your MinGW bin path, e.g.:")
        print(r"         $env:MINGW_BIN = 'C:\msys64\mingw64\bin'")

    _lib = ctypes.CDLL(os.path.join(BUILD_DIR, "librocket.dll"))
else:
    _lib = ctypes.CDLL(os.path.join(BUILD_DIR, "librocket.so"))

_lib.run_staging.restype = None
_lib.run_staging.argtypes = [
    ctypes.POINTER(ctypes.c_int),
    ctypes.POINTER(ctypes.c_double),
    ctypes.POINTER(ctypes.c_double),
    ctypes.POINTER(ctypes.c_double),
    ctypes.POINTER(ctypes.c_double),
    ctypes.POINTER(ctypes.c_double),
    ctypes.POINTER(ctypes.c_double),
    ctypes.POINTER(ctypes.c_double),
    ctypes.POINTER(ctypes.c_double),
    ctypes.POINTER(ctypes.c_double),
    ctypes.POINTER(ctypes.c_double),
    ctypes.POINTER(ctypes.c_double),
    ctypes.POINTER(ctypes.c_double),
    ctypes.POINTER(ctypes.c_double),
    ctypes.POINTER(ctypes.c_int),
]

def run_staging(n_stages, delta_v, payload_mass, isp_list, ks_list):
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
    _lib.run_staging(
        ctypes.byref(n), ctypes.byref(dv), ctypes.byref(pl),
        isp, ks, m0, mf, mp, ms, km, ks_o, kl, nu_e,
        ctypes.byref(total_m0), ctypes.byref(min_found)
    )
    return {
        "total_initial_mass": total_m0.value,
        "minimum_found": bool(min_found.value),
        "stages": [
            {"stage": i+1, "m0": m0[i], "mf": mf[i], "mp": mp[i],
             "ms": ms[i], "k_m": km[i], "k_s": ks_o[i],
             "k_L": kl[i], "nu_e": nu_e[i]}
            for i in range(n_stages)
        ]
    }

# ── ISP / k_s data (auto-generated from Typical_Data.f90) ───────────────────
# Run parse_typical_data.py to regenerate this file after editing Typical_Data.f90
import importlib, sys as _sys

def _load_data():
    """Load typical_data_ranges from gui/ folder, next to gui.py."""
    gui_dir = os.path.dirname(os.path.abspath(__file__))
    if gui_dir not in _sys.path:
        _sys.path.insert(0, gui_dir)
    try:
        import typical_data_ranges as _tdr
        importlib.reload(_tdr)   # always get the latest version
        return _tdr.TYPICAL_DATA, _tdr.PROPELLANTS, _tdr.CYCLES
    except ImportError:
        print("WARNING: typical_data_ranges.py not found.")
        print("         Run parse_typical_data.py to generate it.")
        return {}, [], []

TYPICAL_DATA, PROPELLANTS, CYCLES = _load_data()


# ── Colour palette ────────────────────────────────────────────────────────────
BG_DARK    = "#0d1117"
BG_PANEL   = "#161b22"
BG_CARD    = "#1c2128"
BG_INPUT   = "#21262d"
ACCENT     = "#58a6ff"
ACCENT2    = "#f78166"
TEXT_PRI   = "#e6edf3"
TEXT_SEC   = "#8b949e"
TEXT_DIM   = "#484f58"
BORDER     = "#30363d"
GREEN      = "#3fb950"
ORANGE     = "#d29922"

STYLE = f"""
QMainWindow, QWidget {{
    background-color: {BG_DARK};
    color: {TEXT_PRI};
    font-family: 'Segoe UI', 'Inter', sans-serif;
    font-size: 13px;
}}
QScrollArea {{ border: none; background: {BG_DARK}; }}
QScrollBar:vertical {{
    background: {BG_PANEL}; width: 8px; border-radius: 4px;
}}
QScrollBar::handle:vertical {{
    background: {BORDER}; border-radius: 4px; min-height: 20px;
}}
QScrollBar::add-line:vertical, QScrollBar::sub-line:vertical {{ height: 0px; }}
QGroupBox {{
    background-color: {BG_PANEL};
    border: 1px solid {BORDER};
    border-radius: 8px;
    margin-top: 12px;
    padding: 10px;
}}
QGroupBox::title {{
    subcontrol-origin: margin;
    left: 12px;
    color: {ACCENT};
    font-weight: 600;
    font-size: 12px;
    letter-spacing: 1px;
    text-transform: uppercase;
}}
QLabel {{ color: {TEXT_PRI}; background: transparent; }}
QDoubleSpinBox, QSpinBox {{
    background-color: {BG_INPUT};
    border: 1px solid {BORDER};
    border-radius: 6px;
    color: {TEXT_PRI};
    padding: 4px 8px;
    min-height: 28px;
}}
QDoubleSpinBox:focus, QSpinBox:focus {{
    border-color: {ACCENT};
}}
QDoubleSpinBox::up-button, QSpinBox::up-button {{
    subcontrol-origin: border;
    subcontrol-position: top right;
    width: 20px;
    border-left: 1px solid {BORDER};
    border-bottom: 1px solid {BORDER};
    border-top-right-radius: 6px;
    background-color: {BG_INPUT};
}}
QDoubleSpinBox::up-button:hover, QSpinBox::up-button:hover {{
    background-color: {ACCENT};
}}
QDoubleSpinBox::up-button:pressed, QSpinBox::up-button:pressed {{
    background-color: #388bfd;
}}
QDoubleSpinBox::down-button, QSpinBox::down-button {{
    subcontrol-origin: border;
    subcontrol-position: bottom right;
    width: 20px;
    border-left: 1px solid {BORDER};
    border-top: 1px solid {BORDER};
    border-bottom-right-radius: 6px;
    background-color: {BG_INPUT};
}}
QDoubleSpinBox::down-button:hover, QSpinBox::down-button:hover {{
    background-color: {ACCENT};
}}
QDoubleSpinBox::down-button:pressed, QSpinBox::down-button:pressed {{
    background-color: #388bfd;
}}
QDoubleSpinBox::up-arrow, QSpinBox::up-arrow {{
    width: 7px; height: 7px;
    border-left: 4px solid transparent;
    border-right: 4px solid transparent;
    border-bottom: 6px solid {TEXT_PRI};
}}
QDoubleSpinBox::down-arrow, QSpinBox::down-arrow {{
    width: 7px; height: 7px;
    border-left: 4px solid transparent;
    border-right: 4px solid transparent;
    border-top: 6px solid {TEXT_PRI};
}}
QComboBox {{
    background-color: {BG_INPUT};
    border: 1px solid {BORDER};
    border-radius: 6px;
    color: {TEXT_PRI};
    padding: 4px 8px;
    min-height: 28px;
}}
QComboBox:focus {{ border-color: {ACCENT}; }}
QComboBox::drop-down {{ border: none; width: 24px; }}
QComboBox QAbstractItemView {{
    background-color: {BG_INPUT};
    border: 1px solid {BORDER};
    color: {TEXT_PRI};
    selection-background-color: {ACCENT};
    selection-color: {BG_DARK};
}}
QSlider::groove:horizontal {{
    height: 4px;
    background: {BORDER};
    border-radius: 2px;
}}
QSlider::handle:horizontal {{
    background: {ACCENT};
    width: 14px; height: 14px;
    margin: -5px 0;
    border-radius: 7px;
}}
QSlider::sub-page:horizontal {{
    background: {ACCENT};
    border-radius: 2px;
}}
QSlider:disabled::groove:horizontal {{ background: {TEXT_DIM}; }}
QSlider:disabled::handle:horizontal {{ background: {TEXT_DIM}; }}
QPushButton#launch_btn {{
    background-color: transparent;
    color: {ACCENT};
    border: 2px solid {ACCENT};
    border-radius: 10px;
    padding: 14px 48px;
    font-weight: 700;
    font-size: 16px;
    min-height: 48px;
    letter-spacing: 2px;
}}
QPushButton#launch_btn:hover {{
    background-color: {ACCENT};
    color: {BG_DARK};
}}
QPushButton#launch_btn:pressed {{
    background-color: #388bfd;
    color: {BG_DARK};
}}
QPushButton#run_btn {{
    background-color: {ACCENT};
    color: {BG_DARK};
    border: none;
    border-radius: 8px;
    padding: 10px 32px;
    font-weight: 700;
    font-size: 14px;
    min-height: 40px;
}}
QPushButton#run_btn:hover {{ background-color: #79b8ff; }}
QPushButton#run_btn:pressed {{ background-color: #388bfd; }}
QFrame#divider {{
    background: {BORDER};
    max-height: 1px;
    min-height: 1px;
}}
"""

# ── Stage input widget ────────────────────────────────────────────────────────
class StageInputWidget(QGroupBox):
    def __init__(self, stage_num, parent=None):
        super().__init__(f"Stage {stage_num}", parent)
        self.stage_num = stage_num
        self._build()

    def _build(self):
        layout = QVBoxLayout(self)
        layout.setSpacing(10)

        # Propellant / Oxidizer
        row1 = QHBoxLayout()
        row1.addWidget(QLabel("Propellant / Oxidizer"))
        self.prop_combo = QComboBox()
        self.prop_combo.addItems(PROPELLANTS)
        self.prop_combo.setMinimumWidth(220)
        row1.addWidget(self.prop_combo)
        layout.addLayout(row1)

        # Combustion Cycle
        row2 = QHBoxLayout()
        row2.addWidget(QLabel("Combustion Cycle"))
        self.cycle_combo = QComboBox()
        self.cycle_combo.addItems(CYCLES)
        self.cycle_combo.setMinimumWidth(220)
        row2.addWidget(self.cycle_combo)
        layout.addLayout(row2)

        # ISP slider
        isp_group = QGroupBox("Specific Impulse — ISP (s)")
        isp_layout = QVBoxLayout(isp_group)
        self.isp_slider = QSlider(Qt.Orientation.Horizontal)
        self.isp_slider.setRange(0, 1000)
        self.isp_slider.setValue(500)
        self.isp_value_label = QLabel("— s")
        self.isp_value_label.setAlignment(Qt.AlignmentFlag.AlignCenter)
        self.isp_value_label.setStyleSheet(f"color: {ACCENT}; font-weight: 700; font-size: 15px;")
        self.isp_range_label = QLabel("No data for this combination")
        self.isp_range_label.setAlignment(Qt.AlignmentFlag.AlignCenter)
        self.isp_range_label.setStyleSheet(f"color: {TEXT_SEC}; font-size: 11px;")
        isp_layout.addWidget(self.isp_value_label)
        isp_layout.addWidget(self.isp_slider)
        isp_layout.addWidget(self.isp_range_label)
        layout.addWidget(isp_group)

        # k_s slider
        ks_group = QGroupBox("Structural Coefficient — k_s")
        ks_layout = QVBoxLayout(ks_group)
        self.ks_slider = QSlider(Qt.Orientation.Horizontal)
        self.ks_slider.setRange(0, 1000)
        self.ks_slider.setValue(500)
        self.ks_value_label = QLabel("—")
        self.ks_value_label.setAlignment(Qt.AlignmentFlag.AlignCenter)
        self.ks_value_label.setStyleSheet(f"color: {ACCENT}; font-weight: 700; font-size: 15px;")
        self.ks_range_label = QLabel("No data for this combination")
        self.ks_range_label.setAlignment(Qt.AlignmentFlag.AlignCenter)
        self.ks_range_label.setStyleSheet(f"color: {TEXT_SEC}; font-size: 11px;")
        ks_layout.addWidget(self.ks_value_label)
        ks_layout.addWidget(self.ks_slider)
        ks_layout.addWidget(self.ks_range_label)
        layout.addWidget(ks_group)

        # Connect signals
        self.prop_combo.currentIndexChanged.connect(self._prop_changed)
        self.cycle_combo.currentIndexChanged.connect(self._cycle_changed)
        self.isp_slider.valueChanged.connect(self._update_isp_label)
        self.ks_slider.valueChanged.connect(self._update_ks_label)

        self._refresh_cycle_items()
        self._update_ranges()

    # Connect signals — prop change updates cycle availability too
        # (connected in _build after widgets exist)

    def _prop_changed(self):
        """When propellant changes: grey out invalid cycles, warn if current is now invalid."""
        self._refresh_cycle_items()
        prop  = self.prop_combo.currentIndex() + 1
        cycle = self.cycle_combo.currentIndex()
        d = TYPICAL_DATA.get((prop, cycle))
        if d is None:
            # Current cycle is explicitly invalid for this propellant — reset to first valid
            for c_idx in range(self.cycle_combo.count()):
                test = TYPICAL_DATA.get((prop, c_idx))
                if test is not None:
                    self.cycle_combo.setCurrentIndex(c_idx)
                    break
        self._update_ranges()

    def _cycle_changed(self):
        """When cycle changes: warn if the combination is explicitly invalid."""
        prop  = self.prop_combo.currentIndex() + 1
        cycle = self.cycle_combo.currentIndex()
        d = TYPICAL_DATA.get((prop, cycle))
        if d is None:
            # Show warning in the range labels but don't block the user
            self._set_invalid_state()
        else:
            self._update_ranges()

    def _refresh_cycle_items(self):
        """Grey out cycle entries that are None for the current propellant."""
        prop = self.prop_combo.currentIndex() + 1
        model = self.cycle_combo.model()
        for c_idx in range(self.cycle_combo.count()):
            item = model.item(c_idx)
            d = TYPICAL_DATA.get((prop, c_idx))
            if d is None:
                # Visually dim but keep selectable so user sees the warning
                item.setForeground(__import__('PyQt6.QtGui', fromlist=['QColor']).QColor(TEXT_DIM))
            else:
                item.setForeground(__import__('PyQt6.QtGui', fromlist=['QColor']).QColor(TEXT_PRI))

    def _set_invalid_state(self):
        """Show invalid combination message on both sliders."""
        for slider, val_lbl, range_lbl, unit in [
            (self.isp_slider, self.isp_value_label, self.isp_range_label, "s"),
            (self.ks_slider,  self.ks_value_label,  self.ks_range_label,  ""),
        ]:
            slider.setEnabled(False)
            slider.setRange(0, 1000)
            slider.setValue(0)
            val_lbl.setText(f"— {unit}".strip())
            range_lbl.setText("Invalid combination for this propellant")
            range_lbl.setStyleSheet(f"color: {ACCENT2}; font-size: 11px;")

    def _get_data(self):
        prop  = self.prop_combo.currentIndex() + 1   # 1-based
        cycle = self.cycle_combo.currentIndex()       # 0-based
        return TYPICAL_DATA.get((prop, cycle), (0.0, 0.0, 0.0, 0.0, 0.0, 0.0))

    def _update_ranges(self):
        prop  = self.prop_combo.currentIndex() + 1
        cycle = self.cycle_combo.currentIndex()
        d = TYPICAL_DATA.get((prop, cycle))

        # None means explicitly invalid combination
        if d is None:
            self._set_invalid_state()
            return

        isp_lo, isp_hi, isp_mean = d[0], d[1], d[2]
        ks_lo,  ks_hi,  ks_mean  = d[3], d[4], d[5]

        has_isp = isp_hi > isp_lo or (isp_hi == isp_lo and isp_hi > 0)
        has_ks  = ks_hi  > ks_lo  or (ks_hi  == ks_lo  and ks_hi  > 0)

        # ISP
        self.isp_slider.setEnabled(has_isp)
        if has_isp:
            self.isp_slider.setRange(int(isp_lo * 10), int(isp_hi * 10))
            self.isp_slider.setValue(int(isp_mean * 10))
            self.isp_range_label.setText(f"Range: {isp_lo:.1f} – {isp_hi:.1f} s   |   Mean: {isp_mean:.1f} s")
            self.isp_range_label.setStyleSheet(f"color: {TEXT_SEC}; font-size: 11px;")
        else:
            self.isp_slider.setRange(0, 1000)
            self.isp_slider.setValue(0)
            self.isp_range_label.setText("No data for this combination yet")
            self.isp_range_label.setStyleSheet(f"color: {ORANGE}; font-size: 11px;")
            self.isp_value_label.setText("— s")

        # k_s
        self.ks_slider.setEnabled(has_ks)
        if has_ks:
            self.ks_slider.setRange(int(ks_lo * 10000), int(ks_hi * 10000))
            self.ks_slider.setValue(int(ks_mean * 10000))
            self.ks_range_label.setText(f"Range: {ks_lo:.4f} – {ks_hi:.4f}   |   Mean: {ks_mean:.4f}")
            self.ks_range_label.setStyleSheet(f"color: {TEXT_SEC}; font-size: 11px;")
        else:
            self.ks_slider.setRange(0, 1000)
            self.ks_slider.setValue(0)
            self.ks_range_label.setText("No data for this combination yet")
            self.ks_range_label.setStyleSheet(f"color: {ORANGE}; font-size: 11px;")
            self.ks_value_label.setText("—")

        self._update_isp_label()
        self._update_ks_label()

    def _update_isp_label(self):
        if self.isp_slider.isEnabled():
            val = self.isp_slider.value() / 10.0
            self.isp_value_label.setText(f"{val:.1f} s")

    def _update_ks_label(self):
        if self.ks_slider.isEnabled():
            val = self.ks_slider.value() / 10000.0
            self.ks_value_label.setText(f"{val:.4f}")

    def get_values(self):
        """Return (isp, k_s, has_data) for this stage."""
        prop  = self.prop_combo.currentIndex() + 1
        cycle = self.cycle_combo.currentIndex()
        d = TYPICAL_DATA.get((prop, cycle))

        # Explicitly invalid combination
        if d is None:
            return None, None, False

        isp_lo, isp_hi = d[0], d[1]
        ks_lo,  ks_hi  = d[3], d[4]
        has_isp = isp_hi > isp_lo or (isp_hi == isp_lo and isp_hi > 0)
        has_ks  = ks_hi  > ks_lo  or (ks_hi  == ks_lo  and ks_hi  > 0)
        isp = self.isp_slider.value() / 10.0    if has_isp else None
        ks  = self.ks_slider.value()  / 10000.0 if has_ks  else None
        return isp, ks, (has_isp and has_ks)


# ── Result card widget ────────────────────────────────────────────────────────
class ResultCard(QFrame):
    def __init__(self, stage_num, data, parent=None):
        super().__init__(parent)
        self.setStyleSheet(f"""
            QFrame {{
                background-color: {BG_CARD};
                border: 1px solid {BORDER};
                border-radius: 10px;
            }}
        """)
        layout = QVBoxLayout(self)
        layout.setSpacing(8)
        layout.setContentsMargins(16, 14, 16, 14)

        # Header
        header = QLabel(f"Stage {stage_num}")
        header.setStyleSheet(f"color: {ACCENT}; font-size: 16px; font-weight: 700; border: none;")
        layout.addWidget(header)

        div = QFrame()
        div.setObjectName("divider")
        layout.addWidget(div)

        # Metrics grid
        grid = QGridLayout()
        grid.setHorizontalSpacing(24)
        grid.setVerticalSpacing(6)

        def add_metric(row, col, label, value, unit="", color=TEXT_PRI):
            lbl = QLabel(label)
            lbl.setStyleSheet(f"color: {TEXT_SEC}; font-size: 11px; border: none;")
            val = QLabel(f"{value:,.1f} {unit}".strip())
            val.setStyleSheet(f"color: {color}; font-size: 14px; font-weight: 600; border: none;")
            grid.addWidget(lbl, row*2,   col)
            grid.addWidget(val, row*2+1, col)

        add_metric(0, 0, "Initial Mass (m₀)",    data["m0"],  "kg", TEXT_PRI)
        add_metric(0, 1, "Final Mass (m_f)",      data["mf"],  "kg", TEXT_PRI)
        add_metric(1, 0, "Propellant Mass (m_p)", data["mp"],  "kg", ACCENT2)
        add_metric(1, 1, "Structure Mass (m_s)",  data["ms"],  "kg", TEXT_PRI)
        add_metric(2, 0, "Mass Ratio (k_m)",      data["k_m"], "",   ACCENT)
        add_metric(2, 1, "Payload Ratio (k_L)",   data["k_L"], "",   ACCENT)
        add_metric(3, 0, "Struct. Coeff. (k_s)",  data["k_s"], "",   TEXT_PRI)
        add_metric(3, 1, "Exhaust Vel. (ν_e)",    data["nu_e"],"km/s",TEXT_PRI)

        layout.addLayout(grid)



# ── Splash / presentation screen ──────────────────────────────────────────────
class SplashScreen(QWidget):
    launch_requested = pyqtSignal()

    def __init__(self, parent=None):
        super().__init__(parent)
        self._build()

    def _build(self):
        outer = QVBoxLayout(self)
        outer.setContentsMargins(0, 0, 0, 0)

        # Full-screen dark background
        bg = QWidget()
        bg.setStyleSheet(f"background-color: {BG_DARK};")
        layout = QVBoxLayout(bg)
        layout.setAlignment(Qt.AlignmentFlag.AlignCenter)
        layout.setSpacing(24)

        # ── Logo placeholder ──────────────────────────────────────────────────
        logo_frame = QFrame()
        logo_frame.setFixedSize(180, 180)
        logo_frame.setStyleSheet(f"""
            QFrame {{
                background-color: {BG_PANEL};
                border: 2px dashed {BORDER};
                border-radius: 90px;
            }}
        """)
        logo_layout = QVBoxLayout(logo_frame)
        logo_layout.setAlignment(Qt.AlignmentFlag.AlignCenter)
        logo_placeholder = QLabel("LOGO")
        logo_placeholder.setAlignment(Qt.AlignmentFlag.AlignCenter)
        logo_placeholder.setStyleSheet(f"""
            color: {TEXT_DIM};
            font-size: 13px;
            font-weight: 600;
            letter-spacing: 3px;
            border: none;
            background: transparent;
        """)
        logo_layout.addWidget(logo_placeholder)

        logo_wrapper = QHBoxLayout()
        logo_wrapper.setAlignment(Qt.AlignmentFlag.AlignCenter)
        logo_wrapper.addWidget(logo_frame)

        # ── Title ─────────────────────────────────────────────────────────────
        title = QLabel("ROCKET DESIGN")
        title.setAlignment(Qt.AlignmentFlag.AlignCenter)
        title.setStyleSheet(f"""
            color: {TEXT_PRI};
            font-size: 36px;
            font-weight: 800;
            letter-spacing: 6px;
            background: transparent;
        """)

        # ── Subtitle ──────────────────────────────────────────────────────────
        subtitle = QLabel("Multi-Stage Propulsion Optimizer")
        subtitle.setAlignment(Qt.AlignmentFlag.AlignCenter)
        subtitle.setStyleSheet(f"""
            color: {ACCENT};
            font-size: 15px;
            font-weight: 500;
            letter-spacing: 2px;
            background: transparent;
        """)

        # ── Divider ───────────────────────────────────────────────────────────
        div = QFrame()
        div.setObjectName("divider")
        div.setFixedWidth(320)
        div_wrapper = QHBoxLayout()
        div_wrapper.setAlignment(Qt.AlignmentFlag.AlignCenter)
        div_wrapper.addWidget(div)

        # ── Description ───────────────────────────────────────────────────────
        description = QLabel(
            "Calculate optimal staging mass ratios for multi-stage rockets.\n"
            "Select propellant combinations, combustion cycles, and mission\n"
            "parameters to find the minimum initial mass configuration."
        )
        description.setAlignment(Qt.AlignmentFlag.AlignCenter)
        description.setStyleSheet(f"""
            color: {TEXT_SEC};
            font-size: 13px;
            line-height: 1.6;
            background: transparent;
        """)

        # ── Launch button ─────────────────────────────────────────────────────
        launch_btn = QPushButton("LAUNCH")
        launch_btn.setObjectName("launch_btn")
        launch_btn.setCursor(Qt.CursorShape.PointingHandCursor)
        launch_btn.clicked.connect(self.launch_requested.emit)
        btn_wrapper = QHBoxLayout()
        btn_wrapper.setAlignment(Qt.AlignmentFlag.AlignCenter)
        btn_wrapper.addWidget(launch_btn)

        # ── Version label ─────────────────────────────────────────────────────
        version = QLabel("v1.0")
        version.setAlignment(Qt.AlignmentFlag.AlignCenter)
        version.setStyleSheet(f"color: {TEXT_DIM}; font-size: 11px; background: transparent;")

        layout.addStretch(2)
        layout.addLayout(logo_wrapper)
        layout.addSpacing(16)
        layout.addWidget(title)
        layout.addWidget(subtitle)
        layout.addLayout(div_wrapper)
        layout.addSpacing(8)
        layout.addWidget(description)
        layout.addSpacing(24)
        layout.addLayout(btn_wrapper)
        layout.addSpacing(16)
        layout.addWidget(version)
        layout.addStretch(3)

        outer.addWidget(bg)


# ── Main window ───────────────────────────────────────────────────────────────
class MainWindow(QMainWindow):
    def __init__(self):
        super().__init__()
        self.setWindowTitle("Rocket Staging Optimizer")
        self.setMinimumSize(960, 700)
        self.stage_widgets = []
        self._build_ui()

    def _build_ui(self):
        root = QWidget()
        self.setCentralWidget(root)
        root_layout = QHBoxLayout(root)
        root_layout.setContentsMargins(0, 0, 0, 0)
        root_layout.setSpacing(0)

        # ── Left panel (inputs) ───────────────────────────────────────────────
        left_scroll = QScrollArea()
        left_scroll.setWidgetResizable(True)
        left_scroll.setFixedWidth(420)
        left_scroll.setStyleSheet(f"background: {BG_PANEL}; border-right: 1px solid {BORDER};")

        left_inner = QWidget()
        left_inner.setStyleSheet(f"background: {BG_PANEL};")
        self.left_layout = QVBoxLayout(left_inner)
        self.left_layout.setContentsMargins(16, 20, 16, 20)
        self.left_layout.setSpacing(14)

        # Title
        title = QLabel("ROCKET STAGING")
        title.setStyleSheet(f"color: {TEXT_PRI}; font-size: 20px; font-weight: 800; letter-spacing: 2px;")
        subtitle = QLabel("Multi-stage propulsion optimizer")
        subtitle.setStyleSheet(f"color: {TEXT_SEC}; font-size: 12px;")
        self.left_layout.addWidget(title)
        self.left_layout.addWidget(subtitle)

        div = QFrame(); div.setObjectName("divider"); self.left_layout.addWidget(div)

        # Mission parameters
        mission_group = QGroupBox("MISSION PARAMETERS")
        mg_layout = QGridLayout(mission_group)
        mg_layout.setSpacing(8)

        mg_layout.addWidget(QLabel("ΔV  (km/s)"), 0, 0)
        self.dv_spin = QDoubleSpinBox()
        self.dv_spin.setRange(0.1, 100.0)
        self.dv_spin.setValue(10.0)
        self.dv_spin.setDecimals(2)
        self.dv_spin.setSingleStep(0.5)
        mg_layout.addWidget(self.dv_spin, 0, 1)

        mg_layout.addWidget(QLabel("Payload Mass  (kg)"), 1, 0)
        self.pl_spin = QDoubleSpinBox()
        self.pl_spin.setRange(1.0, 1_000_000.0)
        self.pl_spin.setValue(5000.0)
        self.pl_spin.setDecimals(1)
        self.pl_spin.setSingleStep(100.0)
        mg_layout.addWidget(self.pl_spin, 1, 1)

        mg_layout.addWidget(QLabel("Number of Stages"), 2, 0)
        self.n_stages_spin = QSpinBox()
        self.n_stages_spin.setRange(1, 3)
        self.n_stages_spin.setValue(3)
        mg_layout.addWidget(self.n_stages_spin, 2, 1)

        self.left_layout.addWidget(mission_group)
        self.n_stages_spin.valueChanged.connect(self._rebuild_stage_inputs)

        # Stage inputs container
        self.stages_container = QWidget()
        self.stages_container.setStyleSheet(f"background: {BG_PANEL};")
        self.stages_layout = QVBoxLayout(self.stages_container)
        self.stages_layout.setContentsMargins(0, 0, 0, 0)
        self.stages_layout.setSpacing(10)
        self.left_layout.addWidget(self.stages_container)

        # Run button
        self.run_btn = QPushButton("▶  Run Staging Analysis")
        self.run_btn.setObjectName("run_btn")
        self.run_btn.clicked.connect(self._run)
        self.left_layout.addWidget(self.run_btn)
        self.left_layout.addStretch()

        left_scroll.setWidget(left_inner)
        root_layout.addWidget(left_scroll)

        # ── Right panel (results) ─────────────────────────────────────────────
        right_scroll = QScrollArea()
        right_scroll.setWidgetResizable(True)
        right_scroll.setStyleSheet(f"background: {BG_DARK};")

        self.right_inner = QWidget()
        self.right_inner.setStyleSheet(f"background: {BG_DARK};")
        self.right_layout = QVBoxLayout(self.right_inner)
        self.right_layout.setContentsMargins(24, 24, 24, 24)
        self.right_layout.setSpacing(14)
        self.right_layout.addStretch()

        right_scroll.setWidget(self.right_inner)
        root_layout.addWidget(right_scroll, 1)

        # Build initial stage inputs
        self._rebuild_stage_inputs(self.n_stages_spin.value())
        self._show_empty_state()

    def _rebuild_stage_inputs(self, n):
        # Remove old stage widgets
        for w in self.stage_widgets:
            self.stages_layout.removeWidget(w)
            w.deleteLater()
        self.stage_widgets.clear()

        for i in range(n):
            sw = StageInputWidget(i + 1)
            self.stages_layout.addWidget(sw)
            self.stage_widgets.append(sw)

    def _show_empty_state(self):
        placeholder = QLabel("Run the analysis to see results here.")
        placeholder.setAlignment(Qt.AlignmentFlag.AlignCenter)
        placeholder.setObjectName("placeholder")
        placeholder.setStyleSheet(f"color: {TEXT_DIM}; font-size: 15px;")
        self.right_layout.insertWidget(0, placeholder)

    def _clear_results(self):
        while self.right_layout.count():
            item = self.right_layout.takeAt(0)
            if item.widget():
                item.widget().deleteLater()

    def _run(self):
        n = self.n_stages_spin.value()
        isp_list = []
        ks_list  = []

        # Validate all stages have data
        missing = []
        for i, sw in enumerate(self.stage_widgets):
            isp, ks, ok = sw.get_values()
            if not ok:
                missing.append(i + 1)
            else:
                isp_list.append(isp)
                ks_list.append(ks)

        if missing:
            QMessageBox.warning(
                self, "Missing Data",
                f"Stage(s) {missing} have no ISP or k_s data for the selected\n"
                "propellant / combustion cycle combination.\n\n"
                "Please select a different combination or add data to Typical_Data.f90."
            )
            return

        try:
            results = run_staging(
                n_stages=n,
                delta_v=self.dv_spin.value(),
                payload_mass=self.pl_spin.value(),
                isp_list=isp_list,
                ks_list=ks_list,
            )
        except Exception as e:
            QMessageBox.critical(self, "Fortran Error", str(e))
            return

        self._clear_results()

        # Summary header
        summary = QLabel(
            f"Total Initial Mass:  "
            f"<span style='color:{ACCENT}; font-size:22px; font-weight:700;'>"
            f"{results['total_initial_mass']:,.1f} kg</span>"
        )
        summary.setTextFormat(Qt.TextFormat.RichText)
        summary.setStyleSheet(f"color: {TEXT_PRI}; font-size: 14px;")
        self.right_layout.addWidget(summary)

        min_label = QLabel(
            "✔  Minimum confirmed" if results["minimum_found"]
            else "✘  Minimum not confirmed — check your inputs"
        )
        color = GREEN if results["minimum_found"] else ACCENT2
        min_label.setStyleSheet(f"color: {color}; font-size: 12px; font-weight: 600;")
        self.right_layout.addWidget(min_label)

        div = QFrame(); div.setObjectName("divider")
        self.right_layout.addWidget(div)

        # Stage cards
        for stage in results["stages"]:
            card = ResultCard(stage["stage"], stage)
            self.right_layout.addWidget(card)

        self.right_layout.addStretch()



# ── App window (splash + main stacked) ───────────────────────────────────────
class AppWindow(QMainWindow):
    def __init__(self):
        super().__init__()
        self.setWindowTitle("Rocket Design")
        self.setMinimumSize(960, 700)

        self._stack = QStackedWidget()
        self.setCentralWidget(self._stack)

        self._splash = SplashScreen()
        self._main   = MainWindow()

        self._stack.addWidget(self._splash)   # index 0
        self._stack.addWidget(self._main)     # index 1
        self._stack.setCurrentIndex(0)

        self._splash.launch_requested.connect(self._launch)

    def _launch(self):
        """Fade the splash out then switch to the main GUI."""
        effect = QGraphicsOpacityEffect(self._splash)
        self._splash.setGraphicsEffect(effect)

        self._anim = QPropertyAnimation(effect, b"opacity")
        self._anim.setDuration(600)
        self._anim.setStartValue(1.0)
        self._anim.setEndValue(0.0)
        self._anim.setEasingCurve(QEasingCurve.Type.InOutQuad)
        self._anim.finished.connect(lambda: self._stack.setCurrentIndex(1))
        self._anim.start()


# ── Entry point ───────────────────────────────────────────────────────────────
if __name__ == "__main__":
    app = QApplication(sys.argv)
    app.setStyleSheet(STYLE)
    window = AppWindow()
    window.show()
    sys.exit(app.exec())
