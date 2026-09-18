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
    QGroupBox, QMessageBox, QStackedWidget, QGraphicsOpacityEffect,
    QFileDialog, QTabWidget, QRadioButton, QButtonGroup
)
from PyQt6.QtCore import Qt, QThread, pyqtSignal, QPropertyAnimation, QEasingCurve
from PyQt6.QtGui import QFont, QPalette, QColor

# ── Fortran bridge ────────────────────────────────────────────────────────────
# gui.py lives in gui/  →  root SRC is one level up
GUI_DIR  = os.path.dirname(os.path.abspath(__file__))
ROOT_DIR = os.path.dirname(GUI_DIR)

# Make sure interface/ is on the path so rocket_lib can be imported if needed
# rocket_lib is the single authoritative ctypes bridge (loads build/-only DLL).
sys.path.insert(0, os.path.join(ROOT_DIR, "interface"))
import rocket_lib   # full-pipeline bridge entry (run_full_pipeline, 03-02)

# ── Fairing geometry (Phase 4 mock) ───────────────────────────────────────────
from .fairing_geometry import compute_fairing_geometry_per_stage
from .rocket_diagram import RocketDiagramView

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
        return _tdr.TYPICAL_DATA_BY_STAGE, _tdr.PROPELLANTS, _tdr.CYCLES
    except ImportError:
        print("WARNING: typical_data_ranges.py not found.")
        print("         Run parse_typical_data.py to generate it.")
        return [None, {}, {}, {}], [], []

TYPICAL_DATA_BY_STAGE, PROPELLANTS, CYCLES = _load_data()


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
QPushButton#print_btn {{
    background-color: transparent;
    color: {TEXT_SEC};
    border: 1px solid {BORDER};
    border-radius: 8px;
    padding: 10px 32px;
    font-weight: 600;
    font-size: 14px;
    min-height: 40px;
}}
QPushButton#print_btn:hover {{
    border-color: {ACCENT};
    color: {ACCENT};
}}
QPushButton#print_btn:pressed {{
    color: #388bfd;
    border-color: #388bfd;
}}
QPushButton#print_btn:disabled {{
    color: {TEXT_DIM};
    border-color: {TEXT_DIM};
}}
QFrame#divider {{
    background: {BORDER};
    max-height: 1px;
    min-height: 1px;
}}
QTabWidget::pane {{ background: {BG_DARK}; border: 1px solid {BORDER}; }}
QTabBar::tab {{ background: {BG_PANEL}; color: {TEXT_SEC}; padding: 8px 24px;
               border: 1px solid {BORDER}; border-bottom: none; }}
