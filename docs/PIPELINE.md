# MC3 PS2Recomp Pipeline

## 0. Status

Run:

```bat
00_status.bat
```

This checks the ISO, expected boot ELF, key tools, Ghidra availability, and PS2Recomp build outputs.

## 1. Extract ISO

Run:

```bat
01_extract_iso.bat
```

Expected output:

- `extracted_iso\SYSTEM.CNF`
- `extracted_iso\SLUS_213.55`

If extraction fails, install or expose a reliable ISO extractor. `bsdtar` is the preferred current tool because it is already available in this environment.

## 2. Open Ghidra

Run:

```bat
02_open_ghidra.bat
```

If the script cannot find `ghidraRun.bat`, install a full Ghidra distribution or set `GHIDRA_RUN` to the full path of `ghidraRun.bat`.

Current local Ghidra path:

```text
ghidra_12.1_PUBLIC\ghidraRun.bat
```

Current Emotion Engine extension path:

```text
ghidra_12.1_PUBLIC\Ghidra\Extensions\ghidra-emotionengine-reloaded
```

In Ghidra:

1. Create or open a project in `work\ghidra`.
2. Import `extracted_iso\SLUS_213.55`.
3. Use the Emotion Engine / R5900 language when prompted.
4. Run analysis.
5. Run `PS2Recomp\ps2xRecomp\tools\ghidra\ExportPS2Functions.java`.
6. Save outputs under `work\exports`.

## 3. Build PS2Recomp

Run:

```bat
03_build_ps2recomp.bat
```

Expected tools:

- CMake
- Ninja, or another CMake generator available on the machine
- C++ compiler compatible with this project

The script configures and builds under `PS2Recomp\out\build`.

## 4. Run Recomp

Run:

```bat
04_run_recomp.bat
```

The script looks for TOML files in `work\exports`. If more than one exists, it uses the newest. Generated C++ should go to `work\generated` when the TOML points there.

## 4a. Export From Ghidra Headless

After the ELF has been imported and analyzed in the GUI project, run:

```bat
07_export_ghidra_headless.bat
```

This writes:

- `work\exports\SLUS_213.55.ghidra.toml`
- `work\exports\SLUS_213.55.ghidra.csv`

The script uses the existing `work\mc2recomp` project and runs `ExportPS2Functions.java` without the Script Manager file chooser.

## 5. Native Analyzer Fallback

Run:

```bat
05_native_analyzer_fallback.bat
```

This creates `work\exports\SLUS_213.55.native_analyzer.toml` without Ghidra. Use it only for quick experiments and blocker discovery; the Ghidra export remains the preferred source for a retail stripped game.

## 6. Visual Studio Tool

Run:

```bat
06_open_ps2x_studio.bat
```

This opens the PS2Recomp Studio binary built from this checkout. Use it as a visual helper for ELF/config inspection, not as a replacement for the documented pipeline.

## 7. Index Generated Functions

After a successful Ghidra-based recomp run, generate the function index and incremental batch manifests:

```bat
08_index_generated_functions.bat 250
```

Outputs:

- `work\index\functions_index.csv`
- `docs\FUNCTION_INDEX.md`
- `work\batches\ghidra\batch_####.csv`
- `work\batches\ghidra\batch_####.rsp`

Use these batches for incremental compile/analyze loops instead of attempting to compile every generated `.cpp` at once.

## 8. Compile Generated Code Incrementally

Run a bounded syntax check first:

```bat
09_compile_generated_batch.bat batch_0001 10 syntax
```

Then try object compilation on a small limit:

```bat
09_compile_generated_batch.bat batch_0001 5 object
```

Arguments:

- First: batch name or number, for example `batch_0001` or `1`.
- Second: file limit, for example `10`, `25`, `100`, or `250`.
- Third: mode, either `syntax` or `object`.

Outputs:

- `work\compile\ghidra\batch_####\*.log`
- `work\compile\ghidra\batch_####\batch_####.syntax.summary.csv`
- `work\compile\ghidra\batch_####\batch_####.object.summary.csv`
- `work\compile\ghidra\batch_####\obj\*.o` in object mode

Current include contract for generated sources:

- `work\generated\ghidra`
- `PS2Recomp\ps2xRuntime\include`
- `PS2Recomp\ps2xRuntime\src\lib\Kernel`

## Documentation Loop

After the first successful export, use `docs\FUNCTION_DOC_TEMPLATE.md` for each important function or subsystem. Start from boot, file IO, memory allocation, graphics setup, and game loop blockers before cataloging low-priority helpers.
