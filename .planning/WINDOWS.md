---
schema_version: 1
open_count: 2
waived_count: 0
fixed_count: 0
total_count: 2
last_updated: 2026-08-14T19:45:24.679Z
---

# Broken Windows Ledger

> Cross-phase defect register. With `workflow.windows_enforce` enabled, `/gsd-ship` blocks while `open_count > 0`.
> Waive with `gsd-tools windows waive <id> "<reason>"` (reason required).
> Mark fixed with `gsd-tools windows fixed <id>`.

| id | phase | kind | file | line | description | status | reason | recorded_at | resolved_at |
|----|-------|------|------|------|-------------|--------|--------|-------------|-------------|
| 1 | 01-centralized-3-tab-gui | unrun-verify | SRC/test_call.py |  | Phase gate python SRC/test_call.py unrun: build/librocket.dll missing on this machine (STATE.md blocker); bridge code zero-diff per guard | open |  | 2026-08-14T19:45:23.049Z |  |
| 2 | 01-centralized-3-tab-gui | unrun-verify | SRC/gui/gui.py |  | make gui GUI smoke unrun: requires DLL build + interactive display; human-check items pending user verification (SUMMARY coverage D7) | open |  | 2026-08-14T19:45:24.679Z |  |

````json
[
  {
    "id": 1,
    "kind": "unrun-verify",
    "phase": "01-centralized-3-tab-gui",
    "file": "SRC/test_call.py",
    "line": null,
    "description": "Phase gate python SRC/test_call.py unrun: build/librocket.dll missing on this machine (STATE.md blocker); bridge code zero-diff per guard",
    "status": "open",
    "reason": "",
    "recorded_at": "2026-08-14T19:45:23.049Z",
    "resolved_at": null
  },
  {
    "id": 2,
    "kind": "unrun-verify",
    "phase": "01-centralized-3-tab-gui",
    "file": "SRC/gui/gui.py",
    "line": null,
    "description": "make gui GUI smoke unrun: requires DLL build + interactive display; human-check items pending user verification (SUMMARY coverage D7)",
    "status": "open",
    "reason": "",
    "recorded_at": "2026-08-14T19:45:24.679Z",
    "resolved_at": null
  }
]
````
