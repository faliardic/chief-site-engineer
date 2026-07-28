[CmdletBinding()]
param(
    [string]$FlutterCommand = $(
        if ($env:CSE_FLUTTER_COMMAND) { $env:CSE_FLUTTER_COMMAND } else { 'flutter' }
    )
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

$repositoryRoot = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$mobileRoot = Join-Path $repositoryRoot 'mobile'
$artifactRoot = Join-Path $mobileRoot 'build\release_gate'
$androidSdk = if ($env:ANDROID_HOME) {
    $env:ANDROID_HOME
} else {
    Join-Path $env:LOCALAPPDATA 'Android\Sdk'
}
$aapt2 = Join-Path $androidSdk 'build-tools\36.0.0\aapt2.exe'
$normalSidecar = Join-Path $artifactRoot 'chief-site-engineer-0.1.0-issue212-reminder-pilot-ux-debug.apk'
$normalSidecarExisted = Test-Path -LiteralPath $normalSidecar
$normalSidecarHash = if ($normalSidecarExisted) {
    (Get-FileHash -LiteralPath $normalSidecar -Algorithm SHA256).Hash
} else {
    $null
}
$previousAcceptanceHarness = $env:CSE_ACCEPTANCE_HARNESS

function Invoke-Checked {
    param([string]$Command, [string[]]$Arguments)
    & $Command @Arguments
    if ($LASTEXITCODE -ne 0) {
        throw "Command failed with exit code ${LASTEXITCODE}: $Command"
    }
}

function Invoke-Flutter {
    param([string[]]$Arguments)
    Push-Location $mobileRoot
    try {
        Invoke-Checked -Command $FlutterCommand -Arguments $Arguments
    } finally {
        Pop-Location
    }
}

function Clear-GeneratedReadOnlyAttributes {
    $attrib = Join-Path $env:SystemRoot 'System32\attrib.exe'
    foreach ($generatedRoot in @(
        (Join-Path $mobileRoot 'build'),
        (Join-Path $mobileRoot '.dart_tool'),
        (Join-Path $mobileRoot 'ios\Flutter\ephemeral')
    )) {
        if (-not (Test-Path -LiteralPath $generatedRoot)) { continue }
        Invoke-Checked -Command $attrib -Arguments @('-R', $generatedRoot)
        Invoke-Checked -Command $attrib -Arguments @(
            '-R', (Join-Path $generatedRoot '*'), '/S', '/D'
        )
    }
}

function Build-AcceptanceApk {
    param(
        [string]$Target,
        [string]$ExpectedMarker,
        [string[]]$ForbiddenMarkers,
        [string]$OutputName
    )
    $sharedOutput = Join-Path $mobileRoot 'build\app\outputs\flutter-apk\app-debug.apk'
    $started = [DateTime]::UtcNow.AddSeconds(-2)
    Clear-GeneratedReadOnlyAttributes
    Invoke-Flutter -Arguments @(
        'build', 'apk', '--debug', '--target', $Target,
        '--target-platform', 'android-arm64,android-x64'
    )
    if (-not (Test-Path -LiteralPath $sharedOutput) -or
        (Get-Item -LiteralPath $sharedOutput).LastWriteTimeUtc -lt $started) {
        throw "Acceptance APK was not freshly produced for target $Target."
    }
    $verificationArguments = @(
        (Join-Path $repositoryRoot 'scripts\verify_flutter_apk_entrypoint.py'),
        '--apk', $sharedOutput,
        '--expected-marker', $ExpectedMarker,
        '--forbidden-marker', 'CSE_ENTRYPOINT_NORMAL_LIB_MAIN_DART_V1'
    )
    foreach ($marker in $ForbiddenMarkers) {
        $verificationArguments += @('--forbidden-marker', $marker)
    }
    Invoke-Checked -Command 'python' -Arguments $verificationArguments
    $package = (& $aapt2 dump packagename $sharedOutput 2>&1) -join "`n"
    if ($LASTEXITCODE -ne 0 -or
        $package.Trim() -ne 'com.faliardic.chiefsiteengineer.acceptance') {
        throw 'Synthetic acceptance APK package isolation verification failed.'
    }
    New-Item -ItemType Directory -Force -Path $artifactRoot | Out-Null
    $destination = Join-Path $artifactRoot $OutputName
    Copy-Item -LiteralPath $sharedOutput -Destination $destination -Force
    $artifactVerificationArguments = @(
        (Join-Path $repositoryRoot 'scripts\verify_flutter_apk_entrypoint.py'),
        '--apk', $destination,
        '--expected-marker', $ExpectedMarker,
        '--forbidden-marker', 'CSE_ENTRYPOINT_NORMAL_LIB_MAIN_DART_V1'
    )
    foreach ($marker in $ForbiddenMarkers) {
        $artifactVerificationArguments += @('--forbidden-marker', $marker)
    }
    Invoke-Checked -Command 'python' -Arguments $artifactVerificationArguments
    $checksum = (Get-FileHash -LiteralPath $destination -Algorithm SHA256).Hash.ToLowerInvariant()
    Write-Output "$OutputName SHA256: $checksum"
}

try {
    if (-not (Test-Path -LiteralPath $aapt2)) {
        throw 'Android aapt2 36.0.0 was not found.'
    }
    $env:CSE_ACCEPTANCE_HARNESS = 'true'
    Clear-GeneratedReadOnlyAttributes
    Invoke-Flutter -Arguments @('pub', 'get')
    Build-AcceptanceApk `
        -Target 'integration_test\background_delivery_sidecar_main.dart' `
        -ExpectedMarker 'CSE_ENTRYPOINT_BACKGROUND_ACCEPTANCE_V1' `
        -ForbiddenMarkers @(
            'CSE_ENTRYPOINT_REBOOT_ACCEPTANCE_V1',
            'CSE_ENTRYPOINT_ISSUE252_SMOKE_ACCEPTANCE_V1'
        ) `
        -OutputName 'chief-site-engineer-0.1.0-issue207-background-acceptance-debug.apk'
    Build-AcceptanceApk `
        -Target 'integration_test\background_reboot_sidecar_main.dart' `
        -ExpectedMarker 'CSE_ENTRYPOINT_REBOOT_ACCEPTANCE_V1' `
        -ForbiddenMarkers @(
            'CSE_ENTRYPOINT_BACKGROUND_ACCEPTANCE_V1',
            'CSE_ENTRYPOINT_ISSUE252_SMOKE_ACCEPTANCE_V1'
        ) `
        -OutputName 'chief-site-engineer-0.1.0-issue207-reboot-acceptance-debug.apk'
    Build-AcceptanceApk `
        -Target 'integration_test\issue252_physical_smoke_test.dart' `
        -ExpectedMarker 'CSE_ENTRYPOINT_ISSUE252_SMOKE_ACCEPTANCE_V1' `
        -ForbiddenMarkers @(
            'CSE_ENTRYPOINT_BACKGROUND_ACCEPTANCE_V1',
            'CSE_ENTRYPOINT_REBOOT_ACCEPTANCE_V1'
        ) `
        -OutputName 'chief-site-engineer-0.1.0-issue254-physical-smoke-acceptance-debug.apk'

    if ($normalSidecarExisted) {
        $currentHash = (Get-FileHash -LiteralPath $normalSidecar -Algorithm SHA256).Hash
        if ($currentHash -ne $normalSidecarHash) {
            throw 'Synthetic acceptance build changed the normal field sidecar artifact.'
        }
    } elseif (Test-Path -LiteralPath $normalSidecar) {
        throw 'Synthetic acceptance build unexpectedly created the normal field sidecar.'
    }
    Write-Output 'CSE synthetic acceptance APK build passed without changing the field sidecar.'
} finally {
    $env:CSE_ACCEPTANCE_HARNESS = $previousAcceptanceHarness
}
