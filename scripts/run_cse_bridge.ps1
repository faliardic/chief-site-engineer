param(
    [string]$RepoRoot = "V:\1_PROJECTS\2_ACTIVE\Python\chief-site-engineer",
    [string]$RuntimeRoot = "$env:LOCALAPPDATA\CSE-Bridge"
)

$ErrorActionPreference = "Stop"
$credentialPath = Join-Path $RuntimeRoot "openai_api_key.xml"
$configPath = Join-Path $RuntimeRoot "config.json"
$logPath = Join-Path $RuntimeRoot "worker-last.log"
$exitCode = 1
$pointer = [IntPtr]::Zero

New-Item -ItemType Directory -Path $RuntimeRoot -Force | Out-Null
Set-Content -LiteralPath $logPath -Value ("started_at=" + (Get-Date).ToUniversalTime().ToString("o")) -Encoding UTF8

function Write-BridgeLog {
    param([string]$Value)
    Add-Content -LiteralPath $logPath -Value $Value -Encoding UTF8
}

try {
    if (-not (Test-Path -LiteralPath $credentialPath)) {
        throw "credential_missing"
    }
    if (-not (Test-Path -LiteralPath $configPath)) {
        throw "configuration_missing"
    }

    $config = Get-Content -LiteralPath $configPath -Raw -Encoding UTF8 | ConvertFrom-Json
    $pythonPath = [string]$config.python_path
    $gitPath = [string]$config.git_path
    $ghPath = [string]$config.gh_path
    foreach ($executable in @($pythonPath, $gitPath, $ghPath)) {
        if (-not $executable -or -not (Test-Path -LiteralPath $executable)) {
            throw "configured_executable_missing"
        }
    }

    $pathDirectories = @(
        (Split-Path -Parent $pythonPath),
        (Split-Path -Parent $gitPath),
        (Split-Path -Parent $ghPath)
    ) | Select-Object -Unique
    $env:PATH = (($pathDirectories -join ";") + ";" + $env:PATH)

    $secureKey = Import-Clixml -LiteralPath $credentialPath
    $pointer = [Runtime.InteropServices.Marshal]::SecureStringToBSTR($secureKey)
    $env:OPENAI_API_KEY = [Runtime.InteropServices.Marshal]::PtrToStringBSTR($pointer)
    $env:CSE_BRIDGE_MODEL = [string]$config.model
    $env:CSE_BRIDGE_REPO_ROOT = $RepoRoot

    Push-Location -LiteralPath $RepoRoot
    try {
        $output = & $pythonPath -m tools.cse_bridge_local --repo-root $RepoRoot --runtime-root $RuntimeRoot 2>&1
        $exitCode = $LASTEXITCODE
        foreach ($line in $output) {
            Write-BridgeLog ([string]$line)
        }
        Write-BridgeLog ("exit_code=" + $exitCode)
    }
    finally {
        Pop-Location
    }
}
catch {
    Write-BridgeLog "launcher_error=launcher_failure"
    Write-Error $_.Exception.Message
    $exitCode = 1
}
finally {
    $env:OPENAI_API_KEY = $null
    $env:CSE_BRIDGE_MODEL = $null
    $env:CSE_BRIDGE_REPO_ROOT = $null
    if ($pointer -ne [IntPtr]::Zero) {
        [Runtime.InteropServices.Marshal]::ZeroFreeBSTR($pointer)
    }
    Write-BridgeLog ("finished_at=" + (Get-Date).ToUniversalTime().ToString("o"))
}

exit $exitCode
