param(
    [string]$RepoRoot = "V:\1_PROJECTS\2_ACTIVE\Python\chief-site-engineer",
    [switch]$Smoke,
    [switch]$Uninstall
)

$ErrorActionPreference = "Stop"
$taskName = "CSE Codex Loop"
$runtimeRoot = Join-Path $env:LOCALAPPDATA "CSE-Codex-Loop"
$configPath = Join-Path $runtimeRoot "config.json"
$runnerPath = Join-Path $RepoRoot "scripts\run_cse_codex_loop.ps1"
$powershellPath = (Get-Process -Id $PID).Path

if ($Uninstall) {
    Stop-ScheduledTask -TaskName $taskName -ErrorAction SilentlyContinue
    Unregister-ScheduledTask -TaskName $taskName -Confirm:$false -ErrorAction SilentlyContinue
    Write-Host "CSE Codex Loop Scheduled Task removed. Run records remain in $runtimeRoot."
    exit 0
}

if (-not (Test-Path -LiteralPath $RepoRoot)) {
    throw "Repository not found: $RepoRoot"
}
if (-not (Test-Path -LiteralPath $runnerPath)) {
    throw "Codex loop runner not found: $runnerPath"
}

$pythonCommand = Get-Command python -CommandType Application -ErrorAction SilentlyContinue
$codexCommand = Get-Command codex -CommandType Application -ErrorAction SilentlyContinue
$gitCommand = Get-Command git -CommandType Application -ErrorAction SilentlyContinue
$ghCommand = Get-Command gh -CommandType Application -ErrorAction SilentlyContinue
foreach ($entry in @(
    @{ Name = "python"; Command = $pythonCommand },
    @{ Name = "codex"; Command = $codexCommand },
    @{ Name = "git"; Command = $gitCommand },
    @{ Name = "gh"; Command = $ghCommand }
)) {
    if (-not $entry.Command -or -not $entry.Command.Source) {
        throw ("Required command is unavailable: " + $entry.Name)
    }
}

$pythonPath = (Resolve-Path -LiteralPath ([string]$pythonCommand.Source)).Path
$gitPath = (Resolve-Path -LiteralPath ([string]$gitCommand.Source)).Path
$ghPath = (Resolve-Path -LiteralPath ([string]$ghCommand.Source)).Path
$resolvedRepoRoot = (Resolve-Path -LiteralPath $RepoRoot).Path

$nativeCodexCommand = Get-Command codex.exe -CommandType Application -ErrorAction SilentlyContinue
$codexCandidate = if ($nativeCodexCommand) { [string]$nativeCodexCommand.Source } else { "" }
if (-not $codexCandidate) {
    $launcherRoot = Split-Path -Parent ([string]$codexCommand.Source)
    $architecture = [System.Runtime.InteropServices.RuntimeInformation]::OSArchitecture.ToString()
    if ($architecture -eq "Arm64") {
        $targetTriple = "aarch64-pc-windows-msvc"
        $platformPackage = "codex-win32-arm64"
    }
    else {
        $targetTriple = "x86_64-pc-windows-msvc"
        $platformPackage = "codex-win32-x64"
    }
    $codexCandidates = @(
        (Join-Path $launcherRoot "node_modules\@openai\codex\node_modules\@openai\$platformPackage\vendor\$targetTriple\bin\codex.exe"),
        (Join-Path $launcherRoot "node_modules\@openai\$platformPackage\vendor\$targetTriple\bin\codex.exe")
    )
    $codexCandidate = $codexCandidates | Where-Object {
        Test-Path -LiteralPath $_ -PathType Leaf
    } | Select-Object -First 1
}
if (-not $codexCandidate) {
    throw "Native codex.exe was not found behind the installed Codex launcher."
}
$codexPath = (Resolve-Path -LiteralPath $codexCandidate).Path
if ([System.IO.Path]::GetFileName($codexPath) -ne "codex.exe") {
    throw "Resolved Codex executable is not codex.exe."
}

& $ghPath auth status 1>$null 2>$null
if ($LASTEXITCODE -ne 0) {
    throw "GitHub CLI is not authenticated. Run gh auth login once."
}

New-Item -ItemType Directory -Path $runtimeRoot -Force | Out-Null
@{
    repository = "faliardic/chief-site-engineer"
    repo_root = $resolvedRepoRoot
    python_path = $pythonPath
    codex_path = $codexPath
    git_path = $gitPath
    gh_path = $ghPath
    allowed_base = "master"
    max_runs = 20
} | ConvertTo-Json | Set-Content -LiteralPath $configPath -Encoding UTF8

$argument = "-NoProfile -ExecutionPolicy Bypass -File `"$runnerPath`" -RuntimeRoot `"$runtimeRoot`""
$action = New-ScheduledTaskAction -Execute $powershellPath -Argument $argument -WorkingDirectory $resolvedRepoRoot
$trigger = New-ScheduledTaskTrigger -Once -At (Get-Date).AddMinutes(5) -RepetitionInterval (New-TimeSpan -Minutes 5)
$settings = New-ScheduledTaskSettingsSet -Disable -StartWhenAvailable -MultipleInstances IgnoreNew
$currentIdentity = [System.Security.Principal.WindowsIdentity]::GetCurrent().Name
$principal = New-ScheduledTaskPrincipal -UserId $currentIdentity -LogonType Interactive -RunLevel Limited

Stop-ScheduledTask -TaskName $taskName -ErrorAction SilentlyContinue
Unregister-ScheduledTask -TaskName $taskName -Confirm:$false -ErrorAction SilentlyContinue
Register-ScheduledTask -TaskName $taskName -Action $action -Trigger $trigger -Settings $settings -Principal $principal -Description "Local authenticated Codex implementer and read-only reviewer loop" -Force | Out-Null
Disable-ScheduledTask -TaskName $taskName | Out-Null

$registered = Get-ScheduledTask -TaskName $taskName
if ([string]$registered.State -ne "Disabled") {
    throw "scheduled_task_not_disabled"
}

Write-Host "CSE Codex Loop installed Disabled for the current interactive user."
if ($Smoke) {
    Write-Host "Running the manually requested read-only documentation smoke..."
    & $powershellPath -NoProfile -ExecutionPolicy Bypass -File $runnerPath -RuntimeRoot $runtimeRoot -Smoke
    if ($LASTEXITCODE -ne 0) {
        throw "codex_smoke_failed"
    }
}

Write-Host "Acceptance and a separate operator action are required before enabling the task."
