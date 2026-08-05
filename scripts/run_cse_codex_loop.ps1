param(
    [string]$RuntimeRoot = "$env:LOCALAPPDATA\CSE-Codex-Loop",
    [int]$IssueNumber = 0,
    [switch]$Smoke
)

$ErrorActionPreference = "Stop"
$configPath = Join-Path $RuntimeRoot "config.json"

if (-not (Test-Path -LiteralPath $configPath)) {
    throw "configuration_missing"
}

$config = Get-Content -LiteralPath $configPath -Raw -Encoding UTF8 | ConvertFrom-Json
$repoRoot = [string]$config.repo_root
$pythonPath = [string]$config.python_path
$codexPath = [string]$config.codex_path
$gitPath = [string]$config.git_path
$ghPath = [string]$config.gh_path

foreach ($executable in @($pythonPath, $codexPath, $gitPath, $ghPath)) {
    if (-not $executable -or -not (Test-Path -LiteralPath $executable)) {
        throw "configured_executable_missing"
    }
}
if (-not $repoRoot -or -not (Test-Path -LiteralPath $repoRoot)) {
    throw "configured_repository_missing"
}

$pathDirectories = @(
    (Split-Path -Parent $pythonPath),
    (Split-Path -Parent $codexPath),
    (Split-Path -Parent $gitPath),
    (Split-Path -Parent $ghPath)
) | Select-Object -Unique
$env:PATH = (($pathDirectories -join ";") + ";" + $env:PATH)

$arguments = @(
    "-m",
    "tools.cse_codex_loop",
    "--runtime-root",
    $RuntimeRoot
)
if ($IssueNumber -gt 0) {
    $arguments += @("--issue-number", [string]$IssueNumber)
}
if ($Smoke) {
    $arguments += "--smoke"
}

Push-Location -LiteralPath $repoRoot
try {
    & $pythonPath @arguments
    $exitCode = $LASTEXITCODE
}
finally {
    Pop-Location
}

exit $exitCode
