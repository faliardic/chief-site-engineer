param(
    [string]$RepoRoot = "V:\1_PROJECTS\2_ACTIVE\Python\chief-site-engineer",
    [switch]$Smoke,
    [switch]$Uninstall
)

$ErrorActionPreference = "Stop"
$taskName = "CSE Codex Loop"
$runtimeRoot = Join-Path $env:LOCALAPPDATA "CSE-Codex-Loop"
$configPath = Join-Path $runtimeRoot "config.json"
$controlRepoRoot = Join-Path $runtimeRoot "control-repo"
$powershellPath = (Get-Process -Id $PID).Path

if ($Uninstall) {
    Stop-ScheduledTask -TaskName $taskName -ErrorAction SilentlyContinue
    Unregister-ScheduledTask -TaskName $taskName -Confirm:$false -ErrorAction SilentlyContinue
    Write-Host "CSE Codex Loop Scheduled Task removed. Run records remain in $runtimeRoot."
    exit 0
}

if (-not (Test-Path -LiteralPath $RepoRoot)) {
    throw "bootstrap_repository_missing"
}
$bootstrapInstallerPath = Join-Path $RepoRoot "scripts\install_cse_codex_loop.ps1"
if (-not (Test-Path -LiteralPath $bootstrapInstallerPath -PathType Leaf)) {
    throw "bootstrap_installer_missing"
}
$resolvedBootstrapRepoRoot = (Resolve-Path -LiteralPath $RepoRoot).Path
$resolvedBootstrapInstallerPath = (Resolve-Path -LiteralPath $bootstrapInstallerPath).Path
$resolvedCurrentInstallerPath = (Resolve-Path -LiteralPath $PSCommandPath).Path
if (-not [System.StringComparer]::OrdinalIgnoreCase.Equals(
    $resolvedBootstrapInstallerPath,
    $resolvedCurrentInstallerPath
)) {
    throw "bootstrap_installer_mismatch"
}

$supportedCodexExtensions = @(".exe", ".com", ".cmd", ".bat")
$pythonCommand = Get-Command python -CommandType Application -ErrorAction SilentlyContinue
$codexCommand = Get-Command codex -CommandType Application -ErrorAction SilentlyContinue |
    Where-Object {
        if (-not $_.Source) {
            return $false
        }
        $candidate = [string]$_.Source
        $extension = [System.IO.Path]::GetExtension($candidate).ToLowerInvariant()
        return (
            $extension -in $supportedCodexExtensions -and
            (Test-Path -LiteralPath $candidate -PathType Leaf)
        )
    } |
    Select-Object -First 1
$gitCommand = Get-Command git -CommandType Application -ErrorAction SilentlyContinue
$ghCommand = Get-Command gh -CommandType Application -ErrorAction SilentlyContinue
$flutterCommand = Get-Command flutter.bat -CommandType Application -ErrorAction SilentlyContinue
if (-not $flutterCommand) {
    $flutterCommand = Get-Command flutter -CommandType Application -ErrorAction SilentlyContinue
}
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
$codexPath = (Resolve-Path -LiteralPath ([string]$codexCommand.Source)).Path
$gitPath = (Resolve-Path -LiteralPath ([string]$gitCommand.Source)).Path
$ghPath = (Resolve-Path -LiteralPath ([string]$ghCommand.Source)).Path
$flutterPath = $null
if ($flutterCommand -and $flutterCommand.Source) {
    $flutterPath = (Resolve-Path -LiteralPath ([string]$flutterCommand.Source)).Path
}

$codexExtension = [System.IO.Path]::GetExtension($codexPath).ToLowerInvariant()
if ($codexExtension -notin $supportedCodexExtensions) {
    throw "Resolved Codex application launcher type is unsupported."
}

& $ghPath auth status 1>$null 2>$null
if ($LASTEXITCODE -ne 0) {
    throw "github_cli_unauthenticated"
}

New-Item -ItemType Directory -Path $runtimeRoot -Force | Out-Null

