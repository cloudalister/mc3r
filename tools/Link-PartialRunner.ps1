param(
    [string]$OutputExe = "work\link\partial\mc3_partial.exe",
    [string]$Compiler = "C:\msys64\ucrt64\bin\g++.exe"
)

$ErrorActionPreference = "Stop"

function Add-RspLine([System.Collections.Generic.List[string]]$Lines, [string]$Value) {
    $Lines.Add('"' + $Value.Replace('\', '/') + '"')
}

$root = (Resolve-Path ".").Path
$outDir = Split-Path $OutputExe -Parent
$absOutDir = Join-Path $root $outDir
$absOutputExe = Join-Path $root $OutputExe
$generatedDir = Join-Path $root "work\generated\ghidra"
$objectRoot = Join-Path $root "work\compile\ghidra"
$partialRegister = Join-Path $root "work\link\partial\register_functions.partial.cpp"
$partialRegisterObj = Join-Path $root "work\link\partial\register_functions.partial.o"
$missingStubs = Join-Path $root "work\link\partial\missing_functions.partial.cpp"
$missingStubsObj = Join-Path $root "work\link\partial\missing_functions.partial.o"
$mainObj = Join-Path $root "work\link\partial\main.o"
$rspPath = Join-Path $root "work\link\partial\mc3_partial.link.rsp"
$logPath = Join-Path $root "work\logs\10_link_partial_runner.log"

New-Item -ItemType Directory -Force -Path $absOutDir | Out-Null
New-Item -ItemType Directory -Force -Path (Split-Path $logPath -Parent) | Out-Null

if (!(Test-Path $Compiler)) {
    throw "Compiler not found: $Compiler"
}
if (!(Test-Path $partialRegister)) {
    throw "Partial register source not found: $partialRegister"
}
if (!(Test-Path $missingStubs)) {
    throw "Missing stubs source not found: $missingStubs"
}

$includeArgs = @(
    "-I", (Join-Path $root "PS2Recomp\ps2xRuntime\include"),
    "-I", (Join-Path $root "PS2Recomp\ps2xRuntime\src\lib\Kernel"),
    "-I", $generatedDir,
    "-I", (Join-Path $root "PS2Recomp\out\build\_deps\raylib-src\src"),
    "-I", (Join-Path $root "PS2Recomp\out\build\_deps\raylib-src\src\external\glfw\include")
)

$compileBase = @(
    "-std=c++20",
    "-msse4.1",
    "-DGRAPHICS_API_OPENGL_33",
    "-DPLATFORM_DESKTOP"
)

& $Compiler @compileBase @includeArgs -c (Join-Path $root "PS2Recomp\ps2xRuntime\src\main.cpp") -o $mainObj *> $logPath
if ($LASTEXITCODE -ne 0) {
    throw "Failed to compile main.cpp. See $logPath"
}

& $Compiler @compileBase @includeArgs -c $partialRegister -o $partialRegisterObj *>> $logPath
if ($LASTEXITCODE -ne 0) {
    throw "Failed to compile partial register. See $logPath"
}

& $Compiler @compileBase @includeArgs -c $missingStubs -o $missingStubsObj *>> $logPath
if ($LASTEXITCODE -ne 0) {
    throw "Failed to compile missing stubs. See $logPath"
}

$rsp = New-Object System.Collections.Generic.List[string]
$rsp.Add("-o")
Add-RspLine $rsp $absOutputExe
Add-RspLine $rsp $mainObj
Add-RspLine $rsp $partialRegisterObj
Add-RspLine $rsp $missingStubsObj

Get-ChildItem -Path $objectRoot -Recurse -Filter "*.o" -File |
    Sort-Object FullName |
    ForEach-Object { Add-RspLine $rsp $_.FullName }

Add-RspLine $rsp (Join-Path $root "PS2Recomp\out\build\ps2xRuntime\libps2_runtime.a")
Add-RspLine $rsp "C:\msys64\ucrt64\lib\libz.dll.a"
Add-RspLine $rsp (Join-Path $root "PS2Recomp\out\build\_deps\raylib-build\raylib\libraylib.a")
$rsp.Add("-lopengl32")
$rsp.Add("-lglu32")
$rsp.Add("-lwinmm")
$rsp.Add("-lkernel32")
$rsp.Add("-luser32")
$rsp.Add("-lgdi32")
$rsp.Add("-lwinspool")
$rsp.Add("-lshell32")
$rsp.Add("-lole32")
$rsp.Add("-loleaut32")
$rsp.Add("-luuid")
$rsp.Add("-lcomdlg32")
$rsp.Add("-ladvapi32")

$rsp | Set-Content -Path $rspPath -Encoding ASCII

& $Compiler "@$rspPath" *>> $logPath
if ($LASTEXITCODE -ne 0) {
    throw "Link failed. See $logPath"
}

$compilerDir = Split-Path $Compiler -Parent
foreach ($dll in @("libgcc_s_seh-1.dll", "libstdc++-6.dll", "libwinpthread-1.dll", "zlib1.dll")) {
    $sourceDll = Join-Path $compilerDir $dll
    if (Test-Path -LiteralPath $sourceDll) {
        Copy-Item -LiteralPath $sourceDll -Destination (Join-Path $absOutDir $dll) -Force
    }
    else {
        Add-Content -Path $logPath -Value "[WARN] Runtime DLL not found beside compiler: $sourceDll"
    }
}

Write-Host "[OK] Linked partial runner: $OutputExe"
Write-Host "[OK] Link response file: $rspPath"
Write-Host "[OK] Log: $logPath"
