[CmdletBinding()]
param(
    [ValidateSet('Build', 'Device')]
    [string]$Mode = 'Build',

    [string]$DeviceSerial,

    [string]$FlutterCommand = $(
        if ($env:CSE_FLUTTER_COMMAND) { $env:CSE_FLUTTER_COMMAND } else { 'flutter' }
    )
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

$repositoryRoot = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$mobileRoot = Join-Path $repositoryRoot 'mobile'
$androidSdk = if ($env:ANDROID_HOME) {
    $env:ANDROID_HOME
} else {
    Join-Path $env:LOCALAPPDATA 'Android\Sdk'
}
$adb = Join-Path $androidSdk 'platform-tools\adb.exe'
$aapt2 = Join-Path $androidSdk 'build-tools\36.0.0\aapt2.exe'
$verifier = Join-Path $repositoryRoot 'scripts\verify_flutter_apk_entrypoint.py'
$sharedApk = Join-Path $mobileRoot 'build\app\outputs\flutter-apk\app-debug.apk'
$artifactRoot = Join-Path $mobileRoot 'build\release_gate'
$artifact = Join-Path $artifactRoot 'sefim-0.1.0-issue464-living-plan-acceptance-debug.apk'
$acceptancePackage = 'com.faliardic.sefim.acceptance'
$acceptanceLabel = 'Şefim'
$acceptanceEnvironmentLabel = 'Kabul ortamı · sentetik veri'
$acceptanceNote = 'Acceptance persistence notu'
$updatedAcceptanceNote = "$acceptanceNote guncellendi"
$livingPlanSemanticsPrefix = 'Yaşayan plan öğesi'
$neighborItemIds = @(
    '46400000-0000-4000-8000-000000000011',
    '46400000-0000-4000-8000-000000000021'
)
$allPackages = @(
    'com.faliardic.chiefsiteengineer',
    'com.faliardic.chiefsiteengineer.debug',
    'com.faliardic.chiefsiteengineer.acceptance',
    'com.faliardic.sefim',
    'com.faliardic.sefim.debug',
    'com.faliardic.sefim.acceptance'
)
$nonTargetPackages = @($allPackages | Where-Object { $_ -ne $acceptancePackage })
$previousAcceptanceHarness = $env:CSE_ACCEPTANCE_HARNESS

function Invoke-Checked {
    param(
        [Parameter(Mandatory = $true)][string]$Command,
        [Parameter(Mandatory = $true)][string[]]$Arguments
    )
    $output = (& $Command @Arguments 2>&1) -join "`n"
    if ($LASTEXITCODE -ne 0) {
        throw "Command failed with exit code ${LASTEXITCODE}: $Command`n$output"
    }
    return $output
}

function Invoke-Adb {
    param([Parameter(Mandatory = $true)][string[]]$Arguments)
    return Invoke-Checked -Command $adb -Arguments (@('-s', $DeviceSerial) + $Arguments)
}

function Invoke-HostFlutterBuild {
    param([Parameter(Mandatory = $true)][string[]]$Arguments)
    if ($Arguments -contains '-d' -or
        $Arguments[0] -in @('test', 'drive', 'run', 'install')) {
        throw 'Connected-device Flutter lifecycle commands are forbidden.'
    }
    Push-Location $mobileRoot
    try {
        $output = (& $FlutterCommand @Arguments 2>&1) -join "`n"
        if ($LASTEXITCODE -ne 0) {
            throw "Flutter failed with exit code ${LASTEXITCODE}.`n$output"
        }
        Write-Output $output
    } finally {
        Pop-Location
    }
}

function Get-MaskedSerial {
    $bytes = [Text.Encoding]::UTF8.GetBytes($DeviceSerial)
    $sha = [Security.Cryptography.SHA256]::Create()
    try {
        $hash = [BitConverter]::ToString($sha.ComputeHash($bytes)).Replace('-', '').ToLowerInvariant()
    } finally {
        $sha.Dispose()
    }
    return "sha256:$($hash.Substring(0, 12))"
}

function Get-PackageInventory {
    param([Parameter(Mandatory = $true)][string]$PackageName)
    $pathOutput = (& $adb -s $DeviceSerial shell pm path --user 0 $PackageName 2>&1) -join "`n"
    $pathExit = $LASTEXITCODE
    if ($pathExit -ne 0 -or [string]::IsNullOrWhiteSpace($pathOutput)) {
        return [ordered]@{ package = $PackageName; installed = $false }
    }
    $dump = Invoke-Adb -Arguments @('shell', 'dumpsys', 'package', $PackageName)
    function Match-Value([string]$Pattern) {
        $match = [regex]::Match($dump, $Pattern, [Text.RegularExpressions.RegexOptions]::Multiline)
        if ($match.Success) { return $match.Groups[1].Value.Trim() }
        return $null
    }
    return [ordered]@{
        package = $PackageName
        installed = $true
        path = ($pathOutput -split "`r?`n" | Sort-Object) -join '|'
        versionCode = Match-Value '^\s*versionCode=([^\s]+)'
        versionName = Match-Value '^\s*versionName=(.+)$'
        firstInstallTime = Match-Value '^\s*firstInstallTime=(.+)$'
        lastUpdateTime = Match-Value '^\s*lastUpdateTime=(.+)$'
    }
}

function Convert-InventoryToJson {
    param([Parameter(Mandatory = $true)][object]$Inventory)
    return $Inventory | ConvertTo-Json -Compress -Depth 4
}

function Get-SixPackageInventory {
    $inventory = [ordered]@{}
    foreach ($packageName in $allPackages) {
        $inventory[$packageName] = Get-PackageInventory $packageName
    }
    return $inventory
}

function Assert-NonTargetInventory {
    param(
        [Parameter(Mandatory = $true)][object]$Expected,
        [Parameter(Mandatory = $true)][object]$Actual
    )
    foreach ($packageName in $nonTargetPackages) {
        $before = Convert-InventoryToJson $Expected[$packageName]
        $after = Convert-InventoryToJson $Actual[$packageName]
        if ($after -ne $before) {
            throw "Protected package inventory changed: $packageName"
        }
    }
}

function Assert-AllPackageInventory {
    param([Parameter(Mandatory = $true)][object]$Expected)
    $actual = Get-SixPackageInventory
    foreach ($packageName in $allPackages) {
        $before = Convert-InventoryToJson $Expected[$packageName]
        $after = Convert-InventoryToJson $actual[$packageName]
        if ($after -ne $before) {
            throw "Six-package isolation changed after device mutation: $packageName"
        }
    }
}

function Invoke-IsolatedDeviceMutation {
    param(
        [Parameter(Mandatory = $true)][string[]]$Arguments,
        [Parameter(Mandatory = $true)][object]$ExpectedInventory
    )
    $output = Invoke-Adb -Arguments $Arguments
    Assert-AllPackageInventory -Expected $ExpectedInventory
    return $output
}

function Assert-DevicePreflight {
    if ([string]::IsNullOrWhiteSpace($DeviceSerial)) {
        throw 'Device mode requires an explicit serial.'
    }
    $lines = (Invoke-Checked -Command $adb -Arguments @('devices', '-l')) -split "`r?`n"
    $states = @()
    foreach ($line in $lines) {
        if ($line -match '^([^\s]+)\s+(device|offline|unauthorized)(?:\s|$)') {
            $states += [pscustomobject]@{ serial = $Matches[1]; state = $Matches[2] }
        }
    }
    if (@($states | Where-Object { $_.state -in @('offline', 'unauthorized') }).Count -ne 0) {
        throw 'ADB preflight found an offline or unauthorized device.'
    }
    $usable = @($states | Where-Object { $_.state -eq 'device' })
    if ($usable.Count -ne 1 -or $usable[0].serial -ne $DeviceSerial) {
        throw 'ADB preflight did not resolve exactly the authorized usable serial.'
    }
    $model = Invoke-Adb -Arguments @('shell', 'getprop', 'ro.product.model')
    $api = Invoke-Adb -Arguments @('shell', 'getprop', 'ro.build.version.sdk')
    $abi = Invoke-Adb -Arguments @('shell', 'getprop', 'ro.product.cpu.abi')
    $storage = Invoke-Adb -Arguments @('shell', 'df', '-k', '/data')
    if ($abi.Trim() -ne 'arm64-v8a') {
        throw "Authorized device ABI is not supported by the acceptance artifact: $($abi.Trim())"
    }
    Write-Output "PREFLIGHT device=$(Get-MaskedSerial) model=$($model.Trim()) api=$($api.Trim()) abi=$($abi.Trim())"
    Write-Output ($storage -split "`r?`n" | Select-Object -Last 1)
}

function Assert-ApkContract {
    param([Parameter(Mandatory = $true)][string]$Apk)
    Invoke-Checked -Command 'py' -Arguments @(
        $verifier,
        '--apk', $Apk,
        '--expected-marker', 'CSE_ENTRYPOINT_LIVING_PLAN_ACCEPTANCE_V1',
        '--forbidden-marker', 'CSE_ENTRYPOINT_NORMAL_LIB_MAIN_DART_V1',
        '--forbidden-marker', 'CSE_ENTRYPOINT_BACKGROUND_ACCEPTANCE_V1',
        '--forbidden-marker', 'CSE_ENTRYPOINT_REBOOT_ACCEPTANCE_V1'
    ) | Out-Null
    $package = (Invoke-Checked -Command $aapt2 -Arguments @('dump', 'packagename', $Apk)).Trim()
    if ($package -ne $acceptancePackage -or
        $package -in @(
            'com.faliardic.chiefsiteengineer',
            'com.faliardic.chiefsiteengineer.debug',
            'com.faliardic.chiefsiteengineer.acceptance',
            'com.faliardic.sefim',
            'com.faliardic.sefim.debug'
        )) {
        throw "Acceptance APK package mismatch or protected identity: $package"
    }
    $badging = Invoke-Checked -Command $aapt2 -Arguments @('dump', 'badging', $Apk)
    $labelMatch = [regex]::Match(
        $badging,
        "(?m)^application-label:'([^']*)'\r?$"
    )
    if (-not $labelMatch.Success -or
        $labelMatch.Groups[1].Value -ne $acceptanceLabel) {
        throw 'Acceptance APK label is not exactly Şefim.'
    }
    $launchableMatch = [regex]::Match($badging, "launchable-activity: name='([^']+)'")
    if (-not $launchableMatch.Success) {
        throw 'Acceptance APK launchable activity was not found.'
    }
    Add-Type -AssemblyName System.IO.Compression.FileSystem
    $archive = [IO.Compression.ZipFile]::OpenRead($Apk)
    try {
        $arm64Libraries = @($archive.Entries | Where-Object {
            $_.FullName -like 'lib/arm64-v8a/*.so'
        })
        if ($arm64Libraries.Count -eq 0) {
            throw 'Acceptance APK does not contain arm64-v8a native libraries.'
        }
    } finally {
        $archive.Dispose()
    }
    return [pscustomobject]@{
        package = $package
        label = $labelMatch.Groups[1].Value
        launchableActivity = $launchableMatch.Groups[1].Value
        sha256 = (Get-FileHash -LiteralPath $Apk -Algorithm SHA256).Hash.ToLowerInvariant()
    }
}

function Get-UiHierarchy {
    $output = Invoke-Adb -Arguments @('exec-out', 'uiautomator', 'dump', '/dev/tty')
    $start = $output.IndexOf('<?xml')
    if ($start -lt 0) {
        throw 'Acceptance UI hierarchy was not readable.'
    }
    $end = $output.IndexOf('</hierarchy>', $start)
    if ($end -lt 0) {
        throw 'Acceptance UI hierarchy did not contain a closing element.'
    }
    return $output.Substring($start, ($end - $start) + 12)
}

function Get-NodeBounds {
    param([Parameter(Mandatory = $true)][System.Xml.XmlElement]$Node)
    $bounds = $Node.GetAttribute('bounds')
    if ($bounds -notmatch '^\[(\d+),(\d+)\]\[(\d+),(\d+)\]$') {
        throw "Acceptance UI bounds were invalid: $bounds"
    }
    return [pscustomobject]@{
        left = [int]$Matches[1]
        top = [int]$Matches[2]
        right = [int]$Matches[3]
        bottom = [int]$Matches[4]
    }
}

function Find-UiNode {
    param(
        [Parameter(Mandatory = $true)][xml]$Hierarchy,
        [Parameter(Mandatory = $true)][string]$Text,
        [switch]$Contains,
        [switch]$RequireClickable
    )
    $matches = @()
    foreach ($node in $Hierarchy.SelectNodes('//node')) {
        $visibleText = $node.GetAttribute('text')
        $description = $node.GetAttribute('content-desc')
        $matched = if ($Contains) {
            $visibleText.Contains($Text) -or $description.Contains($Text)
        } else {
            $visibleText -eq $Text -or $description -eq $Text
        }
        if (-not $matched) { continue }
        if ($RequireClickable -and $node.GetAttribute('clickable') -ne 'true') {
            continue
        }
        $bounds = Get-NodeBounds $node
        $matches += [pscustomobject]@{
            node = $node
            area = ($bounds.right - $bounds.left) * ($bounds.bottom - $bounds.top)
        }
    }
    if ($matches.Count -eq 0) { return $null }
    return ($matches | Sort-Object area | Select-Object -First 1).node
}

function Find-UiDescendant {
    param(
        [Parameter(Mandatory = $true)][System.Xml.XmlElement]$Root,
        [Parameter(Mandatory = $true)][string]$Text,
        [switch]$Contains,
        [switch]$RequireClickable
    )
    $matches = @()
    foreach ($node in $Root.SelectNodes('.//node')) {
        $visibleText = $node.GetAttribute('text')
        $description = $node.GetAttribute('content-desc')
        $matched = if ($Contains) {
            $visibleText.Contains($Text) -or $description.Contains($Text)
        } else {
            $visibleText -eq $Text -or $description -eq $Text
        }
        if (-not $matched) { continue }
        if ($RequireClickable -and $node.GetAttribute('clickable') -ne 'true') {
            continue
        }
        $bounds = Get-NodeBounds $node
        $matches += [pscustomobject]@{
            node = $node
            area = ($bounds.right - $bounds.left) * ($bounds.bottom - $bounds.top)
        }
    }
    if ($matches.Count -eq 0) { return $null }
    return ($matches | Sort-Object area | Select-Object -First 1).node
}

function Wait-UiDescendant {
    param(
        [Parameter(Mandatory = $true)][string]$AnchorText,
        [Parameter(Mandatory = $true)][string]$Text,
        [switch]$Contains,
        [switch]$RequireClickable,
        [int]$Attempts = 30
    )
    for ($attempt = 0; $attempt -lt $Attempts; $attempt++) {
        [xml]$hierarchy = Get-UiHierarchy
        $anchor = Find-UiNode -Hierarchy $hierarchy -Text $AnchorText -Contains
        if ($null -ne $anchor) {
            $node = Find-UiDescendant -Root $anchor -Text $Text -Contains:$Contains -RequireClickable:$RequireClickable
            if ($null -ne $node) { return $node }
        }
        Start-Sleep -Milliseconds 300
    }
    throw "Acceptance UI action was not found within ${AnchorText}: $Text"
}

function Wait-UiNode {
    param(
        [Parameter(Mandatory = $true)][string]$Text,
        [switch]$Contains,
        [switch]$RequireClickable,
        [int]$Attempts = 30
    )
    for ($attempt = 0; $attempt -lt $Attempts; $attempt++) {
        [xml]$hierarchy = Get-UiHierarchy
        $node = Find-UiNode -Hierarchy $hierarchy -Text $Text -Contains:$Contains -RequireClickable:$RequireClickable
        if ($null -ne $node) { return $node }
        Start-Sleep -Milliseconds 300
    }
    throw "Acceptance UI text was not found: $Text"
}

function Invoke-UiTap {
    param(
        [Parameter(Mandatory = $true)][System.Xml.XmlElement]$Node,
        [Parameter(Mandatory = $true)][object]$ExpectedInventory
    )
    $bounds = Get-NodeBounds $Node
    $x = [int](($bounds.left + $bounds.right) / 2)
    $y = [int](($bounds.top + $bounds.bottom) / 2)
    Invoke-IsolatedDeviceMutation -Arguments @(
        'shell', 'input', 'tap', "$x", "$y"
    ) -ExpectedInventory $ExpectedInventory | Out-Null
    Start-Sleep -Milliseconds 500
}

function Tap-UiText {
    param(
        [Parameter(Mandatory = $true)][string]$Text,
        [Parameter(Mandatory = $true)][object]$ExpectedInventory,
        [switch]$Contains,
        [switch]$RequireClickable
    )
    $node = Wait-UiNode -Text $Text -Contains:$Contains -RequireClickable:$RequireClickable
    Invoke-UiTap -Node $node -ExpectedInventory $ExpectedInventory
}

function Get-ScrollableNode {
    param([Parameter(Mandatory = $true)][xml]$Hierarchy)
    $candidates = @()
    foreach ($node in $Hierarchy.SelectNodes("//node[@scrollable='true']")) {
        $bounds = Get-NodeBounds $node
        $candidates += [pscustomobject]@{
            node = $node
            area = ($bounds.right - $bounds.left) * ($bounds.bottom - $bounds.top)
        }
    }
    if ($candidates.Count -eq 0) {
        throw 'Acceptance UI has no selector-derived scrollable boundary.'
    }
    return ($candidates | Sort-Object area -Descending | Select-Object -First 1).node
}

function Invoke-SelectorScroll {
    param(
        [Parameter(Mandatory = $true)][object]$ExpectedInventory,
        [ValidateSet('Forward', 'Backward')][string]$Direction = 'Forward'
    )
    [xml]$hierarchy = Get-UiHierarchy
    $node = Get-ScrollableNode $hierarchy
    $bounds = Get-NodeBounds $node
    $x = [int](($bounds.left + $bounds.right) / 2)
    if ($Direction -eq 'Forward') {
        $startY = [int]($bounds.top + (($bounds.bottom - $bounds.top) * 0.78))
        $endY = [int]($bounds.top + (($bounds.bottom - $bounds.top) * 0.28))
    } else {
        $startY = [int]($bounds.top + (($bounds.bottom - $bounds.top) * 0.28))
        $endY = [int]($bounds.top + (($bounds.bottom - $bounds.top) * 0.78))
    }
    Invoke-IsolatedDeviceMutation -Arguments @(
        'shell', 'input', 'swipe', "$x", "$startY", "$x", "$endY", '350'
    ) -ExpectedInventory $ExpectedInventory | Out-Null
    Start-Sleep -Milliseconds 500
}

function Scroll-UntilUiText {
    param(
        [Parameter(Mandatory = $true)][string]$Text,
        [Parameter(Mandatory = $true)][object]$ExpectedInventory,
        [switch]$Contains,
        [int]$Attempts = 10
    )
    for ($attempt = 0; $attempt -lt $Attempts; $attempt++) {
        [xml]$hierarchy = Get-UiHierarchy
        $node = Find-UiNode -Hierarchy $hierarchy -Text $Text -Contains:$Contains
        if ($null -ne $node) { return $node }
        Invoke-SelectorScroll -ExpectedInventory $ExpectedInventory
    }
    throw "Acceptance UI text was not found after selector-derived scroll: $Text"
}

function Find-UniqueUiNodeByDescriptionPattern {
    param(
        [Parameter(Mandatory = $true)][xml]$Hierarchy,
        [Parameter(Mandatory = $true)][string]$Pattern,
        [switch]$RequireClickable
    )
    $regex = [regex]::new($Pattern)
    $matches = @()
    foreach ($node in $Hierarchy.SelectNodes('//node')) {
        if (-not $regex.IsMatch($node.GetAttribute('content-desc'))) { continue }
        if ($RequireClickable -and $node.GetAttribute('clickable') -ne 'true') {
            continue
        }
        $matches += $node
    }
    if ($matches.Count -gt 1) {
        throw "Acceptance semantics selector was not unique: $Pattern"
    }
    if ($matches.Count -eq 0) { return $null }
    return $matches[0]
}

function Scroll-UntilUiDescriptionPattern {
    param(
        [Parameter(Mandatory = $true)][string]$Pattern,
        [Parameter(Mandatory = $true)][object]$ExpectedInventory,
        [switch]$RequireClickable,
        [int]$AttemptsPerDirection = 10
    )
    foreach ($direction in @('Forward', 'Backward')) {
        for ($attempt = 0; $attempt -lt $AttemptsPerDirection; $attempt++) {
            [xml]$hierarchy = Get-UiHierarchy
            $node = Find-UniqueUiNodeByDescriptionPattern `
                -Hierarchy $hierarchy `
                -Pattern $Pattern `
                -RequireClickable:$RequireClickable
            if ($null -ne $node) { return $node }
            Invoke-SelectorScroll `
                -ExpectedInventory $ExpectedInventory `
                -Direction $direction
        }
    }
    throw "Acceptance semantics selector was not visible: $Pattern"
}

function Get-LifecycleAction {
    param(
        [Parameter(Mandatory = $true)][string]$Action,
        [Parameter(Mandatory = $true)][object]$ExpectedInventory,
        [string]$ActivityName,
        [string]$ItemId
    )
    if ([string]::IsNullOrWhiteSpace($ActivityName) -eq
        [string]::IsNullOrWhiteSpace($ItemId)) {
        throw 'Lifecycle selector requires exactly one of ActivityName or ItemId.'
    }
    $prefix = [regex]::Escape($livingPlanSemanticsPrefix)
    $actionPattern = [regex]::Escape($Action)
    $pattern = if (-not [string]::IsNullOrWhiteSpace($ItemId)) {
        "^$prefix · .+ · $([regex]::Escape($ItemId)) · Eylem · $actionPattern$"
    } else {
        "^$prefix · $([regex]::Escape($ActivityName)) · .+ · (?<itemId>[0-9A-Za-z-]+) · Eylem · $actionPattern$"
    }
    $node = Scroll-UntilUiDescriptionPattern `
        -Pattern $pattern `
        -ExpectedInventory $ExpectedInventory `
        -RequireClickable
    $description = $node.GetAttribute('content-desc')
    $match = [regex]::Match($description, $pattern)
    if (-not $match.Success) {
        throw "Acceptance lifecycle selector contract could not be parsed: $description"
    }
    $resolvedItemId = if (-not [string]::IsNullOrWhiteSpace($ItemId)) {
        $ItemId
    } else {
        $match.Groups['itemId'].Value
    }
    return [pscustomobject]@{
        node = $node
        itemId = $resolvedItemId
        description = $description
    }
}

function Get-LifecycleProjectionSnapshot {
    param(
        [Parameter(Mandatory = $true)][string[]]$ItemIds,
        [Parameter(Mandatory = $true)][object]$ExpectedInventory,
        [int]$AttemptsPerDirection = 10
    )
    $statusDescriptions = @{}
    $dateDescriptions = @{}
    $statusPatterns = @{}
    $datePatterns = @{}
    $prefix = [regex]::Escape($livingPlanSemanticsPrefix)
    foreach ($itemId in $ItemIds) {
        $escapedId = [regex]::Escape($itemId)
        $statusPatterns[$itemId] = [regex]::new(
            "^$prefix · .+ · $escapedId · Durum · (Planlandı|Başladı|Tamamlandı|Ertelendi) · Kayıt sürümü · ([0-9]+)$"
        )
        $datePatterns[$itemId] = [regex]::new(
            "^$prefix · .+ · $escapedId · Plan günü · ([0-9]{2}\.[0-9]{2}\.[0-9]{4})$"
        )
    }

    foreach ($direction in @('Forward', 'Backward')) {
        for ($attempt = 0; $attempt -lt $AttemptsPerDirection; $attempt++) {
            [xml]$hierarchy = Get-UiHierarchy
            foreach ($itemId in $ItemIds) {
                $statusNodes = @($hierarchy.SelectNodes('//node') | Where-Object {
                    $statusPatterns[$itemId].IsMatch($_.GetAttribute('content-desc'))
                })
                if ($statusNodes.Count -gt 1) {
                    throw "Acceptance item status semantics was not unique: $itemId"
                }
                if ($statusNodes.Count -eq 1) {
                    $description = $statusNodes[0].GetAttribute('content-desc')
                    if ($statusDescriptions.ContainsKey($itemId) -and
                        $statusDescriptions[$itemId] -ne $description) {
                        throw "Acceptance item status changed during one checkpoint scan: $itemId"
                    }
                    $statusDescriptions[$itemId] = $description
                }

                $dateNodes = @($hierarchy.SelectNodes('//node') | Where-Object {
                    $datePatterns[$itemId].IsMatch($_.GetAttribute('content-desc'))
                })
                if ($dateNodes.Count -gt 1) {
                    throw "Acceptance item date semantics was not unique: $itemId"
                }
                if ($dateNodes.Count -eq 1) {
                    $description = $dateNodes[0].GetAttribute('content-desc')
                    if ($dateDescriptions.ContainsKey($itemId) -and
                        $dateDescriptions[$itemId] -ne $description) {
                        throw "Acceptance item date changed during one checkpoint scan: $itemId"
                    }
                    $dateDescriptions[$itemId] = $description
                }
            }
            if ($statusDescriptions.Count -eq $ItemIds.Count -and
                $dateDescriptions.Count -eq $ItemIds.Count) {
                $snapshot = [ordered]@{}
                foreach ($itemId in $ItemIds) {
                    $statusMatch = $statusPatterns[$itemId].Match($statusDescriptions[$itemId])
                    $dateMatch = $datePatterns[$itemId].Match($dateDescriptions[$itemId])
                    $snapshot[$itemId] = [pscustomobject]@{
                        status = $statusMatch.Groups[1].Value
                        revision = [int]$statusMatch.Groups[2].Value
                        plannedDate = $dateMatch.Groups[1].Value
                    }
                }
                return $snapshot
            }
            Invoke-SelectorScroll `
                -ExpectedInventory $ExpectedInventory `
                -Direction $direction
        }
    }
    $missing = @($ItemIds | Where-Object {
        -not $statusDescriptions.ContainsKey($_) -or
        -not $dateDescriptions.ContainsKey($_)
    })
    throw "Acceptance lifecycle projection was incomplete for item IDs: $($missing -join ', ')"
}

function Assert-LifecycleCheckpoint {
    param(
        [Parameter(Mandatory = $true)][string]$TargetItemId,
        [Parameter(Mandatory = $true)][string]$ExpectedStatus,
        [Parameter(Mandatory = $true)][int]$ExpectedRevision,
        [Parameter(Mandatory = $true)][object]$NeighborSnapshot,
        [Parameter(Mandatory = $true)][object]$ExpectedInventory,
        [string]$ExpectedDate
    )
    $itemIds = @($TargetItemId) + @($NeighborSnapshot.Keys)
    $current = Get-LifecycleProjectionSnapshot `
        -ItemIds $itemIds `
        -ExpectedInventory $ExpectedInventory
    $target = $current[$TargetItemId]
    if ($target.status -ne $ExpectedStatus -or
        $target.revision -ne $ExpectedRevision) {
        throw "Acceptance target lifecycle mismatch: expected $ExpectedStatus/$ExpectedRevision, got $($target.status)/$($target.revision)"
    }
    if (-not [string]::IsNullOrWhiteSpace($ExpectedDate) -and
        $target.plannedDate -ne $ExpectedDate) {
        throw "Acceptance target planned date mismatch: expected $ExpectedDate, got $($target.plannedDate)"
    }
    foreach ($itemId in $NeighborSnapshot.Keys) {
        $before = $NeighborSnapshot[$itemId]
        $after = $current[$itemId]
        if ($after.status -ne $before.status -or
            $after.revision -ne $before.revision -or
            $after.plannedDate -ne $before.plannedDate) {
            throw "Adjacent fixture item changed unexpectedly: $itemId"
        }
    }
    return $target
}

function Enter-UiText {
    param(
        [Parameter(Mandatory = $true)][string]$FieldText,
        [Parameter(Mandatory = $true)][string]$Value,
        [Parameter(Mandatory = $true)][object]$ExpectedInventory
    )
    [xml]$hierarchy = Get-UiHierarchy
    $field = $null
    foreach ($node in $hierarchy.SelectNodes("//node[@class='android.widget.EditText'][@clickable='true']")) {
        if ($node.GetAttribute('hint').Contains($FieldText) -or
            $node.GetAttribute('text').Contains($FieldText) -or
            $node.GetAttribute('content-desc').Contains($FieldText)) {
            $field = $node
            break
        }
    }
    if ($null -eq $field) {
        throw "Acceptance editable field was not found: $FieldText"
    }
    Invoke-UiTap -Node $field -ExpectedInventory $ExpectedInventory
    $encoded = $Value.Replace(' ', '%s')
    Invoke-IsolatedDeviceMutation -Arguments @(
        'shell', 'input', 'text', $encoded
    ) -ExpectedInventory $ExpectedInventory | Out-Null
    Start-Sleep -Milliseconds 300
}

function Replace-OnlyEditableText {
    param(
        [Parameter(Mandatory = $true)][string]$Value,
        [Parameter(Mandatory = $true)][object]$ExpectedInventory
    )
    [xml]$hierarchy = Get-UiHierarchy
    $fields = @($hierarchy.SelectNodes("//node[@class='android.widget.EditText'][@clickable='true']"))
    if ($fields.Count -ne 1) {
        throw "Acceptance dialog did not expose exactly one editable field: $($fields.Count)"
    }
    Invoke-UiTap -Node $fields[0] -ExpectedInventory $ExpectedInventory
    Invoke-IsolatedDeviceMutation -Arguments @(
        'shell', 'input', 'keyevent', 'KEYCODE_MOVE_END'
    ) -ExpectedInventory $ExpectedInventory | Out-Null
    $deleteArguments = @('shell', 'input', 'keyevent')
    for ($index = 0; $index -lt 96; $index++) {
        $deleteArguments += 'KEYCODE_DEL'
    }
    Invoke-IsolatedDeviceMutation `
        -Arguments $deleteArguments `
        -ExpectedInventory $ExpectedInventory | Out-Null
    $encoded = $Value.Replace(' ', '%s')
    Invoke-IsolatedDeviceMutation -Arguments @(
        'shell', 'input', 'text', $encoded
    ) -ExpectedInventory $ExpectedInventory | Out-Null
    Start-Sleep -Milliseconds 300
}

function Hide-Keyboard {
    param([Parameter(Mandatory = $true)][object]$ExpectedInventory)
    Invoke-IsolatedDeviceMutation -Arguments @(
        'shell', 'input', 'keyevent', 'KEYCODE_BACK'
    ) -ExpectedInventory $ExpectedInventory | Out-Null
    Start-Sleep -Milliseconds 300
}

function Run-LivingPlanAcceptanceFlow {
    param([Parameter(Mandatory = $true)][object]$ExpectedInventory)
    Wait-UiNode -Text 'Başlangıç' -Contains | Out-Null
    Tap-UiText -Text '7 Günlük Plan' -Contains -RequireClickable -ExpectedInventory $ExpectedInventory
    Wait-UiNode -Text 'CSE 7 Günlük Plan Pilot' -Contains | Out-Null
    Wait-UiNode -Text 'Geciken' -Contains | Out-Null
    Wait-UiNode -Text 'Önerilen tarihler tahmin niteliğindedir' -Contains | Out-Null

    $add = Scroll-UntilUiText -Text 'İmalat ekle' -Contains -ExpectedInventory $ExpectedInventory
    Invoke-UiTap -Node $add -ExpectedInventory $ExpectedInventory
    Wait-UiNode -Text 'İmalat ara' -Contains | Out-Null
    Enter-UiText -FieldText 'İmalat ara' -Value 'mobilizasyon' -ExpectedInventory $ExpectedInventory
    Invoke-IsolatedDeviceMutation -Arguments @(
        'shell', 'input', 'keyevent', 'KEYCODE_ENTER'
    ) -ExpectedInventory $ExpectedInventory | Out-Null
    Start-Sleep -Seconds 1
    $candidateName = 'Mobilizasyon planı'
    $candidate = Scroll-UntilUiText -Text $candidateName -Contains -ExpectedInventory $ExpectedInventory
    [xml]$hierarchy = Get-UiHierarchy
    $candidate = Find-UiNode -Hierarchy $hierarchy -Text $candidateName -Contains
    if ($null -eq $candidate) {
        throw "Acceptance candidate was not visible: $candidateName"
    }
    $inPlan = Find-UiDescendant -Root $candidate -Text 'Planda'
    if ($null -eq $inPlan) {
        $addCandidate = Find-UiDescendant -Root $candidate -Text 'Plana ekle' -RequireClickable
        if ($null -eq $addCandidate) {
            throw "Acceptance candidate action was not visible: $candidateName"
        }
        Invoke-UiTap -Node $addCandidate -ExpectedInventory $ExpectedInventory
        Tap-UiText -Text 'Plan gününü seç' -Contains -RequireClickable -ExpectedInventory $ExpectedInventory
        Tap-UiText -Text 'Tamam' -RequireClickable -ExpectedInventory $ExpectedInventory
        Enter-UiText -FieldText 'Kısa not (isteğe bağlı)' -Value $acceptanceNote -ExpectedInventory $ExpectedInventory
        Hide-Keyboard -ExpectedInventory $ExpectedInventory
        Tap-UiText -Text 'Plana ekle' -RequireClickable -ExpectedInventory $ExpectedInventory
        Wait-UiNode -Text 'İmalat plana eklendi.' -Contains | Out-Null
        Scroll-UntilUiText -Text $candidateName -Contains -ExpectedInventory $ExpectedInventory | Out-Null
        $inPlan = Wait-UiDescendant -AnchorText $candidateName -Text 'Planda'
    }
    if ($inPlan.GetAttribute('clickable') -ne 'false' -or
        $inPlan.GetAttribute('enabled') -ne 'false') {
        throw "Acceptance candidate duplicate action was not disabled: $candidateName"
    }
    Tap-UiText -Text 'Kapat' -Contains -RequireClickable -ExpectedInventory $ExpectedInventory

    $identityAction = Get-LifecycleAction `
        -ActivityName $candidateName `
        -Action 'Not' `
        -ExpectedInventory $ExpectedInventory
    $targetItemId = $identityAction.itemId
    $initialSnapshot = Get-LifecycleProjectionSnapshot `
        -ItemIds (@($targetItemId) + $neighborItemIds) `
        -ExpectedInventory $ExpectedInventory
    $initialTarget = $initialSnapshot[$targetItemId]
    if ($initialTarget.status -notin @('Planlandı', 'Başladı')) {
        throw "Acceptance target must resume from Planlandı or Başladı, got $($initialTarget.status)."
    }
    $neighborSnapshot = [ordered]@{}
    foreach ($neighborItemId in $neighborItemIds) {
        $neighborSnapshot[$neighborItemId] = $initialSnapshot[$neighborItemId]
    }
    $targetRevision = $initialTarget.revision
    $initialDate = $initialTarget.plannedDate

    if ($initialTarget.status -eq 'Planlandı') {
        $startAction = Get-LifecycleAction `
            -ItemId $targetItemId `
            -Action 'Başlat' `
            -ExpectedInventory $ExpectedInventory
        Invoke-UiTap -Node $startAction.node -ExpectedInventory $ExpectedInventory
        Wait-UiNode -Text 'İmalat başlatıldı.' -Contains | Out-Null
        $targetRevision += 1
        Assert-LifecycleCheckpoint `
            -TargetItemId $targetItemId `
            -ExpectedStatus 'Başladı' `
            -ExpectedRevision $targetRevision `
            -ExpectedDate $initialDate `
            -NeighborSnapshot $neighborSnapshot `
            -ExpectedInventory $ExpectedInventory | Out-Null
    }

    $noteAction = Get-LifecycleAction `
        -ItemId $targetItemId `
        -Action 'Not' `
        -ExpectedInventory $ExpectedInventory
    Invoke-UiTap -Node $noteAction.node -ExpectedInventory $ExpectedInventory
    Replace-OnlyEditableText `
        -Value $updatedAcceptanceNote `
        -ExpectedInventory $ExpectedInventory
    Hide-Keyboard -ExpectedInventory $ExpectedInventory
    Tap-UiText -Text 'Kaydet' -RequireClickable -ExpectedInventory $ExpectedInventory
    Wait-UiNode -Text 'Not kaydedildi.' -Contains | Out-Null
    Scroll-UntilUiText -Text $updatedAcceptanceNote -Contains -ExpectedInventory $ExpectedInventory | Out-Null
    $targetRevision += 1
    Assert-LifecycleCheckpoint `
        -TargetItemId $targetItemId `
        -ExpectedStatus 'Başladı' `
        -ExpectedRevision $targetRevision `
        -ExpectedDate $initialDate `
        -NeighborSnapshot $neighborSnapshot `
        -ExpectedInventory $ExpectedInventory | Out-Null

    $deferAction = Get-LifecycleAction `
        -ItemId $targetItemId `
        -Action 'Ertele' `
        -ExpectedInventory $ExpectedInventory
    Invoke-UiTap -Node $deferAction.node -ExpectedInventory $ExpectedInventory
    Tap-UiText -Text 'Tamam' -RequireClickable -ExpectedInventory $ExpectedInventory
    Wait-UiNode -Text 'İmalat ertelendi.' -Contains | Out-Null
    $targetRevision += 1
    $deferredTarget = Assert-LifecycleCheckpoint `
        -TargetItemId $targetItemId `
        -ExpectedStatus 'Ertelendi' `
        -ExpectedRevision $targetRevision `
        -NeighborSnapshot $neighborSnapshot `
        -ExpectedInventory $ExpectedInventory
    if ($deferredTarget.plannedDate -eq $initialDate) {
        throw 'Acceptance defer did not select a later target date.'
    }

    $completeAction = Get-LifecycleAction `
        -ItemId $targetItemId `
        -Action 'Tamamla' `
        -ExpectedInventory $ExpectedInventory
    Invoke-UiTap -Node $completeAction.node -ExpectedInventory $ExpectedInventory
    Wait-UiNode -Text 'İmalat tamamlandı.' -Contains | Out-Null
    $targetRevision += 1
    Assert-LifecycleCheckpoint `
        -TargetItemId $targetItemId `
        -ExpectedStatus 'Tamamlandı' `
        -ExpectedRevision $targetRevision `
        -ExpectedDate $deferredTarget.plannedDate `
        -NeighborSnapshot $neighborSnapshot `
        -ExpectedInventory $ExpectedInventory | Out-Null

    $reopenAction = Get-LifecycleAction `
        -ItemId $targetItemId `
        -Action 'Yeniden aç' `
        -ExpectedInventory $ExpectedInventory
    Invoke-UiTap -Node $reopenAction.node -ExpectedInventory $ExpectedInventory
    Tap-UiText -Text 'Tamam' -RequireClickable -ExpectedInventory $ExpectedInventory
    Wait-UiNode -Text 'İmalat yeniden açıldı.' -Contains | Out-Null
    $targetRevision += 1
    $reopenedTarget = Assert-LifecycleCheckpoint `
        -TargetItemId $targetItemId `
        -ExpectedStatus 'Planlandı' `
        -ExpectedRevision $targetRevision `
        -NeighborSnapshot $neighborSnapshot `
        -ExpectedInventory $ExpectedInventory
    Scroll-UntilUiText -Text $updatedAcceptanceNote -Contains -ExpectedInventory $ExpectedInventory | Out-Null

    return [pscustomobject]@{
        targetItemId = $targetItemId
        finalRevision = $targetRevision
        finalPlannedDate = $reopenedTarget.plannedDate
        neighborSnapshot = $neighborSnapshot
    }
}

function Assert-RelaunchPersistence {
    param(
        [Parameter(Mandatory = $true)][string]$LaunchableActivity,
        [Parameter(Mandatory = $true)][object]$ExpectedInventory,
        [Parameter(Mandatory = $true)][object]$FlowResult
    )
    Invoke-IsolatedDeviceMutation -Arguments @(
        'shell', 'am', 'force-stop', $acceptancePackage
    ) -ExpectedInventory $ExpectedInventory | Out-Null
    Invoke-IsolatedDeviceMutation -Arguments @(
        'shell', 'am', 'start', '-W', '-n',
        "$acceptancePackage/$LaunchableActivity"
    ) -ExpectedInventory $ExpectedInventory | Out-Null
    Start-Sleep -Seconds 2
    Wait-UiNode -Text 'Başlangıç' -Contains | Out-Null
    Tap-UiText -Text '7 Günlük Plan' -Contains -RequireClickable -ExpectedInventory $ExpectedInventory
    Wait-UiNode -Text 'CSE 7 Günlük Plan Pilot' -Contains | Out-Null
    Scroll-UntilUiText -Text $updatedAcceptanceNote -Contains -ExpectedInventory $ExpectedInventory | Out-Null
    Assert-LifecycleCheckpoint `
        -TargetItemId $FlowResult.targetItemId `
        -ExpectedStatus 'Planlandı' `
        -ExpectedRevision $FlowResult.finalRevision `
        -ExpectedDate $FlowResult.finalPlannedDate `
        -NeighborSnapshot $FlowResult.neighborSnapshot `
        -ExpectedInventory $ExpectedInventory | Out-Null
}

function Assert-NoFatalDiagnostics {
    $acceptancePid = (Invoke-Adb -Arguments @('shell', 'pidof', $acceptancePackage)).Trim()
    if ([string]::IsNullOrWhiteSpace($acceptancePid)) {
        throw 'Acceptance package is not running for fatal-diagnostic verification.'
    }
    $log = Invoke-Adb -Arguments @('logcat', '--pid', $acceptancePid, '-d', '-t', '1000')
    if ($log -match 'FATAL EXCEPTION|AndroidRuntime|flutter_framework_error|uncaught_platform_error|uncaught_async_error|acceptance_fixture_failed') {
        throw 'Acceptance package emitted a fatal diagnostic.'
    }
}

try {
    foreach ($requiredTool in @($aapt2, $verifier)) {
        if (-not (Test-Path -LiteralPath $requiredTool)) {
            throw "Required acceptance tool was not found: $requiredTool"
        }
    }
    $env:CSE_ACCEPTANCE_HARNESS = 'true'

    if ($Mode -eq 'Build') {
        $pubspec = Join-Path $mobileRoot 'pubspec.yaml'
        $lockfile = Join-Path $mobileRoot 'pubspec.lock'
        $pubspecBefore = (Get-FileHash -LiteralPath $pubspec -Algorithm SHA256).Hash
        $lockfileBefore = (Get-FileHash -LiteralPath $lockfile -Algorithm SHA256).Hash
        Invoke-HostFlutterBuild -Arguments @('pub', 'get', '--offline') | Write-Output
        if ((Get-FileHash -LiteralPath $pubspec -Algorithm SHA256).Hash -ne $pubspecBefore -or
            (Get-FileHash -LiteralPath $lockfile -Algorithm SHA256).Hash -ne $lockfileBefore) {
            throw 'Offline plugin metadata preparation changed pubspec or lockfile.'
        }
        $buildStarted = [DateTime]::UtcNow.AddSeconds(-2)
        Invoke-HostFlutterBuild -Arguments @(
            'build', 'apk', '--debug', '--no-pub',
            '--target', 'integration_test\living_plan_acceptance_main.dart',
            '--target-platform', 'android-arm64'
        ) | Write-Output
        if (-not (Test-Path -LiteralPath $sharedApk) -or
            (Get-Item -LiteralPath $sharedApk).LastWriteTimeUtc -lt $buildStarted) {
            throw 'Living Plan acceptance APK was not freshly produced.'
        }
        $sharedContract = Assert-ApkContract -Apk $sharedApk
        New-Item -ItemType Directory -Force -Path $artifactRoot | Out-Null
        Copy-Item -LiteralPath $sharedApk -Destination $artifact -Force
        $artifactContract = Assert-ApkContract -Apk $artifact
        if ($artifactContract.sha256 -ne $sharedContract.sha256) {
            throw 'Copied acceptance artifact SHA-256 does not match build output.'
        }
        Write-Output "PASS host_build=true package=$($artifactContract.package) label=$($artifactContract.label)"
        Write-Output "PASS artifact=$([IO.Path]::GetFileName($artifact)) sha256=$($artifactContract.sha256) abi=arm64-v8a"
        return
    }

    if (-not (Test-Path -LiteralPath $adb)) {
        throw 'Android adb was not found for device acceptance.'
    }
    if (-not (Test-Path -LiteralPath $artifact)) {
        throw 'Verified host-built Şefim acceptance APK is missing.'
    }
    $artifactContract = Assert-ApkContract -Apk $artifact
    Assert-DevicePreflight
    $beforeInstall = Get-SixPackageInventory
    foreach ($packageName in $allPackages) {
        Write-Output "BASELINE $(Convert-InventoryToJson $beforeInstall[$packageName])"
    }

    Invoke-Adb -Arguments @('install', '-r', $artifact) | Write-Output
    $afterInstall = Get-SixPackageInventory
    Assert-NonTargetInventory -Expected $beforeInstall -Actual $afterInstall
    if (-not $afterInstall[$acceptancePackage].installed) {
        throw 'Şefim acceptance package was not installed.'
    }
    $expectedInventory = $afterInstall
    Assert-AllPackageInventory -Expected $expectedInventory

    Invoke-IsolatedDeviceMutation -Arguments @(
        'shell', 'am', 'start', '-W', '-n',
        "$acceptancePackage/$($artifactContract.launchableActivity)"
    ) -ExpectedInventory $expectedInventory | Out-Null
    Start-Sleep -Seconds 2
    $flowResult = Run-LivingPlanAcceptanceFlow -ExpectedInventory $expectedInventory
    Assert-RelaunchPersistence `
        -LaunchableActivity $artifactContract.launchableActivity `
        -ExpectedInventory $expectedInventory `
        -FlowResult $flowResult
    Assert-NoFatalDiagnostics
    Assert-AllPackageInventory -Expected $expectedInventory

    Write-Output "PASS acceptance_package=$acceptancePackage label=$acceptanceLabel"
    Write-Output "PASS artifact=$([IO.Path]::GetFileName($artifact)) sha256=$($artifactContract.sha256) abi=arm64-v8a"
    Write-Output "PASS target_item=$($flowResult.targetItemId) final_revision=$($flowResult.finalRevision) final_date=$($flowResult.finalPlannedDate)"
    Write-Output 'PASS six_package_isolation=true full_flow=true persistence_after_relaunch=true fatal_diagnostics=false'
} finally {
    $env:CSE_ACCEPTANCE_HARNESS = $previousAcceptanceHarness
}
