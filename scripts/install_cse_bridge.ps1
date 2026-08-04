param(
    [string]$RepoRoot = "V:\1_PROJECTS\2_ACTIVE\Python\chief-site-engineer",
    [string]$Model = "gpt-5.1",
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
    Stop-ScheduledTask -TaskName $taskName -ErrorAction SilentlyContinue
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

Stop-ScheduledTask -TaskName $taskName -ErrorAction SilentlyContinue
Unregister-ScheduledTask -TaskName $taskName -Confirm:$false -ErrorAction SilentlyContinue
Start-Sleep -Seconds 1
Write-Host "Running one foreground bridge verification..."
& $powershellPath -NoProfile -ExecutionPolicy Bypass -File $runnerPath -RepoRoot $RepoRoot -RuntimeRoot $runtimeRoot
$verificationExit = $LASTEXITCODE
$verificationState = ""
$reason = "launcher_failure"
if (Test-Path -LiteralPath $statusPath) {
    try {
        $status = Get-Content -LiteralPath $statusPath -Raw -Encoding UTF8 | ConvertFrom-Json
        $verificationState = [string]$status.state
        if ($status.reason -and ([string]$status.reason -match "^[a-z0-9_]+$")) {
            $reason = [string]$status.reason
        }
        elseif ($verificationState -and ($verificationState -ne "PASS")) {
            $reason = "verification_not_pass"
        }
    }
    catch {
        $reason = "status_unavailable"
    }
}

if (($verificationExit -ne 0) -or ($verificationState -ne "PASS")) {
    $body = "<!-- cse-bridge-local-install:FAILED -->`nLocal CSE Bridge foreground verification failed: ``$reason``. API key and raw logs were not posted."
    & $ghPath issue comment 314 --repo "faliardic/chief-site-engineer" --body $body 1>$null 2>$null
    throw "CSE Bridge foreground verification failed: $reason. Details remain in $logPath."
}

$argument = "-NoProfile -ExecutionPolicy Bypass -File `"$runnerPath`" -RepoRoot `"$RepoRoot`" -RuntimeRoot `"$runtimeRoot`""
$action = New-ScheduledTaskAction -Execute $powershellPath -Argument $argument -WorkingDirectory $RepoRoot
$trigger = New-ScheduledTaskTrigger -Once -At (Get-Date).AddMinutes(5) -RepetitionInterval (New-TimeSpan -Minutes 5)
$settings = New-ScheduledTaskSettingsSet -StartWhenAvailable -MultipleInstances IgnoreNew
$currentIdentity = [System.Security.Principal.WindowsIdentity]::GetCurrent().Name
$principal = New-ScheduledTaskPrincipal -UserId $currentIdentity -LogonType Interactive -RunLevel Limited
Register-ScheduledTask -TaskName $taskName -Action $action -Trigger $trigger -Settings $settings -Principal $principal -Description "CSE OpenAI API development bridge" -Force | Out-Null

Remove-Item -LiteralPath $statusPath -Force -ErrorAction SilentlyContinue
$scheduledStart = (Get-Date).ToUniversalTime()
Start-ScheduledTask -TaskName $taskName
$scheduledState = ""
$scheduledReason = "scheduled_task_no_status"
for ($attempt = 0; $attempt -lt 30; $attempt++) {
    Start-Sleep -Seconds 1
    if (-not (Test-Path -LiteralPath $statusPath)) {
        continue
    }
    try {
        $scheduledStatus = Get-Content -LiteralPath $statusPath -Raw -Encoding UTF8 | ConvertFrom-Json
        $updatedAt = [DateTimeOffset]::Parse([string]$scheduledStatus.updated_at).UtcDateTime
        if ($updatedAt -lt $scheduledStart.AddSeconds(-1)) {
            continue
        }
        $scheduledState = [string]$scheduledStatus.state
        if ($scheduledStatus.reason -and ([string]$scheduledStatus.reason -match "^[a-z0-9_]+$")) {
            $scheduledReason = [string]$scheduledStatus.reason
        }
        elseif ($scheduledState -eq "FAILED") {
            $scheduledReason = "scheduled_task_failed"
        }
        break
    }
    catch {
        $scheduledReason = "scheduled_status_invalid"
    }
}

$acceptedScheduledStates = @("STARTING", "RUNNING", "PASS", "SKIPPED")
if ($acceptedScheduledStates -notcontains $scheduledState) {
    Stop-ScheduledTask -TaskName $taskName -ErrorAction SilentlyContinue
    Unregister-ScheduledTask -TaskName $taskName -Confirm:$false -ErrorAction SilentlyContinue
    $body = "<!-- cse-bridge-local-install:FAILED -->`nLocal CSE Bridge Scheduled Task verification failed: ``$scheduledReason``. API key and raw logs were not posted."
    & $ghPath issue comment 314 --repo "faliardic/chief-site-engineer" --body $body 1>$null 2>$null
    throw "CSE Bridge Scheduled Task verification failed: $scheduledReason. Details remain in $logPath."
}

$passBody = "<!-- cse-bridge-local-install:PASS -->`nLocal CSE Bridge foreground and Scheduled Task launch verification passed. The five-minute task is active."
& $ghPath issue comment 314 --repo "faliardic/chief-site-engineer" --body $passBody 1>$null 2>$null
Write-Host "CSE Bridge verified and installed. The Scheduled Task launched successfully and will repeat every five minutes."
