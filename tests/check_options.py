"""Check each add-on's options and schema with the Supervisor's own validator.

    python tests/check_options.py SUPERVISOR_CHECKOUT

The defaults in config.yaml must pass, and so must the example options in
tests/options/<add-on>.json, which set every optional option.
"""
import json
import sys
from pathlib import Path
from unittest.mock import MagicMock

import yaml

sys.path.insert(0, sys.argv[1])
from supervisor.apps.options import AppOptions, UiOptions  # noqa: E402

root = Path(__file__).resolve().parent.parent
failed = False
for config in sorted(root.glob("*/config.yaml")):
    cfg = yaml.safe_load(config.read_text())
    check = AppOptions(MagicMock(), cfg["schema"], cfg["name"], cfg["slug"])
    tries = {"defaults": cfg["options"]}
    example = root / "tests" / "options" / f"{config.parent.name}.json"
    if example.exists():
        tries["every option"] = {**cfg["options"], **json.loads(example.read_text())}
    for what, options in tries.items():
        try:
            check(options)
            print(f"ok - {config.parent.name}: {what}")
        except Exception as exc:  # the Supervisor raises voluptuous errors
            print(f"not ok - {config.parent.name}: {what}: {exc}")
            failed = True
    missing = set(cfg["schema"]) - set(tries.get("every option", cfg["options"]))
    if example.exists() and missing:
        print(f"not ok - {config.parent.name}: the example leaves out {sorted(missing)}")
        failed = True
    UiOptions(MagicMock())(cfg["schema"])           # the Configuration tab renders
sys.exit(1 if failed else 0)
