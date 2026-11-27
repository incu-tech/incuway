#!/usr/bin/env python3
"""Check that every entry point in a specs-from-code inventory.json is accounted for once.

Usage: python3 check_coverage.py docs/specs/{slug}/inventory.json

An entry point is accounted for when it has exactly one of:
  - capability: "CAP-xx"                          (assigned)
  - capability: null + exclusion: {reason, ...}   (excluded)

Exits 0 when every entry point is accounted for, 1 otherwise, 2 on unreadable input.
Standard library only, so it runs anywhere Python 3 does.
"""
import json
import sys
from collections import Counter, defaultdict


def main(argv):
    if len(argv) != 2:
        print(__doc__.strip().splitlines()[2], file=sys.stderr)
        return 2
    try:
        with open(argv[1], encoding="utf-8") as fh:
            inv = json.load(fh)
    except (OSError, json.JSONDecodeError) as err:
        print(f"cannot read {argv[1]}: {err}", file=sys.stderr)
        return 2

    eps = inv.get("entryPoints", [])
    problems = []

    dupes = [i for i, n in Counter(e.get("id") for e in eps).items() if n > 1]
    for i in dupes:
        problems.append(f"{i}: duplicated id")

    by_cap = defaultdict(list)
    excluded = []
    for e in eps:
        eid = e.get("id", "?")
        cap = e.get("capability")
        exc = e.get("exclusion")
        if cap and exc:
            problems.append(f"{eid}: both assigned to {cap} and excluded")
        elif cap:
            by_cap[cap].append(eid)
        elif exc:
            if not exc.get("reason"):
                problems.append(f"{eid}: excluded without a reason")
            excluded.append(eid)
        else:
            problems.append(f"{eid}: unaccounted (no capability, no exclusion)")

    for cap in sorted(by_cap):
        print(f"{cap}: {', '.join(by_cap[cap])}")
    if excluded:
        print(f"excluded: {', '.join(excluded)}")
    for p in problems:
        print(f"PROBLEM {p}")

    assigned = sum(len(v) for v in by_cap.values())
    unaccounted = len(eps) - assigned - len(excluded)
    print(
        f"coverage: {len(eps)} entry points · {assigned} assigned to {len(by_cap)} capabilities · "
        f"{len(excluded)} excluded · {unaccounted} unaccounted"
    )
    return 1 if problems else 0


if __name__ == "__main__":
    sys.exit(main(sys.argv))
