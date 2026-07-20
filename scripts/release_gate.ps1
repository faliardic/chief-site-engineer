[CmdletBinding()]
param(
    [string]$FlutterCommand = $(
        if ($env:CSE_FLUTTER_COMMAND) { $env:CSE_FLUTTER_COMMAND } else { 'flutter' }
    ),
    [string]$BundletoolJar = $env:CSE_BUNDLETOOL_JAR,
    [string]$AndroidDevice = 'emulator-5554',
    [switch]$SkipIntegration,
    [switch]$SkipPython,
    [switch]$SkipSignedArtifacts
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
$adb = Join-Path $androidSdk 'platform-tools\adb.exe'
$zipalign = Join-Path $androidSdk 'build-tools\36.0.0\zipalign.exe'
$apksigner = Join-Path $androidSdk 'build-tools\36.0.0\apksigner.bat'
$aapt2 = Join-Path $androidSdk 'build-tools\36.0.0\aapt2.exe'
$temporaryRoot = $null
$temporarySidecarApk = $null
$previousSigningFile = $env:CSE_KEY_PROPERTIES_FILE
$previousSigningRequired = $env:CSE_REQUIRE_SIGNING

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

try {
    New-Item -ItemType Directory -Force -Path $artifactRoot | Out-Null
    Invoke-Flutter -Arguments @('pub', 'get')
    Invoke-Flutter -Arguments @('analyze')
    Invoke-Flutter -Arguments @('test', '--no-pub')

    Invoke-Flutter -Arguments @('build', 'apk', '--debug', '--target-platform', 'android-arm64')
    $debugApk = Join-Path $mobileRoot 'build\app\outputs\flutter-apk\app-debug.apk'
    if (-not (Test-Path -LiteralPath $debugApk)) {
        throw 'Debug sidecar APK was not produced.'
    }
    $temporarySidecarApk = Join-Path ([IO.Path]::GetTempPath()) ("cse-sidecar-{0}.apk" -f [guid]::NewGuid().ToString('N'))
    Copy-Item -LiteralPath $debugApk -Destination $temporarySidecarApk
    if (-not $SkipIntegration) {
        if (-not (Test-Path -LiteralPath $adb)) {
            throw 'Android adb was not found for the integration gate.'
        }
        Invoke-Checked -Command $adb -Arguments @('-s', $AndroidDevice, 'install', '-r', '-g', $debugApk)
        & $adb -s $AndroidDevice shell pm grant com.faliardic.chiefsiteengineer.debug android.permission.POST_NOTIFICATIONS 2>$null
        Invoke-Flutter -Arguments @('test', '--no-pub', 'integration_test\app_smoke_test.dart', '-d', $AndroidDevice)
        $gradle = Join-Path $mobileRoot 'android\gradlew.bat'
        if (Test-Path -LiteralPath $gradle) {
            Push-Location (Join-Path $mobileRoot 'android')
            try { & $gradle --stop | Out-Null } finally { Pop-Location }
        }
        Invoke-Flutter -Arguments @('clean')
        Invoke-Flutter -Arguments @('pub', 'get')
    }

    New-Item -ItemType Directory -Force -Path $artifactRoot | Out-Null
    if (-not (Test-Path -LiteralPath $aapt2) -or
        -not (Test-Path -LiteralPath $zipalign) -or
        -not (Test-Path -LiteralPath $apksigner)) {
        throw 'Android build-tools 36.0.0 artifact validators were not found.'
    }
    $sidecarApk = Join-Path $artifactRoot 'chief-site-engineer-0.1.0-issue198-sidecar-debug.apk'
    Copy-Item -LiteralPath $temporarySidecarApk -Destination $sidecarApk -Force
    $sidecarPackage = (& $aapt2 dump packagename $sidecarApk 2>&1) -join "`n"
    if ($LASTEXITCODE -ne 0 -or $sidecarPackage.Trim() -ne 'com.faliardic.chiefsiteengineer.debug') {
        throw 'Debug sidecar package identity verification failed.'
    }
    $sidecarPermissions = (& $aapt2 dump permissions $sidecarApk 2>&1) -join "`n"
    if ($LASTEXITCODE -ne 0 -or
        $sidecarPermissions -match 'READ_EXTERNAL_STORAGE|WRITE_EXTERNAL_STORAGE|READ_MEDIA_IMAGES|READ_MEDIA_VIDEO|READ_MEDIA_AUDIO|MANAGE_EXTERNAL_STORAGE') {
        throw 'Debug sidecar contains a forbidden broad storage/media permission.'
    }
    Push-Location $artifactRoot
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
        (Join-Path $artifactRoot 'SIDECAR_SHA256.txt'),
        "$sidecarChecksum  $([IO.Path]::GetFileName($sidecarApk))`n",
        [Text.UTF8Encoding]::new($false)
    )
    Write-Output "Debug sidecar APK SHA256: $sidecarChecksum"
    $env:CSE_KEY_PROPERTIES_FILE = $null
    $env:CSE_REQUIRE_SIGNING = $null
    Invoke-Checked -Command 'python' -Arguments @(
        (Join-Path $repositoryRoot 'scripts\prepare_flutter_release_registrant.py')
    )
    Invoke-Flutter -Arguments @('build', 'appbundle', '--release', '--target-platform', 'android-arm64')
    $builtAab = Join-Path $mobileRoot 'build\app\outputs\bundle\release\app-release.aab'
    $unsignedAab = Join-Path $artifactRoot 'app-release-unsigned.aab'
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
        Invoke-Checked -Command 'python' -Arguments @(
            (Join-Path $repositoryRoot 'scripts\prepare_flutter_release_registrant.py')
        )
        Invoke-Flutter -Arguments @('build', 'appbundle', '--release', '--target-platform', 'android-arm64')
        $signedAab = Join-Path $artifactRoot 'app-release-ephemeral-signed.aab'
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
        $rcApk = Join-Path $artifactRoot 'chief-site-engineer-0.1.0-rc-ephemeral.apk'
        Copy-Item -LiteralPath $universalSource -Destination $rcApk -Force
        Push-Location $artifactRoot
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
            (Join-Path $artifactRoot 'RC_SHA256.txt'),
            "$checksum  $([IO.Path]::GetFileName($rcApk))`n",
            [Text.UTF8Encoding]::new($false)
        )
        Write-Output "RC APK SHA256: $checksum"
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
}
