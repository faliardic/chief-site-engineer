[CmdletBinding()]
param(
    [string]$FlutterCommand = $(
        if ($env:CSE_FLUTTER_COMMAND) { $env:CSE_FLUTTER_COMMAND } else { 'flutter' }
    ),
    [string]$AndroidDevice = 'R5CY21WKZFX',
    [string]$RunId = [DateTime]::Now.ToString('yyyyMMddHHmmss')
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

$productionPackage = 'com.faliardic.chiefsiteengineer.debug'
$acceptancePackage = 'com.faliardic.chiefsiteengineer.acceptance'
$normalMarker = 'CSE_ENTRYPOINT_NORMAL_LIB_MAIN_DART_V1'
$acceptanceMarker = 'CSE_ENTRYPOINT_ISSUE252_SMOKE_ACCEPTANCE_V1'
$repositoryRoot = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$mobileRoot = Join-Path $repositoryRoot 'mobile'
$artifactRoot = Join-Path $mobileRoot 'build\release_gate'
$androidSdk = if ($env:ANDROID_HOME) {
    $env:ANDROID_HOME
} else {
    Join-Path $env:LOCALAPPDATA 'Android\Sdk'
}
$adb = Join-Path $androidSdk 'platform-tools\adb.exe'
$aapt2 = Join-Path $androidSdk 'build-tools\36.0.0\aapt2.exe'
$entrypointVerifier = Join-Path $repositoryRoot 'scripts\verify_flutter_apk_entrypoint.py'
$normalArtifact = Join-Path $artifactRoot 'chief-site-engineer-0.1.0-issue212-reminder-pilot-ux-debug.apk'
$installedAcceptanceArtifact = Join-Path $artifactRoot 'chief-site-engineer-0.1.0-issue254-physical-smoke-installed.apk'
$previousAcceptanceHarness = $env:CSE_ACCEPTANCE_HARNESS

function Invoke-Checked {
    param([string]$Command, [string[]]$Arguments)
    & $Command @Arguments
    if ($LASTEXITCODE -ne 0) {
        throw "Command failed with exit code ${LASTEXITCODE}: $Command"
    }
}

function Invoke-AdbText {
    param([string[]]$Arguments)
    $output = (& $adb -s $AndroidDevice @Arguments 2>&1) -join "`n"
    if ($LASTEXITCODE -ne 0) {
        throw "ADB command failed for the selected physical device."
    }
    return $output.Trim()
}

function Read-RequiredMatch {
    param(
        [string]$Text,
        [string]$Pattern,
        [string]$Label
    )
    $match = [regex]::Match($Text, $Pattern, [Text.RegularExpressions.RegexOptions]::Multiline)
    if (-not $match.Success) {
        throw "Production package snapshot is missing $Label."
    }
    return $match.Groups[1].Value.Trim()
}

function Get-ProcessIdentity {
    param([string]$PackageName)
    $output = (& $adb -s $AndroidDevice shell pidof $PackageName 2>$null) -join ' '
    if ($LASTEXITCODE -notin @(0, 1)) {
        throw "Production process identity could not be read."
    }
    return $output.Trim()
}

function Get-ProductionSnapshot {
    $codePath = Invoke-AdbText -Arguments @('shell', 'pm', 'path', $productionPackage)
    if ($codePath -notmatch '^package:/.+/base\.apk$') {
        throw 'Production debug package is not installed with a verifiable code path.'
    }
    $dump = Invoke-AdbText -Arguments @('shell', 'dumpsys', 'package', $productionPackage)
    return [ordered]@{
        applicationId = $productionPackage
        codePath = $codePath
        versionCode = Read-RequiredMatch -Text $dump -Pattern 'versionCode=(\d+)' -Label 'versionCode'
        versionName = Read-RequiredMatch -Text $dump -Pattern 'versionName=([^\r\n]+)' -Label 'versionName'
        firstInstallTime = Read-RequiredMatch -Text $dump -Pattern 'firstInstallTime=([^\r\n]+)' -Label 'firstInstallTime'
        lastUpdateTime = Read-RequiredMatch -Text $dump -Pattern 'lastUpdateTime=([^\r\n]+)' -Label 'lastUpdateTime'
        dataDirectory = Read-RequiredMatch -Text $dump -Pattern 'dataDir=([^\r\n]+)' -Label 'dataDir'
        ceDataInode = Read-RequiredMatch -Text $dump -Pattern 'ceDataInode=(\d+)' -Label 'ceDataInode'
        deDataInode = Read-RequiredMatch -Text $dump -Pattern 'deDataInode=(\d+)' -Label 'deDataInode'
        processId = Get-ProcessIdentity -PackageName $productionPackage
    }
}

function Assert-SameProductionSnapshot {
    param(
        [Collections.Specialized.OrderedDictionary]$Before,
        [Collections.Specialized.OrderedDictionary]$After
    )
    foreach ($key in $Before.Keys) {
        if ($Before[$key] -ne $After[$key]) {
            throw "Production package metadata changed at $key."
        }
    }
}

function Assert-ApkIdentity {
    param(
        [string]$Apk,
        [string]$ExpectedPackage,
        [string]$ExpectedMarker,
        [string[]]$ForbiddenMarkers
    )
    if (-not (Test-Path -LiteralPath $Apk)) {
        throw "Required APK artifact was not found."
    }
    $package = (& $aapt2 dump packagename $Apk 2>&1) -join "`n"
    if ($LASTEXITCODE -ne 0 -or $package.Trim() -ne $ExpectedPackage) {
        throw "APK applicationId isolation verification failed."
    }
    $arguments = @(
        $entrypointVerifier,
        '--apk', $Apk,
        '--expected-marker', $ExpectedMarker
    )
    foreach ($marker in $ForbiddenMarkers) {
        $arguments += @('--forbidden-marker', $marker)
    }
    Invoke-Checked -Command 'python' -Arguments $arguments
}

function Invoke-SmokePhase {
    param([string]$ExpectedPassMarker)
    Push-Location $mobileRoot
    try {
        $arguments = @(
            'test',
            '--no-pub',
            "--dart-define=CSE_ISSUE254_RUN_ID=$RunId",
            'integration_test\issue252_physical_smoke_test.dart',
            '-d', $AndroidDevice
        )
        $lines = & $FlutterCommand @arguments 2>&1
        $exitCode = $LASTEXITCODE
        foreach ($line in $lines) { Write-Host $line }
        if ($exitCode -ne 0) {
            throw "Issue 252 physical smoke phase failed with exit code $exitCode."
        }
        if (($lines -join "`n") -notmatch [regex]::Escape($ExpectedPassMarker)) {
            throw "Issue 252 physical smoke phase did not emit its PASS marker."
        }
    } finally {
        Pop-Location
    }
}

try {
    if ($RunId -notmatch '^\d{14}$') {
        throw 'RunId must contain exactly 14 digits.'
    }
    if (-not (Test-Path -LiteralPath $adb) -or
        -not (Test-Path -LiteralPath $aapt2)) {
        throw 'Android platform/build tools 36.0.0 were not found.'
    }
    if ((Invoke-AdbText -Arguments @('get-state')) -ne 'device') {
        throw 'Selected physical Android device is not ready.'
    }

    Assert-ApkIdentity `
        -Apk $normalArtifact `
        -ExpectedPackage $productionPackage `
        -ExpectedMarker $normalMarker `
        -ForbiddenMarkers @(
            'CSE_ENTRYPOINT_BACKGROUND_ACCEPTANCE_V1',
            'CSE_ENTRYPOINT_REBOOT_ACCEPTANCE_V1',
            $acceptanceMarker
        )

    $before = Get-ProductionSnapshot
    $env:CSE_ACCEPTANCE_HARNESS = 'true'
    Invoke-SmokePhase -ExpectedPassMarker 'CSE_ISSUE254_PHASE1_PASS'

    $installedPackagePath = Invoke-AdbText -Arguments @(
        'shell', 'pm', 'path', $acceptancePackage
    )
    if ($installedPackagePath -notmatch '^package:(/.+/base\.apk)$') {
        throw 'Acceptance package code path could not be resolved.'
    }
    $remoteAcceptanceApk = $Matches[1]

    Invoke-AdbText -Arguments @('shell', 'input', 'keyevent', 'KEYCODE_HOME') | Out-Null
    Invoke-AdbText -Arguments @('shell', 'am', 'kill', $acceptancePackage) | Out-Null
    if ((Get-ProcessIdentity -PackageName $acceptancePackage) -ne '') {
        throw 'Acceptance package process did not stop for the restart boundary.'
    }

    Invoke-SmokePhase -ExpectedPassMarker 'CSE_ISSUE254_PHASE2_PASS'

    New-Item -ItemType Directory -Force -Path $artifactRoot | Out-Null
    Invoke-Checked -Command $adb -Arguments @(
        '-s', $AndroidDevice, 'pull', $remoteAcceptanceApk,
        $installedAcceptanceArtifact
    )
    Assert-ApkIdentity `
        -Apk $installedAcceptanceArtifact `
        -ExpectedPackage $acceptancePackage `
        -ExpectedMarker $acceptanceMarker `
        -ForbiddenMarkers @(
            $normalMarker,
            'CSE_ENTRYPOINT_BACKGROUND_ACCEPTANCE_V1',
            'CSE_ENTRYPOINT_REBOOT_ACCEPTANCE_V1'
        )

    $after = Get-ProductionSnapshot
    Assert-SameProductionSnapshot -Before $before -After $after

    $checksum = (
        Get-FileHash -LiteralPath $installedAcceptanceArtifact -Algorithm SHA256
    ).Hash.ToLowerInvariant()
    Write-Output 'Physical device smoke: PASS'
    Write-Output "ApplicationId: $acceptancePackage"
    Write-Output "Artifact SHA-256: $checksum"
    Write-Output "Synthetic run: $RunId"
    Write-Output 'Production debug package metadata/process/data inodes: unchanged'
} finally {
    $env:CSE_ACCEPTANCE_HARNESS = $previousAcceptanceHarness
}
