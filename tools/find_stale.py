import os, csv, hashlib, json

ROOT = r"E:\Games\Emuladores\Sony\mc3recomp"
GEN = os.path.join(ROOT, "work", "generated", "ghidra")
COMPILE = os.path.join(ROOT, "work", "compile", "ghidra")
MANIFEST = os.path.join(ROOT, "work", "exports", "compile_manifest.json")
COMPILE_KEY = "g++-cxx20-msse4.1-wall-generated-ghidra-kernel-v1"

def sha256(path):
    digest = hashlib.sha256()
    with open(path, "rb") as fh:
        for chunk in iter(lambda: fh.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()

try:
    with open(MANIFEST, encoding="utf-8") as fh:
        manifest = json.load(fh)
except (FileNotFoundError, json.JSONDecodeError):
    manifest = {"compile_key": "", "sources": {}}

cpp_files = {}  # lower(base) -> (base, path)
for f in os.listdir(GEN):
    if f.endswith(".cpp") and f != "register_functions.cpp":
        base = f[:-4]
        cpp_files[base.lower()] = (base, os.path.join(GEN, f))

print("Total cpp (excl register_functions):", len(cpp_files))

obj_files = {}  # lower(base) -> (base, path)
batch_dirs = sorted(d for d in os.listdir(COMPILE) if d.startswith("batch_"))
print("Total batches:", len(batch_dirs))
for b in batch_dirs:
    objdir = os.path.join(COMPILE, b, "obj")
    if not os.path.isdir(objdir):
        continue
    for f in os.listdir(objdir):
        if f.endswith(".o"):
            base = f[:-2]
            obj_files[base.lower()] = (base, os.path.join(objdir, f), b)

print("Total obj:", len(obj_files))

missing = []
stale = []
rows = []
for key, (base, cpp) in cpp_files.items():
    entry = obj_files.get(key)
    cpp_mtime = os.path.getmtime(cpp)
    if entry is None:
        missing.append(base)
        rows.append((base, cpp, "", "MISSING", cpp_mtime, "", ""))
        continue
    obase, o, batch = entry
    o_mtime = os.path.getmtime(o)
    o_size = os.path.getsize(o)
    source_hash = sha256(cpp)
    cached = manifest.get("sources", {}).get(base.lower(), {})
    hash_ok = (manifest.get("compile_key") == COMPILE_KEY and
               cached.get("sha256") == source_hash and o_size >= 200)
    status = "OK" if hash_ok or o_mtime >= cpp_mtime else "STALE"
    if status == "STALE":
        stale.append((base, cpp, o, batch))
    rows.append((base, cpp, o, status, cpp_mtime, o_mtime, o_size))

print("Missing:", len(missing))
for m in missing:
    print("  MISSING:", m)
print("Stale (hash/mtime):", len(stale))

out_csv = os.path.join(ROOT, "work", "exports", "stale_objects.csv")
os.makedirs(os.path.dirname(out_csv), exist_ok=True)
with open(out_csv, "w", newline="", encoding="utf-8") as fh:
    w = csv.writer(fh)
    w.writerow(["base", "cpp", "obj", "status", "cpp_mtime", "obj_mtime", "obj_size", "sha256"])
    for r in rows:
        base, cpp, obj, status, cpp_mtime, obj_mtime, obj_size = r
        w.writerow(r + (sha256(cpp),) if obj else r + ("",))

print("Wrote", out_csv)

# dump stale list for recompilation
stale_csv = os.path.join(ROOT, "work", "exports", "stale_only.csv")
with open(stale_csv, "w", newline="", encoding="utf-8") as fh:
    w = csv.writer(fh)
    w.writerow(["base", "cpp", "obj", "batch"])
    for r in stale:
        w.writerow(r)
print("Wrote", stale_csv)
