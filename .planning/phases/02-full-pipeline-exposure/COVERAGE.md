# Phase 2: API Coverage Declaration

**Declared:** 2026-09-06 (planning time) — `workflow.api_coverage_gate`

**No external API integration.** The only bridge in this phase is the project's own
locally-built `build/librocket.dll` invoked via the Python standard-library `ctypes`
module. PyQt6 is the GUI toolkit (already installed in Phase 1), not a third-party
API/SDK being integrated. No network calls, no external services, no new third-party
Python packages.

Coverage matrix: not applicable — deterministic detector returned `{"detected": false}`.