$bootstrapTopLevelOutput = @(
    & $gitPath -C $resolvedBootstrapRepoRoot rev-parse --show-toplevel 2>$null
)
if ($LASTEXITCODE -ne 0 -or $bootstrapTopLevelOutput.Count -ne 1) {
    throw "bootstrap_repository_invalid"
}
try {
    $resolvedBootstrapTopLevel = (
        Resolve-Path -LiteralPath ([string]$bootstrapTopLevelOutput[0])
    ).Path
}
catch {
    throw "bootstrap_repository_invalid"
}
if (-not [System.StringComparer]::OrdinalIgnoreCase.Equals(
    $resolvedBootstrapRepoRoot,
    $resolvedBootstrapTopLevel
)) {
    throw "bootstrap_repository_invalid"
}

$originOutput = @(
    & $gitPath -C $resolvedBootstrapRepoRoot remote get-url origin 2>$null
)
if ($LASTEXITCODE -ne 0 -or $originOutput.Count -ne 1) {
    throw "bootstrap_repository_origin_unavailable"
}
$originUrl = ([string]$originOutput[0]).Trim()
$acceptedOrigins = @(
    "https://github.com/faliardic/chief-site-engineer.git",
    "https://github.com/faliardic/chief-site-engineer",
    "git@github.com:faliardic/chief-site-engineer.git",
    "git@github.com:faliardic/chief-site-engineer",
    "ssh://git@github.com/faliardic/chief-site-engineer.git",
    "ssh://git@github.com/faliardic/chief-site-engineer"
)
if ($originUrl -notin $acceptedOrigins) {
    throw "bootstrap_repository_origin_unexpected"
}

$controlRepoAlreadyExists = Test-Path -LiteralPath $controlRepoRoot
if ($controlRepoAlreadyExists) {
    if (-not (Test-Path -LiteralPath $configPath -PathType Leaf)) {
        throw "control_repository_role_unexpected"
    }
    try {
        $existingConfig = Get-Content -LiteralPath $configPath -Raw -Encoding UTF8 |
            ConvertFrom-Json
        $existingConfiguredRepoRoot = (
            Resolve-Path -LiteralPath ([string]$existingConfig.repo_root)
        ).Path
        $resolvedExistingControlRepoRoot = (
            Resolve-Path -LiteralPath $controlRepoRoot
        ).Path
    }
    catch {
        throw "control_repository_role_unexpected"
    }
    if (
        [string]$existingConfig.repository_role -cne "dedicated_control_clone_v1" -or
        -not [System.StringComparer]::OrdinalIgnoreCase.Equals(
            $existingConfiguredRepoRoot,
            $resolvedExistingControlRepoRoot
        )
    ) {
        throw "control_repository_role_unexpected"
    }
}
else {
    & $gitPath clone --branch master --single-branch --no-tags --no-recurse-submodules -- $originUrl $controlRepoRoot 1>$null 2>$null
    if ($LASTEXITCODE -ne 0) {
        throw "control_repository_clone_failed"
    }
}

$controlTopLevelOutput = @(
    & $gitPath -C $controlRepoRoot rev-parse --show-toplevel 2>$null
)
if ($LASTEXITCODE -ne 0 -or $controlTopLevelOutput.Count -ne 1) {
    throw "control_repository_invalid"
}
try {
    $resolvedControlRepoRoot = (Resolve-Path -LiteralPath $controlRepoRoot).Path
    $resolvedControlTopLevel = (
        Resolve-Path -LiteralPath ([string]$controlTopLevelOutput[0])
    ).Path
}
catch {
    throw "control_repository_invalid"
}
if (-not [System.StringComparer]::OrdinalIgnoreCase.Equals(
    $resolvedControlRepoRoot,
    $resolvedControlTopLevel
)) {
    throw "control_repository_invalid"
}

$controlOriginOutput = @(
    & $gitPath -C $controlRepoRoot remote get-url origin 2>$null
)
if ($LASTEXITCODE -ne 0 -or $controlOriginOutput.Count -ne 1) {
    throw "control_repository_origin_unavailable"
}
if (([string]$controlOriginOutput[0]).Trim() -notin $acceptedOrigins) {
    throw "control_repository_origin_unexpected"
}

