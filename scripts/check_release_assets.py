#!/usr/bin/env python3
"""Verify each github_release_binaries asset_pattern still matches the
latest GitHub release for its repo. Run manually or via CI to catch
upstream asset-naming changes before an ansible run fails on them.
"""
import json
import os
import re
import sys
import urllib.error
import urllib.request
from pathlib import Path

import yaml

PACKAGES_FILE = Path(__file__).resolve().parent.parent / "ansible/group_vars/all/packages.yml"


def fetch_latest_assets(repo: str) -> list[str]:
    url = f"https://api.github.com/repos/{repo}/releases/latest"
    headers = {"User-Agent": "check-release-assets"}
    token = os.environ.get("GITHUB_TOKEN")
    if token:
        headers["Authorization"] = f"Bearer {token}"
    req = urllib.request.Request(url, headers=headers)
    with urllib.request.urlopen(req, timeout=15) as resp:
        data = json.load(resp)
    return [a["name"] for a in data.get("assets", [])]


def main() -> int:
    entries = yaml.safe_load(PACKAGES_FILE.read_text())["github_release_binaries"]
    failures = []

    for entry in entries:
        repo = entry["repo"]
        pattern = entry["asset_pattern"]
        try:
            assets = fetch_latest_assets(repo)
        except urllib.error.HTTPError as e:
            failures.append(f"{repo}: HTTP {e.code} fetching latest release")
            continue
        except urllib.error.URLError as e:
            failures.append(f"{repo}: network error ({e.reason})")
            continue

        if not any(re.search(pattern, a) for a in assets):
            failures.append(
                f"{repo}: pattern {pattern!r} matches nothing in {assets}"
            )
        else:
            print(f"OK  {repo}")

    if failures:
        print("\nMISMATCHES:")
        for f in failures:
            print(f"  - {f}")
        return 1

    print("\nAll asset patterns match their latest release.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
