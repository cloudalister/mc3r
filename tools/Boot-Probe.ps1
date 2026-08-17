param(
    [int]$Seconds = 10,
    [ValidateSet("probe", "runtime", "analyze", "latch", "stage2", "iopqueue", "latch-iopqueue", "latch-iopqueue-gsfield", "latch-iopqueue-gsfield-callback", "payload592", "pollsid", "pollsid541760ret1", "pollsid5422c8pass", "pollsid59c", "pollsid59c595", "pollsid59c595ret2", "pollsid59c595ret2mode9", "pollsid59c595ret2mode9payload1", "pollsid59c595ret2mode9payload1m3", "pollsid59c595ret2mode9payload1m3skip5a", "pollsid59c595ret2mode9payload1m3skip5areq4", "pollsid59c595ret2mode9payload1m3skip5areq4nosid", "pollsid59c595ret2mode9payload1m3skip5areq4ret2", "pollsid59c595ret2mode9payload1m3skip5areq4ret2ret1", "pollsid59c595ret2mode9payload1m3skip5areq4ret2ret1a8", "pollsid59c595ret2mode9payload1m3skip5areq4ret2ret1a8logicalresolver", "compare")]
    [string]$Mode = "probe",
    # Optional analyze-only input for deterministic tests. Existing batch callers keep using TraceLog.
    [string]$AnalyzeTracePath = "",
    # Do not write latest_status.md or docs status when analyzing a synthetic trace.
    [switch]$NoWriteStatus,
    # Validation-only entry point used by 14_run_boot_trace.bat and synthetic tests.
    [switch]$ValidateDeterministicBudget
)

$ErrorActionPreference = "Stop"

function Test-DispatchBudget {
    param([string]$Value)

    if ([string]::IsNullOrWhiteSpace($Value) -or $Value -notmatch '^[1-9][0-9]*$') {
        return $false
    }

    [uint64]$parsed = 0
    return [uint64]::TryParse($Value, [ref]$parsed) -and $parsed -gt 0
}

if ($ValidateDeterministicBudget) {
    # The wrapper calls this only for MC3_DETERMINISTIC=1. Keep the helper
    # faithful to the opt-in gate so synthetic checks can prove legacy mode
    # never rejects or propagates a stale budget.
    if ($env:MC3_DETERMINISTIC -ne "1") {
        Write-Output "MC3 deterministic budget gate inactive."
        exit 0
    }
    if (-not (Test-DispatchBudget -Value $env:MC3_DISPATCH_BUDGET)) {
        Write-Output "[ERROR] MC3_DISPATCH_BUDGET must be a positive decimal integer when MC3_DETERMINISTIC=1."
        exit 2
    }
    Write-Output "MC3 dispatch budget accepted: $env:MC3_DISPATCH_BUDGET"
    exit 0
}

$Root = (Resolve-Path ".").Path
$LogDir = Join-Path $Root "work\logs"
$StateDir = Join-Path $Root "work\boot_probe"
$TraceLog = Join-Path $LogDir "14_run_boot_trace.log"
$DriverLog = Join-Path $LogDir ("15_auto_boot_probe_{0}.log" -f (Get-Date -Format "yyyyMMdd_HHmmss"))
$StatusPath = Join-Path $StateDir "latest_status.md"
$DocsStatusPath = Join-Path $Root "docs\BOOT_PROBE_STATUS.md"
$GeneratedDir = Join-Path $Root "work\generated\ghidra"
$RegisterSource = Join-Path $GeneratedDir "register_functions.cpp"

New-Item -ItemType Directory -Force -Path $LogDir, $StateDir | Out-Null

function Write-Step {
    param([string]$Message)
    $line = "[{0}] {1}" -f (Get-Date -Format "yyyy-MM-dd HH:mm:ss"), $Message
    Write-Host $line
    Add-Content -LiteralPath $DriverLog -Value $line
}

