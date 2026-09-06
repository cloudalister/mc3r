param([ValidateSet('2300d0','5c3a48','5b94f0','5b94f8','5b9990','5b9998')][string]$Entry = '2300d0')
$ErrorActionPreference = 'Stop'
$address = [Convert]::ToUInt32($Entry,16)
$delayWord = if ($Entry -eq '5c3a48') { 0x0000102d } else { 0 }
$owners = @{
    '2300d0' = @('FUN_002300d8_0x2300d8','batch_0009')
    '5c3a48' = @('FUN_005c3a68_0x5c3a68','batch_0061')
    '5b94f0' = @('FUN_005b9500_0x5b9500','batch_0060')
    '5b94f8' = @('FUN_005b9500_0x5b9500','batch_0060')
    '5b9990' = @('FUN_005b9908_0x5b9908','batch_0060')
    '5b9998' = @('FUN_005b9908_0x5b9908','batch_0060')
}
$owner, $batch = $owners[$Entry]
$root = Split-Path -Parent $PSScriptRoot
Set-Location $root
if (Get-Process mc3_partial -ErrorAction SilentlyContinue) { throw 'MC3 is running' }
$bytes = [IO.File]::ReadAllBytes((Join-Path $root 'extracted_iso/SLUS_213.55'))
if ($bytes.Length -lt 52 -or [BitConverter]::ToUInt32($bytes,0) -ne 0x464c457f -or $bytes[4] -ne 1 -or $bytes[5] -ne 1) { throw 'Expected little-endian ELF32' }
$ph = [BitConverter]::ToUInt32($bytes,28)
$size = [BitConverter]::ToUInt16($bytes,42)
$count = [BitConverter]::ToUInt16($bytes,44)
$verified = $false
if ($size -lt 32 -or ([long]$ph + [long]$size*$count) -gt $bytes.Length) { throw 'Invalid program headers' }
for ($i=0; $i -lt $count; $i++) {
    $p = $ph + $i*$size
    if ([BitConverter]::ToUInt32($bytes,$p) -ne 1) { continue }
    $off = [BitConverter]::ToUInt32($bytes,$p+4)
    $va = [BitConverter]::ToUInt32($bytes,$p+8)
    $len = [BitConverter]::ToUInt32($bytes,$p+16)
    if ($address -ge $va -and ($address+8) -le ([long]$va+$len)) {
        $at = [long]$off + $address - $va
        if ($at+8 -gt $bytes.Length -or [BitConverter]::ToUInt32($bytes,$at) -ne 0x03e00008 -or [BitConverter]::ToUInt32($bytes,$at+4) -ne $delayWord) { throw 'Leaf bytes mismatch; do not compile guessed behavior' }
        $verified = $true
    }
}
if (!$verified) { throw 'Leaf not mapped in ELF' }
$source = "work/generated/ghidra/$owner.cpp"
$content = [IO.File]::ReadAllText((Join-Path $root $source))
$call = if ($Entry.StartsWith('5b')) { "mc3VerifiedNopLeaf<0x${Entry}u>(ctx);" } else { "mc3VerifiedLeaf$Entry(ctx);" }
foreach ($hook in @("case 0x${Entry}u: goto label_$Entry;", $call)) {
    if (!$content.Contains($hook)) { throw 'Generated leaf patch missing; see docs/RESULT_VERIFIED_LEAF_2026-09-06.md' }
}
$env:PATH = 'C:\msys64\ucrt64\bin;' + $env:PATH
& rtk proxy 'C:\msys64\ucrt64\bin\g++.exe' '-std=c++20' '-O2' '-fno-strict-aliasing' '-msse4.1' '-Wall' '-Wno-unused-variable' '-Wno-unused-label' '-Wno-comment' -I work/generated/ghidra -I PS2Recomp/ps2xRuntime/include -I PS2Recomp/ps2xRuntime/src/lib/Kernel -c $source -o "work/compile/ghidra/$batch/obj/$owner.o"
if ($LASTEXITCODE -ne 0) { throw 'Leaf owner compilation failed' }
"PASS: ELF leaf $Entry and exact delay slot verified; owner rebuilt. Regenerate registration before link."
