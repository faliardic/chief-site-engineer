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
$runnerPath = Join-Path $RepoRoot "scripts\run_cse_bridge.ps1"

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

foreach ($command in @("python", "git", "gh")) {
    if (-not (Get-Command $command -ErrorAction SilentlyContinue)) {
        throw "Required command is unavailable: $command"
    }
}

& gh auth status 1>$null 2>$null
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
} | ConvertTo-Json | Set-Content -LiteralPath $configPath -Encoding UTF8

$argument = "-NoProfile -ExecutionPolicy Bypass -File `"$runnerPath`" -RepoRoot `"$RepoRoot`" -RuntimeRoot `"$runtimeRoot`""
$action = New-ScheduledTaskAction -Execute "powershell.exe" -Argument $argument
$trigger = New-ScheduledTaskTrigger -Once -At (Get-Date).AddMinutes(1) -RepetitionInterval (New-TimeSpan -Minutes 5)
$settings = New-ScheduledTaskSettingsSet -StartWhenAvailable -MultipleInstances IgnoreNew
Register-ScheduledTask -TaskName $taskName -Action $action -Trigger $trigger -Settings $settings -Description "CSE OpenAI API development bridge" -Force | Out-Null
Start-ScheduledTask -TaskName $taskName
Write-Host "CSE Bridge installed and started. It will check approved tasks every five minutes."
