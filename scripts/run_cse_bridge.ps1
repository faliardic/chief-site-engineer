param(
    [string]$RepoRoot = "V:\1_PROJECTS\2_ACTIVE\Python\chief-site-engineer",
    [string]$RuntimeRoot = "$env:LOCALAPPDATA\CSE-Bridge"
)

$ErrorActionPreference = "Stop"
$credentialPath = Join-Path $RuntimeRoot "openai_api_key.xml"
$configPath = Join-Path $RuntimeRoot "config.json"

if (-not (Test-Path -LiteralPath $credentialPath)) {
    throw "CSE Bridge OpenAI credential is not installed."
}
if (-not (Test-Path -LiteralPath $configPath)) {
    throw "CSE Bridge configuration is not installed."
}

$secureKey = Import-Clixml -LiteralPath $credentialPath
$pointer = [Runtime.InteropServices.Marshal]::SecureStringToBSTR($secureKey)
try {
    $env:OPENAI_API_KEY = [Runtime.InteropServices.Marshal]::PtrToStringBSTR($pointer)
    $config = Get-Content -LiteralPath $configPath -Raw -Encoding UTF8 | ConvertFrom-Json
    $env:CSE_BRIDGE_MODEL = [string]$config.model
    $env:CSE_BRIDGE_REPO_ROOT = $RepoRoot
    Push-Location -LiteralPath $RepoRoot
    try {
        & python -m tools.cse_bridge_local --repo-root $RepoRoot --runtime-root $RuntimeRoot
        exit $LASTEXITCODE
    }
    finally {
        Pop-Location
    }
}
finally {
    $env:OPENAI_API_KEY = $null
    $env:CSE_BRIDGE_MODEL = $null
    [Runtime.InteropServices.Marshal]::ZeroFreeBSTR($pointer)
}
