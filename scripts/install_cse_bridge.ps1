param(
    [string]$RepoRoot = "V:\1_PROJECTS\2_ACTIVE\Python\chief-site-engineer",
    [string]$Model = "gpt-5.1-codex",
    [switch]$ResetKey,
    [switch]$Uninstall
)

$ErrorActionPreference = "Stop"
$taskName = "CSE Bridge"
$runtimeRoot = Join-Path $env:LOCALAPPDATA "CSE-Bridge"
$credentialPath = Join-Path $runtimeRoot "openai_api_key.xml"
$configPath = Join-Path $runtimeRoot "config.json"
$statusPath = Join-Path $runtimeRoot "worker-status.json"
$logPath = Join-Path $runtimeRoot "worker-last.log"
$runnerPath = Join-Path $RepoRoot "scripts\run_cse_bridge.ps1"
$powershellPath = Join-Path $PSHOME "powershell.exe"

if ($Uninstall) {
    Unregister-ScheduledTask -TaskName $taskName -Confirm:$false -ErrorAction SilentlyContinue
    Write-Host "CSE Bridge scheduled task removed. Credentials were preserved in $runtimeRoot."
    exit 0
}

if (-not (Test-Path -LiteralPath $RepoRoot)) {
    throw "Repository not found: $RepoRoot"
}
if (-not (Test-Path -LiteralPath $runnerPath)) {
    throw "Bridge runner not found: $runnerPath"
}

$pythonCommand = Get-Command python -ErrorAction SilentlyContinue
$gitCommand = Get-Command git -ErrorAction SilentlyContinue
$ghCommand = Get-Command gh -ErrorAction SilentlyContinue
foreach ($entry in @(
    @{ Name = "python"; Command = $pythonCommand },
    @{ Name = "git"; Command = $gitCommand },
    @{ Name = "gh"; Command = $ghCommand }
)) {
    if (-not $entry.Command -or -not $entry.Command.Source) {
        throw ("Required command is unavailable: " + $entry.Name)
    }
}

$pythonPath = [string]$pythonCommand.Source
$gitPath = [string]$gitCommand.Source
$ghPath = [string]$ghCommand.Source

& $ghPath auth status 1>$null 2>$null
if ($LASTEXITCODE -ne 0) {
    throw "GitHub CLI is not authenticated. Run gh auth login once."
}

New-Item -ItemType Directory -Path $runtimeRoot -Force | Out-Null
if ($ResetKey -or -not (Test-Path -LiteralPath $credentialPath)) {
    $secureKey = Read-Host "OpenAI API key" -AsSecureString
    $secureKey | Export-Clixml -LiteralPath $credentialPath
}

@{
    model = $Model
    repository = "faliardic/chief-site-engineer"
    repo_root = $RepoRoot
    python_path = $pythonPath
    git_path = $gitPath
    gh_path = $ghPath
} | ConvertTo-Json | Set-Content -LiteralPath $configPath -Encoding UTF8

Unregister-ScheduledTask -TaskName $taskName -Confirm:$false -ErrorAction SilentlyContinue
Write-Host "Running one foreground bridge verification..."
& $powershellPath -NoProfile -ExecutionPolicy Bypass -File $runnerPath -RepoRoot $RepoRoot -RuntimeRoot $runtimeRoot
$verificationExit = $LASTEXITCODE

if ($verificationExit -ne 0) {
    $reason = "launcher_failure"
    if (Test-Path -LiteralPath $statusPath) {
        try {
            $status = Get-Content -LiteralPath $statusPath -Raw -Encoding UTF8 | ConvertFrom-Json
            if ($status.reason -and ([string]$status.reason -match "^[a-z0-9_]+$")) {
                $reason = [string]$status.reason
            }
        }
        catch {
            $reason = "status_unavailable"
        }
    }
    $body = "<!-- cse-bridge-local-install:FAILED -->`nLocal CSE Bridge verification failed: ``$reason``. API key and raw logs were not posted."
    & $ghPath issue comment 314 --repo "faliardic/chief-site-engineer" --body $body 1>$null 2>$null
    throw "CSE Bridge verification failed: $reason. Details remain in $logPath."
}

$argument = "-NoProfile -ExecutionPolicy Bypass -File `"$runnerPath`" -RepoRoot `"$RepoRoot`" -RuntimeRoot `"$runtimeRoot`""
$action = New-ScheduledTaskAction -Execute $powershellPath -Argument $argument -WorkingDirectory $RepoRoot
$trigger = New-ScheduledTaskTrigger -Once -At (Get-Date).AddMinutes(5) -RepetitionInterval (New-TimeSpan -Minutes 5)
$settings = New-ScheduledTaskSettingsSet -StartWhenAvailable -MultipleInstances IgnoreNew
Register-ScheduledTask -TaskName $taskName -Action $action -Trigger $trigger -Settings $settings -Description "CSE OpenAI API development bridge" -Force | Out-Null

$passBody = "<!-- cse-bridge-local-install:PASS -->`nLocal CSE Bridge foreground verification passed. The five-minute Scheduled Task is registered."
& $ghPath issue comment 314 --repo "faliardic/chief-site-engineer" --body $passBody 1>$null 2>$null
Write-Host "CSE Bridge verified and installed. It will check approved tasks every five minutes."
