#!/usr/bin/env python3
import argparse, bisect, csv, re
from collections import Counter
from pathlib import Path
FRAME=re.compile(r"\[boot-trace:frame\] tick=(\d+).*?pc=0x([0-9a-fA-F]+).*?gifPk1=(\d+).*?gifPk2=(\d+).*?gifPk3=(\d+).*?gsPrims=(\d+).*?gsPixels=(\d+)")
DISP=re.compile(r"\[boot-trace:dispatch-window\] total=(\d+).*?uniqueSample=(\d+).*?pc=0x([0-9a-fA-F]+).*?pcs=([^\r\n]*)")
READ=re.compile(r"kind=(read(?:-bytes)?)\b.*?\blsn=0x([0-9a-fA-F]+)(?:.*?\bsectors=0x([0-9a-fA-F]+))?")
def syms(p):
    r=[]
    with open(p,encoding="utf-8-sig",errors="replace",newline="") as f:
        for row in csv.reader(f):
            for c in row[:4]:
                m=re.fullmatch(r"\s*(?:0x)?([0-9a-fA-F]{6,8})\s*",c)
                if m:
                    r.append((int(m.group(1),16),next((x.strip() for x in row if x.strip() and not re.fullmatch(r"\s*(?:0x)?[0-9a-fA-F]{6,8}\s*",x)), "sub_"+m.group(1))))
                    break
    r=sorted(set(r)); return r,[x[0] for x in r]
def near(r,k,pc):
    i=bisect.bisect_right(k,pc)-1
    return r[i][1] if i>=0 else "<before-symbols>"
def main():
    ap=argparse.ArgumentParser(); ap.add_argument("--log",required=True); ap.add_argument("--symbols",required=True); ap.add_argument("--out",required=True); a=ap.parse_args()
    r,k=syms(a.symbols); frames=[]; funcs=Counter(); disp=[]; reads=[]; msgs=[]; last=0; maxm=[0]*5; budget=timeout=returned=False
    with open(a.log,encoding="utf-8",errors="replace") as f:
        for n,line in enumerate(f,1):
            m=FRAME.search(line)
            if m:
                last=int(m.group(1)); pc=int(m.group(2),16); v=tuple(map(int,m.groups()[2:])); name=near(r,k,pc); frames.append((last,pc,name,*v,n)); funcs[name]+=1
                maxm=[max(x,y) for x,y in zip(maxm,v)]
            if "[tty]" in line or "[printf]" in line: msgs.append((last,line.rstrip()))
            m=DISP.search(line)
            if m: disp.append((int(m.group(1)),int(m.group(2)),int(m.group(3),16),m.group(4).strip(),n))
            m=READ.search(line)
            if m: reads.append((last,m.group(1),int(m.group(2),16),m.group(3) or "?",n))
            budget |= "dispatch-budget-reached" in line; timeout |= "timeout reached" in line; returned |= "loop-exit" in line or "game-thread-return" in line
    pcs={x[1] for x in frames}; recent=disp[-3:]; plateau=len(recent)>=2 and all(x[1]==1 for x in recent) and len({x[2] for x in recent})==1
    if budget: end="dispatch budget reached"
    elif timeout: end="runner timeout reached"
    elif returned: end="guest loop/thread returned"
    else: end="no recognized termination marker"
    if maxm[3]>0 and maxm[4]>0: verdict="render gate reached"
    elif plateau: verdict="loop/plateau from recent dispatch windows"
    elif len(pcs)>1: verdict="progress: sampled PC moved"
    else: verdict="no render and insufficient PC variation"
    out=Path(a.out); out.parent.mkdir(parents=True,exist_ok=True)
    with open(out,"w",encoding="utf-8") as w:
        w.write("# Long run timeline - generated\n\n")
        w.write(f"- frames: {len(frames)}; dispatch windows: {len(disp)}; last tick: {last}\n- derived conclusion: {verdict}\n- derived end reason: {end}\n- maximum metrics gifPk1/gifPk2/gifPk3/gsPrims/gsPixels: {maxm}\n\n")
        w.write("## PC timeline\n\n|tick|seconds|PC|nearest function|gifPk1|gifPk2|gifPk3|gsPrims|gsPixels|\n|---:|---:|---|---|---:|---:|---:|---:|---:|\n")
        for x in frames[::10]+([] if not frames or frames[-1] in frames[::10] else [frames[-1]]): w.write("|%d|%.1f|0x%08x|%s|%d|%d|%d|%d|%d|\n"%(x[0],x[0]/60,x[1],x[2],*x[3:8]))
        w.write("\n## Top 20 sampled functions\n\n")
        for n,c in funcs.most_common(20): w.write(f"- {n}: {c}\n")
        w.write("\n## Dispatch windows\n\n")
        for x in disp: w.write(f"- total={x[0]} unique={x[1]} pc=0x{x[2]:08x} pcs={x[3]}\n")
        w.write("\n## TTY/printf\n\n")
        for t,line in msgs: w.write(f"tick={t} {line}\n")
        w.write("\n## CD LBAs\n\n")
        for x in reads: w.write(f"tick={x[0]} kind={x[1]} lba=0x{x[2]:x} sectors={x[3]} line={x[4]}\n")
if __name__=="__main__": main()
