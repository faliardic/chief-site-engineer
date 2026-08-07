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
$repositoryRole = [string]$config.repository_role
$expectedRepoRoot = Join-Path $RuntimeRoot "control-repo"

if ($repositoryRole -cne "dedicated_control_clone_v1") {
    throw "runtime_control_clone_unconfigured"
}
if (
    -not $repoRoot -or
    -not (Test-Path -LiteralPath $repoRoot -PathType Container) -or
    -not (Test-Path -LiteralPath $expectedRepoRoot -PathType Container)
) {
    throw "runtime_control_clone_unconfigured"
}
try {
    $resolvedRepoRoot = (Resolve-Path -LiteralPath $repoRoot).Path
    $resolvedExpectedRepoRoot = (Resolve-Path -LiteralPath $expectedRepoRoot).Path
}
catch {
    throw "runtime_control_clone_unconfigured"
}
if (-not [System.StringComparer]::OrdinalIgnoreCase.Equals(
    $resolvedRepoRoot,
    $resolvedExpectedRepoRoot
)) {
    throw "runtime_control_clone_unconfigured"
}
$repoRoot = $resolvedRepoRoot

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

$trackedStatus = @(
    & $gitPath -C $repoRoot status --porcelain=v1 --untracked-files=no 2>$null
)
if ($LASTEXITCODE -ne 0) {
    throw "runtime_repository_status_failed"
}
if ($trackedStatus.Count -ne 0) {
    throw "runtime_repository_dirty"
}

& $gitPath -C $repoRoot fetch --no-tags --no-recurse-submodules origin master 1>$null 2>$null
if ($LASTEXITCODE -ne 0) {
    throw "runtime_master_fetch_failed"
}

$currentHeadOutput = @(
    & $gitPath -C $repoRoot rev-parse --verify "HEAD^{commit}" 2>$null
)
if ($LASTEXITCODE -ne 0 -or $currentHeadOutput.Count -ne 1) {
    throw "runtime_head_unavailable"
}
$currentHead = ([string]$currentHeadOutput[0]).Trim()

$remoteMasterOutput = @(
    & $gitPath -C $repoRoot rev-parse --verify "refs/remotes/origin/master^{commit}" 2>$null
)
if ($LASTEXITCODE -ne 0 -or $remoteMasterOutput.Count -ne 1) {
    throw "runtime_master_unavailable"
}
$remoteMasterHead = ([string]$remoteMasterOutput[0]).Trim()

if ($currentHead -cne $remoteMasterHead) {
    & $gitPath -C $repoRoot merge-base --is-ancestor $currentHead $remoteMasterHead 1>$null 2>$null
    $ancestryExitCode = $LASTEXITCODE
    if ($ancestryExitCode -eq 1) {
        throw "runtime_master_non_fast_forward"
    }
    if ($ancestryExitCode -ne 0) {
        throw "runtime_master_ancestry_failed"
    }

    & $gitPath -C $repoRoot switch --detach refs/remotes/origin/master 1>$null 2>$null
    if ($LASTEXITCODE -ne 0) {
        throw "runtime_master_switch_failed"
    }
}

$finalHeadOutput = @(
    & $gitPath -C $repoRoot rev-parse --verify "HEAD^{commit}" 2>$null
)
if ($LASTEXITCODE -ne 0 -or $finalHeadOutput.Count -ne 1) {
    throw "runtime_final_head_unavailable"
}
if (([string]$finalHeadOutput[0]).Trim() -cne $remoteMasterHead) {
    throw "runtime_master_switch_incomplete"
}
$finalTrackedStatus = @(
    & $gitPath -C $repoRoot status --porcelain=v1 --untracked-files=no 2>$null
)
if ($LASTEXITCODE -ne 0) {
    throw "runtime_repository_status_failed"
}
if ($finalTrackedStatus.Count -ne 0) {
    throw "runtime_repository_dirty"
}

$pathDirectories = @(
    (Split-Path -Parent $pythonPath),
    (Split-Path -Parent $codexPath),
    (Split-Path -Parent $gitPath),
    (Split-Path -Parent $ghPath)
) | Select-Object -Unique
$env:PATH = (($pathDirectories -join ";") + ";" + $env:PATH)

# The selected commit may replace this file on disk. This process deliberately
# continues without dot-sourcing, restarting, or re-entering the runner.
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
