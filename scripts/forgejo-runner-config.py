"""Merge a credential-free runner template without deleting live registration."""
import json
import os
from pathlib import Path
import sys
import yaml

def merge(current, template):
    for key, value in template.items():
        if isinstance(value, dict) and isinstance(current.get(key), dict):
            merge(current[key], value)
        else:
            current[key] = value
    return current

def main():
    template_path, config_path = map(Path, sys.argv[1:])
    template = yaml.safe_load(template_path.read_text()) or {}
    current = yaml.safe_load(config_path.read_text()) if config_path.exists() else {}
    updated = merge(current or {}, template)
    # JSON is valid YAML and avoids serializing credentials into command output.
    old_umask = os.umask(0o077)
    try:
        stage = config_path.with_suffix('.new')
        stage.write_text(json.dumps(updated, indent=2) + '\n')
        os.chmod(stage, 0o600)
        stage.replace(config_path)
    finally:
        os.umask(old_umask)

if __name__ == '__main__':
    main()