function Invoke-BatStep {
    param(
        [string]$BatName,
        [string[]]$ArgsList,
        [string]$Label
    )

    $batPath = Join-Path $Root $BatName
    if (-not (Test-Path -LiteralPath $batPath)) {
        throw "Missing required script: $batPath"
    }

    Write-Step $Label
    $cmdArgs = @("/c", "`"$batPath`"") + $ArgsList
    & cmd.exe @cmdArgs
    if ($LASTEXITCODE -ne 0) {
        throw "$BatName failed with exit code $LASTEXITCODE"
    }
}

function Set-ProbeExperimentEnv {
    param([string]$Experiment)

    Remove-Item Env:\MC3_TRACE_LOGICAL_RESOLVER -ErrorAction SilentlyContinue
    Remove-Item Env:\MC3_SIF_EXPERIMENT_LATCH_REG4 -ErrorAction SilentlyContinue
    Remove-Item Env:\MC3_SIF_EXPERIMENT_STAGE2 -ErrorAction SilentlyContinue
    Remove-Item Env:\MC3_SIF_EXPERIMENT_IOP_QUEUE -ErrorAction SilentlyContinue
    Remove-Item Env:\MC3_GS_EXPERIMENT_FIELD_BIT -ErrorAction SilentlyContinue
    Remove-Item Env:\MC3_SIF_EXPERIMENT_CALLBACK_SIGNAL -ErrorAction SilentlyContinue
    Remove-Item Env:\MC3_SIF_EXPERIMENT_CALLBACK_5413F0 -ErrorAction SilentlyContinue
    Remove-Item Env:\MC3_SIF_EXPERIMENT_CALLBACK_541348 -ErrorAction SilentlyContinue
    Remove-Item Env:\MC3_SIF_EXPERIMENT_592_PAYLOAD -ErrorAction SilentlyContinue
    Remove-Item Env:\MC3_SIF_EXPERIMENT_59C_RESULT -ErrorAction SilentlyContinue
    Remove-Item Env:\MC3_SIF_EXPERIMENT_59C_RESULT_VALUE -ErrorAction SilentlyContinue
    Remove-Item Env:\MC3_SIF_EXPERIMENT_59C_CLEAR_QUEUE -ErrorAction SilentlyContinue
    Remove-Item Env:\MC3_SIF_EXPERIMENT_59C_SYNC_ACTIVE_QUEUE_SEQ -ErrorAction SilentlyContinue
    Remove-Item Env:\MC3_SIF_EXPERIMENT_595_COMPLETE -ErrorAction SilentlyContinue
    Remove-Item Env:\MC3_SIF_EXPERIMENT_595_CLEAR_QUEUE -ErrorAction SilentlyContinue
    Remove-Item Env:\MC3_SIF_EXPERIMENT_595_PAYLOAD_RET1 -ErrorAction SilentlyContinue
    Remove-Item Env:\MC3_SEMA_EXPERIMENT_POLL_RETURNS_SID -ErrorAction SilentlyContinue
    Remove-Item Env:\MC3_EXPERIMENT_541760_RET1_FOR_MODE4 -ErrorAction SilentlyContinue
    Remove-Item Env:\MC3_EXPERIMENT_541760_RET1_FOR_MODE9 -ErrorAction SilentlyContinue
    Remove-Item Env:\MC3_EXPERIMENT_5422C8_PASS_541760 -ErrorAction SilentlyContinue
    Remove-Item Env:\MC3_EXPERIMENT_549488_ACCEPT_REQ5_BUSY -ErrorAction SilentlyContinue
    Remove-Item Env:\MC3_EXPERIMENT_5424A8_DELAYED_REQ5_COMPLETE -ErrorAction SilentlyContinue
    Remove-Item Env:\MC3_EXPERIMENT_541A78_RET1_FOR_MODE3 -ErrorAction SilentlyContinue
    Remove-Item Env:\MC3_EXPERIMENT_5A8898_SKIP_FATAL_LOOP -ErrorAction SilentlyContinue
    Remove-Item Env:\MC3_SIF_EXPERIMENT_REQ4_620D80_STATUS -ErrorAction SilentlyContinue
    Remove-Item Env:\MC3_SIF_EXPERIMENT_REQ4_620D80_STATUS_VALUE -ErrorAction SilentlyContinue
    Remove-Item Env:\MC3_EXPERIMENT_704200_QUEUE_DRAIN -ErrorAction SilentlyContinue

    if ($Experiment -eq "latch") {
        $env:MC3_SIF_EXPERIMENT_LATCH_REG4 = "1"
    }
    elseif ($Experiment -eq "stage2") {
        $env:MC3_SIF_EXPERIMENT_STAGE2 = "1"
    }
    elseif ($Experiment -eq "iopqueue") {
        $env:MC3_SIF_EXPERIMENT_IOP_QUEUE = "1"
    }
    elseif ($Experiment -eq "latch-iopqueue") {
        $env:MC3_SIF_EXPERIMENT_LATCH_REG4 = "1"
        $env:MC3_SIF_EXPERIMENT_IOP_QUEUE = "1"
    }
    elseif ($Experiment -eq "latch-iopqueue-gsfield") {
        $env:MC3_SIF_EXPERIMENT_LATCH_REG4 = "1"
        $env:MC3_SIF_EXPERIMENT_IOP_QUEUE = "1"
        $env:MC3_GS_EXPERIMENT_FIELD_BIT = "1"
    }
    elseif ($Experiment -eq "latch-iopqueue-gsfield-callback") {
        $env:MC3_SIF_EXPERIMENT_LATCH_REG4 = "1"
        $env:MC3_SIF_EXPERIMENT_IOP_QUEUE = "1"
        $env:MC3_GS_EXPERIMENT_FIELD_BIT = "1"
        $env:MC3_SIF_EXPERIMENT_CALLBACK_SIGNAL = "1"
    }
    elseif ($Experiment -eq "payload592") {
        $env:MC3_SIF_EXPERIMENT_LATCH_REG4 = "1"
        $env:MC3_SIF_EXPERIMENT_IOP_QUEUE = "1"
        $env:MC3_GS_EXPERIMENT_FIELD_BIT = "1"
        $env:MC3_SIF_EXPERIMENT_CALLBACK_SIGNAL = "1"
        $env:MC3_SIF_EXPERIMENT_592_PAYLOAD = "1"
    }
    elseif ($Experiment -eq "pollsid") {
        $env:MC3_SIF_EXPERIMENT_LATCH_REG4 = "1"
        $env:MC3_SIF_EXPERIMENT_IOP_QUEUE = "1"
        $env:MC3_GS_EXPERIMENT_FIELD_BIT = "1"
        $env:MC3_SIF_EXPERIMENT_CALLBACK_SIGNAL = "1"
        $env:MC3_SIF_EXPERIMENT_592_PAYLOAD = "1"
        $env:MC3_SEMA_EXPERIMENT_POLL_RETURNS_SID = "1"
    }
    elseif ($Experiment -eq "pollsid541760ret1") {
        $env:MC3_SIF_EXPERIMENT_LATCH_REG4 = "1"
        $env:MC3_SIF_EXPERIMENT_IOP_QUEUE = "1"
        $env:MC3_GS_EXPERIMENT_FIELD_BIT = "1"
        $env:MC3_SIF_EXPERIMENT_CALLBACK_SIGNAL = "1"
        $env:MC3_SIF_EXPERIMENT_592_PAYLOAD = "1"
        $env:MC3_SEMA_EXPERIMENT_POLL_RETURNS_SID = "1"
        $env:MC3_EXPERIMENT_541760_RET1_FOR_MODE4 = "1"
    }
    elseif ($Experiment -eq "pollsid5422c8pass") {
        $env:MC3_SIF_EXPERIMENT_LATCH_REG4 = "1"
        $env:MC3_SIF_EXPERIMENT_IOP_QUEUE = "1"
        $env:MC3_GS_EXPERIMENT_FIELD_BIT = "1"
        $env:MC3_SIF_EXPERIMENT_CALLBACK_SIGNAL = "1"
        $env:MC3_SIF_EXPERIMENT_592_PAYLOAD = "1"
        $env:MC3_SEMA_EXPERIMENT_POLL_RETURNS_SID = "1"
        $env:MC3_EXPERIMENT_5422C8_PASS_541760 = "1"
    }
    elseif ($Experiment -eq "pollsid59c") {
        $env:MC3_SIF_EXPERIMENT_LATCH_REG4 = "1"
        $env:MC3_SIF_EXPERIMENT_IOP_QUEUE = "1"
        $env:MC3_GS_EXPERIMENT_FIELD_BIT = "1"
        $env:MC3_SIF_EXPERIMENT_CALLBACK_SIGNAL = "1"
        $env:MC3_SIF_EXPERIMENT_592_PAYLOAD = "1"
        $env:MC3_SEMA_EXPERIMENT_POLL_RETURNS_SID = "1"
        $env:MC3_SIF_EXPERIMENT_59C_RESULT = "1"
    }
    elseif ($Experiment -eq "pollsid59c595") {
        $env:MC3_SIF_EXPERIMENT_LATCH_REG4 = "1"
        $env:MC3_SIF_EXPERIMENT_IOP_QUEUE = "1"
        $env:MC3_GS_EXPERIMENT_FIELD_BIT = "1"
        $env:MC3_SIF_EXPERIMENT_CALLBACK_SIGNAL = "1"
        $env:MC3_SIF_EXPERIMENT_592_PAYLOAD = "1"
        $env:MC3_SEMA_EXPERIMENT_POLL_RETURNS_SID = "1"
        $env:MC3_SIF_EXPERIMENT_59C_RESULT = "1"
        $env:MC3_SIF_EXPERIMENT_595_COMPLETE = "1"
        $env:MC3_EXPERIMENT_5422C8_PASS_541760 = "1"
        $env:MC3_EXPERIMENT_704200_QUEUE_DRAIN = "1"
        $env:MC3_SIF_EXPERIMENT_CALLBACK_5413F0 = "1"
    }
    elseif ($Experiment -eq "pollsid59c595ret2") {
        $env:MC3_SIF_EXPERIMENT_LATCH_REG4 = "1"
        $env:MC3_SIF_EXPERIMENT_IOP_QUEUE = "1"
        $env:MC3_GS_EXPERIMENT_FIELD_BIT = "1"
        $env:MC3_SIF_EXPERIMENT_CALLBACK_SIGNAL = "1"
        $env:MC3_SIF_EXPERIMENT_592_PAYLOAD = "1"
        $env:MC3_SEMA_EXPERIMENT_POLL_RETURNS_SID = "1"
        $env:MC3_SIF_EXPERIMENT_59C_RESULT = "1"
        $env:MC3_SIF_EXPERIMENT_59C_RESULT_VALUE = "2"
        $env:MC3_SIF_EXPERIMENT_595_COMPLETE = "1"
        $env:MC3_EXPERIMENT_5422C8_PASS_541760 = "1"
        $env:MC3_EXPERIMENT_704200_QUEUE_DRAIN = "1"
        $env:MC3_SIF_EXPERIMENT_CALLBACK_5413F0 = "1"
    }
    elseif ($Experiment -eq "pollsid59c595ret2mode9") {
        $env:MC3_SIF_EXPERIMENT_LATCH_REG4 = "1"
        $env:MC3_SIF_EXPERIMENT_IOP_QUEUE = "1"
        $env:MC3_GS_EXPERIMENT_FIELD_BIT = "1"
        $env:MC3_SIF_EXPERIMENT_CALLBACK_SIGNAL = "1"
        $env:MC3_SIF_EXPERIMENT_592_PAYLOAD = "1"
        $env:MC3_SEMA_EXPERIMENT_POLL_RETURNS_SID = "1"
        $env:MC3_SIF_EXPERIMENT_59C_RESULT = "1"
        $env:MC3_SIF_EXPERIMENT_59C_RESULT_VALUE = "2"
        $env:MC3_SIF_EXPERIMENT_595_COMPLETE = "1"
        $env:MC3_EXPERIMENT_5422C8_PASS_541760 = "1"
        $env:MC3_EXPERIMENT_704200_QUEUE_DRAIN = "1"
        $env:MC3_SIF_EXPERIMENT_CALLBACK_5413F0 = "1"
        $env:MC3_EXPERIMENT_541760_RET1_FOR_MODE9 = "1"
        $env:MC3_SIF_EXPERIMENT_CALLBACK_541348 = "1"
        $env:MC3_SIF_EXPERIMENT_595_CLEAR_QUEUE = "1"
        $env:MC3_SIF_EXPERIMENT_59C_SYNC_ACTIVE_QUEUE_SEQ = "1"
        $env:MC3_EXPERIMENT_549488_ACCEPT_REQ5_BUSY = "1"
        $env:MC3_EXPERIMENT_5424A8_DELAYED_REQ5_COMPLETE = "1"
    }
    elseif ($Experiment -eq "pollsid59c595ret2mode9payload1") {
        $env:MC3_SIF_EXPERIMENT_LATCH_REG4 = "1"
        $env:MC3_SIF_EXPERIMENT_IOP_QUEUE = "1"
        $env:MC3_GS_EXPERIMENT_FIELD_BIT = "1"
        $env:MC3_SIF_EXPERIMENT_CALLBACK_SIGNAL = "1"
        $env:MC3_SIF_EXPERIMENT_592_PAYLOAD = "1"
        $env:MC3_SEMA_EXPERIMENT_POLL_RETURNS_SID = "1"
        $env:MC3_SIF_EXPERIMENT_59C_RESULT = "1"
        $env:MC3_SIF_EXPERIMENT_59C_RESULT_VALUE = "2"
        $env:MC3_SIF_EXPERIMENT_595_COMPLETE = "1"
        $env:MC3_EXPERIMENT_5422C8_PASS_541760 = "1"
        $env:MC3_EXPERIMENT_704200_QUEUE_DRAIN = "1"
        $env:MC3_SIF_EXPERIMENT_CALLBACK_5413F0 = "1"
        $env:MC3_EXPERIMENT_541760_RET1_FOR_MODE9 = "1"
        $env:MC3_SIF_EXPERIMENT_CALLBACK_541348 = "1"
        $env:MC3_SIF_EXPERIMENT_595_CLEAR_QUEUE = "1"
        $env:MC3_SIF_EXPERIMENT_59C_SYNC_ACTIVE_QUEUE_SEQ = "1"
        $env:MC3_EXPERIMENT_549488_ACCEPT_REQ5_BUSY = "1"
        $env:MC3_EXPERIMENT_5424A8_DELAYED_REQ5_COMPLETE = "1"
        $env:MC3_SIF_EXPERIMENT_595_PAYLOAD_RET1 = "1"
    }
    elseif ($Experiment -eq "pollsid59c595ret2mode9payload1m3") {
        $env:MC3_SIF_EXPERIMENT_LATCH_REG4 = "1"
        $env:MC3_SIF_EXPERIMENT_IOP_QUEUE = "1"
        $env:MC3_GS_EXPERIMENT_FIELD_BIT = "1"
        $env:MC3_SIF_EXPERIMENT_CALLBACK_SIGNAL = "1"
        $env:MC3_SIF_EXPERIMENT_592_PAYLOAD = "1"
        $env:MC3_SEMA_EXPERIMENT_POLL_RETURNS_SID = "1"
        $env:MC3_SIF_EXPERIMENT_59C_RESULT = "1"
        $env:MC3_SIF_EXPERIMENT_59C_RESULT_VALUE = "2"
        $env:MC3_SIF_EXPERIMENT_595_COMPLETE = "1"
        $env:MC3_EXPERIMENT_5422C8_PASS_541760 = "1"
        $env:MC3_EXPERIMENT_704200_QUEUE_DRAIN = "1"
        $env:MC3_SIF_EXPERIMENT_CALLBACK_5413F0 = "1"
        $env:MC3_EXPERIMENT_541760_RET1_FOR_MODE9 = "1"
        $env:MC3_SIF_EXPERIMENT_CALLBACK_541348 = "1"
        $env:MC3_SIF_EXPERIMENT_595_CLEAR_QUEUE = "1"
        $env:MC3_SIF_EXPERIMENT_59C_SYNC_ACTIVE_QUEUE_SEQ = "1"
        $env:MC3_EXPERIMENT_549488_ACCEPT_REQ5_BUSY = "1"
        $env:MC3_EXPERIMENT_5424A8_DELAYED_REQ5_COMPLETE = "1"
        $env:MC3_SIF_EXPERIMENT_595_PAYLOAD_RET1 = "1"
        $env:MC3_EXPERIMENT_541A78_RET1_FOR_MODE3 = "1"
    }
    elseif ($Experiment -eq "pollsid59c595ret2mode9payload1m3skip5a") {
        $env:MC3_SIF_EXPERIMENT_LATCH_REG4 = "1"
        $env:MC3_SIF_EXPERIMENT_IOP_QUEUE = "1"
        $env:MC3_GS_EXPERIMENT_FIELD_BIT = "1"
        $env:MC3_SIF_EXPERIMENT_CALLBACK_SIGNAL = "1"
        $env:MC3_SIF_EXPERIMENT_592_PAYLOAD = "1"
        $env:MC3_SEMA_EXPERIMENT_POLL_RETURNS_SID = "1"
        $env:MC3_SIF_EXPERIMENT_59C_RESULT = "1"
        $env:MC3_SIF_EXPERIMENT_59C_RESULT_VALUE = "2"
        $env:MC3_SIF_EXPERIMENT_595_COMPLETE = "1"
        $env:MC3_EXPERIMENT_5422C8_PASS_541760 = "1"
        $env:MC3_EXPERIMENT_704200_QUEUE_DRAIN = "1"
        $env:MC3_SIF_EXPERIMENT_CALLBACK_5413F0 = "1"
        $env:MC3_EXPERIMENT_541760_RET1_FOR_MODE9 = "1"
        $env:MC3_SIF_EXPERIMENT_CALLBACK_541348 = "1"
        $env:MC3_SIF_EXPERIMENT_595_CLEAR_QUEUE = "1"
        $env:MC3_SIF_EXPERIMENT_59C_SYNC_ACTIVE_QUEUE_SEQ = "1"
        $env:MC3_EXPERIMENT_549488_ACCEPT_REQ5_BUSY = "1"
        $env:MC3_EXPERIMENT_5424A8_DELAYED_REQ5_COMPLETE = "1"
        $env:MC3_SIF_EXPERIMENT_595_PAYLOAD_RET1 = "1"
        $env:MC3_EXPERIMENT_541A78_RET1_FOR_MODE3 = "1"
        $env:MC3_EXPERIMENT_5A8898_SKIP_FATAL_LOOP = "1"
    }
elseif ($Experiment -eq "pollsid59c595ret2mode9payload1m3skip5areq4nosid") {
    $env:MC3_TRACE_5420C0 = "1"
    $env:MC3_TRACE_2455F0 = "1"
        $env:MC3_SIF_EXPERIMENT_LATCH_REG4 = "1"
        $env:MC3_SIF_EXPERIMENT_IOP_QUEUE = "1"
        $env:MC3_GS_EXPERIMENT_FIELD_BIT = "1"
        $env:MC3_SIF_EXPERIMENT_CALLBACK_SIGNAL = "1"
        $env:MC3_SIF_EXPERIMENT_592_PAYLOAD = "1"
        $env:MC3_SIF_EXPERIMENT_59C_RESULT = "1"
        $env:MC3_SIF_EXPERIMENT_59C_RESULT_VALUE = "2"
        $env:MC3_SIF_EXPERIMENT_595_COMPLETE = "1"
        $env:MC3_EXPERIMENT_5422C8_PASS_541760 = "1"
        $env:MC3_EXPERIMENT_704200_QUEUE_DRAIN = "1"
        $env:MC3_SIF_EXPERIMENT_CALLBACK_5413F0 = "1"
        $env:MC3_EXPERIMENT_541760_RET1_FOR_MODE9 = "1"
        $env:MC3_SIF_EXPERIMENT_CALLBACK_541348 = "1"
        $env:MC3_SIF_EXPERIMENT_595_CLEAR_QUEUE = "1"
        $env:MC3_SIF_EXPERIMENT_59C_SYNC_ACTIVE_QUEUE_SEQ = "1"
        $env:MC3_EXPERIMENT_549488_ACCEPT_REQ5_BUSY = "1"
        $env:MC3_EXPERIMENT_5424A8_DELAYED_REQ5_COMPLETE = "1"
        $env:MC3_SIF_EXPERIMENT_595_PAYLOAD_RET1 = "1"
        $env:MC3_EXPERIMENT_541A78_RET1_FOR_MODE3 = "1"
        $env:MC3_EXPERIMENT_5A8898_SKIP_FATAL_LOOP = "1"
        $env:MC3_SIF_EXPERIMENT_REQ4_620D80_STATUS = "1"
        $env:MC3_SIF_EXPERIMENT_REQ4_620D80_STATUS_VALUE = "1"
    }
    elseif ($Experiment -eq "pollsid59c595ret2mode9payload1m3skip5areq4ret2") {
        $env:MC3_TRACE_2455F0 = "1"
        $env:MC3_EXPERIMENT_2455F0_RET2 = "1"
        $env:MC3_SIF_EXPERIMENT_LATCH_REG4 = "1"
        $env:MC3_SIF_EXPERIMENT_IOP_QUEUE = "1"
        $env:MC3_GS_EXPERIMENT_FIELD_BIT = "1"
        $env:MC3_SIF_EXPERIMENT_CALLBACK_SIGNAL = "1"
        $env:MC3_SIF_EXPERIMENT_592_PAYLOAD = "1"
        $env:MC3_SIF_EXPERIMENT_59C_RESULT = "1"
        $env:MC3_SIF_EXPERIMENT_59C_RESULT_VALUE = "2"
        $env:MC3_SIF_EXPERIMENT_595_COMPLETE = "1"
        $env:MC3_EXPERIMENT_5422C8_PASS_541760 = "1"
        $env:MC3_EXPERIMENT_704200_QUEUE_DRAIN = "1"
        $env:MC3_SIF_EXPERIMENT_CALLBACK_5413F0 = "1"
        $env:MC3_EXPERIMENT_541760_RET1_FOR_MODE9 = "1"
        $env:MC3_SIF_EXPERIMENT_CALLBACK_541348 = "1"
        $env:MC3_SIF_EXPERIMENT_595_CLEAR_QUEUE = "1"
        $env:MC3_SIF_EXPERIMENT_59C_SYNC_ACTIVE_QUEUE_SEQ = "1"
        $env:MC3_EXPERIMENT_549488_ACCEPT_REQ5_BUSY = "1"
        $env:MC3_EXPERIMENT_5424A8_DELAYED_REQ5_COMPLETE = "1"
        $env:MC3_SIF_EXPERIMENT_595_PAYLOAD_RET1 = "1"
        $env:MC3_EXPERIMENT_541A78_RET1_FOR_MODE3 = "1"
        $env:MC3_EXPERIMENT_5A8898_SKIP_FATAL_LOOP = "1"
        $env:MC3_SIF_EXPERIMENT_REQ4_620D80_STATUS = "1"
        $env:MC3_SIF_EXPERIMENT_REQ4_620D80_STATUS_VALUE = "1"
    }
    elseif ($Experiment -eq "pollsid59c595ret2mode9payload1m3skip5areq4ret2ret1") {
        Set-ProbeExperimentEnv -Experiment "pollsid59c595ret2mode9payload1m3skip5areq4ret2"
        $env:MC3_EXPERIMENT_5422C8_RET1 = "1"
    }
    elseif ($Experiment -eq "pollsid59c595ret2mode9payload1m3skip5areq4ret2ret1a8") {
        Set-ProbeExperimentEnv -Experiment "pollsid59c595ret2mode9payload1m3skip5areq4ret2ret1"
        $env:MC3_EXPERIMENT_5424A8_RET1 = "1"
        $env:MC3_TRACE_541968 = "1"
        $env:MC3_EXPERIMENT_5422C8_SKIP_LATCH = "1"
        $env:MC3_EXPERIMENT_541968_SKIP_WAIT = "1"
        $env:MC3_EXPERIMENT_24574C_SKIP_LOOP = "1"
        $env:MC3_TRACE_PROVIDER = "1"
    }
    elseif ($Experiment -eq "pollsid59c595ret2mode9payload1m3skip5areq4ret2ret1a8logicalresolver") {
        Set-ProbeExperimentEnv -Experiment "pollsid59c595ret2mode9payload1m3skip5areq4ret2ret1a8"
        $env:MC3_TRACE_LOGICAL_RESOLVER = "1"
    }
    elseif ($Experiment -eq "pollsid59c595ret2mode9payload1m3skip5areq4") {
        $env:MC3_SIF_EXPERIMENT_LATCH_REG4 = "1"
        $env:MC3_SIF_EXPERIMENT_IOP_QUEUE = "1"
        $env:MC3_GS_EXPERIMENT_FIELD_BIT = "1"
        $env:MC3_SIF_EXPERIMENT_CALLBACK_SIGNAL = "1"
        $env:MC3_SIF_EXPERIMENT_592_PAYLOAD = "1"
        $env:MC3_SEMA_EXPERIMENT_POLL_RETURNS_SID = "1"
        $env:MC3_SIF_EXPERIMENT_59C_RESULT = "1"
        $env:MC3_SIF_EXPERIMENT_59C_RESULT_VALUE = "2"
        $env:MC3_SIF_EXPERIMENT_595_COMPLETE = "1"
        $env:MC3_EXPERIMENT_5422C8_PASS_541760 = "1"
        $env:MC3_EXPERIMENT_704200_QUEUE_DRAIN = "1"
        $env:MC3_SIF_EXPERIMENT_CALLBACK_5413F0 = "1"
        $env:MC3_EXPERIMENT_541760_RET1_FOR_MODE9 = "1"
        $env:MC3_SIF_EXPERIMENT_CALLBACK_541348 = "1"
        $env:MC3_SIF_EXPERIMENT_595_CLEAR_QUEUE = "1"
        $env:MC3_SIF_EXPERIMENT_59C_SYNC_ACTIVE_QUEUE_SEQ = "1"
        $env:MC3_EXPERIMENT_549488_ACCEPT_REQ5_BUSY = "1"
        $env:MC3_EXPERIMENT_5424A8_DELAYED_REQ5_COMPLETE = "1"
        $env:MC3_SIF_EXPERIMENT_595_PAYLOAD_RET1 = "1"
        $env:MC3_EXPERIMENT_541A78_RET1_FOR_MODE3 = "1"
        $env:MC3_EXPERIMENT_5A8898_SKIP_FATAL_LOOP = "1"
        $env:MC3_SIF_EXPERIMENT_REQ4_620D80_STATUS = "1"
        $env:MC3_SIF_EXPERIMENT_REQ4_620D80_STATUS_VALUE = "1"
    }
}

function Convert-HexToUInt64 {
    param([string]$Value)
    if ([string]::IsNullOrWhiteSpace($Value)) {
        return $null
    }
    $clean = $Value.Trim().ToLowerInvariant()
    if ($clean.StartsWith("0x")) {
        $clean = $clean.Substring(2)
    }
    if ($clean.Length -eq 0) {
        return $null
    }
    return [Convert]::ToUInt64($clean, 16)
}

function Format-Hex {
    param($Value)
    if ($null -eq $Value) {
        return "n/a"
    }
    return ("0x{0:x}" -f [uint64]$Value)
}

function Get-FieldHex {
    param([string]$Line, [string]$Name)
    if ($Line -match ("(?:^|\s){0}=(0x[0-9a-fA-F]+)" -f [Regex]::Escape($Name))) {
        return Convert-HexToUInt64 $Matches[1]
    }
    return $null
}

function Get-FieldInt {
    param([string]$Line, [string]$Name)
    if ($Line -match ("(?:^|\s){0}=([0-9]+)" -f [Regex]::Escape($Name))) {
        return [int64]$Matches[1]
    }
    return $null
}

function Get-LastMatchingLine {
    param([string[]]$Lines, [string]$Pattern)
    for ($i = $Lines.Count - 1; $i -ge 0; --$i) {
        if ($Lines[$i] -match $Pattern) {
            return $Lines[$i]
        }
    }
    return $null
}

function Get-TailMatchingLines {
    param([string[]]$Lines, [string]$Pattern, [int]$Count = 8)
    $items = New-Object System.Collections.Generic.List[string]
    for ($i = $Lines.Count - 1; $i -ge 0 -and $items.Count -lt $Count; --$i) {
        if ($Lines[$i] -match $Pattern) {
            $items.Add($Lines[$i])
        }
    }
    $array = $items.ToArray()
    [Array]::Reverse($array)
    return $array
}

function Get-DeterministicEvidence {
    param([string[]]$Lines)

    $driver = Get-LastMatchingLine -Lines $Lines -Pattern '\[boot-trace-driver\] deterministic=(yes|no) dispatch-budget=([^\s]+)'
    $deterministic = "no"
    $budget = "n/a"
    if ($driver -and $driver -match 'deterministic=(yes|no) dispatch-budget=([^\s]+)') {
        $deterministic = $Matches[1]
        $budget = $Matches[2]
    }

    # These are raw trace facts; do not infer either from the mode or exit code.
    $budgetMarker = if (Get-LastMatchingLine -Lines $Lines -Pattern 'dispatch-budget-reached') { "yes" } else { "no" }
    $timeoutReached = if (Get-LastMatchingLine -Lines $Lines -Pattern 'timeout reached') { "yes" } else { "no" }

    return [pscustomobject]@{
        Deterministic = $deterministic
        DispatchBudget = $budget
        BudgetMarker = $budgetMarker
        TimeoutReached = $timeoutReached
    }
}

function Get-LastFrame {
    param([string[]]$Lines)

    # Concurrent trace writers can splice another marker or a partial token into
    # a frame line. Counters are evidence of visual output, so only accept them
    # from a complete, standalone frame with every field in the emitted order.
    $completeFramePattern = '^\[boot-trace:frame\] tick=[0-9]+ activeThreads=[0-9]+ pc=0x[0-9a-fA-F]+ ra=0x[0-9a-fA-F]+ sp=0x[0-9a-fA-F]+ gp=0x[0-9a-fA-F]+ dispfb1=0x[0-9a-fA-F]+ display1=0x[0-9a-fA-F]+ dma=[0-9]+ gif=[0-9]+ gsw=[0-9]+ vif=[0-9]+$'
    $line = Get-LastMatchingLine -Lines $Lines -Pattern $completeFramePattern
    if ($line) {
        return [pscustomobject]@{
            Line = $line
            Pc = Get-FieldHex $line "pc"
            Ra = Get-FieldHex $line "ra"
            Sp = Get-FieldHex $line "sp"
            Gp = Get-FieldHex $line "gp"
            Dma = Get-FieldInt $line "dma"
            Gif = Get-FieldInt $line "gif"
            Gsw = Get-FieldInt $line "gsw"
            Vif = Get-FieldInt $line "vif"
        }
    }

    $pcFallbackPatterns = @(
        "\[boot-trace:dispatch-window\].*pc=0x",
        "\[boot-trace:loop-exit\].*pc=0x",
        "\[boot-trace:game-thread-return\].*pc=0x"
    )

    foreach ($pattern in $pcFallbackPatterns) {
        $line = Get-LastMatchingLine -Lines $Lines -Pattern $pattern
        if ($line) {
            return [pscustomobject]@{
                Line = $line
                Pc = Get-FieldHex $line "pc"
                Ra = Get-FieldHex $line "ra"
                Sp = Get-FieldHex $line "sp"
                Gp = Get-FieldHex $line "gp"
                # Fallback traces are PC-only evidence. Never promote their
                # counters (or any corruption that preceded them) to render.
                Dma = 0
                Gif = 0
                Gsw = 0
                Vif = 0
            }
        }
    }

    return [pscustomobject]@{
        Line = $null
        Pc = $null
        Ra = $null
        Sp = $null
        Gp = $null
        Dma = 0
        Gif = 0
        Gsw = 0
        Vif = 0
    }
}

function Resolve-Address {
    param($Address)

    if ($null -eq $Address) {
        return [pscustomobject]@{ Function = "n/a"; File = "n/a"; Evidence = "no pc" }
    }

    $hex = ("{0:x}" -f [uint64]$Address)
    $hex8 = ("{0:x8}" -f [uint64]$Address)

    if (Test-Path -LiteralPath $RegisterSource) {
        $pattern = "runtime\.registerFunction\(0x$hex(?:u)?\s*,\s*([A-Za-z0-9_]+)\)"
        $match = Select-String -LiteralPath $RegisterSource -Pattern $pattern -CaseSensitive:$false -ErrorAction SilentlyContinue | Select-Object -First 1
        if ($match -and $match.Line -match $pattern) {
            $fn = $Matches[1]
            $candidate = Join-Path $GeneratedDir ($fn + ".cpp")
            return [pscustomobject]@{
                Function = $fn
                File = $(if (Test-Path -LiteralPath $candidate) { $candidate } else { "n/a" })
                Evidence = "register_functions.cpp"
            }
        }
    }

    $nameGuess = Join-Path $GeneratedDir ("FUN_{0}_0x{1}.cpp" -f $hex8, $hex)
    if (Test-Path -LiteralPath $nameGuess) {
        return [pscustomobject]@{
            Function = [IO.Path]::GetFileNameWithoutExtension($nameGuess)
            File = $nameGuess
            Evidence = "filename"
        }
    }

    # A textual address occurrence is not a function mapping: e.g. the value
    # 0x3 appears throughout generated instructions. Only the runtime registry
    # or an exact generated function filename establishes a known function.
    return [pscustomobject]@{ Function = "unresolved"; File = "n/a"; Evidence = "not found" }
}

function Get-Classification {
    param(
        [string[]]$Lines,
        $Frame,
        $Resolved,
        [string]$LastWait,
        [string]$LastGetReg,
        [string]$LastSifCommand
    )

    $missing = Get-LastMatchingLine -Lines $Lines -Pattern "Function not found|missing-function|first-bad-pc|uncompiled"

    # A sampled PC must map to a known runtime/generated function before it can
    # qualify any progress signal. This prevents noisy values such as 0x3 from
    # becoming visual evidence merely because VIF happened to move.
    if ($null -eq $Frame.Pc -or $Resolved.Function -in @("n/a", "unresolved")) {
        $detail = "stable pc $(Format-Hex $Frame.Pc) did not resolve to a known generated/runtime function ($($Resolved.Evidence))"
        if ($missing) {
            $detail = "$detail; missing-function evidence also observed: $missing"
        }
        return [pscustomobject]@{ Name = "invalid-pc"; Detail = $detail }
    }

    $visualTraffic = (($Frame.Gif -as [int64]) -gt 0) -or (($Frame.Gsw -as [int64]) -gt 0)
    if ($visualTraffic) {
        $detail = "gif/gsw counters moved"
        if ($missing) {
            $detail = "$detail; missing-function evidence also observed: $missing"
        }
        return [pscustomobject]@{ Name = "render-started"; Detail = $detail }
    }

    # Keep a missing dispatch visible when only DMA/VIF moved. Such counters are
    # transport activity, not visual output and must not mask the actual blocker.
    if ($missing) {
        return [pscustomobject]@{ Name = "missing-function"; Detail = $missing }
    }

    $transportTraffic = (($Frame.Dma -as [int64]) -gt 0) -or (($Frame.Vif -as [int64]) -gt 0)
    if ($transportTraffic) {
        return [pscustomobject]@{ Name = "counters-moved"; Detail = "dma/vif counters moved without gif/gsw visual traffic" }
    }

    if ($LastGetReg -and $LastGetReg -match "reg=0x4" -and $LastGetReg -match "value=0x20000" -and $Frame.Pc -eq (Convert-HexToUInt64 "0x246740")) {
        return [pscustomobject]@{ Name = "sif-reg-poll"; Detail = "stable at 0x246740; condition is sceSifGetReg(4) & 0x00040000" }
    }

    if ($LastWait) {
        $sid = $null
        if ($LastWait -match "sid=([0-9]+)") {
            $sid = $Matches[1]
        }
        if ($sid) {
            $wake = Get-LastMatchingLine -Lines $Lines -Pattern ("WaitSema:wake.*sid={0}|SignalSema.*sid={0}" -f [Regex]::Escape($sid))
            if (-not $wake) {
                return [pscustomobject]@{ Name = "semaphore"; Detail = $LastWait }
            }
        }
        else {
            return [pscustomobject]@{ Name = "semaphore"; Detail = $LastWait }
        }
    }

    if ($LastSifCommand) {
        return [pscustomobject]@{ Name = "sif-request"; Detail = $LastSifCommand }
    }

    return [pscustomobject]@{ Name = "unknown-loop"; Detail = "no known blocker pattern matched" }
}

function New-MarkdownStatus {
    param(
        [string[]]$Lines,
        $Frame,
        $Resolved,
        $Classification,
        [string]$LastWait,
        [string[]]$SifRegs,
        [string[]]$SifCommands,
        $DeterministicEvidence
    )

    $exe = Join-Path $Root "work\link\partial\mc3_partial.exe"
    $exeStamp = "n/a"
    if (Test-Path -LiteralPath $exe) {
        $exeStamp = (Get-Item -LiteralPath $exe).LastWriteTime.ToString("yyyy-MM-dd HH:mm:ss")
    }

    $regBlock = if ($SifRegs -and $SifRegs.Count -gt 0) { ($SifRegs -join "`n") } else { "n/a" }
    $cmdBlock = if ($SifCommands -and $SifCommands.Count -gt 0) { ($SifCommands -join "`n") } else { "n/a" }
    $waitBlock = if ($LastWait) { $LastWait } else { "n/a" }
    $dma = if ($null -eq $Frame.Dma) { 0 } else { $Frame.Dma }
    $gif = if ($null -eq $Frame.Gif) { 0 } else { $Frame.Gif }
    $gsw = if ($null -eq $Frame.Gsw) { 0 } else { $Frame.Gsw }
    $vif = if ($null -eq $Frame.Vif) { 0 } else { $Frame.Vif }
    $renderTraffic = "dma={0} gif={1} gsw={2} vif={3}" -f $dma, $gif, $gsw, $vif

    $next = switch ($Classification.Name) {
        "sif-reg-poll" { "Run baseline vs MC3_SIF_EXPERIMENT_LATCH_REG4=1 and accept only if PC moves past 0x246740 or render traffic starts." }
        "missing-function" { "Resume trace-driven compile for the missing function/batch, then relink and probe again." }
        "semaphore" { "Find the producer expected to signal the blocked semaphore before adding compatibility." }
        "render-started" { "Capture the first GIF/GS write PC window and map the visual call sites." }
        "counters-moved" { "DMA/VIF moved without GIF/GS writes; this is not visual render. Inspect the transport path and blocker evidence." }
        "invalid-pc" { "Discard this noisy PC sample; it does not resolve to a known generated/runtime function." }
        default { "Inspect the final stable PC and nearby trace window before adding a runtime experiment." }
    }

    @"
# MC3 Boot Probe Status

Updated: $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")
Mode: $Mode
Seconds: $Seconds
Trace log: $TraceLog
Driver log: $DriverLog
Partial runner timestamp: $exeStamp

## Summary

| Field | Value |
|---|---|
| Classification | $($Classification.Name) |
| Detail | $($Classification.Detail) |
| Stable PC | $(Format-Hex $Frame.Pc) |
| RA | $(Format-Hex $Frame.Ra) |
| SP | $(Format-Hex $Frame.Sp) |
| GP | $(Format-Hex $Frame.Gp) |
| Function | $($Resolved.Function) |
| File | $($Resolved.File) |
| Resolve evidence | $($Resolved.Evidence) |
| Render counters | $renderTraffic |
| Deterministic | $($DeterministicEvidence.Deterministic) |
| Dispatch budget | $($DeterministicEvidence.DispatchBudget) |
| Dispatch budget marker | $($DeterministicEvidence.BudgetMarker) |
| Timeout reached | $($DeterministicEvidence.TimeoutReached) |

## Last Stable Frame

~~~text
$($Frame.Line)
~~~

## Last WaitSema Block

~~~text
$waitBlock
~~~

## Last SIF Reg Reads/Writes

~~~text
$regBlock
~~~

## Last SIF Command Envelopes

~~~text
$cmdBlock
~~~

## Next Action

$next
"@
}

function Analyze-Trace {
    param([string]$TracePath)

    if (-not (Test-Path -LiteralPath $TracePath)) {
        throw "Trace log not found: $TracePath"
    }

    $lines = Get-Content -LiteralPath $TracePath -ErrorAction Stop
    $frame = Get-LastFrame -Lines $lines
    $resolved = Resolve-Address -Address $frame.Pc
    $lastWait = Get-LastMatchingLine -Lines $lines -Pattern "\[boot-trace:WaitSema:block\]"
    $lastGetReg = Get-LastMatchingLine -Lines $lines -Pattern "\[sceSifGetReg\]"
    $sifRegs = Get-TailMatchingLines -Lines $lines -Pattern "\[sceSif(?:Get|Set)Reg\]" -Count 12
    $sifCommands = Get-TailMatchingLines -Lines $lines -Pattern "\[boot-trace:sif-command-compat\]|\[boot-trace:mc3-iop-queue-experiment\]|\[boot-trace:mc3-iop-response-experiment\]|0x80000009|0x8000000a|0x8000000A" -Count 12
    $classification = Get-Classification -Lines $lines -Frame $frame -Resolved $resolved -LastWait $lastWait -LastGetReg $lastGetReg -LastSifCommand ($sifCommands | Select-Object -Last 1)
    $deterministicEvidence = Get-DeterministicEvidence -Lines $lines

    return [pscustomobject]@{
        Lines = $lines
        Frame = $frame
        Resolved = $resolved
        LastWait = $lastWait
        SifRegs = $sifRegs
        SifCommands = $sifCommands
        Classification = $classification
        DeterministicEvidence = $deterministicEvidence
    }
}

function Write-Status {
    param($Analysis)

    $markdown = New-MarkdownStatus -Lines $Analysis.Lines -Frame $Analysis.Frame -Resolved $Analysis.Resolved -Classification $Analysis.Classification -LastWait $Analysis.LastWait -SifRegs $Analysis.SifRegs -SifCommands $Analysis.SifCommands -DeterministicEvidence $Analysis.DeterministicEvidence
    Set-Content -LiteralPath $StatusPath -Value $markdown -Encoding ASCII
    Set-Content -LiteralPath $DocsStatusPath -Value $markdown -Encoding ASCII

    Write-Step "Status written: $StatusPath"
    Write-Step "Docs updated: $DocsStatusPath"
    Write-Host ""
    Write-Host "Classification: $($Analysis.Classification.Name)"
    Write-Host "Stable PC: $(Format-Hex $Analysis.Frame.Pc)"
    Write-Host "Function: $($Analysis.Resolved.Function)"
    Write-Host "Status: $StatusPath"
}

function Invoke-ProbeRun {
    param([string]$Experiment)

    Set-ProbeExperimentEnv -Experiment $Experiment
    Invoke-BatStep -BatName "14_run_boot_trace.bat" -ArgsList @([string]$Seconds) -Label "Run boot trace ($Experiment)"
    $traceCopy = Join-Path $StateDir ("boot_trace_{0}_{1}.log" -f $Experiment, (Get-Date -Format "yyyyMMdd_HHmmss"))
    Copy-Item -LiteralPath $TraceLog -Destination $traceCopy -Force
    $analysis = Analyze-Trace -TracePath $TraceLog
    return [pscustomobject]@{
        Experiment = $Experiment
        Trace = $traceCopy
        Analysis = $analysis
    }
}

function New-ComparisonMarkdown {
    param($Results)

    $validResults = @($Results | Where-Object { $_.PSObject.Properties.Name -contains "Analysis" })
    $rows = New-Object System.Collections.Generic.List[string]
    foreach ($result in $validResults) {
        $frame = $result.Analysis.Frame
        $classification = $result.Analysis.Classification
        $resolved = $result.Analysis.Resolved
        $dma = if ($null -eq $frame.Dma) { 0 } else { $frame.Dma }
        $gif = if ($null -eq $frame.Gif) { 0 } else { $frame.Gif }
        $gsw = if ($null -eq $frame.Gsw) { 0 } else { $frame.Gsw }
        $vif = if ($null -eq $frame.Vif) { 0 } else { $frame.Vif }
        $rows.Add("| $($result.Experiment) | $($classification.Name) | $(Format-Hex $frame.Pc) | $($resolved.Function) | dma=$dma gif=$gif gsw=$gsw vif=$vif | $($result.Trace) |")
    }

    $baseline = $validResults | Where-Object { $_.Experiment -eq "baseline" } | Select-Object -First 1
    $advanced = $false
    foreach ($result in $validResults) {
        if ($result.Experiment -eq "baseline") {
            continue
        }
        $frame = $result.Analysis.Frame
        $baseFrame = $baseline.Analysis.Frame
        $trueRender = (($frame.Gif -as [int64]) -gt 0) -or (($frame.Gsw -as [int64]) -gt 0)
        if ($frame.Pc -ne $baseFrame.Pc -or $trueRender) {
            $advanced = $true
        }
    }

    $decision = if ($advanced) {
        "At least one experiment moved the stable PC or produced GIF/GS visual traffic. Stable-PC movement alone is not visual success."
    }
    else {
        "No experiment moved past the baseline. Do not promote the SIF reg4 experiment yet."
    }

    @"
# MC3 Boot Probe Comparison

Updated: $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")
Seconds per run: $Seconds

| Experiment | Classification | Stable PC | Function | Render counters | Trace |
|---|---|---|---|---|---|
$($rows -join "`n")

## Decision

$decision
"@
}

if (-not $NoWriteStatus) {
    Write-Step "Boot probe start: root=$Root mode=$Mode seconds=$Seconds"
}

if ($Mode -eq "runtime") {
    Invoke-BatStep -BatName "03_build_ps2recomp.bat" -ArgsList @() -Label "Build PS2Recomp"
    Invoke-BatStep -BatName "10_link_partial_runner.bat" -ArgsList @("fast") -Label "Fast relink partial runner"
    Set-ProbeExperimentEnv -Experiment "baseline"
    Invoke-BatStep -BatName "14_run_boot_trace.bat" -ArgsList @([string]$Seconds) -Label "Run boot trace"
}
elseif ($Mode -eq "probe") {
    Set-ProbeExperimentEnv -Experiment "baseline"
    Invoke-BatStep -BatName "14_run_boot_trace.bat" -ArgsList @([string]$Seconds) -Label "Run boot trace"
}
elseif ($Mode -eq "latch") {
    Invoke-ProbeRun -Experiment "latch" | Out-Null
}
elseif ($Mode -eq "stage2") {
    Invoke-ProbeRun -Experiment "stage2" | Out-Null
}
elseif ($Mode -eq "iopqueue") {
    Invoke-ProbeRun -Experiment "iopqueue" | Out-Null
}
elseif ($Mode -eq "latch-iopqueue") {
    Invoke-ProbeRun -Experiment "latch-iopqueue" | Out-Null
}
elseif ($Mode -eq "latch-iopqueue-gsfield") {
    Invoke-ProbeRun -Experiment "latch-iopqueue-gsfield" | Out-Null
}
elseif ($Mode -eq "latch-iopqueue-gsfield-callback") {
    Invoke-ProbeRun -Experiment "latch-iopqueue-gsfield-callback" | Out-Null
}
elseif ($Mode -eq "payload592") {
    Invoke-ProbeRun -Experiment "payload592" | Out-Null
}
elseif ($Mode -eq "pollsid") {
    Invoke-ProbeRun -Experiment "pollsid" | Out-Null
}
elseif ($Mode -eq "pollsid541760ret1") {
    Invoke-ProbeRun -Experiment "pollsid541760ret1" | Out-Null
}
elseif ($Mode -eq "pollsid5422c8pass") {
    Invoke-ProbeRun -Experiment "pollsid5422c8pass" | Out-Null
}
elseif ($Mode -eq "pollsid59c") {
    Invoke-ProbeRun -Experiment "pollsid59c" | Out-Null
}
elseif ($Mode -eq "pollsid59c595") {
    Invoke-ProbeRun -Experiment "pollsid59c595" | Out-Null
}
elseif ($Mode -eq "pollsid59c595ret2") {
    Invoke-ProbeRun -Experiment "pollsid59c595ret2" | Out-Null
}
elseif ($Mode -eq "pollsid59c595ret2mode9") {
    Invoke-ProbeRun -Experiment "pollsid59c595ret2mode9" | Out-Null
}
elseif ($Mode -eq "pollsid59c595ret2mode9payload1") {
    Invoke-ProbeRun -Experiment "pollsid59c595ret2mode9payload1" | Out-Null
}
elseif ($Mode -eq "pollsid59c595ret2mode9payload1m3") {
    Invoke-ProbeRun -Experiment "pollsid59c595ret2mode9payload1m3" | Out-Null
}
elseif ($Mode -eq "pollsid59c595ret2mode9payload1m3skip5a") {
    Invoke-ProbeRun -Experiment "pollsid59c595ret2mode9payload1m3skip5a" | Out-Null
}
elseif ($Mode -eq "pollsid59c595ret2mode9payload1m3skip5areq4") {
    Invoke-ProbeRun -Experiment "pollsid59c595ret2mode9payload1m3skip5areq4" | Out-Null
}
elseif ($Mode -eq "pollsid59c595ret2mode9payload1m3skip5areq4nosid") {
    Invoke-ProbeRun -Experiment "pollsid59c595ret2mode9payload1m3skip5areq4nosid" | Out-Null
}
elseif ($Mode -eq "pollsid59c595ret2mode9payload1m3skip5areq4ret2") {
    Invoke-ProbeRun -Experiment "pollsid59c595ret2mode9payload1m3skip5areq4ret2" | Out-Null
}
elseif ($Mode -eq "pollsid59c595ret2mode9payload1m3skip5areq4ret2ret1") {
    Invoke-ProbeRun -Experiment "pollsid59c595ret2mode9payload1m3skip5areq4ret2ret1" | Out-Null
}
elseif ($Mode -eq "pollsid59c595ret2mode9payload1m3skip5areq4ret2ret1a8") {
    Invoke-ProbeRun -Experiment "pollsid59c595ret2mode9payload1m3skip5areq4ret2ret1a8" | Out-Null
}
elseif ($Mode -eq "pollsid59c595ret2mode9payload1m3skip5areq4ret2ret1a8logicalresolver") {
    Invoke-ProbeRun -Experiment "pollsid59c595ret2mode9payload1m3skip5areq4ret2ret1a8logicalresolver" | Out-Null
}
elseif ($Mode -eq "compare") {
    $results = @()
    $results += Invoke-ProbeRun -Experiment "baseline"
    $results += Invoke-ProbeRun -Experiment "latch"
    $results += Invoke-ProbeRun -Experiment "stage2"
    $results += Invoke-ProbeRun -Experiment "latch-iopqueue"
    $results += Invoke-ProbeRun -Experiment "latch-iopqueue-gsfield"
    $results += Invoke-ProbeRun -Experiment "latch-iopqueue-gsfield-callback"
    $results += Invoke-ProbeRun -Experiment "payload592"
    $results += Invoke-ProbeRun -Experiment "pollsid"
    $results += Invoke-ProbeRun -Experiment "pollsid59c"
    $results += Invoke-ProbeRun -Experiment "pollsid59c595"
    $comparisonPath = Join-Path $StateDir "latest_comparison.md"
    $comparison = New-ComparisonMarkdown -Results $results
    Set-Content -LiteralPath $comparisonPath -Value $comparison -Encoding ASCII
    Copy-Item -LiteralPath $comparisonPath -Destination (Join-Path $Root "docs\BOOT_PROBE_COMPARISON.md") -Force
    Write-Step "Comparison written: $comparisonPath"
}
else {
    Set-ProbeExperimentEnv -Experiment "baseline"
    if (-not $NoWriteStatus) {
        Write-Step "Analyze existing trace only"
    }
}

if ($Mode -ne "compare") {
    $analysisPath = $TraceLog
    if ($Mode -eq "analyze" -and -not [string]::IsNullOrWhiteSpace($AnalyzeTracePath)) {
        $analysisPath = $AnalyzeTracePath
    }
    $analysis = Analyze-Trace -TracePath $analysisPath
    if ($NoWriteStatus) {
        Write-Output "Classification: $($analysis.Classification.Name)"
        Write-Output "Detail: $($analysis.Classification.Detail)"
        Write-Output "Stable PC: $(Format-Hex $analysis.Frame.Pc)"
        Write-Output "Function: $($analysis.Resolved.Function)"
    }
    else {
        Write-Status -Analysis $analysis
    }
}
