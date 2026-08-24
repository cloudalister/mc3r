import os, csv, subprocess, sys, time, hashlib, json
from concurrent.futures import ThreadPoolExecutor, as_completed

ROOT = r"E:\Games\Emuladores\Sony\mc3recomp"
os.environ["PATH"] = r"C:\msys64\ucrt64\bin;" + os.environ["PATH"]
GXX = r"C:\msys64\ucrt64\bin\g++.exe"

ARGS = ["-std=c++20", "-msse4.1", "-Wall", "-Wno-unused-variable", "-Wno-unused-label", "-Wno-comment",
        "-I", os.path.join(ROOT, r"work\generated\ghidra"),
        "-I", os.path.join(ROOT, r"PS2Recomp\ps2xRuntime\include"),
        "-I", os.path.join(ROOT, r"PS2Recomp\ps2xRuntime\src\lib\Kernel")]
MANIFEST = os.path.join(ROOT, r"work\exports\compile_manifest.json")
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

all_rows = list(csv.DictReader(open(os.path.join(ROOT, r"work\exports\stale_only.csv"), encoding="utf-8")))
rows = []
skipped = 0
for row in all_rows:
    cached = manifest.get("sources", {}).get(row["base"].lower(), {})
    if (manifest.get("compile_key") == COMPILE_KEY and
            cached.get("sha256") == sha256(row["cpp"]) and
            os.path.exists(row["obj"]) and os.path.getsize(row["obj"]) >= 200):
        skipped += 1
    else:
        rows.append(row)
print("candidates:", len(all_rows), "to compile:", len(rows), "hash-skipped:", skipped, flush=True)

fail_log = os.path.join(ROOT, r"work\exports\parallel_compile_failures.log")
failures = []
done = [0]
t0 = time.time()

def compile_one(r):
    tmp = r["obj"] + ".tmp"
    p = subprocess.run([GXX] + ARGS + ["-c", r["cpp"], "-o", tmp], capture_output=True, text=True)
    if p.returncode != 0 or not os.path.exists(tmp) or os.path.getsize(tmp) < 200:
        try: os.remove(tmp)
        except OSError: pass
        return (r, p.returncode, p.stderr[-800:])
    os.replace(tmp, r["obj"])
    return None

with ThreadPoolExecutor(max_workers=20) as ex:
    futs = [ex.submit(compile_one, r) for r in rows]
    for f in as_completed(futs):
        res = f.result()
        done[0] += 1
        if res:
            failures.append(res)
        if done[0] % 500 == 0:
            print("progress %d/%d fail=%d elapsed=%.0fs" % (done[0], len(rows), len(failures), time.time()-t0), flush=True)

print("DONE total=%d failures=%d elapsed=%.0fs" % (len(rows), len(failures), time.time()-t0), flush=True)
with open(fail_log, "w", encoding="utf-8") as fh:
    for r, rc, err in failures:
        fh.write("=== %s rc=%s\n%s\n" % (r["base"], rc, err))
        print("FAIL", r["base"], "rc=", rc, flush=True)

if not failures and all_rows:
    sources = {}
    for row in all_rows:
        if os.path.exists(row["obj"]) and os.path.getsize(row["obj"]) >= 200:
            sources[row["base"].lower()] = {"sha256": sha256(row["cpp"]), "obj": row["obj"]}
    os.makedirs(os.path.dirname(MANIFEST), exist_ok=True)
    with open(MANIFEST, "w", encoding="utf-8") as fh:
        json.dump({"compile_key": COMPILE_KEY, "sources": sources}, fh, indent=2, sort_keys=True)
    print("Wrote hash manifest:", MANIFEST, "entries=", len(sources), flush=True)
elif not failures:
    print("No candidates; preserved existing hash manifest.", flush=True)
