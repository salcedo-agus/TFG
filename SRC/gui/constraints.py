"""
constraints.py
───────────────────────────────────────────────────────
Fairing constraint validation for GUI (Phase 4, Plan 04-02).

Enforces the D-04 constraint matrix:
- Body Statistical (1) → Fairing Constant (1), Tapered (2, max=last_body_d)
- Body Constant (2) → Fairing Constant (1), Hammer-Head (3, min=body_d)
- Body User-specified (3) → Fairing Constant (1) only

Dynamic spinbox range updates and fairing mode radio rebuilding.
"""

from PyQt6.QtWidgets import QButtonGroup, QDoubleSpinBox, QRadioButton


class FairingConstraintValidator:
    """
    Centralizes fairing-body constraint logic and widget management.
    """

    # D-04 Constraint Matrix: body_mode_id → {fairing_mode_id: (label, min_expr, max_expr)}
    # min_expr/max_expr can be: "body_d", "last_body_d", float, or None
    CONSTRAINTS = {
        1: {  # Statistical body
            1: ("Constant (same as body)", None, None),      # Fairing = body, no spinbox
            2: ("Tapered (smaller than body)", 0.5, "last_body_d"),  # User ≤ last stage body D
        },
        2: {  # Constant body
            1: ("Constant (same as body)", None, None),      # Fairing = body, no spinbox
            3: ("Hammer-Head (larger than body)", "body_d", 20.0),   # User ≥ body D
        },
        3: {  # User-specified body
            1: ("Constant (same as body)", None, None),      # Fairing = body only
        },
    }

    def __init__(
        self,
        body_mode_group: QButtonGroup,
        fairing_mode_group: QButtonGroup,
        fairing_mode_groupbox,  # QGroupBox containing the fairing mode radios
        fairing_spin: QDoubleSpinBox,
        get_body_diameters_fn,
        get_last_body_d_fn,
        get_body_d_fn,
    ):
        self.body_mode_group = body_mode_group
        self.fairing_mode_group = fairing_mode_group
        self.fairing_mode_groupbox = fairing_mode_groupbox
        self.fairing_spin = fairing_spin
        self.get_body_diameters = get_body_diameters_fn
        self.get_last_body_d = get_last_body_d_fn
        self.get_body_d = get_body_d_fn

        # Connect signals
        body_mode_group.buttonToggled.connect(self._on_body_mode_changed)
        fairing_mode_group.buttonToggled.connect(self._on_fairing_mode_changed)

    def _on_body_mode_changed(self, btn, checked):
        """Called when body mode radio is toggled."""
        if not checked:
            return
        body_mode = self.body_mode_group.id(btn)
        self._rebuild_fairing_modes(body_mode)
        self._update_fairing_spinbox_range()

    def _on_fairing_mode_changed(self, btn, checked):
        """Called when fairing mode radio is toggled."""
        if not checked:
            return
        self._update_fairing_spinbox_range()

    def _rebuild_fairing_modes(self, body_mode: int):
        """
        Clear and repopulate fairing mode radios based on constraint matrix.
        Preserves button group IDs (1, 2, 3) for each mode.
        """
        allowed = self.CONSTRAINTS.get(body_mode, {})

        # Clear existing buttons from group
        for button in list(self.fairing_mode_group.buttons()):
            self.fairing_mode_group.removeButton(button)

        # Get the layout of the fairing mode group box (QGroupBox)
        layout = self.fairing_mode_groupbox.layout()
        if not layout:
            return

        # Remove all existing widgets from the layout (radios and helpers)
        while layout.count():
            item = layout.takeAt(0)
            if item.widget():
                item.widget().deleteLater()

        # Recreate and add allowed modes
        # Order: 1 (Constant) always first, then 2, then 3
        for mode_id in sorted(allowed.keys()):
            label, _, _ = allowed[mode_id]
            radio = QRadioButton(label)
            self.fairing_mode_group.addButton(radio, mode_id)
            layout.addWidget(radio)

            # Also add helper text
            constraint = allowed[mode_id]
            helper_text = self._get_helper_text(mode_id, constraint)
            if helper_text:
                helper_lbl = self._create_helper_label(helper_text)
                layout.addWidget(helper_lbl)

        # Add stretch at the end
        layout.addStretch()

        # Select the first allowed mode (Constant = 1 is always allowed)
        first_button = self.fairing_mode_group.button(min(allowed.keys()))
        if first_button:
            first_button.setChecked(True)

    def _get_helper_text(self, mode_id: int, constraint: tuple) -> str:
        """Generate helper text for a fairing mode."""
        label, _, _ = constraint
        if mode_id == 1:
            return "Constant: fairing diameter equals body diameter"
        elif mode_id == 2:
            return "Tapered: fairing diameter ≤ last stage body diameter (user-specified)"
        elif mode_id == 3:
            return "Hammer-Head: fairing diameter ≥ body diameter (user-specified)"
        return ""

    def _create_helper_label(self, text: str):
        """Create a styled helper label (11px TEXT_SEC)."""
        from PyQt6.QtWidgets import QLabel
        from PyQt6.QtCore import Qt

        lbl = QLabel(text)
        lbl.setStyleSheet("color: #8b949e; font-size: 11px;")
        lbl.setIndent(26)
        return lbl

    def _update_fairing_spinbox_range(self):
        """
        Update spinbox range based on current body mode and fairing mode.
        Resolves min/max expressions using getter functions.
        """
        body_mode = self.body_mode_group.checkedId()
        fairing_mode = self.fairing_mode_group.checkedId()

        if body_mode == -1 or fairing_mode == -1:
            self.fairing_spin.setVisible(False)
            return

        constraint = self.CONSTRAINTS.get(body_mode, {}).get(fairing_mode)
        if not constraint:
            self.fairing_spin.setVisible(False)
            return

        _, min_expr, max_expr = constraint

        # If both None → Constant mode, hide spinbox
        if min_expr is None and max_expr is None:
            self.fairing_spin.setVisible(False)
            self.fairing_spin.setToolTip("")
            return

        # Resolve expressions to actual values
        body_diameters = self.get_body_diameters()
        last_body_d = self.get_last_body_d()
        body_d = self.get_body_d()

        def resolve(expr):
            if expr == "body_d":
                return body_d
            elif expr == "last_body_d":
                return last_body_d
            elif isinstance(expr, (int, float)):
                return float(expr)
            return None

        min_val = resolve(min_expr)
        max_val = resolve(max_expr)

        # Apply range
        if min_val is not None and max_val is not None:
            # Ensure min <= max
            if min_val > max_val:
                min_val, max_val = max_val, min_val
            self.fairing_spin.setRange(min_val, max_val)
            self.fairing_spin.setVisible(True)

            # Set tooltip at boundaries
            if fairing_mode == 2:  # Tapered
                self.fairing_spin.setToolTip(
                    "Fairing diameter must be ≤ last stage body diameter (Tapered)"
                )
            elif fairing_mode == 3:  # Hammer-Head
                self.fairing_spin.setToolTip(
                    "Fairing diameter must be ≥ body diameter (Hammer-Head)"
                )
        else:
            self.fairing_spin.setVisible(False)
            self.fairing_spin.setToolTip("")