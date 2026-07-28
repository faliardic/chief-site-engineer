[CmdletBinding()]
param(
    [string]$FlutterCommand = $(
        if ($env:CSE_FLUTTER_COMMAND) { $env:CSE_FLUTTER_COMMAND } else { 'flutter' }
    ),
    [string]$BundletoolJar = $env:CSE_BUNDLETOOL_JAR,
    [string]$AndroidDevice = 'emulator-5554',
    [switch]$SkipIntegration,
    [switch]$SkipPython,
    [switch]$SkipSignedArtifacts,
    [switch]$SkipFlutterValidation,
    [switch]$IncludeAcceptanceArtifacts,
    [switch]$RunIssue254PhysicalSmoke,
    [switch]$RunIsolatedFlutterCommand,
    [string]$BuildKind,
    [string]$BuildRunId,
    [string[]]$FlutterArguments,
    [string]$AdbCommand,
    [switch]$RunVerifiedAcceptanceSmokeOnly,
    [string]$VerifiedAcceptanceArtifactPath,
    [string]$VerifiedAcceptanceSha256,
    [long]$VerifiedAcceptanceLength,
    [long]$VerifiedAcceptanceLastWriteUtcTicks,
    [string]$AcceptanceRunId
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
$adb = if ($AdbCommand) {
    $AdbCommand
} else {
    Join-Path $androidSdk 'platform-tools\adb.exe'
}
$zipalign = Join-Path $androidSdk 'build-tools\36.0.0\zipalign.exe'
$apksigner = Join-Path $androidSdk 'build-tools\36.0.0\apksigner.bat'
$aapt2 = Join-Path $androidSdk 'build-tools\36.0.0\aapt2.exe'
$temporaryRoot = $null
$temporarySidecarApk = $null
$artifactWorkRoot = $null
$verifiedIssue254Artifact = $null
$issue252AcceptanceMarker = 'CSE_ENTRYPOINT_ISSUE252_SMOKE_ACCEPTANCE_V1'
$gateRunId = "{0}-{1}" -f (
    [DateTime]::UtcNow.ToString('yyyyMMddHHmmssfffffff')
), [guid]::NewGuid().ToString('N').Substring(0, 8)
$buildSequence = 0
$previousSigningFile = $env:CSE_KEY_PROPERTIES_FILE
$previousSigningRequired = $env:CSE_REQUIRE_SIGNING
$previousAcceptanceHarness = $env:CSE_ACCEPTANCE_HARNESS
$previousArtifactStagingRoot = $env:CSE_RELEASE_GATE_ARTIFACT_STAGING_ROOT

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

function Assert-SafeBuildRootSegment {
    param(
        [string]$Value,
        [string]$Label
    )
    if (-not $Value -or $Value -notmatch '^[a-z0-9][a-z0-9-]{0,95}$') {
        throw "$Label must contain only lowercase ASCII letters, digits, and hyphens."
    }
}

function Assert-SafeArtifactStagingRoot {
    param([string]$Path)
    $fullPath = [IO.Path]::GetFullPath($Path)
    $systemTemporaryRoot = [IO.Path]::GetFullPath([IO.Path]::GetTempPath())
    if (-not $fullPath.StartsWith(
        $systemTemporaryRoot,
        [StringComparison]::OrdinalIgnoreCase
    ) -or -not ([IO.Path]::GetFileName($fullPath)).StartsWith(
        'cse-release-gate-artifacts-',
        [StringComparison]::OrdinalIgnoreCase
    )) {
        throw 'Refusing to use an unexpected release-gate artifact staging directory.'
    }
    return $fullPath
}

function Copy-CurrentReleaseGateArtifactsToStaging {
    $stagingRoot = $env:CSE_RELEASE_GATE_ARTIFACT_STAGING_ROOT
    if (-not $stagingRoot) { return }
    $resolvedStagingRoot = Assert-SafeArtifactStagingRoot -Path $stagingRoot
    if (-not (Test-Path -LiteralPath $resolvedStagingRoot -PathType Container)) {
        throw 'Release-gate artifact staging directory does not exist.'
    }
    $currentArtifactRoot = Join-Path $mobileRoot 'build\release_gate'
    if (-not (Test-Path -LiteralPath $currentArtifactRoot -PathType Container)) {
        return
    }
    Get-ChildItem -LiteralPath $currentArtifactRoot -File | ForEach-Object {
        Copy-Item -LiteralPath $_.FullName -Destination $resolvedStagingRoot -Force
    }
}

function Move-ExistingFlutterBuildRoot {
    param(
        [string]$Kind,
        [string]$RunId
    )
    Assert-SafeBuildRootSegment -Value $Kind -Label 'BuildKind'
    Assert-SafeBuildRootSegment -Value $RunId -Label 'BuildRunId'
    $buildRoot = Join-Path $mobileRoot 'build'
    if (-not (Test-Path -LiteralPath $buildRoot -PathType Container)) {
        return
    }
    $quarantineName = 'build.release-gate-{0}-{1}-stale' -f $Kind, $RunId
    $quarantineRoot = Join-Path $mobileRoot $quarantineName
    if (Test-Path -LiteralPath $quarantineRoot) {
        throw "Flutter build-root quarantine target already exists: $quarantineName"
    }
    Copy-CurrentReleaseGateArtifactsToStaging
    try {
        [IO.Directory]::Move($buildRoot, $quarantineRoot)
    } catch {
        throw "Atomic Flutter build-root rotation failed before Flutter start: $($_.Exception.Message)"
    }
    Write-Output "Flutter build root rotated atomically: $quarantineName"
}

function New-BuildInvocationId {
    $script:buildSequence += 1
    return '{0}-{1:d3}' -f $gateRunId, $script:buildSequence
}

function Invoke-IsolatedFlutterBuild {
    param(
        [string]$Kind,
        [string[]]$Arguments,
        [string]$ExpectedOutput,
        [string]$StaleOutputMessage = 'Atomic build-root rotation left a stale Flutter output.'
    )
    $runId = New-BuildInvocationId
    Move-ExistingFlutterBuildRoot -Kind $Kind -RunId $runId
    if ($ExpectedOutput -and (Test-Path -LiteralPath $ExpectedOutput)) {
        throw $StaleOutputMessage
    }
    $started = [DateTime]::UtcNow.AddSeconds(-2)
    Invoke-Flutter -Arguments $Arguments
    if ($ExpectedOutput -and (
        -not (Test-Path -LiteralPath $ExpectedOutput -PathType Leaf) -or
        (Get-Item -LiteralPath $ExpectedOutput).LastWriteTimeUtc -lt $started
    )) {
        throw "Flutter output was not freshly produced by build kind $Kind."
    }
}

function Publish-ReleaseGateArtifacts {
    if (-not $artifactWorkRoot -or
        -not (Test-Path -LiteralPath $artifactWorkRoot -PathType Container)) {
        throw 'Release-gate artifact work directory is unavailable.'
    }
    New-Item -ItemType Directory -Force -Path $artifactRoot | Out-Null
    Get-ChildItem -LiteralPath $artifactWorkRoot -File | ForEach-Object {
        Copy-Item -LiteralPath $_.FullName -Destination $artifactRoot -Force
    }
}

function Build-VerifiedAcceptanceApk {
    param(
        [string]$Kind,
        [string]$Target,
        [string]$ExpectedMarker,
        [string[]]$ForbiddenMarkers,
        [string]$OutputName,
        [string[]]$DartDefines = @(),
        [switch]$PhysicalSmokeArtifact
    )
    if ($OutputName -eq 'chief-site-engineer-0.1.0-issue212-reminder-pilot-ux-debug.apk') {
        throw 'Acceptance artifact cannot use the normal field/release name.'
    }
    $sharedOutput = Join-Path $mobileRoot 'build\app\outputs\flutter-apk\app-debug.apk'
    $arguments = @(
        'build', 'apk', '--debug', '--target', $Target,
        '--target-platform', 'android-arm64,android-x64'
    )
    foreach ($definition in $DartDefines) {
        $arguments += "--dart-define=$definition"
    }
    $started = [DateTime]::UtcNow.AddSeconds(-2)
    Invoke-IsolatedFlutterBuild `
        -Kind $Kind `
        -Arguments $arguments `
        -ExpectedOutput $sharedOutput

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
        throw "Acceptance applicationId verification failed: $OutputName"
    }

    $destination = Join-Path $artifactWorkRoot $OutputName
    if (Test-Path -LiteralPath $destination) {
        throw "Acceptance artifact destination already exists: $OutputName"
    }
    Copy-Item -LiteralPath $sharedOutput -Destination $destination
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
    $artifactPackage = (& $aapt2 dump packagename $destination 2>&1) -join "`n"
    if ($LASTEXITCODE -ne 0 -or
        $artifactPackage.Trim() -ne 'com.faliardic.chiefsiteengineer.acceptance') {
        throw "Copied acceptance applicationId verification failed: $OutputName"
    }
    $item = Get-Item -LiteralPath $destination
    if ($item.LastWriteTimeUtc -lt $started) {
        throw "Acceptance artifact predates its current build invocation: $OutputName"
    }
    $checksum = (Get-FileHash -LiteralPath $destination -Algorithm SHA256).Hash.ToLowerInvariant()
    Write-Output (
        "$OutputName length=$($item.Length) " +
        "lastWriteUtc=$($item.LastWriteTimeUtc.ToString('O')) SHA256=$checksum"
    )

    if ($PhysicalSmokeArtifact) {
        $script:verifiedIssue254Artifact = [pscustomobject]@{
            Path = $item.FullName
            Name = $item.Name
            BuildKind = $Kind
            Marker = $ExpectedMarker
            Length = [long]$item.Length
            LastWriteUtcTicks = [long]$item.LastWriteTimeUtc.Ticks
            Sha256 = $checksum
        }
    }
}

function Assert-VerifiedAcceptanceArtifactUnchanged {
    param([psobject]$Record)
    $expectedName = 'chief-site-engineer-0.1.0-issue254-physical-smoke-acceptance-debug.apk'
    if (-not $Record -or
        $Record.Name -ne $expectedName -or
        $Record.BuildKind -ne 'issue254-acceptance-apk' -or
        $Record.Marker -ne $issue252AcceptanceMarker) {
        throw 'Physical smoke requires the exact verified Issue #254 acceptance artifact.'
    }
    if (-not (Test-Path -LiteralPath $Record.Path -PathType Leaf)) {
        throw 'Verified Issue #254 acceptance artifact is missing.'
    }
    $item = Get-Item -LiteralPath $Record.Path
    if (-not $item.FullName.Equals(
        [IO.Path]::GetFullPath($Record.Path),
        [StringComparison]::OrdinalIgnoreCase
    ) -or
        $item.Name -ne $expectedName -or
        [long]$item.Length -ne [long]$Record.Length -or
        [long]$item.LastWriteTimeUtc.Ticks -ne [long]$Record.LastWriteUtcTicks) {
        throw 'Verified Issue #254 acceptance artifact path/metadata changed.'
    }
    $checksum = (
        Get-FileHash -LiteralPath $item.FullName -Algorithm SHA256
    ).Hash.ToLowerInvariant()
    if ($checksum -ne $Record.Sha256) {
        throw 'Verified Issue #254 acceptance artifact SHA-256 changed.'
    }
}

function Invoke-AdbText {
    param([string[]]$Arguments)
    $output = (& $adb -s $AndroidDevice @Arguments 2>&1) -join "`n"
    if ($LASTEXITCODE -ne 0) {
        throw 'ADB command failed for the selected physical device.'
    }
    return $output.Trim()
}

function Read-RequiredPackageMatch {
    param(
        [string]$Text,
        [string]$Pattern,
        [string]$Label
    )
    $match = [regex]::Match(
        $Text,
        $Pattern,
        [Text.RegularExpressions.RegexOptions]::Multiline
    )
    if (-not $match.Success) {
        throw "Production package snapshot is missing $Label."
    }
    return $match.Groups[1].Value.Trim()
}

function Get-PackageProcessIdentity {
    param([string]$PackageName)
    $output = (& $adb -s $AndroidDevice shell pidof $PackageName 2>$null) -join ' '
    if ($LASTEXITCODE -notin @(0, 1)) {
        throw 'Package process identity could not be read.'
    }
    return $output.Trim()
}

function Get-ProductionPackageSnapshot {
    $productionPackage = 'com.faliardic.chiefsiteengineer.debug'
    $codePath = Invoke-AdbText -Arguments @('shell', 'pm', 'path', $productionPackage)
    if ($codePath -notmatch '^package:/.+/base\.apk$') {
        throw 'Production debug package is not installed with a verifiable code path.'
    }
    $dump = Invoke-AdbText -Arguments @('shell', 'dumpsys', 'package', $productionPackage)
    return [ordered]@{
        applicationId = $productionPackage
        codePath = $codePath
        versionCode = Read-RequiredPackageMatch -Text $dump -Pattern 'versionCode=(\d+)' -Label 'versionCode'
        versionName = Read-RequiredPackageMatch -Text $dump -Pattern 'versionName=([^\r\n]+)' -Label 'versionName'
        firstInstallTime = Read-RequiredPackageMatch -Text $dump -Pattern 'firstInstallTime=([^\r\n]+)' -Label 'firstInstallTime'
        lastUpdateTime = Read-RequiredPackageMatch -Text $dump -Pattern 'lastUpdateTime=([^\r\n]+)' -Label 'lastUpdateTime'
        dataDirectory = Read-RequiredPackageMatch -Text $dump -Pattern 'dataDir=([^\r\n]+)' -Label 'dataDir'
        ceDataInode = Read-RequiredPackageMatch -Text $dump -Pattern 'ceDataInode=(\d+)' -Label 'ceDataInode'
        deDataInode = Read-RequiredPackageMatch -Text $dump -Pattern 'deDataInode=(\d+)' -Label 'deDataInode'
        processId = Get-PackageProcessIdentity -PackageName $productionPackage
    }
}

function Assert-SameProductionPackageSnapshot {
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

function Wait-AcceptancePassMarker {
    param(
        [string]$ExpectedMarker,
        [string]$RunId
    )
    $acceptancePackage = 'com.faliardic.chiefsiteengineer.acceptance'
    $deadline = [DateTime]::UtcNow.AddMinutes(5)
    while ([DateTime]::UtcNow -lt $deadline) {
        $processIdentity = Get-PackageProcessIdentity -PackageName $acceptancePackage
        if ($processIdentity) {
            $processId = ($processIdentity -split '\s+')[0]
            $logs = (
                & $adb -s $AndroidDevice logcat -d -v brief --pid $processId -t 2000 2>&1
            ) -join "`n"
            if ($LASTEXITCODE -ne 0) {
                throw 'Acceptance-only logcat read failed.'
            }
            if ($logs -match [regex]::Escape("$ExpectedMarker run=$RunId")) {
                return
            }
            if ($logs -match 'EXCEPTION CAUGHT BY FLUTTER TEST FRAMEWORK|Test failed') {
                throw 'Issue #252 acceptance test reported a failure.'
            }
        }
        Start-Sleep -Seconds 2
    }
    throw "Timed out waiting for acceptance marker $ExpectedMarker."
}

function Invoke-VerifiedAcceptancePhysicalSmoke {
    param(
        [psobject]$ArtifactRecord,
        [string]$RunId
    )
    Assert-VerifiedAcceptanceArtifactUnchanged -Record $ArtifactRecord
    if ($RunId -notmatch '^\d{14}$') {
        throw 'Acceptance RunId must contain exactly 14 digits.'
    }
    if (-not (Test-Path -LiteralPath $adb -PathType Leaf)) {
        throw 'Android adb was not found for the physical acceptance smoke.'
    }
    if ((Invoke-AdbText -Arguments @('get-state')) -ne 'device') {
        throw 'Selected physical Android device is not ready.'
    }

    $acceptancePackage = 'com.faliardic.chiefsiteengineer.acceptance'
    $before = Get-ProductionPackageSnapshot
    Assert-VerifiedAcceptanceArtifactUnchanged -Record $ArtifactRecord
    Invoke-AdbText -Arguments @('install', '-r', $ArtifactRecord.Path) | Out-Null
    $activityResult = Invoke-AdbText -Arguments @(
        'shell', 'cmd', 'package', 'resolve-activity', '--brief',
        $acceptancePackage
    )
    $activityMatch = [regex]::Match(
        $activityResult,
        '(?m)^([A-Za-z0-9_.]+/[A-Za-z0-9_.$]+)$'
    )
    if (-not $activityMatch.Success) {
        throw 'Acceptance launcher activity could not be resolved.'
    }
    $activity = $activityMatch.Groups[1].Value

    Invoke-AdbText -Arguments @('shell', 'am', 'start', '-W', '-n', $activity) | Out-Null
    Wait-AcceptancePassMarker `
        -ExpectedMarker 'CSE_ISSUE254_PHASE1_PASS' `
        -RunId $RunId

    Invoke-AdbText -Arguments @('shell', 'input', 'keyevent', 'KEYCODE_HOME') | Out-Null
    Invoke-AdbText -Arguments @(
        'shell', 'am', 'start', '-W', '-n', $activity,
        '-f', '0x10008000'
    ) | Out-Null
    Wait-AcceptancePassMarker `
        -ExpectedMarker 'CSE_ISSUE254_PHASE2_PASS' `
        -RunId $RunId

    $after = Get-ProductionPackageSnapshot
    Assert-SameProductionPackageSnapshot -Before $before -After $after
    Write-Output 'Physical device smoke: PASS'
    Write-Output "ApplicationId: $acceptancePackage"
    Write-Output "Artifact path: $($ArtifactRecord.Path)"
    Write-Output "Artifact SHA-256: $($ArtifactRecord.Sha256)"
    Write-Output "Synthetic run: $RunId"
    Write-Output 'Production debug package metadata/process/data inodes: unchanged'
}

function Resolve-JdkTool {
    param([string]$Name)
    $command = Get-Command $Name -ErrorAction SilentlyContinue
    if ($command) { return $command.Source }
    $candidates = @()
    if ($env:JAVA_HOME) { $candidates += (Join-Path $env:JAVA_HOME "bin\$Name.exe") }
    $candidates += (Join-Path $env:ProgramFiles "Android\Android Studio\jbr\bin\$Name.exe")
    foreach ($candidate in $candidates) {
        if (Test-Path -LiteralPath $candidate) { return $candidate }
    }
    throw "$Name was not found in PATH, JAVA_HOME, or Android Studio JBR."
}

function Clear-GeneratedReadOnlyAttributes {
    $attrib = Join-Path $env:SystemRoot 'System32\attrib.exe'
    foreach ($generatedRoot in @(
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

if ($RunIsolatedFlutterCommand) {
    if (-not $BuildKind -or -not $BuildRunId -or
        -not $FlutterArguments -or $FlutterArguments.Count -eq 0) {
        throw 'Isolated Flutter command requires BuildKind, BuildRunId, and FlutterArguments.'
    }
    Move-ExistingFlutterBuildRoot -Kind $BuildKind -RunId $BuildRunId
    Invoke-Flutter -Arguments $FlutterArguments
    return
}

if ($RunVerifiedAcceptanceSmokeOnly) {
    $record = [pscustomobject]@{
        Path = $VerifiedAcceptanceArtifactPath
        Name = [IO.Path]::GetFileName($VerifiedAcceptanceArtifactPath)
        BuildKind = 'issue254-acceptance-apk'
        Marker = $issue252AcceptanceMarker
        Length = $VerifiedAcceptanceLength
        LastWriteUtcTicks = $VerifiedAcceptanceLastWriteUtcTicks
        Sha256 = $VerifiedAcceptanceSha256
    }
    Invoke-VerifiedAcceptancePhysicalSmoke `
        -ArtifactRecord $record `
        -RunId $AcceptanceRunId
    return
}

try {
    if ($RunIssue254PhysicalSmoke -and -not $IncludeAcceptanceArtifacts) {
        throw 'Issue #254 physical smoke requires IncludeAcceptanceArtifacts.'
    }
    if ($IncludeAcceptanceArtifacts -and -not $SkipSignedArtifacts) {
        throw 'Acceptance artifact ordering requires SkipSignedArtifacts.'
    }
    if ($IncludeAcceptanceArtifacts) {
        $AcceptanceRunId = [DateTime]::Now.ToString('yyyyMMddHHmmss')
    }
    $env:CSE_ACCEPTANCE_HARNESS = $null
    $artifactWorkRoot = Join-Path ([IO.Path]::GetTempPath()) (
        "cse-release-gate-artifacts-{0}" -f [guid]::NewGuid().ToString('N')
    )
    New-Item -ItemType Directory -Path $artifactWorkRoot | Out-Null
    $env:CSE_RELEASE_GATE_ARTIFACT_STAGING_ROOT = $artifactWorkRoot
    Clear-GeneratedReadOnlyAttributes
    Invoke-Flutter -Arguments @('pub', 'get')
    if (-not $SkipFlutterValidation) {
        Invoke-Flutter -Arguments @('analyze')
        Invoke-Flutter -Arguments @('test', '--no-pub')
    }

    $debugApk = Join-Path $mobileRoot 'build\app\outputs\flutter-apk\app-debug.apk'
    Clear-GeneratedReadOnlyAttributes
    Invoke-Flutter -Arguments @('pub', 'get')
    $normalBuildStarted = [DateTime]::UtcNow.AddSeconds(-2)
    Invoke-IsolatedFlutterBuild `
        -Kind 'normal-debug-apk' `
        -Arguments @(
            'build', 'apk', '--debug', '--target', 'lib\main.dart',
            '--target-platform', 'android-arm64'
        ) `
        -ExpectedOutput $debugApk `
        -StaleOutputMessage (
            'Flutter clean left a stale app-debug.apk before the field sidecar build.'
        )
    if (-not (Test-Path -LiteralPath $debugApk)) {
        throw 'Debug sidecar APK was not produced.'
    }
    if ((Get-Item -LiteralPath $debugApk).LastWriteTimeUtc -lt $normalBuildStarted) {
        throw 'Debug sidecar APK predates the explicit lib/main.dart build.'
    }
    Invoke-Checked -Command 'python' -Arguments @(
        (Join-Path $repositoryRoot 'scripts\verify_flutter_apk_entrypoint.py'),
        '--apk', $debugApk,
        '--expected-marker', 'CSE_ENTRYPOINT_NORMAL_LIB_MAIN_DART_V1',
        '--forbidden-marker', 'CSE_ENTRYPOINT_BACKGROUND_ACCEPTANCE_V1',
        '--forbidden-marker', 'CSE_ENTRYPOINT_REBOOT_ACCEPTANCE_V1',
        '--forbidden-marker', $issue252AcceptanceMarker
    )
    $temporarySidecarApk = Join-Path ([IO.Path]::GetTempPath()) ("cse-sidecar-{0}.apk" -f [guid]::NewGuid().ToString('N'))
    Copy-Item -LiteralPath $debugApk -Destination $temporarySidecarApk
    if (-not $SkipIntegration) {
        if (-not (Test-Path -LiteralPath $adb)) {
            throw 'Android adb was not found for the integration gate.'
        }
        Invoke-Checked -Command $adb -Arguments @('-s', $AndroidDevice, 'install', '-r', '-g', $debugApk)
        & $adb -s $AndroidDevice shell pm grant com.faliardic.chiefsiteengineer.debug android.permission.POST_NOTIFICATIONS 2>$null
        & $adb -s $AndroidDevice shell appops set com.faliardic.chiefsiteengineer.debug SCHEDULE_EXACT_ALARM allow 2>$null
        Invoke-IsolatedFlutterBuild `
            -Kind 'normal-integration-smoke' `
            -Arguments @(
                'test', '--no-pub', 'integration_test\app_smoke_test.dart',
                '-d', $AndroidDevice
            )
        Clear-GeneratedReadOnlyAttributes
        Invoke-Flutter -Arguments @('pub', 'get')
    }

    New-Item -ItemType Directory -Force -Path $artifactWorkRoot | Out-Null
    if (-not (Test-Path -LiteralPath $aapt2) -or
        -not (Test-Path -LiteralPath $zipalign) -or
        -not (Test-Path -LiteralPath $apksigner)) {
        throw 'Android build-tools 36.0.0 artifact validators were not found.'
    }
    $sidecarApk = Join-Path $artifactWorkRoot 'chief-site-engineer-0.1.0-issue212-reminder-pilot-ux-debug.apk'
    Copy-Item -LiteralPath $temporarySidecarApk -Destination $sidecarApk -Force
    Invoke-Checked -Command 'python' -Arguments @(
        (Join-Path $repositoryRoot 'scripts\verify_flutter_apk_entrypoint.py'),
        '--apk', $sidecarApk,
        '--expected-marker', 'CSE_ENTRYPOINT_NORMAL_LIB_MAIN_DART_V1',
        '--forbidden-marker', 'CSE_ENTRYPOINT_BACKGROUND_ACCEPTANCE_V1',
        '--forbidden-marker', 'CSE_ENTRYPOINT_REBOOT_ACCEPTANCE_V1',
        '--forbidden-marker', 'CSE_ENTRYPOINT_ISSUE252_SMOKE_ACCEPTANCE_V1'
    )
    $sidecarPackage = (& $aapt2 dump packagename $sidecarApk 2>&1) -join "`n"
    if ($LASTEXITCODE -ne 0 -or $sidecarPackage.Trim() -ne 'com.faliardic.chiefsiteengineer.debug') {
        throw 'Debug sidecar package identity verification failed.'
    }
    $sidecarPermissions = (& $aapt2 dump permissions $sidecarApk 2>&1) -join "`n"
    if ($LASTEXITCODE -ne 0 -or
        $sidecarPermissions -match 'READ_EXTERNAL_STORAGE|WRITE_EXTERNAL_STORAGE|READ_MEDIA_IMAGES|READ_MEDIA_VIDEO|READ_MEDIA_AUDIO|MANAGE_EXTERNAL_STORAGE') {
        throw 'Debug sidecar contains a forbidden broad storage/media permission.'
    }
    Push-Location $artifactWorkRoot
    try {
        $sidecarName = [IO.Path]::GetFileName($sidecarApk)
        Invoke-Checked -Command $zipalign -Arguments @('-c', '-P', '16', '-v', '4', $sidecarName)
        Invoke-Checked -Command $apksigner -Arguments @('verify', '--verbose', $sidecarName)
    } finally {
        Pop-Location
    }
    Invoke-Checked -Command 'python' -Arguments @(
        (Join-Path $repositoryRoot 'scripts\validate_mobile_release.py'),
        '--apk', $sidecarApk
    )
    $sidecarChecksum = (Get-FileHash -LiteralPath $sidecarApk -Algorithm SHA256).Hash.ToLowerInvariant()
    [IO.File]::WriteAllText(
        (Join-Path $artifactWorkRoot 'SIDECAR_SHA256.txt'),
        "$sidecarChecksum  $([IO.Path]::GetFileName($sidecarApk))`n",
        [Text.UTF8Encoding]::new($false)
    )
    Write-Output "Debug sidecar APK SHA256: $sidecarChecksum"

    if ($IncludeAcceptanceArtifacts) {
        $env:CSE_ACCEPTANCE_HARNESS = 'true'
        Build-VerifiedAcceptanceApk `
            -Kind 'background-acceptance-apk' `
            -Target 'integration_test\background_delivery_sidecar_main.dart' `
            -ExpectedMarker 'CSE_ENTRYPOINT_BACKGROUND_ACCEPTANCE_V1' `
            -ForbiddenMarkers @(
                'CSE_ENTRYPOINT_REBOOT_ACCEPTANCE_V1',
                $issue252AcceptanceMarker
            ) `
            -OutputName (
                'chief-site-engineer-0.1.0-issue207-' +
                'background-acceptance-debug.apk'
            )
        Build-VerifiedAcceptanceApk `
            -Kind 'reboot-acceptance-apk' `
            -Target 'integration_test\background_reboot_sidecar_main.dart' `
            -ExpectedMarker 'CSE_ENTRYPOINT_REBOOT_ACCEPTANCE_V1' `
            -ForbiddenMarkers @(
                'CSE_ENTRYPOINT_BACKGROUND_ACCEPTANCE_V1',
                $issue252AcceptanceMarker
            ) `
            -OutputName (
                'chief-site-engineer-0.1.0-issue207-' +
                'reboot-acceptance-debug.apk'
            )
        $env:CSE_ACCEPTANCE_HARNESS = $null
    }

    $env:CSE_KEY_PROPERTIES_FILE = $null
    $env:CSE_REQUIRE_SIGNING = $null
    Clear-GeneratedReadOnlyAttributes
    Invoke-Checked -Command 'python' -Arguments @(
        (Join-Path $repositoryRoot 'scripts\prepare_flutter_release_registrant.py')
    )
    $builtAab = Join-Path $mobileRoot 'build\app\outputs\bundle\release\app-release.aab'
    Invoke-IsolatedFlutterBuild `
        -Kind 'release-aab-unsigned' `
        -Arguments @(
            'build', 'appbundle', '--release',
            '--target-platform', 'android-arm64'
        ) `
        -ExpectedOutput $builtAab
    $unsignedAab = Join-Path $artifactWorkRoot 'app-release-unsigned.aab'
    Copy-Item -LiteralPath $builtAab -Destination $unsignedAab -Force
    $mergedManifest = Get-ChildItem -LiteralPath (Join-Path $mobileRoot 'build\app\intermediates\merged_manifests\release') -Filter AndroidManifest.xml -Recurse | Select-Object -First 1
    if (-not $mergedManifest) { throw 'Merged release AndroidManifest.xml was not produced.' }
    Invoke-Checked -Command 'python' -Arguments @(
        (Join-Path $repositoryRoot 'scripts\validate_mobile_release.py'),
        '--require-plugin-privacy-inventory',
        '--merged-manifest', $mergedManifest.FullName,
        '--aab', $unsignedAab
    )

    if (-not $SkipSignedArtifacts) {
        if (-not $BundletoolJar -or -not (Test-Path -LiteralPath $BundletoolJar)) {
            throw 'CSE_BUNDLETOOL_JAR must point to verified bundletool 1.18.3.'
        }
        $bundletoolHash = (Get-FileHash -LiteralPath $BundletoolJar -Algorithm SHA256).Hash
        if ($bundletoolHash -ne 'A099CFA1543F55593BC2ED16A70A7C67FE54B1747BB7301F37FDFD6D91028E29') {
            throw 'bundletool SHA-256 mismatch.'
        }
        if (-not (Test-Path -LiteralPath $zipalign) -or -not (Test-Path -LiteralPath $apksigner)) {
            throw 'Android build-tools 36.0.0 zipalign/apksigner were not found.'
        }
        $temporaryRoot = Join-Path ([IO.Path]::GetTempPath()) ("cse-release-gate-{0}" -f [guid]::NewGuid().ToString('N'))
        New-Item -ItemType Directory -Path $temporaryRoot | Out-Null
        $keystore = Join-Path $temporaryRoot 'ephemeral-release-gate.p12'
        $properties = Join-Path $temporaryRoot 'key.properties'
        $passwordBytes = [Security.Cryptography.RandomNumberGenerator]::GetBytes(24)
        $password = [Convert]::ToHexString($passwordBytes).ToLowerInvariant()
        $keytool = Resolve-JdkTool 'keytool'
        Invoke-Checked -Command $keytool -Arguments @(
            '-genkeypair', '-storetype', 'PKCS12', '-keystore', $keystore,
            '-alias', 'cse-ephemeral', '-keyalg', 'RSA', '-keysize', '3072',
            '-validity', '2', '-dname', 'CN=CSE Ephemeral Release Gate, O=Local Test, C=TR',
            '-storepass', $password, '-keypass', $password, '-noprompt'
        )
        [IO.File]::WriteAllText(
            $properties,
            "storeFile=ephemeral-release-gate.p12`nstorePassword=$password`nkeyAlias=cse-ephemeral`nkeyPassword=$password`n",
            [Text.UTF8Encoding]::new($false)
        )
        $env:CSE_KEY_PROPERTIES_FILE = $properties
        $env:CSE_REQUIRE_SIGNING = 'true'
        Clear-GeneratedReadOnlyAttributes
        Invoke-Checked -Command 'python' -Arguments @(
            (Join-Path $repositoryRoot 'scripts\prepare_flutter_release_registrant.py')
        )
        Invoke-IsolatedFlutterBuild `
            -Kind 'release-aab-signed' `
            -Arguments @(
                'build', 'appbundle', '--release',
                '--target-platform', 'android-arm64'
            ) `
            -ExpectedOutput $builtAab
        $signedAab = Join-Path $artifactWorkRoot 'app-release-ephemeral-signed.aab'
        Copy-Item -LiteralPath $builtAab -Destination $signedAab -Force
        $jarsigner = Resolve-JdkTool 'jarsigner'
        $jarsignerOutput = & $jarsigner -verify -verbose -certs $signedAab 2>&1
        if ($LASTEXITCODE -ne 0 -or
            ($jarsignerOutput -join "`n") -notmatch 'jar verified' -or
            ($jarsignerOutput -join "`n") -match 'jar is unsigned') {
            throw 'Ephemeral signed AAB signer verification failed.'
        }
        Write-Output 'Ephemeral signed AAB signer verified.'

        $apks = Join-Path $temporaryRoot 'universal.apks'
        $bundletoolOutput = & java @(
            '-jar', $BundletoolJar, 'build-apks',
            "--bundle=$unsignedAab", "--output=$apks", '--mode=universal',
            "--ks=$keystore", '--ks-key-alias=cse-ephemeral',
            "--ks-pass=pass:$password", "--key-pass=pass:$password"
        ) 2>&1
        if ($LASTEXITCODE -ne 0) {
            throw 'Bundletool universal APK creation failed.'
        }
        $extracted = Join-Path $temporaryRoot 'universal'
        [IO.Compression.ZipFile]::ExtractToDirectory($apks, $extracted)
        $universalSource = Join-Path $extracted 'universal.apk'
        $rcApk = Join-Path $artifactWorkRoot 'chief-site-engineer-0.1.0-rc-ephemeral.apk'
        Copy-Item -LiteralPath $universalSource -Destination $rcApk -Force
        Push-Location $artifactWorkRoot
        try {
            $rcApkName = [IO.Path]::GetFileName($rcApk)
            Invoke-Checked -Command $zipalign -Arguments @('-c', '-P', '16', '-v', '4', $rcApkName)
            $apksignerOutput = & $apksigner verify --verbose --print-certs $rcApkName 2>&1
            $apksignerText = $apksignerOutput -join "`n"
            if ($LASTEXITCODE -ne 0 -or
                $apksignerText -notmatch '(?m)^Verifies$' -or
                $apksignerText -notmatch 'Verified using v2 scheme \(APK Signature Scheme v2\): true' -or
                $apksignerText -notmatch 'Number of signers: 1') {
                throw 'RC APK signer verification failed.'
            }
            Write-Output 'Ephemeral RC APK signer verified.'
        } finally {
            Pop-Location
        }
        Invoke-Checked -Command 'python' -Arguments @(
            (Join-Path $repositoryRoot 'scripts\validate_mobile_release.py'),
            '--require-plugin-privacy-inventory',
            '--aab', $signedAab, '--apk', $rcApk
        )
        $checksum = (Get-FileHash -LiteralPath $rcApk -Algorithm SHA256).Hash.ToLowerInvariant()
        [IO.File]::WriteAllText(
            (Join-Path $artifactWorkRoot 'RC_SHA256.txt'),
            "$checksum  $([IO.Path]::GetFileName($rcApk))`n",
            [Text.UTF8Encoding]::new($false)
        )
        Write-Output "RC APK SHA256: $checksum"
    }

    if ($IncludeAcceptanceArtifacts) {
        $env:CSE_ACCEPTANCE_HARNESS = 'true'
        Build-VerifiedAcceptanceApk `
            -Kind 'issue254-acceptance-apk' `
            -Target 'integration_test\issue252_physical_smoke_test.dart' `
            -ExpectedMarker $issue252AcceptanceMarker `
            -ForbiddenMarkers @(
                'CSE_ENTRYPOINT_BACKGROUND_ACCEPTANCE_V1',
                'CSE_ENTRYPOINT_REBOOT_ACCEPTANCE_V1'
            ) `
            -OutputName (
                'chief-site-engineer-0.1.0-issue254-' +
                'physical-smoke-acceptance-debug.apk'
            ) `
            -DartDefines @("CSE_ISSUE254_RUN_ID=$AcceptanceRunId") `
            -PhysicalSmokeArtifact
        $env:CSE_ACCEPTANCE_HARNESS = $null
        if (-not $verifiedIssue254Artifact) {
            throw 'Issue #254 verified acceptance artifact record was not produced.'
        }
    }

    Publish-ReleaseGateArtifacts
    if ($RunIssue254PhysicalSmoke) {
        Invoke-VerifiedAcceptancePhysicalSmoke `
            -ArtifactRecord $verifiedIssue254Artifact `
            -RunId $AcceptanceRunId
    }

    if (-not $SkipPython) {
        Push-Location $repositoryRoot
        try {
            Invoke-Checked -Command 'python' -Arguments @('-m', 'pytest', '-rs')
            Invoke-Checked -Command 'python' -Arguments @('-m', 'compileall', '-q', 'app', 'scripts')
            Invoke-Checked -Command 'python' -Arguments @('-m', 'json.tool', '.cse\state\project_state.json')
            Invoke-Checked -Command 'git' -Arguments @('diff', '--check')
        } finally {
            Pop-Location
        }
    }
    Write-Output 'CSE mobile release gate passed.'
} finally {
    $env:CSE_KEY_PROPERTIES_FILE = $previousSigningFile
    $env:CSE_REQUIRE_SIGNING = $previousSigningRequired
    $env:CSE_ACCEPTANCE_HARNESS = $previousAcceptanceHarness
    $env:CSE_RELEASE_GATE_ARTIFACT_STAGING_ROOT = $previousArtifactStagingRoot
    if ($temporaryRoot -and (Test-Path -LiteralPath $temporaryRoot)) {
        $resolvedTemporaryRoot = (Resolve-Path -LiteralPath $temporaryRoot).Path
        $systemTemporaryRoot = [IO.Path]::GetFullPath([IO.Path]::GetTempPath())
        if (-not $resolvedTemporaryRoot.StartsWith($systemTemporaryRoot, [StringComparison]::OrdinalIgnoreCase) -or
            -not ([IO.Path]::GetFileName($resolvedTemporaryRoot)).StartsWith('cse-release-gate-')) {
            throw 'Refusing to clean an unexpected release-gate directory.'
        }
        Remove-Item -LiteralPath $resolvedTemporaryRoot -Recurse -Force
    }
    if ($temporarySidecarApk -and (Test-Path -LiteralPath $temporarySidecarApk)) {
        $resolvedSidecar = (Resolve-Path -LiteralPath $temporarySidecarApk).Path
        $systemTemporaryRoot = [IO.Path]::GetFullPath([IO.Path]::GetTempPath())
        if (-not $resolvedSidecar.StartsWith($systemTemporaryRoot, [StringComparison]::OrdinalIgnoreCase) -or
            -not ([IO.Path]::GetFileName($resolvedSidecar)).StartsWith('cse-sidecar-') -or
            [IO.Path]::GetExtension($resolvedSidecar) -ne '.apk') {
            throw 'Refusing to clean an unexpected sidecar temporary file.'
        }
        Remove-Item -LiteralPath $resolvedSidecar -Force
    }
    if ($artifactWorkRoot -and (Test-Path -LiteralPath $artifactWorkRoot)) {
        $resolvedArtifactWorkRoot = Assert-SafeArtifactStagingRoot -Path $artifactWorkRoot
        Remove-Item -LiteralPath $resolvedArtifactWorkRoot -Recurse -Force
    }
}
