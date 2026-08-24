"""Seed the source/object hash manifest after a known-good full compile."""
import hashlib
import json
import os
import csv

ROOT = r"E:\Games\Emuladores\Sony\mc3recomp"
MANIFEST = os.path.join(ROOT, r"work\exports\compile_manifest.json")
KEY = "g++-cxx20-msse4.1-wall-generated-ghidra-kernel-v1"

def digest(path):
    h = hashlib.sha256()
    with open(path, "rb") as fh:
        for chunk in iter(lambda: fh.read(1024 * 1024), b""):
            h.update(chunk)
    return h.hexdigest()

rows = list(csv.DictReader(open(os.path.join(ROOT, r"work\exports\stale_objects.csv"), encoding="utf-8")))
missing = [r["base"] for r in rows if r["status"] == "MISSING"]
stale = [r["base"] for r in rows if r["status"] == "STALE"]
if missing or stale:
    raise SystemExit(f"refusing to seed: missing={len(missing)} stale={len(stale)}")

sources = {}
for row in rows:
    if row["status"] != "OK" or not os.path.exists(row["obj"]):
        continue
    sources[row["base"].lower()] = {"sha256": digest(row["cpp"]), "obj": row["obj"]}

os.makedirs(os.path.dirname(MANIFEST), exist_ok=True)
with open(MANIFEST, "w", encoding="utf-8") as fh:
    json.dump({"compile_key": KEY, "sources": sources}, fh, indent=2, sort_keys=True)
print(f"Seeded {len(sources)} entries: {MANIFEST}")