QTabBar::tab:selected {{ background: {BG_CARD}; color: {ACCENT}; font-weight: 600; }}
QTabBar::tab:!selected:hover {{ color: {TEXT_PRI}; }}
QTabBar::tab:top:!selected {{ margin-top: 3px; }}
QRadioButton {{ color: {TEXT_PRI}; background: transparent; }}
QRadioButton::indicator {{ width: 16px; height: 16px; }}
QRadioButton::indicator:checked {{ background: {ACCENT}; }}
"""

# ── Stage input widget ────────────────────────────────────────────────────────
class NoScrollComboBox(QComboBox):
    def wheelEvent(self, event):
        event.ignore()

class StageInputWidget(QGroupBox):
    validity_changed = pyqtSignal()

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
        self.prop_combo = NoScrollComboBox()
        self.prop_combo.addItems(PROPELLANTS)
        self.prop_combo.setMinimumWidth(220)
        row1.addWidget(self.prop_combo)
        layout.addLayout(row1)

        # Combustion Cycle
        row2 = QHBoxLayout()
        row2.addWidget(QLabel("Combustion Cycle"))
        self.cycle_combo = NoScrollComboBox()
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
        self.prop_combo.currentIndexChanged.connect(self.validity_changed)
        self.cycle_combo.currentIndexChanged.connect(self._cycle_changed)
        self.cycle_combo.currentIndexChanged.connect(self.validity_changed)
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
        d = TYPICAL_DATA_BY_STAGE[self.stage_num].get((prop, cycle))
        if d is None:
            # Current cycle is explicitly invalid for this propellant — reset to first valid
            for c_idx in range(self.cycle_combo.count()):
                test = TYPICAL_DATA_BY_STAGE[self.stage_num].get((prop, c_idx))
                if test is not None:
                    self.cycle_combo.setCurrentIndex(c_idx)
                    break
        self._update_ranges()

    def _cycle_changed(self):
        """When cycle changes: warn if the combination is explicitly invalid."""
        prop  = self.prop_combo.currentIndex() + 1
        cycle = self.cycle_combo.currentIndex()
        d = TYPICAL_DATA_BY_STAGE[self.stage_num].get((prop, cycle))
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
            d = TYPICAL_DATA_BY_STAGE[self.stage_num].get((prop, c_idx))
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
        cycle = self.cycle_combo.currentIndex()      # 0-based
        stage_data = TYPICAL_DATA_BY_STAGE[self.stage_num]
        return stage_data.get((prop, cycle), (0.0, 0.0, 0.0, 0.0, 0.0, 0.0))

    def _update_ranges(self):
        prop  = self.prop_combo.currentIndex() + 1
        cycle = self.cycle_combo.currentIndex()
        d = TYPICAL_DATA_BY_STAGE[self.stage_num].get((prop, cycle))

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
        d = TYPICAL_DATA_BY_STAGE[self.stage_num].get((prop, cycle))

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

    def get_propellant_index(self):
        """1-based Fortran propellant code (1-8) for this stage — the same index
        get_values computes at the combo; feeds the Geometry_calc select-case
        tables via run_full_pipeline (02-02)."""
        return self.prop_combo.currentIndex() + 1


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

        def add_metric(row, col, label, value, unit="", color=TEXT_PRI, fmt=":,.1f"):
            lbl = QLabel(label)
            lbl.setStyleSheet(f"color: {TEXT_SEC}; font-size: 11px; border: none;")
            try:
                if isinstance(value, (int, float)) and value == value:
                    # value == value excludes NaN: "nan" would be a fabricated
                    # number, not a real result (PIPE-02).
                    text = f"{fmt % value}" if fmt.startswith("%") else f"{value:{fmt.lstrip(':')}}"
                    text = f"{text} {unit}".strip()
                else:
                    # Placeholder for partial or invalid population (PIPE-02):
                    # never a fabricated number — "—" in TEXT_DIM until Phase 2
                    # packs the value.
                    text, color = "—", TEXT_DIM
            except (TypeError, ValueError):
                text, color = "—", TEXT_DIM
            val = QLabel(text)
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
        # Rows 4-5: per-stage ΔV + geometry — .get() defaults (None) render "—"
        # (TEXT_DIM) until Phase 2 packs dv/diameter/length/volume (signature-stable).
        add_metric(4, 0, "Stage ΔV",     data.get("dv"),       "km/s", fmt="%.2f")
        add_metric(4, 1, "Diameter",     data.get("diameter"), "m",    fmt="%.2f")
        add_metric(5, 0, "Length",       data.get("length"),   "m",    fmt="%.2f")
        add_metric(5, 1, "Volume",       data.get("volume"),   "m³",   fmt="%.2f")

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
        # Central container: the tab widget fills the window and a shared Run
        # button row sits beneath it. The Run button must be reachable from
        # every tab EXCEPT Results (index 0) — a single widget shown/hidden by
        # the current tab, instead of duplicating it across layouts (user
        # request, 2026-09-06). Built BEFORE _rebuild_stage_inputs so the
        # _update_run_button 'ready' styling has its target from the start.
        self.tabs = QTabWidget()

        container = QWidget()
        outer = QVBoxLayout(container)
        outer.setContentsMargins(0, 0, 0, 0)
        outer.setSpacing(0)

        # Shared Run button — objectName / ready property / stylesheet /
        # clicked connection contract unchanged, only its home layout moved.
        self.run_btn = QPushButton("▶  Run Staging Analysis")
        self.run_btn.setObjectName("run_btn")
        self.run_btn.setProperty("ready", False)
        self.run_btn.setStyleSheet(f"""
            QPushButton {{ background-color: {BG_INPUT}; color: {TEXT_DIM}; border: 1px solid {BORDER}; border-radius: 8px; padding: 10px 32px; font-weight: 700; font-size: 14px; min-height: 40px; }}
            QPushButton[ready=true] {{ background-color: {GREEN}; color: {BG_DARK}; border: none; }}
            QPushButton[ready=true]:hover {{ background-color: #56d364; color: {BG_DARK}; }}
            QPushButton[ready=true]:pressed {{ background-color: #3fb950; color: {BG_DARK}; }}
        """)
        self.run_btn.clicked.connect(self._run)

        outer.addWidget(self.tabs, 1)
        run_row = QHBoxLayout()
        run_row.setContentsMargins(24, 12, 24, 16)
        run_row.addStretch()
        run_row.addWidget(self.run_btn)
        run_row.addStretch()
        outer.addLayout(run_row)
        self.setCentralWidget(container)

        self.tabs.addTab(self._build_results_tab(), "Results")                # index 0 — central/home (D-02)
        self.tabs.addTab(self._build_setup_tab(),   "Setup")
        self.tabs.addTab(self._build_vehicle_tab(), "Vehicle Configuration")  # index 2

        # Run visibility follows the current tab: hidden on Results (index 0),
        # shown on every other tab. Explicit initial sync guards the case where
        # adding the first tab did not emit currentChanged (Results is active
        # on open, so the button starts hidden).
        self.tabs.currentChanged.connect(self._on_tab_changed)
        self._on_tab_changed(self.tabs.currentIndex())

        # Build initial stage inputs
        self._rebuild_stage_inputs(self.n_stages_spin.value())
        self._show_empty_state()

    def _on_tab_changed(self, index):
        """Show the shared Run button on every tab except Results (index 0)."""
        self.run_btn.setVisible(index != 0)

    def _build_results_tab(self):
        """Results tab (index 0): central/home surface (D-02)."""
        scroll = QScrollArea()
        scroll.setWidgetResizable(True)
        scroll.setStyleSheet(f"background: {BG_DARK};")
        inner = QWidget()
        inner.setStyleSheet(f"background: {BG_DARK};")
        self.results_layout = QVBoxLayout(inner)
        self.results_layout.setContentsMargins(24, 24, 24, 24)   # UI-SPEC lg token
        self.results_layout.setSpacing(14)
        self.results_layout.addStretch()

        # Save Results — relocated from the input panel (UI-SPEC:156), pinned
        # above the trailing stretch; disabled until a successful run.
        self.print_btn = QPushButton("⬇  Save Results")
        self.print_btn.setObjectName("print_btn")
        self.print_btn.clicked.connect(self._print_results)
        self.print_btn.setEnabled(False)
        self.results_layout.addWidget(self.print_btn)

        scroll.setWidget(inner)
        return scroll

    def _build_setup_tab(self):
        """Setup tab (index 1): relocated input panel, verbatim (D-08)."""
        scroll = QScrollArea()
        scroll.setWidgetResizable(True)
        scroll.setStyleSheet(f"background: {BG_PANEL};")
        inner = QWidget()
        inner.setStyleSheet(f"background: {BG_PANEL};")
        self.setup_layout = QVBoxLayout(inner)
        self.setup_layout.setContentsMargins(16, 20, 16, 20)
        self.setup_layout.setSpacing(14)

        # Title
        title = QLabel("ROCKET STAGING")
        title.setStyleSheet(f"color: {TEXT_PRI}; font-size: 20px; font-weight: 800; letter-spacing: 2px;")
        subtitle = QLabel("Multi-stage propulsion optimizer")
        subtitle.setStyleSheet(f"color: {TEXT_SEC}; font-size: 12px;")
        self.setup_layout.addWidget(title)
        self.setup_layout.addWidget(subtitle)

        div = QFrame(); div.setObjectName("divider"); self.setup_layout.addWidget(div)

        # Mission parameters
        mission_group = QGroupBox("MISSION PARAMETERS")
        mg_layout = QGridLayout(mission_group)
        mg_layout.setSpacing(8)

        # Orbit height (row 0) — NEW (UI-SPEC:166); drives the internal ΔV (D-10)
        mg_layout.addWidget(QLabel("Orbit Height (km)"), 0, 0)
        self.orbit_height = QDoubleSpinBox()
        self.orbit_height.setRange(100.0, 2000.0)   # bounded per V5 input validation
        self.orbit_height.setValue(500.0)
        self.orbit_height.setDecimals(1)
        self.orbit_height.setSingleStep(10.0)
        mg_layout.addWidget(self.orbit_height, 0, 1)

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

        # Read-only ΔV (auto) — row 3 (UI-SPEC:169); never hand-entered (D-10)
        mg_layout.addWidget(QLabel("ΔV (auto)"), 3, 0)
        self.auto_dv_label = QLabel("— km/s")
        self.auto_dv_label.setStyleSheet(f"color: {TEXT_SEC}; font-size: 12px;")
        mg_layout.addWidget(self.auto_dv_label, 3, 1)

        self.setup_layout.addWidget(mission_group)
        self.n_stages_spin.valueChanged.connect(self._rebuild_stage_inputs)

        # Stage inputs container
        self.stages_container = QWidget()
        self.stages_container.setStyleSheet(f"background: {BG_PANEL};")
        self.stages_layout = QVBoxLayout(self.stages_container)
        self.stages_layout.setContentsMargins(0, 0, 0, 0)
        self.stages_layout.setSpacing(10)
        self.setup_layout.addWidget(self.stages_container)

        # Run button lives in the shared row beneath the tabs (_build_ui) so it
        # is reachable from Setup AND Vehicle Configuration, hidden only on the
        # Results tab (user request, 2026-09-06). Keep the trailing stretch:
        # setup content stays top-aligned.
        self.setup_layout.addStretch()

        # Signal wiring — preserved across tab relocation (Pitfall 3)
        self.pl_spin.valueChanged.connect(self._on_inputs_changed)
        self.n_stages_spin.valueChanged.connect(self._on_inputs_changed)
        # Orbit height fans out to invalidation AND the auto-ΔV label (UI-SPEC:174-175)
        self.orbit_height.valueChanged.connect(self._on_inputs_changed)
        self.orbit_height.valueChanged.connect(self._update_auto_dv_label)

        scroll.setWidget(inner)
        return scroll

    def _build_vehicle_tab(self):
        """Vehicle Configuration tab (index 2): diameter-mode radios (D-11/D-12)
        and fairing mode controls (FAIR-01/03/04, D-01..D-03).

        Body mode semantics mirror Fortran diameter_setup 1/2/3 (Geometry_calc.f90:92-105);
        fairing mode is Python mock for Phase 4 (v1.1), replaced by Fortran in v2+."""
        scroll = QScrollArea()
        scroll.setWidgetResizable(True)
        scroll.setStyleSheet(f"background: {BG_PANEL};")
        inner = QWidget()
        inner.setStyleSheet(f"background: {BG_PANEL};")
        self.vehicle_layout = QVBoxLayout(inner)
        self.vehicle_layout.setContentsMargins(16, 20, 16, 20)
        self.vehicle_layout.setSpacing(14)

        # Header — mirrors the Setup header pattern (UI-SPEC:178)
        title = QLabel("VEHICLE CONFIGURATION")
        title.setStyleSheet(f"color: {TEXT_PRI}; font-size: 20px; font-weight: 800; letter-spacing: 2px;")
        subtitle = QLabel("Diameter sizing mode")
        subtitle.setStyleSheet(f"color: {TEXT_SEC}; font-size: 12px;")
        self.vehicle_layout.addWidget(title)
        self.vehicle_layout.addWidget(subtitle)

        div = QFrame(); div.setObjectName("divider"); self.vehicle_layout.addWidget(div)

        # ── Body / Fairing mode groups side-by-side (60/40 split, D-01) ──
        modes_split = QHBoxLayout()
        modes_split.setSpacing(16)

        # LEFT: Body Diameter Mode (60% weight)
        body_container = QWidget()
        body_layout = QVBoxLayout(body_container)
        body_layout.setContentsMargins(0, 0, 0, 0)
        body_layout.setSpacing(8)

        # "Body" header label (D-03)
        body_header = QLabel("Body")
        body_header.setStyleSheet(f"color: {ACCENT}; font-size: 12px; font-weight: 600; letter-spacing: 1px;")
        body_layout.addWidget(body_header)

        # DIAMETER MODE group — 3 mutually-exclusive radios (QButtonGroup), each
        # with its 11px TEXT_SEC helper line (UI-SPEC:179-186).
        self.mode_group = QGroupBox("DIAMETER MODE")
        mode_layout = QVBoxLayout(self.mode_group)
        mode_layout.setSpacing(10)

        self.mode_stat  = QRadioButton("Statistically determined")   # → 1, default checked
        self.mode_const = QRadioButton("Constant")                   # → 2
        self.mode_user  = QRadioButton("User-specified")             # → 3 (CONTEXT D-11 label)

        self.mode_buttons = QButtonGroup(self)
        self.mode_buttons.addButton(self.mode_stat, 1)
        self.mode_buttons.addButton(self.mode_const, 2)
        self.mode_buttons.addButton(self.mode_user, 3)

        self.diameter_mode = 1                       # Phase 2 handoff state (Pitfall 8)
        self.mode_stat.setChecked(True)              # mirrors config.txt Diameter_setup = 1

        mode_layout.addWidget(self.mode_stat)
        mode_layout.addWidget(self._vehicle_helper(
            "Statistically determined: each stage diameter from propellant regression curves on stage mass"))
        mode_layout.addWidget(self.mode_const)
        mode_layout.addWidget(self._vehicle_helper(
            "Constant: all stages take the widest statistical diameter"))
        mode_layout.addWidget(self.mode_user)
        mode_layout.addWidget(self._vehicle_helper(
            "User-specified: all stages take the diameter entered below"))

        body_layout.addWidget(self.mode_group)

        # User-specified diameter box (D-12, GUI-07) — bounded per V5; mirrors
        # config.txt User_defined_diameter = 2.0 (UI-SPEC:188)
        diam_row = QHBoxLayout()
        diam_row.addWidget(QLabel("User-Specified Diameter (m)"))
        self.diameter_spin = QDoubleSpinBox()
        self.diameter_spin.setRange(0.5, 20.0)
        self.diameter_spin.setValue(2.00)
        self.diameter_spin.setDecimals(2)
        self.diameter_spin.setSingleStep(0.1)
        self.diameter_spin.setVisible(False)         # visibility contract: mode 3 only
        diam_row.addWidget(self.diameter_spin)
        body_layout.addLayout(diam_row)

        body_layout.addStretch()
        modes_split.addWidget(body_container, 60)  # 60% weight (D-01)

        # RIGHT: Fairing Diameter Mode (40% weight)
        fairing_container = QWidget()
        fairing_layout = QVBoxLayout(fairing_container)
        fairing_layout.setContentsMargins(0, 0, 0, 0)
        fairing_layout.setSpacing(8)

        # "Fairing" header label (D-03)
        fairing_header = QLabel("Fairing")
        fairing_header.setStyleSheet(f"color: {ACCENT2}; font-size: 12px; font-weight: 600; letter-spacing: 1px;")
        fairing_layout.addWidget(fairing_header)

        # FAIRING MODE group (D-01, D-02: initially hidden)
        self.fairing_mode_group = QGroupBox("FAIRING MODE")
        fairing_mode_layout = QVBoxLayout(self.fairing_mode_group)
        fairing_mode_layout.setSpacing(10)

        self.fairing_mode_const = QRadioButton("Constant (same as body)")      # → 1
        self.fairing_mode_tapered = QRadioButton("Tapered (smaller than body)") # → 2
        self.fairing_mode_hammer = QRadioButton("Hammer-Head (larger than body)") # → 3

        self.fairing_mode_buttons = QButtonGroup(self)
        self.fairing_mode_buttons.addButton(self.fairing_mode_const, 1)
        self.fairing_mode_buttons.addButton(self.fairing_mode_tapered, 2)
        self.fairing_mode_buttons.addButton(self.fairing_mode_hammer, 3)

        self.fairing_mode = 1                       # Phase 4 state: 1=Constant, 2=Tapered, 3=Hammer-Head
        self.fairing_mode_const.setChecked(True)    # default per FAIR-01

        fairing_mode_layout.addWidget(self.fairing_mode_const)
        fairing_mode_layout.addWidget(self._vehicle_helper(
            "Constant: fairing diameter equals body diameter"))
        fairing_mode_layout.addWidget(self.fairing_mode_tapered)
        fairing_mode_layout.addWidget(self._vehicle_helper(
            "Tapered: fairing diameter ≤ last stage body diameter (user-specified)"))
        fairing_mode_layout.addWidget(self.fairing_mode_hammer)
        fairing_mode_layout.addWidget(self._vehicle_helper(
            "Hammer-Head: fairing diameter ≥ body diameter (user-specified)"))

        fairing_layout.addWidget(self.fairing_mode_group)

        # Fairing diameter spinbox (conditional, mirrors diameter_spin pattern)
        fairing_diam_row = QHBoxLayout()
        fairing_diam_row.addWidget(QLabel("Fairing Diameter (m)"))
        self.fairing_diameter_spin = QDoubleSpinBox()
        self.fairing_diameter_spin.setRange(0.5, 20.0)
        self.fairing_diameter_spin.setValue(2.00)
        self.fairing_diameter_spin.setDecimals(2)
        self.fairing_diameter_spin.setSingleStep(0.1)
        self.fairing_diameter_spin.setSuffix(" m")
        self.fairing_diameter_spin.setVisible(False)   # hidden for Constant mode
        fairing_diam_row.addWidget(self.fairing_diameter_spin)
        fairing_layout.addLayout(fairing_diam_row)

        fairing_layout.addStretch()
        modes_split.addWidget(fairing_container, 40)  # 40% weight (D-01)

        self.vehicle_layout.addLayout(modes_split)

        # Fairing group initially hidden (D-02): appears after body mode selected
        self.fairing_mode_group.setVisible(False)

        # ── Rocket Diagram View (VIS-01) ──
        self.rocket_diagram = RocketDiagramView()
        self.rocket_diagram.setMinimumHeight(300)
        self.vehicle_layout.addWidget(self.rocket_diagram)

        # Visibility contract + Phase 2 state. Widgets are never rebuilt, so the
        # diameter value persists across mode toggles and tab switches. Wired
        # only AFTER every widget above is fully built — the construction-time
        # setChecked/setValue calls (mode_stat at ~913, diameter_spin at ~933)
        # must not retroactively trigger invalidation.
        self.mode_user.toggled.connect(self.diameter_spin.setVisible)
        self.mode_buttons.buttonToggled.connect(self._on_mode_toggled)
        # Diameter configuration is an input: toggling any mode radio or
        # changing the user-specified value invalidates results exactly like
        # every other input (D-04/D-05 state integrity — no stale converged
        # numbers are shown or exported against changed diameter inputs).
        self.mode_buttons.buttonToggled.connect(self._on_inputs_changed)
        self.diameter_spin.valueChanged.connect(self._on_inputs_changed)

        # Fairing mode wiring (D-02, FAIR-01/03/04)
        # Show fairing group when any body mode is selected (user interaction)
        self.mode_buttons.buttonToggled.connect(self._on_body_mode_toggled)
        # Store fairing mode and invalidate on change
        self.fairing_mode_buttons.buttonToggled.connect(self._on_fairing_mode_toggled)
        self.fairing_mode_buttons.buttonToggled.connect(self._on_inputs_changed)
        self.fairing_diameter_spin.valueChanged.connect(self._on_inputs_changed)

        self.vehicle_layout.addStretch()
        scroll.setWidget(inner)
        return scroll

    def _vehicle_helper(self, text):
        """11px TEXT_SEC helper line under a mode radio (UI-SPEC copy contract)."""
        lbl = QLabel(text)
        lbl.setStyleSheet(f"color: {TEXT_SEC}; font-size: 11px;")
        lbl.setIndent(26)
        return lbl

    def _on_mode_toggled(self, btn, checked):
        """Store the diameter mode int (1/2/3) for Phase 2 handoff (Pitfall 8).

        Fires on any radio toggle (user click or programmatic setChecked);
        only the checked transition updates the stored mode."""
        if checked:
            self.diameter_mode = self.mode_buttons.id(btn)

    def _on_body_mode_toggled(self, btn, checked):
        """Show fairing mode group when any body mode is selected (D-02)."""
        if checked:
            self.fairing_mode_group.setVisible(True)

    def _on_fairing_mode_toggled(self, btn, checked):
        """Store the fairing mode int (1/2/3) and update spinbox visibility.

        Constant mode (1): no user input needed, spinbox hidden.
        Tapered (2) / Hammer-Head (3): spinbox visible for user-specified diameter."""
        if checked:
            self.fairing_mode = self.fairing_mode_buttons.id(btn)
            # Spinbox visible only for non-Constant modes
            self.fairing_diameter_spin.setVisible(self.fairing_mode != 1)

    def _rebuild_stage_inputs(self, n):
        for w in self.stage_widgets:
            self.stages_layout.removeWidget(w)
            w.deleteLater()
        self.stage_widgets.clear()

        for i in range(n):
            sw = StageInputWidget(i + 1)
            sw.validity_changed.connect(self._update_run_button)
            sw.validity_changed.connect(self._on_inputs_changed)
            sw.isp_slider.valueChanged.connect(self._on_inputs_changed)
            sw.ks_slider.valueChanged.connect(self._on_inputs_changed)
            self.stages_layout.addWidget(sw)
            self.stage_widgets.append(sw)

        self._update_run_button()

    def _show_empty_state(self):
        placeholder = QLabel("Run the analysis to see results here.")
        placeholder.setAlignment(Qt.AlignmentFlag.AlignCenter)
        placeholder.setObjectName("placeholder")
        placeholder.setStyleSheet(f"color: {TEXT_DIM}; font-size: 15px;")
        self.results_layout.insertWidget(0, placeholder)
        # Re-pin Save Results at the bottom (above the trailing stretch); it is
        # preserved by reference across _clear_results (relocated from the old
        # input panel where it lived outside the cleared layout).
        if self.results_layout.indexOf(self.print_btn) == -1:
            self.results_layout.addStretch()
            self.results_layout.addWidget(self.print_btn)

    def _clear_results(self):
        while self.results_layout.count():
            item = self.results_layout.takeAt(0)
            if item.widget() and item.widget() is not self.print_btn:
                item.widget().deleteLater()

    def _update_run_button(self):
        all_valid = all(sw.get_values()[2] for sw in self.stage_widgets)
        self.run_btn.setProperty("ready", all_valid)
        self.run_btn.style().unpolish(self.run_btn)
        self.run_btn.style().polish(self.run_btn)

    def _on_inputs_changed(self):
        self._clear_results()
        self._show_empty_state()
        self.print_btn.setEnabled(False)
        self._last_v_circ = None          # no stale V_circ survives an input change (D-04/D-05)
        self._update_auto_dv_label()

    def _update_auto_dv_label(self):
        """Refresh the read-only ΔV (auto) label from the last run's Fortran V_circ."""
        v = getattr(self, '_last_v_circ', None)
        if isinstance(v, (int, float)) and v == v:  # v == v excludes NaN (ResultCard idiom)
            self.auto_dv_label.setText(f"{v:.2f} km/s")
        else:
            self.auto_dv_label.setText("— km/s")

    def _print_results(self):
        if not (hasattr(self, '_last_results') and hasattr(self, '_last_configs')
                and getattr(self, '_last_v_circ', None) is not None):
            QMessageBox.warning(self, "No Results", "Run the staging analysis first.")
            return

        dv  = self._last_v_circ   # Fortran V_circ — label == export Delta-V line == filename (D-01/D-05)
        pl  = int(self.pl_spin.value())
        n   = self.n_stages_spin.value()
        default_name = f"staging_{n}stage_dv{dv:.1f}_pl{pl}kg.txt"

        path, _ = QFileDialog.getSaveFileName(
            self, "Save Results", default_name, "Text Files (*.txt)"
        )
        if not path:
            return

        r = self._last_results
        lines = []
        lines.append("=" * 48)
        lines.append("  ROCKET STAGING RESULTS")
        lines.append("=" * 48)
        lines.append(f"  Delta-V:       {dv:.2f} km/s")
        lines.append(f"  Payload mass:  {self.pl_spin.value():.1f} kg")
        lines.append(f"  Stages:        {self.n_stages_spin.value()}")
        lines.append(f"  Total initial mass: {r['total_initial_mass']:,.1f} kg")
        lines.append(f"  Minimum found: {'Yes' if r['minimum_found'] else 'No'}")
        lines.append("")
        if len(r["stages"]) != len(self._last_configs):
            QMessageBox.critical(
                self, "Export Error",
                "Stage results and configuration are out of sync. Re-run the analysis."
            )
            return

        for s, cfg in zip(r["stages"], self._last_configs):
            lines.append(f"  Stage {s['stage']}")
            lines.append(f"    Propellant:        {cfg['propellant']}")
            lines.append(f"    Combustion cycle:  {cfg['cycle']}")
            lines.append(f"    Initial mass (m0): {s['m0']:>12,.1f} kg")
            lines.append(f"    Final mass   (mf): {s['mf']:>12,.1f} kg")
            lines.append(f"    Propellant   (mp): {s['mp']:>12,.1f} kg")
            lines.append(f"    Structure    (ms): {s['ms']:>12,.1f} kg")
            lines.append(f"    Mass ratio  (k_m): {s['k_m']:>12.4f}")
            lines.append(f"    Struct coef (k_s): {s['k_s']:>12.4f}")
            lines.append(f"    Payload rat (k_L): {s['k_L']:>12.4f}")
            lines.append(f"    Exhaust vel (v_e): {s['nu_e']:>12.4f} km/s")
            lines.append("")

        # Fairing Geometry section (FAIR-04, D-10)
        # Compute fairing geometry for export (same as in _run)
        body_diameters = [s.get("diameter", 2.0) for s in r["stages"]]
        fairing_d = self.fairing_diameter_spin.value() if self.fairing_mode != 1 else None
        fairing_data = compute_fairing_geometry_per_stage(
            body_diameters, self.fairing_mode, fairing_d
        )
        if fairing_data:
            lines.append("  FAIRING GEOMETRY")
            for i, f in enumerate(fairing_data):
                lines.append(f"    Stage {i+1} Fairing:")
                lines.append(f"      Diameter:  {f.get('diameter', 0.0):>10.2f} m")
                lines.append(f"      Length:    {f.get('length', 0.0):>10.2f} m")
                lines.append(f"      Volume:    {f.get('volume', 0.0):>10.2f} m³")
                lines.append("")

        lines.append("=" * 48)

        with open(path, "w", encoding="utf-8") as f:
            f.write("\n".join(lines))

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
            results = rocket_lib.run_full_pipeline(
                n_stages=n,
                orbit_height=self.orbit_height.value(),
                payload_mass=self.pl_spin.value(),
                isp_list=isp_list,
                ks_list=ks_list,
                propellant_list=[sw.get_propellant_index() for sw in self.stage_widgets],
                diameter_setup=self.diameter_mode,
                user_diameter=self.diameter_spin.value(),
            )

            # Compute fairing geometry from stage body diameters (Phase 4 mock)
            body_diameters = [s.get("diameter", 2.0) for s in results["stages"]]
            fairing_d = self.fairing_diameter_spin.value() if self.fairing_mode != 1 else None
            fairing_data = compute_fairing_geometry_per_stage(
                body_diameters, self.fairing_mode, fairing_d
            )

            # Build rocket diagram with stage data + fairing (VIS-01)
            stage_data = [{"diameter": s.get("diameter", 2.0), "length": s.get("length", 10.0)}
                          for s in results["stages"]]
            self.rocket_diagram.build_rocket_scene(stage_data, fairing_data)

            self._clear_results()

            # Summary header
            summary = QLabel(
                f"Total Initial Mass:  "
                f"<span style='color:{ACCENT}; font-size:22px; font-weight:700;'>"
                f"{results['total_initial_mass']:,.1f} kg</span>"
            )
            summary.setTextFormat(Qt.TextFormat.RichText)
            summary.setStyleSheet(f"color: {TEXT_PRI}; font-size: 14px;")
            self.results_layout.addWidget(summary)

            min_label = QLabel(
                "✔  Minimum confirmed" if results["minimum_found"]
                else "✘  Minimum not confirmed — check your inputs"
            )
            color = GREEN if results["minimum_found"] else ACCENT2
            min_label.setStyleSheet(f"color: {color}; font-size: 12px; font-weight: 600;")
            self.results_layout.addWidget(min_label)

            div = QFrame(); div.setObjectName("divider")
            self.results_layout.addWidget(div)

            # Stage cards
            for stage in results["stages"]:
                card = ResultCard(stage["stage"], stage)
                self.results_layout.addWidget(card)

            # Partial-state hint (UI-SPEC:112): one 11px TEXT_DIM label after the
            # cards when ANY placeholder "—" is rendered (Phase 1 has no per-stage
            # ΔV/geometry); absent in the pre-run empty state (no cards -> no hint).
            if any(
                s.get("dv") is None or s.get("diameter") is None
                or s.get("length") is None or s.get("volume") is None
                for s in results["stages"]
            ):
                hint = QLabel("ΔV and geometry populate with full pipeline wiring (Phase 2).")
                hint.setStyleSheet(f"color: {TEXT_DIM}; font-size: 11px; border: none;")
                self.results_layout.addWidget(hint)

            self._last_configs = [
                {
                    "propellant": sw.prop_combo.currentText(),
                    "cycle":      sw.cycle_combo.currentText(),
                }
                for sw in self.stage_widgets
            ]
            self._last_results = results
            self._last_v_circ = results["v_circ"]   # Fortran V_circ — label/export source (D-01/D-04/D-05)
            self._update_auto_dv_label()
            self.print_btn.setEnabled(True)
            # Auto-switch to Results after a successful run (UI-SPEC:193) — fires
            # only in this success path; _on_inputs_changed never navigates.
            self.tabs.setCurrentIndex(0)

            self._last_results = results

            # Save Results pinned above the final stretch (UI-SPEC:156)
            self.results_layout.addWidget(self.print_btn)
            self.results_layout.addStretch()
        except Exception as e:
            QMessageBox.critical(self, "Fortran Error", str(e))
            return



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
