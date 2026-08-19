import os, csv

ROOT = r"E:\Games\Emuladores\Sony\mc3recomp"
GEN = os.path.join(ROOT, "work", "generated", "ghidra")
COMPILE = os.path.join(ROOT, "work", "compile", "ghidra")

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
    status = "STALE" if o_mtime < cpp_mtime else "OK"
    if status == "STALE":
        stale.append((base, cpp, o, batch))
    rows.append((base, cpp, o, status, cpp_mtime, o_mtime, o_size))

print("Missing:", len(missing))
for m in missing:
    print("  MISSING:", m)
print("Stale (mtime):", len(stale))

out_csv = os.path.join(ROOT, "work", "exports", "stale_objects.csv")
os.makedirs(os.path.dirname(out_csv), exist_ok=True)
with open(out_csv, "w", newline="", encoding="utf-8") as fh:
    w = csv.writer(fh)
    w.writerow(["base", "cpp", "obj", "status", "cpp_mtime", "obj_mtime", "obj_size"])
    for r in rows:
        w.writerow(r)

print("Wrote", out_csv)

# dump stale list for recompilation
stale_csv = os.path.join(ROOT, "work", "exports", "stale_only.csv")
with open(stale_csv, "w", newline="", encoding="utf-8") as fh:
    w = csv.writer(fh)
    w.writerow(["base", "cpp", "obj", "batch"])
    for r in stale:
        w.writerow(r)
print("Wrote", stale_csv)