$trackedStatus = @(
    & $gitPath -C $controlRepoRoot status --porcelain=v1 --untracked-files=no 2>$null
)
if ($LASTEXITCODE -ne 0) {
    throw "control_repository_status_failed"
}
if ($trackedStatus.Count -ne 0) {
    throw "control_repository_dirty"
}

& $gitPath -C $controlRepoRoot fetch --no-tags --no-recurse-submodules origin master 1>$null 2>$null
if ($LASTEXITCODE -ne 0) {
    throw "control_repository_fetch_failed"
}
$remoteMasterOutput = @(
    & $gitPath -C $controlRepoRoot rev-parse --verify "refs/remotes/origin/master^{commit}" 2>$null
)
if ($LASTEXITCODE -ne 0 -or $remoteMasterOutput.Count -ne 1) {
    throw "control_repository_master_unavailable"
}
$remoteMasterHead = ([string]$remoteMasterOutput[0]).Trim()

$currentHeadOutput = @(
    & $gitPath -C $controlRepoRoot rev-parse --verify "HEAD^{commit}" 2>$null
)
if ($LASTEXITCODE -ne 0 -or $currentHeadOutput.Count -ne 1) {
    throw "control_repository_head_unavailable"
}
$currentHead = ([string]$currentHeadOutput[0]).Trim()

if ($currentHead -cne $remoteMasterHead) {
    & $gitPath -C $controlRepoRoot merge-base --is-ancestor $currentHead $remoteMasterHead 1>$null 2>$null
    $ancestryExitCode = $LASTEXITCODE
    if ($ancestryExitCode -eq 1) {
        throw "control_repository_master_non_fast_forward"
    }
    if ($ancestryExitCode -ne 0) {
        throw "control_repository_master_ancestry_failed"
    }

    & $gitPath -C $controlRepoRoot switch --detach refs/remotes/origin/master 1>$null 2>$null
    if ($LASTEXITCODE -ne 0) {
        throw "control_repository_switch_failed"
    }
}
$finalHeadOutput = @(
    & $gitPath -C $controlRepoRoot rev-parse --verify "HEAD^{commit}" 2>$null
)
if ($LASTEXITCODE -ne 0 -or $finalHeadOutput.Count -ne 1) {
    throw "control_repository_final_head_unavailable"
}
if (([string]$finalHeadOutput[0]).Trim() -cne $remoteMasterHead) {
    throw "control_repository_switch_incomplete"
}
$finalTrackedStatus = @(
    & $gitPath -C $controlRepoRoot status --porcelain=v1 --untracked-files=no 2>$null
)
if ($LASTEXITCODE -ne 0) {
    throw "control_repository_status_failed"
}
if ($finalTrackedStatus.Count -ne 0) {
    throw "control_repository_dirty"
}

$runnerPath = Join-Path $resolvedControlRepoRoot "scripts\run_cse_codex_loop.ps1"
if (-not (Test-Path -LiteralPath $runnerPath -PathType Leaf)) {
    throw "control_repository_runner_missing"
}
@{
    repository = "faliardic/chief-site-engineer"
    repository_role = "dedicated_control_clone_v1"
    repo_root = $resolvedControlRepoRoot
    python_path = $pythonPath
    codex_path = $codexPath
    git_path = $gitPath
    gh_path = $ghPath
    flutter_path = $flutterPath
    allowed_base = "master"
    max_runs = 20
} | ConvertTo-Json | Set-Content -LiteralPath $configPath -Encoding UTF8

$argument = "-NoProfile -ExecutionPolicy Bypass -File `"$runnerPath`" -RuntimeRoot `"$runtimeRoot`""
$action = New-ScheduledTaskAction -Execute $powershellPath -Argument $argument -WorkingDirectory $resolvedControlRepoRoot
$trigger = New-ScheduledTaskTrigger -Once -At (Get-Date).AddMinutes(5) -RepetitionInterval (New-TimeSpan -Minutes 5)
$settings = New-ScheduledTaskSettingsSet -Disable -StartWhenAvailable -MultipleInstances IgnoreNew -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries
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

