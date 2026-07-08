#!/usr/bin/env bash
# check-bank.sh <features-dir> — validate a feature bank. Exit 0 = valid.
set -euo pipefail
DIR="${1:?usage: check-bank.sh <features-dir>}"
python3 - "$DIR" <<'PY'
import sys, os, re, glob
d = sys.argv[1]
problems = []
STATUSES = {"proposed","in-progress","implemented","deprecated"}
index = os.path.join(d, "INDEX.md")
if not os.path.isfile(index):
    problems.append(f"missing {index}")
    print("\n".join(problems)); sys.exit(1)
index_text = open(index, encoding="utf-8").read()

def frontmatter(path):
    t = open(path, encoding="utf-8").read()
    m = re.match(r"^---\n(.*?)\n---", t, re.S)
    return m.group(1) if m else ""

for f in sorted(glob.glob(os.path.join(d, "*.md"))):
    base = os.path.basename(f)
    if base == "INDEX.md" or base.endswith(".CHANGELOG.md"):
        continue
    fid = base[:-3]
    fm = frontmatter(f)
    if not fm:
        problems.append(f"{base}: no frontmatter"); continue
    for field in ("id","title","status"):
        if not re.search(rf"^{field}:\s*\S", fm, re.M):
            problems.append(f"{base}: missing '{field}'")
    st = re.search(r"^status:\s*([\w-]+)", fm, re.M)
    if st and st.group(1) not in STATUSES:
        problems.append(f"{base}: bad status '{st.group(1)}'")
    for listf in ("acceptance_criteria","non_goals"):
        # non-empty = at least one '  - ' item under the key
        blk = re.search(rf"^{listf}:\s*\n((?:\s+-\s.*\n?)+)", fm, re.M)
        if not blk:
            problems.append(f"{base}: '{listf}' empty or missing")
    if not os.path.isfile(os.path.join(d, fid + ".CHANGELOG.md")):
        problems.append(f"{base}: missing {fid}.CHANGELOG.md")
    if f"`{fid}`" not in index_text:
        problems.append(f"{base}: id not listed in INDEX.md")

if problems:
    print("FEATURE BANK INVALID:")
    print("\n".join(" - " + p for p in problems))
    sys.exit(1)
print("feature bank OK")
PY
