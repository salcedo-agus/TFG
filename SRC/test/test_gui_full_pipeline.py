"""Offscreen GUI tests for SRC/gui/gui.py full-pipeline wiring (Phase 02).

Maps the 02-02 VERIFICATION must-haves to executable widget assertions using
QT_QPA_PLATFORM=offscreen (the same technique the phase's throwaway harnesses
used). There is no browser in this PyQt6 stack, so these are the E2E tier.

QMessageBox.warning/.critical are patched once per test class to record calls
instead of showing modal dialogs; QFileDialog.getSaveFileName is patched only
in the export test.

Run from the repo root:
    python -m unittest discover -s SRC/test -p "test_gui_full_pipeline.py" -v
"""

import os
import sys
import tempfile
import unittest
from unittest import mock

os.environ["QT_QPA_PLATFORM"] = "offscreen"

_TEST_DIR = os.path.dirname(os.path.abspath(__file__))
_SRC_DIR  = os.path.abspath(os.path.join(_TEST_DIR, ".."))
_GUI_DIR  = os.path.join(_SRC_DIR, "gui")
_INTERFACE = os.path.join(_SRC_DIR, "interface")
for _p in (_GUI_DIR, _INTERFACE):
    if _p not in sys.path:
        sys.path.insert(0, _p)

from PyQt6.QtWidgets import QApplication

import gui

# Valid data combo across every stage table: LH2/LOX (index 0) +
# "Gas Generator" (cycle index 2) — (1, 2) has real isp/ks rows for stages 1-3.
# The GUI default (1, 0) carries no ISP, so runs would be blocked without this.
VALID_CYCLE_INDEX = 2


def _configure_valid_combos(window):
    for sw in window.stage_widgets:
        sw.prop_combo.setCurrentIndex(0)      # LH2 / LOX
        sw.cycle_combo.setCurrentIndex(VALID_CYCLE_INDEX)


def _count_widgets(window, widget_type):
    layout = window.results_layout
    return sum(
        1
        for i in range(layout.count())
        if layout.itemAt(i).widget() and isinstance(layout.itemAt(i).widget(), widget_type)
    )


