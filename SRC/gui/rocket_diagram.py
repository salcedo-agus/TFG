"""
rocket_diagram.py
───────────────────────────────────────────────────────
Rocket dimension diagram using QGraphicsView/QGraphicsScene.
True-scale rendering (1m = 1px), zoom/pan, PNG export.
"""

from PyQt6.QtWidgets import (
    QGraphicsView, QGraphicsScene, QGraphicsRectItem, QGraphicsPolygonItem,
    QGraphicsLineItem, QGraphicsTextItem
)
from PyQt6.QtCore import Qt, QRectF, QPointF
from PyQt6.QtGui import QTransform
from PyQt6.QtGui import QPainter, QPixmap, QPen, QColor, QPolygonF, QFont

from .fairing_geometry import compute_fairing_geometry_per_stage


# Color constants (mirror gui.py palette)
ACCENT = "#58a6ff"
ACCENT2 = "#f78166"
BG_CARD = "#1c2128"
TEXT_PRI = "#e6edf3"
TEXT_SEC = "#8b949e"
BORDER = "#30363d"


class RocketDiagramScene(QGraphicsScene):
    """Scene containing the rocket diagram items."""

    def __init__(self, parent=None):
        super().__init__(parent)


class RocketDiagramView(QGraphicsView):
    """
    Rocket diagram view with true-scale rendering, zoom, pan, and PNG export.
    """

    def __init__(self, parent=None):
        super().__init__(parent)
        self.scene = RocketDiagramScene(self)
        self.setScene(self.scene)

        # Rendering hints for quality
        self.setRenderHints(
            QPainter.RenderHint.Antialiasing |
            QPainter.RenderHint.SmoothPixmapTransform
        )

        # Interaction: pan with mouse drag (disabled until Phase 5 per PLAN)
        # self.setDragMode(QGraphicsView.DragMode.ScrollHandDrag)
        self.setDragMode(QGraphicsView.DragMode.NoDrag)

        # Zoom anchor under mouse
        self.setTransformationAnchor(QGraphicsView.ViewportAnchor.AnchorUnderMouse)
        self.setResizeAnchor(QGraphicsView.ViewportAnchor.AnchorViewCenter)

        # True-scale: 1 meter = 1 pixel, Y-up (flip Qt's Y-down)
        self.setTransform(QTransform.fromScale(1, -1))

    def wheelEvent(self, event):
        """Zoom with Ctrl+wheel (disabled until Phase 5 per PLAN)."""
        if event.modifiers() & Qt.KeyboardModifier.ControlModifier:
            factor = 1.15 if event.angleDelta().y() > 0 else 1 / 1.15
            self.scale(factor, factor)
        else:
            super().wheelEvent(event)

    def build_rocket_scene(self, stage_data: list[dict], fairing_data: list[dict]):
        """
        Build the rocket diagram from stage data and fairing data.

        Args:
            stage_data: List of dicts with 'diameter', 'length' keys (from Fortran results)
            fairing_data: List of dicts from fairing_geometry.compute_fairing_geometry_per_stage
        """
        self.scene.clear()

        if not stage_data:
            return

        # Calculate scene dimensions (true-scale meters)
        y_offset = 0.0
        max_stage_d = max(s["diameter"] for s in stage_data) if stage_data else 2.0
        fairing_d = fairing_data[0]["diameter"] if fairing_data else 0.0
        max_d = max(max_stage_d, fairing_d)
        scene_width = max_d * 1.5
        scene_height = sum(s["length"] for s in stage_data) + (fairing_data[0]["length"] if fairing_data else 0)

        # Stage bodies (rectangles centered at x=0, stacked vertically)
        for stage in stage_data:
            d = stage["diameter"]
            L = stage["length"]
            rect = QRectF(-d / 2, y_offset, d, L)
            item = QGraphicsRectItem(rect)
            # Thin cosmetic pen (2cm in true-scale)
            item.setPen(QPen(QColor(ACCENT), 0.02))
            item.setBrush(QColor(BG_CARD))
            self.scene.addItem(item)
            y_offset += L

        # Fairing (polygon from ogive coords)
        if fairing_data:
            f = fairing_data[0]
            # Right half of ogive profile
            right_coords = [QPointF(x, y_offset + y) for x, y in f["coords"]]
            # Left half (mirrored)
            left_coords = [QPointF(-x, y_offset + y) for x, y in f["coords"]]
            # Closed polygon: right half up, then left half down
            fairing_poly = QPolygonF(right_coords + left_coords[::-1])
            item = QGraphicsPolygonItem(fairing_poly)
            item.setPen(QPen(QColor(ACCENT2), 0.02))
            item.setBrush(QColor(ACCENT2).lighter(150))
            self.scene.addItem(item)

        # Set scene rect and fit to view
        self.scene.setSceneRect(-scene_width / 2, 0, scene_width, scene_height)
        self.fitInView(self.scene.sceneRect(), Qt.AspectRatioMode.KeepAspectRatio)

    def export_png(self, path: str) -> bool:
        """
        Export the current diagram to PNG.

        Args:
            path: Output file path

        Returns:
            True if successful, False otherwise
        """
        try:
            rect = self.scene.sceneRect()
            if rect.isEmpty():
                return False

            # Create pixmap at current zoom level
            pixmap = QPixmap(int(rect.width()), int(rect.height()))
            pixmap.fill(Qt.GlobalColor.transparent)

            painter = QPainter(pixmap)
            painter.setRenderHint(QPainter.RenderHint.Antialiasing)
            self.scene.render(painter)
            painter.end()

            return pixmap.save(path, "PNG")
        except Exception:
            return False


if __name__ == "__main__":
    # Quick self-test
    import sys
    from PyQt6.QtWidgets import QApplication

    app = QApplication(sys.argv)

    # Mock stage data
    stages = [
        {"diameter": 2.0, "length": 20.0},
        {"diameter": 2.0, "length": 15.0},
        {"diameter": 1.5, "length": 10.0},
    ]

    # Mock fairing data (Constant mode)
    fairing = compute_fairing_geometry_per_stage([2.0, 2.0, 1.5], 1)

    view = RocketDiagramView()
    view.build_rocket_scene(stages, fairing)
    view.resize(800, 600)
    view.show()

    sys.exit(app.exec())