class FullPipelineGuiTest(unittest.TestCase):

    @classmethod
    def setUpClass(cls):
        if QApplication.instance() is None:
            cls._app = QApplication([])
        else:
            cls._app = QApplication.instance()
        # Record dialog calls instead of showing modals (would block offscreen).
        cls._patchers = [
            mock.patch.object(gui.QMessageBox, "warning"),
            mock.patch.object(gui.QMessageBox, "critical"),
        ]
        for p in cls._patchers:
            p.start()
            cls.addClassCleanup(p.stop)

    def setUp(self):
        self.win = gui.MainWindow()
        _configure_valid_combos(self.win)

    def tearDown(self):
        self.win.close()
        self.win.deleteLater()
        QApplication.processEvents()

    # ── helpers ──────────────────────────────────────────────────────────────
    def _run(self):
        self.win._run()
        QApplication.processEvents()

    @property
    def cards(self):
        return _count_widgets(self.win, gui.ResultCard)

    def _assert_stale_cleared(self):
        self.assertEqual(self.cards, 0)
        self.assertFalse(self.win.print_btn.isEnabled())
        self.assertIsNone(self.win._last_v_circ)
        self.assertEqual(self.win.auto_dv_label.text(), "— km/s")

    # ── 1. initial state ─────────────────────────────────────────────────────
    def test_initial_state(self):
        self.assertEqual(self.win.auto_dv_label.text(), "— km/s")
        self.assertFalse(self.win.print_btn.isEnabled())
        self.assertEqual(self.cards, 0)
        self.assertIs(self.win.run_btn.property("ready"), True)   # defaults are a valid config

    # ── 2. successful run contracts ──────────────────────────────────────────
    def test_run_populates_cards(self):
        self._run()
        self.assertEqual(self.cards, 3)
        self.assertTrue(self.win.print_btn.isEnabled())
        self.assertEqual(self.win.auto_dv_label.text(), "7.62 km/s")
        self.assertEqual(self.win.tabs.currentIndex(), 0)   # auto-switch to Results

    def test_hint_absent_after_run(self):
        self._run()
        texts = [
            w.text()
            for i in range(self.win.results_layout.count())
            for w in [self.win.results_layout.itemAt(i).widget()]
            if w is not None and isinstance(w, gui.QLabel)
        ]
        self.assertFalse(any("populate with full pipeline" in t for t in texts),
                         "partial-state hint appeared after a full run")

    # ── 3. input invalidation (02-02 must-have 6 + follow-up 1 + WR-01) ──────
    def test_invalidation_orbit(self):
        self._run()
        self.win.orbit_height.setValue(600.0)
        self._assert_stale_cleared()

    def test_invalidation_payload(self):
        self._run()
        self.win.pl_spin.setValue(6000.0)
        self._assert_stale_cleared()

    def test_invalidation_stage_count(self):
        self._run()
        self.win.n_stages_spin.setValue(2)
        self._assert_stale_cleared()

    def test_invalidation_diameter_mode(self):
        """GATE A (follow-up 1): toggling a diameter-mode radio clears results."""
        self._run()
        self.win.mode_const.setChecked(True)
        self._assert_stale_cleared()

    def test_invalidation_diameter_value(self):
        """GATE B (follow-up 1): changing the user-specified diameter clears."""
        self.win.mode_user.setChecked(True)     # make user diameter active
        self._run()
        self.win.diameter_spin.setValue(3.5)
        self._assert_stale_cleared()

    def test_invalidation_isp_ks_sliders(self):
        """WR-01 regression (fd29b9e): each slider change invalidates."""
        self._run()
        sw = self.win.stage_widgets[0]          # stage 1 widget
        isp = sw.isp_slider
        isp.setValue(max(isp.minimum(), isp.value() - 1))
        self._assert_stale_cleared()
        # re-establish stale state, then nudge k_s
        self._run()
        ks = self.win.stage_widgets[0].ks_slider
        ks.setValue(min(ks.maximum(), ks.value() + 1))
        self._assert_stale_cleared()

    # ── 4. export guard + export chain (D-05) ────────────────────────────────
    def test_print_guard_before_run(self):
        # _print_results warns + returns (gui.py:1065-1069) without ever
        # touching QFileDialog when no prior run produced results.
        calls = []

        def fake_save(*args, **kwargs):
            calls.append(args)
            return ("", "")

        with mock.patch.object(gui.QFileDialog, "getSaveFileName", side_effect=fake_save):
            self.win._print_results()
        gui.QMessageBox.warning.assert_called()
        self.assertEqual(calls, [], "QFileDialog must not open with no results")

    def test_export_deltav_label_filename(self):
        self._run()
        n = self.win.n_stages_spin.value()
        pl = int(self.win.pl_spin.value())
        label = self.win.auto_dv_label.text()             # "7.62 km/s"
        expected_dv = float(label.split()[0])

        fake_dialog = mock.MagicMock()
        def fake_save(parent, title, default_name, filt):
            fake_dialog.suggested = default_name
            return os.path.join(self._tmpdir, default_name), filt
        self._tmpdir = tempfile.mkdtemp(prefix="phase02_export_")
        with mock.patch.object(gui.QFileDialog, "getSaveFileName", fake_save):
            self.win._print_results()

        path = os.path.join(self._tmpdir, fake_dialog.suggested)
        self.assertTrue(os.path.isfile(path))
        with open(path, "r", encoding="utf-8") as f:
            content = f.read()
        dv_line = next(line for line in content.splitlines() if line.strip().startswith("Delta-V:"))
        self.assertAlmostEqual(float(dv_line.split()[-2]), expected_dv, delta=1e-9)
        # filename contract: staging_{n}stage_dv{dv:.1f}_pl{pl}kg.txt
        self.assertEqual(
            os.path.basename(path),
            f"staging_{n}stage_dv{expected_dv:.1f}_pl{pl}kg.txt",
        )

    # ── 5. Run button per-tab visibility (follow-up 2 / GATE C) ──────────────
    def test_run_button_visibility(self):
        self.win.show()
        QApplication.processEvents()
        self.win.tabs.setCurrentIndex(0)                 # Results
        QApplication.processEvents()
        self.assertFalse(self.win.run_btn.isVisible())
        self.win.tabs.setCurrentIndex(1)                 # Setup
        QApplication.processEvents()
        self.assertTrue(self.win.run_btn.isVisible())
        self.win.tabs.setCurrentIndex(2)                 # Vehicle Configuration
        QApplication.processEvents()
        self.assertTrue(self.win.run_btn.isVisible())

    # ── 6. stage-count rebuild drives the run surface ────────────────────────
    def test_stage_count_run(self):
        self.win.n_stages_spin.setValue(1)
        QApplication.processEvents()
        self.assertEqual(len(self.win.stage_widgets), 1)
        _configure_valid_combos(self.win)                # re-valid for n=1
        self._run()
        self.assertEqual(self.cards, 1)


if __name__ == "__main__":
    unittest.main()