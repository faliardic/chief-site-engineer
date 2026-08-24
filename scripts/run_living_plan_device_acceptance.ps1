[CmdletBinding()]
param(
    [ValidateSet('Build', 'Device')]
    [string]$Mode = 'Build',

    [string]$DeviceSerial,

    [ValidateSet('Full', 'CleanRelaunch')]
    [string]$DeviceScenario = 'Full',

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
$artifact = Join-Path $artifactRoot 'sefim-0.1.0-issue476-living-plan-intelligence-acceptance-debug.apk'
$acceptancePackage = 'com.faliardic.sefim.acceptance'
$acceptanceLabel = 'Şefim'
$acceptanceEnvironmentLabel = 'Kabul ortamı · sentetik veri'
$acceptanceNote = 'Acceptance persistence notu'
$updatedAcceptanceNote = "$acceptanceNote guncellendi"
$livingPlanSemanticsPrefix = 'Yaşayan plan öğesi'
$intelligenceItemId = '47600000-0000-4000-8000-000000000041'
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
$script:activeAcceptanceCheckpoint = 'not_started'
$script:lastSuccessfulAcceptanceStep = 'not_started'

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
    $script:activeAcceptanceCheckpoint = "device_mutation:$($Arguments -join ' ')"
    $output = Invoke-Adb -Arguments $Arguments
    Assert-AllPackageInventory -Expected $ExpectedInventory
    $script:lastSuccessfulAcceptanceStep = $script:activeAcceptanceCheckpoint
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
    $script:activeAcceptanceCheckpoint = "wait_ui_descendant:${AnchorText}:$Text"
    for ($attempt = 0; $attempt -lt $Attempts; $attempt++) {
        [xml]$hierarchy = Get-UiHierarchy
        $anchor = Find-UiNode -Hierarchy $hierarchy -Text $AnchorText -Contains
        if ($null -ne $anchor) {
            $node = Find-UiDescendant -Root $anchor -Text $Text -Contains:$Contains -RequireClickable:$RequireClickable
            if ($null -ne $node) {
                $script:lastSuccessfulAcceptanceStep = $script:activeAcceptanceCheckpoint
                return $node
            }
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
    $script:activeAcceptanceCheckpoint = "wait_ui_node:$Text"
    for ($attempt = 0; $attempt -lt $Attempts; $attempt++) {
        [xml]$hierarchy = Get-UiHierarchy
        $node = Find-UiNode -Hierarchy $hierarchy -Text $Text -Contains:$Contains -RequireClickable:$RequireClickable
        if ($null -ne $node) {
            $script:lastSuccessfulAcceptanceStep = $script:activeAcceptanceCheckpoint
            return $node
        }
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

function ConvertTo-BoundedUiHierarchyEvidence {
    param(
        [Parameter(Mandatory = $true)][xml]$Hierarchy,
        [int]$MaximumNodes = 80
    )
    $eligible = @()
    $ordinal = 0
    foreach ($node in $Hierarchy.SelectNodes('//node')) {
        $text = $node.GetAttribute('text')
        $description = $node.GetAttribute('content-desc')
        $resourceId = $node.GetAttribute('resource-id')
        $hint = $node.GetAttribute('hint')
        $clickable = $node.GetAttribute('clickable')
        $focusable = $node.GetAttribute('focusable')
        $meaningful = -not [string]::IsNullOrWhiteSpace($text) -or
            -not [string]::IsNullOrWhiteSpace($description) -or
            -not [string]::IsNullOrWhiteSpace($resourceId) -or
            -not [string]::IsNullOrWhiteSpace($hint) -or
            $clickable -eq 'true' -or $focusable -eq 'true'
        if (-not $meaningful) { continue }
        $containsSave = $text.Contains('Kaydet') -or
            $description.Contains('Kaydet') -or $hint.Contains('Kaydet')
        $interactive = $clickable -eq 'true' -or $focusable -eq 'true'
        $priority = if ($containsSave) { 0 } elseif ($interactive) { 1 } else { 2 }
        $eligible += [pscustomobject]@{
            ordinal = $ordinal
            priority = $priority
            text = $text
            contentDesc = $description
            resourceId = $resourceId
            hint = $hint
            className = $node.GetAttribute('class')
            clickable = $clickable
            enabled = $node.GetAttribute('enabled')
            focusable = $focusable
            focused = $node.GetAttribute('focused')
            bounds = $node.GetAttribute('bounds')
        }
        $ordinal += 1
    }
    $captured = @($eligible |
        Sort-Object -Property priority, ordinal |
        Select-Object -First $MaximumNodes)
    return [pscustomobject]@{
        totalMeaningfulNodes = $eligible.Count
        maximumNodes = $MaximumNodes
        capturedNodes = $captured.Count
        truncated = $eligible.Count -gt $MaximumNodes
        nodes = $captured
    }
}

function Tap-KaydetWithObservability {
    param(
        [Parameter(Mandatory = $true)][string]$CallerLabel,
        [Parameter(Mandatory = $true)][string]$FlowLabel,
        [Parameter(Mandatory = $true)][string]$PrecedingCheckpoint,
        [Parameter(Mandatory = $true)][object]$ExpectedInventory
    )
    $checkpoint = [ordered]@{
        event = 'kaydet_lookup_checkpoint'
        caller = $CallerLabel
        flow = $FlowLabel
        precedingCheckpoint = $PrecedingCheckpoint
    }
    Write-Output "DIAGNOSTIC_KAYDET_CHECKPOINT $($checkpoint | ConvertTo-Json -Compress)"
    try {
        $node = Wait-UiNode -Text 'Kaydet' -RequireClickable
    } catch {
        $lookupError = $_
        $failure = [ordered]@{
            event = 'kaydet_lookup_failure'
            caller = $CallerLabel
            flow = $FlowLabel
            precedingCheckpoint = $PrecedingCheckpoint
            error = $lookupError.Exception.Message
        }
        Write-Output "DIAGNOSTIC_KAYDET_FAILURE $($failure | ConvertTo-Json -Compress)"
        try {
            [xml]$failureHierarchy = Get-UiHierarchy
            $snapshot = ConvertTo-BoundedUiHierarchyEvidence `
                -Hierarchy $failureHierarchy `
                -MaximumNodes 80
            $hierarchyEvidence = [ordered]@{
                event = 'kaydet_failure_hierarchy'
                caller = $CallerLabel
                flow = $FlowLabel
                precedingCheckpoint = $PrecedingCheckpoint
                snapshot = $snapshot
            }
            Write-Output "DIAGNOSTIC_KAYDET_HIERARCHY $($hierarchyEvidence | ConvertTo-Json -Compress -Depth 10)"
        } catch {
            $captureFailure = [ordered]@{
                event = 'kaydet_failure_hierarchy_capture_failed'
                caller = $CallerLabel
                flow = $FlowLabel
                precedingCheckpoint = $PrecedingCheckpoint
                error = $_.Exception.Message
            }
            Write-Output "DIAGNOSTIC_KAYDET_HIERARCHY_FAILURE $($captureFailure | ConvertTo-Json -Compress)"
        }
        throw $lookupError
    }
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

function Convert-CanonicalDateToDisplay {
    param([Parameter(Mandatory = $true)][string]$Value)
    return [DateTime]::ParseExact(
        $Value,
        'yyyy-MM-dd',
        [Globalization.CultureInfo]::InvariantCulture
    ).ToString('dd.MM.yyyy', [Globalization.CultureInfo]::InvariantCulture)
}

function Convert-DurableStatusToUi {
    param([Parameter(Mandatory = $true)][string]$Status)
    switch ($Status) {
        'PLANNED' { return 'Planlandı' }
        'STARTED' { return 'Başladı' }
        'COMPLETED' { return 'Tamamlandı' }
        'DEFERRED' { return 'Ertelendi' }
        default { throw "Unsupported durable Living Plan status: $Status" }
    }
}

function Convert-DurableProgressToUi {
    param([AllowNull()][object]$Progress)
    if ($null -eq $Progress) { return 'Raporlanmadı' }
    return "%$([int]$Progress)"
}

function Find-LivingPlanWindowStartInHierarchy {
    param([Parameter(Mandatory = $true)][xml]$Hierarchy)
    $pattern = [regex]::new('^([0-9]{2}\.[0-9]{2}\.[0-9]{4}) başlangıç$')
    $values = @()
    foreach ($node in $Hierarchy.SelectNodes('//node')) {
        foreach ($attribute in @('text', 'content-desc')) {
            $match = $pattern.Match($node.GetAttribute($attribute))
            if ($match.Success) { $values += $match.Groups[1].Value }
        }
    }
    $unique = @($values | Sort-Object -Unique)
    if ($unique.Count -gt 1) { throw 'Acceptance UI exposed multiple Living Plan window starts.' }
    if ($unique.Count -eq 0) { return $null }
    return [DateTime]::ParseExact(
        $unique[0],
        'dd.MM.yyyy',
        [Globalization.CultureInfo]::InvariantCulture
    )
}

function Get-LivingPlanWindowStart {
    param(
        [Parameter(Mandatory = $true)][object]$ExpectedInventory,
        [int]$AttemptsPerDirection = 12
    )
    foreach ($direction in @('Backward', 'Forward')) {
        for ($attempt = 0; $attempt -lt $AttemptsPerDirection; $attempt++) {
            [xml]$hierarchy = Get-UiHierarchy
            $windowStart = Find-LivingPlanWindowStartInHierarchy -Hierarchy $hierarchy
            if ($null -ne $windowStart) { return $windowStart }
            Invoke-SelectorScroll -ExpectedInventory $ExpectedInventory -Direction $direction
        }
    }
    throw 'Acceptance Living Plan window-start control was not visible.'
}

function Invoke-LivingPlanWindowShift {
    param(
        [Parameter(Mandatory = $true)][ValidateSet('Previous', 'Next')][string]$Direction,
        [Parameter(Mandatory = $true)][object]$ExpectedInventory
    )
    $before = Get-LivingPlanWindowStart -ExpectedInventory $ExpectedInventory
    $description = if ($Direction -eq 'Previous') { 'Önceki yedi gün' } else { 'Sonraki yedi gün' }
    $node = Scroll-UntilUiDescriptionPattern -Pattern ("^" + [regex]::Escape($description) + "$") -ExpectedInventory $ExpectedInventory -RequireClickable
    Invoke-UiTap -Node $node -ExpectedInventory $ExpectedInventory
    $expected = $before.AddDays($(if ($Direction -eq 'Previous') { -7 } else { 7 }))
    for ($attempt = 0; $attempt -lt 30; $attempt++) {
        [xml]$hierarchy = Get-UiHierarchy
        $observed = Find-LivingPlanWindowStartInHierarchy -Hierarchy $hierarchy
        if ($null -ne $observed) {
            if ($observed -eq $expected) { return $observed }
            if ($observed -ne $before) {
                throw "Acceptance Living Plan window shifted unexpectedly: $($observed.ToString('dd.MM.yyyy'))"
            }
        }
        Start-Sleep -Milliseconds 300
    }
    throw "Acceptance Living Plan window did not shift $Direction."
}

function Set-LivingPlanWindowForDate {
    param(
        [Parameter(Mandatory = $true)][string]$PlannedDate,
        [Parameter(Mandatory = $true)][object]$ExpectedInventory,
        [int]$MaxWindowShifts = 110
    )
    $target = [DateTime]::ParseExact(
        $PlannedDate,
        'dd.MM.yyyy',
        [Globalization.CultureInfo]::InvariantCulture
    )
    $current = Get-LivingPlanWindowStart -ExpectedInventory $ExpectedInventory
    for ($shift = 0; $shift -le $MaxWindowShifts; $shift++) {
        if ($target -ge $current -and $target -le $current.AddDays(6)) { return $current }
        if ($shift -eq $MaxWindowShifts) { break }
        $direction = if ($target -lt $current) { 'Previous' } else { 'Next' }
        $current = Invoke-LivingPlanWindowShift -Direction $direction -ExpectedInventory $ExpectedInventory
    }
    throw "Acceptance could not resolve a bounded Living Plan window for: $PlannedDate"
}

function Get-LifecycleAction {
    param(
        [Parameter(Mandatory = $true)][string]$Action,
        [Parameter(Mandatory = $true)][object]$ExpectedInventory,
        [string]$ActivityName,
        [string]$ItemId,
        [int]$AttemptsPerDirection = 10
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
    $node = $null
    $tapPointBlocked = $false
    for ($tapAttempt = 0; $tapAttempt -lt $AttemptsPerDirection; $tapAttempt++) {
        $node = Scroll-UntilUiDescriptionPattern `
            -Pattern $pattern `
            -ExpectedInventory $ExpectedInventory `
            -RequireClickable `
            -AttemptsPerDirection $AttemptsPerDirection
        $targetBounds = Get-NodeBounds $node
        $targetX = [int](($targetBounds.left + $targetBounds.right) / 2)
        $targetY = [int](($targetBounds.top + $targetBounds.bottom) / 2)
        [xml]$hierarchy = $node.OwnerDocument
        $addButton = Find-UiNode `
            -Hierarchy $hierarchy `
            -Text 'İmalat ekle' `
            -Contains `
            -RequireClickable
        $tapPointBlocked = $false
        if ($null -ne $addButton) {
            $addBounds = Get-NodeBounds $addButton
            $tapPointBlocked = $targetX -ge $addBounds.left -and
                $targetX -le $addBounds.right -and
                $targetY -ge $addBounds.top -and
                $targetY -le $addBounds.bottom
        }
        if (-not $tapPointBlocked) { break }
        Invoke-SelectorScroll -ExpectedInventory $ExpectedInventory -Direction Forward
    }
    if ($tapPointBlocked) {
        throw "Acceptance lifecycle action tap point remained occluded: $Action"
    }
    $description = $node.GetAttribute('content-desc')
    $match = [regex]::Match($description, $pattern)
    if (-not $match.Success) { throw "Acceptance lifecycle selector contract could not be parsed: $description" }
    $resolvedItemId = if (-not [string]::IsNullOrWhiteSpace($ItemId)) { $ItemId } else { $match.Groups['itemId'].Value }
    return [pscustomobject]@{ node=$node; itemId=$resolvedItemId; description=$description }
}

function Get-LifecycleActionAcrossWindows {
    param(
        [Parameter(Mandatory = $true)][string]$Action,
        [Parameter(Mandatory = $true)][object]$ExpectedInventory,
        [string]$ActivityName,
        [string]$ItemId,
        [int]$MaxWindowsPerDirection = 110
    )
    $origin = Get-LivingPlanWindowStart -ExpectedInventory $ExpectedInventory
    $lastMissing = $null
    try {
        return Get-LifecycleAction -Action $Action -ExpectedInventory $ExpectedInventory -ActivityName $ActivityName -ItemId $ItemId -AttemptsPerDirection 3
    } catch {
        if ($_.Exception.Message -notlike 'Acceptance semantics selector was not visible:*') { throw }
        $lastMissing = $_
    }
    for ($window = 0; $window -lt $MaxWindowsPerDirection; $window++) {
        Invoke-LivingPlanWindowShift -Direction Previous -ExpectedInventory $ExpectedInventory | Out-Null
        try {
            return Get-LifecycleAction -Action $Action -ExpectedInventory $ExpectedInventory -ActivityName $ActivityName -ItemId $ItemId -AttemptsPerDirection 3
        } catch {
            if ($_.Exception.Message -notlike 'Acceptance semantics selector was not visible:*') { throw }
            $lastMissing = $_
        }
    }
    Set-LivingPlanWindowForDate -PlannedDate $origin.ToString('dd.MM.yyyy') -ExpectedInventory $ExpectedInventory | Out-Null
    for ($window = 0; $window -lt $MaxWindowsPerDirection; $window++) {
        Invoke-LivingPlanWindowShift -Direction Next -ExpectedInventory $ExpectedInventory | Out-Null
        try {
            return Get-LifecycleAction -Action $Action -ExpectedInventory $ExpectedInventory -ActivityName $ActivityName -ItemId $ItemId -AttemptsPerDirection 3
        } catch {
            if ($_.Exception.Message -notlike 'Acceptance semantics selector was not visible:*') { throw }
            $lastMissing = $_
        }
    }
    throw "Acceptance lifecycle action was not found in bounded windows: $Action. $($lastMissing.Exception.Message)"
}

function Get-LifecycleProjectionSnapshot {
    param(
        [Parameter(Mandatory = $true)][string[]]$ItemIds,
        [Parameter(Mandatory = $true)][object]$ExpectedInventory,
        [int]$AttemptsPerDirection = 10
    )
    $statusDescriptions = @{}
    $dateDescriptions = @{}
    $progressDescriptions = @{}
    $statusPatterns = @{}
    $datePatterns = @{}
    $progressPatterns = @{}
    $prefix = [regex]::Escape($livingPlanSemanticsPrefix)
    foreach ($itemId in $ItemIds) {
        $escapedId = [regex]::Escape($itemId)
        $statusPatterns[$itemId] = [regex]::new(
            "^$prefix · .+ · $escapedId · Durum · (Planlandı|Başladı|Tamamlandı|Ertelendi) · Kayıt sürümü · ([0-9]+)$"
        )
        $datePatterns[$itemId] = [regex]::new(
            "^$prefix · .+ · $escapedId · Plan günü · ([0-9]{2}\.[0-9]{2}\.[0-9]{4})$"
        )
        $progressPatterns[$itemId] = [regex]::new(
            "^$prefix · .+ · $escapedId · İlerleme · (Raporlanmadı|%[0-9]{1,3})$"
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

                $progressNodes = @($hierarchy.SelectNodes('//node') | Where-Object {
                    $progressPatterns[$itemId].IsMatch($_.GetAttribute('content-desc'))
                })
                if ($progressNodes.Count -gt 1) {
                    throw "Acceptance item progress semantics was not unique: $itemId"
                }
                if ($progressNodes.Count -eq 1) {
                    $description = $progressNodes[0].GetAttribute('content-desc')
                    if ($progressDescriptions.ContainsKey($itemId) -and
                        $progressDescriptions[$itemId] -ne $description) {
                        throw "Acceptance item progress changed during one checkpoint scan: $itemId"
                    }
                    $progressDescriptions[$itemId] = $description
                }
            }
            if ($statusDescriptions.Count -eq $ItemIds.Count -and
                $dateDescriptions.Count -eq $ItemIds.Count -and
                $progressDescriptions.Count -eq $ItemIds.Count) {
                $snapshot = [ordered]@{}
                foreach ($itemId in $ItemIds) {
                    $statusMatch = $statusPatterns[$itemId].Match($statusDescriptions[$itemId])
                    $dateMatch = $datePatterns[$itemId].Match($dateDescriptions[$itemId])
                    $progressMatch = $progressPatterns[$itemId].Match($progressDescriptions[$itemId])
                    $snapshot[$itemId] = [pscustomobject]@{
                        status = $statusMatch.Groups[1].Value
                        revision = [int]$statusMatch.Groups[2].Value
                        plannedDate = $dateMatch.Groups[1].Value
                        progress = $progressMatch.Groups[1].Value
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
        -not $dateDescriptions.ContainsKey($_) -or
        -not $progressDescriptions.ContainsKey($_)
    })
    throw "Acceptance lifecycle projection was incomplete for item IDs: $($missing -join ', ')"
}

function Get-DurableLivingPlanSnapshot {
    param([Parameter(Mandatory = $true)][string]$ItemId)

    $databasePath = 'files/cse_mobile/debug/database/cse_mobile.sqlite3'
    $encoded = Invoke-Adb -Arguments @(
        'exec-out', 'run-as', $acceptancePackage, 'base64', $databasePath
    )
    $bytes = [Convert]::FromBase64String(($encoded -replace '\s', ''))
    $tempDatabase = Join-Path `
        ([IO.Path]::GetTempPath()) `
        "cse-living-plan-$([guid]::NewGuid().ToString('N')).sqlite3"
    [IO.File]::WriteAllBytes($tempDatabase, $bytes)
    try {
        $query = @"
import json, sqlite3, sys
p, item_id = sys.argv[1:3]
c = sqlite3.connect('file:' + p.replace('\\', '/') + '?mode=ro&immutable=1', uri=True)
c.row_factory = sqlite3.Row
def one(sql):
    row = c.execute(sql, (item_id,)).fetchone()
    return dict(row) if row is not None else None
def rows(sql): return [dict(row) for row in c.execute(sql, (item_id,))]
item = one('''SELECT id,status,progress_percent,planned_date,note,revision,
 updated_at,status_changed_at FROM project_living_plan_items WHERE id=?''')
history = one('''SELECT count(*) event_count,min(sequence) first_sequence,
 max(sequence) last_sequence FROM project_living_plan_events
 WHERE living_plan_item_id=?''')
receipts = rows('''SELECT id,event_type,intent_json,result_json,result_revision,
 is_no_op,event_sequence FROM project_living_plan_command_receipts
 WHERE living_plan_item_id=? ORDER BY rowid''')
events = rows('''SELECT id,sequence,event_type FROM project_living_plan_events
 WHERE living_plan_item_id=? ORDER BY sequence''')
incoherent = one('''SELECT count(*) count
 FROM project_living_plan_command_receipts r
 LEFT JOIN project_living_plan_events e ON e.id=r.id
 WHERE r.living_plan_item_id=? AND (
 (r.is_no_op=1 AND (r.event_sequence IS NOT NULL OR e.id IS NOT NULL)) OR
 (r.is_no_op=0 AND (e.id IS NULL OR r.event_sequence!=r.result_revision OR
 e.sequence!=r.result_revision OR e.event_type!=r.event_type)))''')
for receipt in receipts:
    receipt['intent'] = json.loads(receipt.pop('intent_json'))
    receipt['result'] = json.loads(receipt.pop('result_json'))
print(json.dumps({'item':item,'history':history,'receipts':receipts,
 'events':events,'incoherent_receipt_count':incoherent['count']},
 ensure_ascii=True,separators=(',',':')))
"@
        $json = Invoke-Checked `
            -Command 'py' `
            -Arguments @('-c', $query, $tempDatabase, $ItemId)
        return $json | ConvertFrom-Json
    } finally {
        Remove-Item -LiteralPath $tempDatabase -Force
    }
}

function Assert-DurableLivingPlanSnapshot {
    param([Parameter(Mandatory = $true)][object]$Snapshot)
    if ($null -eq $Snapshot.item) { throw 'Acceptance durable projection item was missing.' }
    $revision = [int]$Snapshot.item.revision
    if ([int]$Snapshot.history.event_count -ne $revision -or
        [int]$Snapshot.history.first_sequence -ne 1 -or
        [int]$Snapshot.history.last_sequence -ne $revision -or
        [int]$Snapshot.incoherent_receipt_count -ne 0) {
        throw 'Acceptance durable projection, receipt and event history were incoherent.'
    }
    $progress = $Snapshot.item.progress_percent
    if (($Snapshot.item.status -eq 'COMPLETED' -and
            ($null -eq $progress -or [int]$progress -ne 100)) -or
        ($Snapshot.item.status -ne 'COMPLETED' -and
            $null -ne $progress -and
            ([int]$progress -lt 0 -or [int]$progress -gt 99))) {
        throw 'Acceptance durable status/progress invariant was incoherent.'
    }
    return $Snapshot.item
}

function Resolve-DurableLivingPlanMutationRevision {
    param(
        [Parameter(Mandatory = $true)][object]$Before,
        [Parameter(Mandatory = $true)][object]$After,
        [Parameter(Mandatory = $true)][string]$ExpectedEventType,
        [Parameter(Mandatory = $true)][string]$ExpectedStatus,
        [Parameter(Mandatory = $true)][AllowNull()][object]$ExpectedProgress,
        [Parameter(Mandatory = $true)][string]$ExpectedDate,
        [Parameter(Mandatory = $true)][AllowEmptyString()][string]$ExpectedNote,
        [string]$ExpectedIntentField,
        [AllowNull()][object]$ExpectedIntentValue
    )
    $beforeItem = Assert-DurableLivingPlanSnapshot -Snapshot $Before
    $afterItem = Assert-DurableLivingPlanSnapshot -Snapshot $After
    $beforeReceiptIds = [Collections.Generic.HashSet[string]]::new()
    foreach ($receipt in @($Before.receipts)) { [void]$beforeReceiptIds.Add([string]$receipt.id) }
    $newReceipts = @($After.receipts | Where-Object { -not $beforeReceiptIds.Contains([string]$_.id) })
    if ((@($After.receipts).Count) -ne ((@($Before.receipts).Count) + 1) -or $newReceipts.Count -ne 1) {
        throw 'Acceptance mutation did not append exactly one durable receipt.'
    }
    $receipt = $newReceipts[0]
    if ($receipt.event_type -ne $ExpectedEventType -or
        $receipt.intent.operation -ne $ExpectedEventType -or
        [int]$receipt.intent.expected_revision -ne [int]$beforeItem.revision) {
        throw 'Acceptance durable receipt intent did not match the operation.'
    }
    if ($ExpectedEventType -eq 'NOTE_UPDATED' -and $receipt.intent.note -ne $ExpectedNote) {
        throw 'Acceptance durable note intent did not match the operation.'
    }
    if (-not [string]::IsNullOrWhiteSpace($ExpectedIntentField)) {
        $intentProperty = $receipt.intent.PSObject.Properties[$ExpectedIntentField]
        if ($null -eq $intentProperty -or $intentProperty.Value -ne $ExpectedIntentValue) {
            throw "Acceptance durable receipt intent field did not match: $ExpectedIntentField"
        }
    }
    $beforeEventIds = [Collections.Generic.HashSet[string]]::new()
    foreach ($event in @($Before.events)) { [void]$beforeEventIds.Add([string]$event.id) }
    $newEvents = @($After.events | Where-Object { -not $beforeEventIds.Contains([string]$_.id) })
    $beforeRevision = [int]$beforeItem.revision
    $afterRevision = [int]$afterItem.revision
    $isNoOp = [int]$receipt.is_no_op -eq 1
    if ($isNoOp) {
        if ($afterRevision -ne $beforeRevision -or $null -ne $receipt.event_sequence -or
            $newEvents.Count -ne 0 -or (@($After.events).Count) -ne (@($Before.events).Count)) {
            throw 'Acceptance durable no-op changed revision or appended an event.'
        }
        foreach ($field in @('status','progress_percent','planned_date','note','revision','updated_at','status_changed_at')) {
            if ($afterItem.$field -ne $beforeItem.$field) { throw "Acceptance durable no-op changed projection field: $field" }
        }
    } else {
        if ($afterRevision -ne ($beforeRevision + 1) -or
            [int]$receipt.event_sequence -ne $afterRevision -or $newEvents.Count -ne 1 -or
            (@($After.events).Count) -ne ((@($Before.events).Count) + 1)) {
            throw 'Acceptance changed mutation did not advance exactly one revision/event.'
        }
        $event = $newEvents[0]
        if ($event.id -ne $receipt.id -or $event.event_type -ne $ExpectedEventType -or
            [int]$event.sequence -ne $afterRevision) {
            throw 'Acceptance changed mutation event was not aligned with its receipt.'
        }
    }
    if ([int]$receipt.result_revision -ne $afterRevision -or
        [int]$receipt.result.revision -ne $afterRevision -or
        $receipt.result.status -ne $afterItem.status -or
        $receipt.result.progress_percent -ne $afterItem.progress_percent -or
        $receipt.result.planned_date -ne $afterItem.planned_date -or
        $receipt.result.note -ne $afterItem.note -or
        $receipt.result.updated_at -ne $afterItem.updated_at -or
        $receipt.result.status_changed_at -ne $afterItem.status_changed_at -or
        $afterItem.status -ne $ExpectedStatus -or
        $afterItem.progress_percent -ne $ExpectedProgress -or
        $afterItem.planned_date -ne $ExpectedDate -or
        $afterItem.note -ne $ExpectedNote) {
        throw 'Acceptance durable receipt result did not align with the projection.'
    }
    return $afterRevision
}

function Assert-LifecycleCheckpoint {
    param(
        [Parameter(Mandatory = $true)][string]$TargetItemId,
        [Parameter(Mandatory = $true)][string]$ExpectedStatus,
        [Parameter(Mandatory = $true)][int]$ExpectedRevision,
        [Parameter(Mandatory = $true)][string]$ExpectedProgress,
        [Parameter(Mandatory = $true)][object]$NeighborSnapshot,
        [Parameter(Mandatory = $true)][object]$ExpectedInventory,
        [string]$ExpectedDate
    )
    if ([string]::IsNullOrWhiteSpace($ExpectedDate)) {
        $durable = Get-DurableLivingPlanSnapshot -ItemId $TargetItemId
        $item = Assert-DurableLivingPlanSnapshot -Snapshot $durable
        $ExpectedDate = Convert-CanonicalDateToDisplay -Value $item.planned_date
    }
    Set-LivingPlanWindowForDate -PlannedDate $ExpectedDate -ExpectedInventory $ExpectedInventory | Out-Null
    $currentTarget = Get-LifecycleProjectionSnapshot -ItemIds @($TargetItemId) -ExpectedInventory $ExpectedInventory
    $target = $currentTarget[$TargetItemId]
    if ($target.status -ne $ExpectedStatus -or $target.revision -ne $ExpectedRevision) {
        throw "Acceptance target lifecycle mismatch: expected $ExpectedStatus/$ExpectedRevision, got $($target.status)/$($target.revision)"
    }
    if ($target.progress -ne $ExpectedProgress) { throw "Acceptance target progress mismatch: expected $ExpectedProgress, got $($target.progress)" }
    if ($target.plannedDate -ne $ExpectedDate) { throw "Acceptance target planned date mismatch: expected $ExpectedDate, got $($target.plannedDate)" }
    foreach ($itemId in $NeighborSnapshot.Keys) {
        $before = $NeighborSnapshot[$itemId]
        Set-LivingPlanWindowForDate -PlannedDate $before.plannedDate -ExpectedInventory $ExpectedInventory | Out-Null
        $currentNeighbor = Get-LifecycleProjectionSnapshot -ItemIds @($itemId) -ExpectedInventory $ExpectedInventory
        $after = $currentNeighbor[$itemId]
        if ($after.status -ne $before.status -or $after.revision -ne $before.revision -or
            $after.plannedDate -ne $before.plannedDate -or $after.progress -ne $before.progress) {
            throw "Adjacent fixture item changed unexpectedly: $itemId"
        }
    }
    Set-LivingPlanWindowForDate -PlannedDate $ExpectedDate -ExpectedInventory $ExpectedInventory | Out-Null
    return $target
}

function Assert-LifecycleActionAbsent {
    param(
        [Parameter(Mandatory = $true)][string]$ItemId,
        [Parameter(Mandatory = $true)][string]$Action,
        [Parameter(Mandatory = $true)][object]$ExpectedInventory,
        [int]$AttemptsPerDirection = 8
    )
    $prefix = [regex]::Escape($livingPlanSemanticsPrefix)
    $pattern = "^$prefix · .+ · $([regex]::Escape($ItemId)) · Eylem · $([regex]::Escape($Action))$"
    foreach ($direction in @('Forward', 'Backward')) {
        for ($attempt = 0; $attempt -lt $AttemptsPerDirection; $attempt++) {
            [xml]$hierarchy = Get-UiHierarchy
            $node = Find-UniqueUiNodeByDescriptionPattern `
                -Hierarchy $hierarchy `
                -Pattern $pattern
            if ($null -ne $node) {
                throw "Acceptance action must be absent for ${ItemId}: $Action"
            }
            Invoke-SelectorScroll `
                -ExpectedInventory $ExpectedInventory `
                -Direction $direction
        }
    }
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

function Assert-LivingPlanIntelligenceReadOnly {
    param([Parameter(Mandatory = $true)][object]$ExpectedInventory)

    $before = Get-DurableLivingPlanSnapshot -ItemId $intelligenceItemId
    $item = Assert-DurableLivingPlanSnapshot -Snapshot $before
    if ($item.status -ne 'STARTED' -or $null -eq $item.progress_percent -or
        [int]$item.progress_percent -lt 0 -or [int]$item.progress_percent -gt 99) {
        throw 'Acceptance intelligence source was not STARTED with explicit progress.'
    }
    $plannedDate = Convert-CanonicalDateToDisplay -Value $item.planned_date
    Set-LivingPlanWindowForDate -PlannedDate $plannedDate -ExpectedInventory $ExpectedInventory | Out-Null
    $summaryPattern = [regex]::Escape($intelligenceItemId) +
        '.*Tahmini kalan:.*Tahmini bitiş:.*Referansa göre:'
    Scroll-UntilUiDescriptionPattern `
        -Pattern $summaryPattern `
        -ExpectedInventory $ExpectedInventory | Out-Null
    $actionPattern = [regex]::Escape($intelligenceItemId) +
        '.*Eylem.*\d+ sonraki iş etkilenebilir'
    $action = Scroll-UntilUiDescriptionPattern `
        -Pattern $actionPattern `
        -RequireClickable `
        -ExpectedInventory $ExpectedInventory
    Invoke-UiTap -Node $action -ExpectedInventory $ExpectedInventory

    Wait-UiNode -Text 'Tahmini etki' | Out-Null
    Wait-UiNode -Text 'Bu bir önizlemedir; plan tarihleri değişmedi.' | Out-Null
    Wait-UiNode -Text 'Tahmini başlangıç:' -Contains | Out-Null
    Wait-UiNode -Text 'Tahmini bitiş:' -Contains | Out-Null
    [xml]$detailHierarchy = Get-UiHierarchy
    $positiveShift = @($detailHierarchy.SelectNodes('//node') | Where-Object {
        $text = $_.GetAttribute('text')
        $description = $_.GetAttribute('content-desc')
        $text -match '^\+[1-9][0-9]* gün$' -or (
            $description -match '(?m)^Tahmini başlangıç: [0-9]{2}\.[0-9]{2}\.[0-9]{4}\r?$' -and
            $description -match '(?m)^Tahmini bitiş: [0-9]{2}\.[0-9]{2}\.[0-9]{4}\r?$' -and
            $description -match '(?m)^\+[1-9][0-9]* gün\r?$'
        )
    })
    if ($positiveShift.Count -lt 1) {
        throw 'Acceptance impact detail did not expose a positive impacted activity shift.'
    }

    $after = Get-DurableLivingPlanSnapshot -ItemId $intelligenceItemId
    $beforeJson = $before | ConvertTo-Json -Compress -Depth 30
    $afterJson = $after | ConvertTo-Json -Compress -Depth 30
    if ($afterJson -ne $beforeJson) {
        throw 'Acceptance impact detail mutated item/revision/event/receipt/progress/plannedDate truth.'
    }
    Assert-AllPackageInventory -Expected $ExpectedInventory
    Invoke-IsolatedDeviceMutation -Arguments @(
        'shell', 'input', 'keyevent', 'KEYCODE_BACK'
    ) -ExpectedInventory $ExpectedInventory | Out-Null
    Start-Sleep -Milliseconds 500
    return [pscustomobject]@{
        itemId = $intelligenceItemId
        revision = [int]$item.revision
        progress = [int]$item.progress_percent
        plannedDate = [string]$item.planned_date
    }
}

function Get-AcceptanceFixtureState {
    $databasePath = 'files/cse_mobile/debug/database/cse_mobile.sqlite3'
    $encoded = Invoke-Adb -Arguments @(
        'exec-out', 'run-as', $acceptancePackage, 'base64', $databasePath
    )
    $bytes = [Convert]::FromBase64String(($encoded -replace '\s', ''))
    $tempDatabase = Join-Path `
        ([IO.Path]::GetTempPath()) `
        "cse-fixture-state-$([guid]::NewGuid().ToString('N')).sqlite3"
    [IO.File]::WriteAllBytes($tempDatabase, $bytes)
    try {
        $query = @"
import json, sqlite3, sys
p = sys.argv[1]
c = sqlite3.connect('file:' + p.replace('\\', '/') + '?mode=ro&immutable=1', uri=True)
c.row_factory = sqlite3.Row
project_id = '46400000-0000-4000-8000-000000000001'
items = [dict(row) for row in c.execute('''SELECT id,reference_snapshot_id,
 activity_instance_id,activity_id,planned_date,status,progress_percent,note,
 revision FROM project_living_plan_items WHERE project_id=? ORDER BY id''',
 (project_id,))]
snapshots = [dict(row) for row in c.execute('''SELECT s.id,s.generated_at,
 s.superseded_at,s.activity_count,m.dependency_count,m.projection_sha256
 FROM project_schedule_snapshots s
 LEFT JOIN project_schedule_snapshot_dependency_manifests m
 ON m.snapshot_id=s.id WHERE s.project_id=? ORDER BY s.generated_at,s.id''',
 (project_id,))]
print(json.dumps({'project_id': project_id, 'items': items,
 'snapshots': snapshots}, ensure_ascii=True, separators=(',', ':')))
"@
        return Invoke-Checked `
            -Command 'py' `
            -Arguments @('-c', $query, $tempDatabase)
    } finally {
        Remove-Item -LiteralPath $tempDatabase -Force
    }
}

function Assert-CleanAcceptanceFixtureState {
    param(
        [Parameter(Mandatory = $true)][int]$ExpectedTargetProgress,
        [Parameter(Mandatory = $true)][int]$ExpectedTargetRevision,
        [Parameter(Mandatory = $true)][object]$ExpectedInventory
    )

    $fixture = Get-AcceptanceFixtureState | ConvertFrom-Json
    $items = @($fixture.items)
    $expectedItemIds = @(
        $neighborItemIds[0],
        $neighborItemIds[1],
        $intelligenceItemId
    ) | Sort-Object
    $actualItemIds = @($items | ForEach-Object { [string]$_.id } | Sort-Object)
    if (@(Compare-Object -ReferenceObject $expectedItemIds -DifferenceObject $actualItemIds).Count -ne 0) {
        throw "CleanAcceptance fixture item set was not exact: $($actualItemIds -join ', ')"
    }

    $byId = @{}
    foreach ($item in $items) { $byId[[string]$item.id] = $item }
    $target = $byId[$intelligenceItemId]
    $planned = $byId[$neighborItemIds[0]]
    $started = $byId[$neighborItemIds[1]]
    if ($target.status -ne 'STARTED' -or
        [int]$target.progress_percent -ne $ExpectedTargetProgress -or
        [int]$target.revision -ne $ExpectedTargetRevision) {
        throw "CleanAcceptance target baseline mismatch: $($target.status)/$($target.progress_percent)/$($target.revision)"
    }
    if ($planned.status -ne 'PLANNED' -or $null -ne $planned.progress_percent -or
        [int]$planned.revision -ne 1) {
        throw 'CleanAcceptance planned neighbor baseline was not deterministic.'
    }
    if ($started.status -ne 'STARTED' -or $null -ne $started.progress_percent -or
        [int]$started.revision -ne 2) {
        throw 'CleanAcceptance started neighbor baseline was not deterministic.'
    }

    $targetDate = [DateTime]::ParseExact(
        [string]$target.planned_date,
        'yyyy-MM-dd',
        [Globalization.CultureInfo]::InvariantCulture
    )
    $plannedDate = [DateTime]::ParseExact(
        [string]$planned.planned_date,
        'yyyy-MM-dd',
        [Globalization.CultureInfo]::InvariantCulture
    )
    $startedDate = [DateTime]::ParseExact(
        [string]$started.planned_date,
        'yyyy-MM-dd',
        [Globalization.CultureInfo]::InvariantCulture
    )
    if ($plannedDate -ne $targetDate.AddDays(-1) -or $startedDate -ne $targetDate) {
        throw 'CleanAcceptance fixture dates were not deterministic.'
    }

    $visibleWindowStart = Get-LivingPlanWindowStart -ExpectedInventory $ExpectedInventory
    if ($targetDate -lt $visibleWindowStart -or $targetDate -gt $visibleWindowStart.AddDays(6)) {
        throw "CleanAcceptance target date was outside the active window: $($target.planned_date) / $($visibleWindowStart.ToString('yyyy-MM-dd'))"
    }

    $neighborSnapshot = [ordered]@{}
    foreach ($neighborId in $neighborItemIds) {
        $neighbor = $byId[$neighborId]
        $neighborSnapshot[$neighborId] = [pscustomobject]@{
            status = Convert-DurableStatusToUi -Status ([string]$neighbor.status)
            progress = Convert-DurableProgressToUi -Progress $neighbor.progress_percent
            revision = [int]$neighbor.revision
            plannedDate = Convert-CanonicalDateToDisplay -Value ([string]$neighbor.planned_date)
        }
    }
    $targetDisplayDate = Convert-CanonicalDateToDisplay -Value ([string]$target.planned_date)
    Assert-LifecycleCheckpoint `
        -TargetItemId $intelligenceItemId `
        -ExpectedStatus 'Başladı' `
        -ExpectedRevision $ExpectedTargetRevision `
        -ExpectedProgress "%$ExpectedTargetProgress" `
        -ExpectedDate $targetDisplayDate `
        -NeighborSnapshot $neighborSnapshot `
        -ExpectedInventory $ExpectedInventory | Out-Null

    return [pscustomobject]@{
        target = $target
        targetDisplayDate = $targetDisplayDate
        activeWindowStart = $visibleWindowStart.ToString('yyyy-MM-dd')
        neighborSnapshot = $neighborSnapshot
        fixtureState = $fixture
    }
}

function Run-CleanAcceptanceRelaunchScenario {
    param(
        [Parameter(Mandatory = $true)][string]$LaunchableActivity,
        [Parameter(Mandatory = $true)][object]$ExpectedInventory
    )

    $script:activeAcceptanceCheckpoint = 'clean_fixture_boot'
    Wait-UiNode -Text 'Başlangıç' -Contains | Out-Null
    Tap-UiText -Text '7 Günlük Plan' -Contains -RequireClickable -ExpectedInventory $ExpectedInventory
    Wait-UiNode -Text 'CSE 7 Günlük Plan Pilot' -Contains | Out-Null
    $baseline = Assert-CleanAcceptanceFixtureState `
        -ExpectedTargetProgress 47 `
        -ExpectedTargetRevision 3 `
        -ExpectedInventory $ExpectedInventory
    $script:lastSuccessfulAcceptanceStep = $script:activeAcceptanceCheckpoint

    $script:activeAcceptanceCheckpoint = 'clean_relaunch_mutation'
    $beforeMutation = Get-DurableLivingPlanSnapshot -ItemId $intelligenceItemId
    $beforeItem = Assert-DurableLivingPlanSnapshot -Snapshot $beforeMutation
    $progressAction = Get-LifecycleAction `
        -ItemId $intelligenceItemId `
        -Action 'İlerleme' `
        -ExpectedInventory $ExpectedInventory
    Invoke-UiTap -Node $progressAction.node -ExpectedInventory $ExpectedInventory
    Wait-UiNode -Text 'İlerlemeyi güncelle' -Contains | Out-Null
    Replace-OnlyEditableText -Value '63' -ExpectedInventory $ExpectedInventory
    Hide-Keyboard -ExpectedInventory $ExpectedInventory
    Tap-KaydetWithObservability `
        -CallerLabel 'clean_relaunch_progress_63_save' `
        -FlowLabel 'Run-CleanAcceptanceRelaunchScenario' `
        -PrecedingCheckpoint 'clean_relaunch_progress_63_value_entered_keyboard_dismissed' `
        -ExpectedInventory $ExpectedInventory
    Wait-UiNode -Text 'İlerleme %63 olarak kaydedildi.' -Contains | Out-Null
    $afterMutation = Get-DurableLivingPlanSnapshot -ItemId $intelligenceItemId
    $mutationRevision = Resolve-DurableLivingPlanMutationRevision `
        -Before $beforeMutation `
        -After $afterMutation `
        -ExpectedEventType 'PROGRESS_UPDATED' `
        -ExpectedStatus 'STARTED' `
        -ExpectedProgress 63 `
        -ExpectedDate $beforeItem.planned_date `
        -ExpectedNote $beforeItem.note
    if ($mutationRevision -ne 4) {
        throw "CleanAcceptance mutation revision was not deterministic: $mutationRevision"
    }
    Assert-CleanAcceptanceFixtureState `
        -ExpectedTargetProgress 63 `
        -ExpectedTargetRevision 4 `
        -ExpectedInventory $ExpectedInventory | Out-Null
    $script:lastSuccessfulAcceptanceStep = $script:activeAcceptanceCheckpoint

    $script:activeAcceptanceCheckpoint = 'clean_relaunch_persistence'
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
    $relaunch = Assert-CleanAcceptanceFixtureState `
        -ExpectedTargetProgress 63 `
        -ExpectedTargetRevision 4 `
        -ExpectedInventory $ExpectedInventory
    if ($relaunch.target.planned_date -ne $baseline.target.planned_date) {
        throw 'CleanAcceptance relaunch changed the target planned date.'
    }
    $script:lastSuccessfulAcceptanceStep = $script:activeAcceptanceCheckpoint
    return [pscustomobject]@{
        targetItemId = $intelligenceItemId
        status = [string]$relaunch.target.status
        progress = [int]$relaunch.target.progress_percent
        revision = [int]$relaunch.target.revision
        plannedDate = [string]$relaunch.target.planned_date
        activeWindowStart = [string]$relaunch.activeWindowStart
        itemCount = @($relaunch.fixtureState.items).Count
    }
}
function Get-AcceptanceDigestEvidence {
    $sourcePaths = @(
        $artifact,
        (Join-Path $mobileRoot 'integration_test\living_plan_acceptance_main.dart'),
        (Join-Path $mobileRoot 'integration_test\support\living_plan_acceptance_fixture.dart'),
        (Join-Path $mobileRoot 'lib\app.dart'),
        (Join-Path $mobileRoot 'lib\bootstrap\app_bootstrap.dart'),
        (Join-Path $mobileRoot 'lib\features\living_plan\living_plan_page.dart'),
        (Join-Path $mobileRoot 'lib\application\construction_living_plan_intelligence_application.dart'),
        (Join-Path $mobileRoot 'lib\domain\construction_living_plan_intelligence_models.dart'),
        $PSCommandPath
    )
    $digests = @()
    foreach ($pathValue in $sourcePaths) {
        if (-not (Test-Path -LiteralPath $pathValue)) { continue }
        $item = Get-Item -LiteralPath $pathValue
        $relative = if ($item.FullName.StartsWith($repositoryRoot, [StringComparison]::OrdinalIgnoreCase)) {
            $item.FullName.Substring($repositoryRoot.Length).TrimStart('\')
        } else {
            $item.FullName
        }
        $digests += [pscustomobject]@{
            path = $relative
            bytes = $item.Length
            sha256 = (Get-FileHash -LiteralPath $item.FullName -Algorithm SHA256).Hash.ToLowerInvariant()
        }
    }
    return $digests
}

function Write-DeviceFailureDiagnostics {
    param([Parameter(Mandatory = $true)][System.Management.Automation.ErrorRecord]$Failure)

    $summary = [ordered]@{
        event = 'device_acceptance_failure'
        caller = [string]$Failure.InvocationInfo.MyCommand
        line = $Failure.InvocationInfo.ScriptLineNumber
        activeCheckpoint = $script:activeAcceptanceCheckpoint
        lastSuccessfulStep = $script:lastSuccessfulAcceptanceStep
        errorType = $Failure.Exception.GetType().FullName
        error = $Failure.Exception.Message
        scriptStackTrace = $Failure.ScriptStackTrace
    }
    Write-Output "DIAGNOSTIC_DEVICE_FAILURE $($summary | ConvertTo-Json -Compress)"

    try {
        [xml]$failureHierarchy = Get-UiHierarchy
        $snapshot = ConvertTo-BoundedUiHierarchyEvidence `
            -Hierarchy $failureHierarchy `
            -MaximumNodes 80
        Write-Output "DIAGNOSTIC_DEVICE_HIERARCHY $($snapshot | ConvertTo-Json -Compress -Depth 10)"
    } catch {
        Write-Output "DIAGNOSTIC_DEVICE_HIERARCHY_FAILURE $($_.Exception.Message)"
    }

    try {
        $screenshot = Join-Path `
            ([IO.Path]::GetTempPath()) `
            "cse-device-failure-$([guid]::NewGuid().ToString('N')).png"
        $screenshotProcess = Start-Process `
            -FilePath $adb `
            -ArgumentList @('-s', $DeviceSerial, 'exec-out', 'screencap', '-p') `
            -NoNewWindow `
            -Wait `
            -PassThru `
            -RedirectStandardOutput $screenshot
        if ($screenshotProcess.ExitCode -ne 0 -or -not (Test-Path -LiteralPath $screenshot)) {
            throw "Acceptance screenshot failed with exit code $($screenshotProcess.ExitCode)."
        }
        $screenshotEvidence = [ordered]@{
            path = $screenshot
            bytes = (Get-Item -LiteralPath $screenshot).Length
            sha256 = (Get-FileHash -LiteralPath $screenshot -Algorithm SHA256).Hash.ToLowerInvariant()
        }
        Write-Output "DIAGNOSTIC_DEVICE_SCREENSHOT $($screenshotEvidence | ConvertTo-Json -Compress)"
    } catch {
        Write-Output "DIAGNOSTIC_DEVICE_SCREENSHOT_FAILURE $($_.Exception.Message)"
    }
    try {
        $windowLines = Invoke-Adb -Arguments @('shell', 'dumpsys', 'window', 'windows')
        $currentWindow = @($windowLines -split "`r?`n" | Where-Object {
            $_ -match 'mCurrentFocus|mFocusedApp|com\.faliardic\.sefim\.acceptance'
        } | Select-Object -Last 40)
        Write-Output "DIAGNOSTIC_DEVICE_WINDOW $($currentWindow | ConvertTo-Json -Compress)"
    } catch {
        Write-Output "DIAGNOSTIC_DEVICE_WINDOW_FAILURE $($_.Exception.Message)"
    }

    try {
        $acceptancePid = (Invoke-Adb -Arguments @('shell', 'pidof', $acceptancePackage)).Trim()
        if ([string]::IsNullOrWhiteSpace($acceptancePid)) {
            throw 'Acceptance package PID was unavailable.'
        }
        $log = Invoke-Adb -Arguments @('logcat', '--pid', $acceptancePid, '-d', '-t', '1500')
        $filteredLog = @($log -split "`r?`n" | Where-Object {
            $_ -match 'CSE_ENTRYPOINT|acceptance|living_plan|flutter|FATAL|Exception|Error'
        } | Select-Object -Last 120)
        Write-Output "DIAGNOSTIC_DEVICE_LOGCAT $($filteredLog | ConvertTo-Json -Compress)"
    } catch {
        Write-Output "DIAGNOSTIC_DEVICE_LOGCAT_FAILURE $($_.Exception.Message)"
    }

    try {
        $fixtureState = Get-AcceptanceFixtureState
        Write-Output "DIAGNOSTIC_DEVICE_FIXTURE_STATE $fixtureState"
    } catch {
        Write-Output "DIAGNOSTIC_DEVICE_FIXTURE_STATE_FAILURE $($_.Exception.Message)"
    }

    try {
        $digests = Get-AcceptanceDigestEvidence
        Write-Output "DIAGNOSTIC_DEVICE_DIGESTS $($digests | ConvertTo-Json -Compress -Depth 5)"
    } catch {
        Write-Output "DIAGNOSTIC_DEVICE_DIGESTS_FAILURE $($_.Exception.Message)"
    }
}

function Run-LivingPlanAcceptanceFlow {
    param([Parameter(Mandatory = $true)][object]$ExpectedInventory)
    Wait-UiNode -Text 'Başlangıç' -Contains | Out-Null
    Tap-UiText -Text '7 Günlük Plan' -Contains -RequireClickable -ExpectedInventory $ExpectedInventory
    Wait-UiNode -Text 'CSE 7 Günlük Plan Pilot' -Contains | Out-Null
    Wait-UiNode -Text 'Geciken' -Contains | Out-Null
    Wait-UiNode -Text 'Önerilen tarihler tahmin niteliğindedir' -Contains | Out-Null
    $intelligenceProof = Assert-LivingPlanIntelligenceReadOnly `
        -ExpectedInventory $ExpectedInventory

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
    Invoke-IsolatedDeviceMutation -Arguments @(
        'shell', 'input', 'keyevent', 'KEYCODE_BACK'
    ) -ExpectedInventory $ExpectedInventory | Out-Null
    Start-Sleep -Seconds 1

    $identityAction = Get-LifecycleActionAcrossWindows -ActivityName $candidateName -Action 'Not' -ExpectedInventory $ExpectedInventory
    $targetItemId = $identityAction.itemId
    $durable = Get-DurableLivingPlanSnapshot -ItemId $targetItemId
    $durableItem = Assert-DurableLivingPlanSnapshot -Snapshot $durable
    $targetRevision = [int]$durableItem.revision
    $initialDate = Convert-CanonicalDateToDisplay -Value $durableItem.planned_date
    $targetNote = [string]$durableItem.note

    $neighborSnapshot = [ordered]@{}
    foreach ($neighborItemId in $neighborItemIds) {
        $neighborDurable = Get-DurableLivingPlanSnapshot -ItemId $neighborItemId
        $neighborItem = Assert-DurableLivingPlanSnapshot -Snapshot $neighborDurable
        $neighborDate = Convert-CanonicalDateToDisplay -Value $neighborItem.planned_date
        Set-LivingPlanWindowForDate -PlannedDate $neighborDate -ExpectedInventory $ExpectedInventory | Out-Null
        $neighborCurrent = Get-LifecycleProjectionSnapshot -ItemIds @($neighborItemId) -ExpectedInventory $ExpectedInventory
        $neighborUi = $neighborCurrent[$neighborItemId]
        if ($neighborUi.status -ne (Convert-DurableStatusToUi -Status $neighborItem.status) -or
            $neighborUi.progress -ne (Convert-DurableProgressToUi -Progress $neighborItem.progress_percent) -or
            $neighborUi.revision -ne [int]$neighborItem.revision -or $neighborUi.plannedDate -ne $neighborDate) {
            throw "Acceptance neighbor UI/durable projection mismatch: $neighborItemId"
        }
        $neighborSnapshot[$neighborItemId] = $neighborUi
    }

    Assert-LifecycleCheckpoint -TargetItemId $targetItemId -ExpectedStatus (Convert-DurableStatusToUi -Status $durableItem.status) -ExpectedRevision $targetRevision -ExpectedProgress (Convert-DurableProgressToUi -Progress $durableItem.progress_percent) -ExpectedDate $initialDate -NeighborSnapshot $neighborSnapshot -ExpectedInventory $ExpectedInventory | Out-Null

    if ($durableItem.status -ne 'PLANNED' -or $null -ne $durableItem.progress_percent) {
        if ($durableItem.status -ne 'COMPLETED') {
            $beforeNormalizeComplete = $durable
            $normalizeComplete = Get-LifecycleAction -ItemId $targetItemId -Action 'Tamamla' -ExpectedInventory $ExpectedInventory
            Invoke-UiTap -Node $normalizeComplete.node -ExpectedInventory $ExpectedInventory
            Wait-UiNode -Text 'İmalat tamamlandı.' -Contains | Out-Null
            $afterNormalizeComplete = Get-DurableLivingPlanSnapshot -ItemId $targetItemId
            $targetRevision = Resolve-DurableLivingPlanMutationRevision -Before $beforeNormalizeComplete -After $afterNormalizeComplete -ExpectedEventType 'COMPLETED' -ExpectedStatus 'COMPLETED' -ExpectedProgress 100 -ExpectedDate $beforeNormalizeComplete.item.planned_date -ExpectedNote $targetNote
            if ($targetRevision -ne ([int]$beforeNormalizeComplete.item.revision + 1)) { throw 'Acceptance normalization Complete was not an observed state change.' }
            $durable = $afterNormalizeComplete
            $durableItem = Assert-DurableLivingPlanSnapshot -Snapshot $durable
            $initialDate = Convert-CanonicalDateToDisplay -Value $durableItem.planned_date
        }
        Assert-LifecycleCheckpoint -TargetItemId $targetItemId -ExpectedStatus 'Tamamlandı' -ExpectedRevision $targetRevision -ExpectedProgress '%100' -ExpectedDate $initialDate -NeighborSnapshot $neighborSnapshot -ExpectedInventory $ExpectedInventory | Out-Null
        Assert-LifecycleActionAbsent -ItemId $targetItemId -Action 'İlerleme' -ExpectedInventory $ExpectedInventory

        $beforeNormalizeReopen = $durable
        $normalizeReopen = Get-LifecycleAction -ItemId $targetItemId -Action 'Yeniden aç' -ExpectedInventory $ExpectedInventory
        Invoke-UiTap -Node $normalizeReopen.node -ExpectedInventory $ExpectedInventory
        Tap-UiText -Text 'Tamam' -RequireClickable -ExpectedInventory $ExpectedInventory
        Wait-UiNode -Text 'İmalat yeniden açıldı.' -Contains | Out-Null
        $afterNormalizeReopen = Get-DurableLivingPlanSnapshot -ItemId $targetItemId
        $targetRevision = Resolve-DurableLivingPlanMutationRevision -Before $beforeNormalizeReopen -After $afterNormalizeReopen -ExpectedEventType 'REOPENED' -ExpectedStatus 'PLANNED' -ExpectedProgress $null -ExpectedDate $afterNormalizeReopen.item.planned_date -ExpectedNote $targetNote -ExpectedIntentField 'new_planned_date' -ExpectedIntentValue $afterNormalizeReopen.item.planned_date
        if ($targetRevision -ne ([int]$beforeNormalizeReopen.item.revision + 1)) { throw 'Acceptance normalization Reopen was not an observed state change.' }
        $durable = $afterNormalizeReopen
        $durableItem = Assert-DurableLivingPlanSnapshot -Snapshot $durable
        $initialDate = Convert-CanonicalDateToDisplay -Value $durableItem.planned_date
        Assert-LifecycleCheckpoint -TargetItemId $targetItemId -ExpectedStatus 'Planlandı' -ExpectedRevision $targetRevision -ExpectedProgress 'Raporlanmadı' -ExpectedDate $initialDate -NeighborSnapshot $neighborSnapshot -ExpectedInventory $ExpectedInventory | Out-Null
    }

    Assert-LifecycleCheckpoint `
        -TargetItemId $targetItemId `
        -ExpectedStatus 'Planlandı' `
        -ExpectedRevision $targetRevision `
        -ExpectedProgress 'Raporlanmadı' `
        -ExpectedDate $initialDate `
        -NeighborSnapshot $neighborSnapshot `
        -ExpectedInventory $ExpectedInventory | Out-Null
    Assert-LifecycleActionAbsent `
        -ItemId $targetItemId `
        -Action 'İlerleme' `
        -ExpectedInventory $ExpectedInventory

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
        -ExpectedProgress 'Raporlanmadı' `
        -ExpectedDate $initialDate `
        -NeighborSnapshot $neighborSnapshot `
        -ExpectedInventory $ExpectedInventory | Out-Null

    $progress47Action = Get-LifecycleAction `
        -ItemId $targetItemId `
        -Action 'İlerleme' `
        -ExpectedInventory $ExpectedInventory
    Invoke-UiTap -Node $progress47Action.node -ExpectedInventory $ExpectedInventory
    Wait-UiNode -Text 'İlerlemeyi güncelle' -Contains | Out-Null
    Replace-OnlyEditableText -Value '47' -ExpectedInventory $ExpectedInventory
    Hide-Keyboard -ExpectedInventory $ExpectedInventory
    Tap-KaydetWithObservability `
        -CallerLabel 'progress_47_save' `
        -FlowLabel 'Run-LivingPlanAcceptanceFlow' `
        -PrecedingCheckpoint 'progress_47_value_entered_keyboard_dismissed' `
        -ExpectedInventory $ExpectedInventory
    Wait-UiNode -Text 'İlerleme %47 olarak kaydedildi.' -Contains | Out-Null
    $targetRevision += 1
    Assert-LifecycleCheckpoint `
        -TargetItemId $targetItemId `
        -ExpectedStatus 'Başladı' `
        -ExpectedRevision $targetRevision `
        -ExpectedProgress '%47' `
        -ExpectedDate $initialDate `
        -NeighborSnapshot $neighborSnapshot `
        -ExpectedInventory $ExpectedInventory | Out-Null

    $beforeNoteMutation = Get-DurableLivingPlanSnapshot -ItemId $targetItemId
    $noteAction = Get-LifecycleAction `
        -ItemId $targetItemId `
        -Action 'Not' `
        -ExpectedInventory $ExpectedInventory
    Invoke-UiTap -Node $noteAction.node -ExpectedInventory $ExpectedInventory
    Replace-OnlyEditableText `
        -Value $updatedAcceptanceNote `
        -ExpectedInventory $ExpectedInventory
    Hide-Keyboard -ExpectedInventory $ExpectedInventory
    Tap-KaydetWithObservability `
        -CallerLabel 'note_update_save' `
        -FlowLabel 'Run-LivingPlanAcceptanceFlow' `
        -PrecedingCheckpoint 'note_value_entered_keyboard_dismissed' `
        -ExpectedInventory $ExpectedInventory
    Wait-UiNode -Text 'Not kaydedildi.' -Contains | Out-Null
    Scroll-UntilUiText -Text $updatedAcceptanceNote -Contains -ExpectedInventory $ExpectedInventory | Out-Null
    $afterNoteMutation = Get-DurableLivingPlanSnapshot -ItemId $targetItemId
    $targetRevision = Resolve-DurableLivingPlanMutationRevision `
        -Before $beforeNoteMutation `
        -After $afterNoteMutation `
        -ExpectedEventType 'NOTE_UPDATED' `
        -ExpectedStatus 'STARTED' `
        -ExpectedProgress 47 `
        -ExpectedDate $beforeNoteMutation.item.planned_date `
        -ExpectedNote $updatedAcceptanceNote
    Assert-LifecycleCheckpoint `
        -TargetItemId $targetItemId `
        -ExpectedStatus 'Başladı' `
        -ExpectedRevision $targetRevision `
        -ExpectedProgress '%47' `
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
        -ExpectedProgress '%47' `
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
        -ExpectedProgress '%100' `
        -ExpectedDate $deferredTarget.plannedDate `
        -NeighborSnapshot $neighborSnapshot `
        -ExpectedInventory $ExpectedInventory | Out-Null
    Assert-LifecycleActionAbsent `
        -ItemId $targetItemId `
        -Action 'İlerleme' `
        -ExpectedInventory $ExpectedInventory

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
        -ExpectedProgress 'Raporlanmadı' `
        -NeighborSnapshot $neighborSnapshot `
        -ExpectedInventory $ExpectedInventory
    Scroll-UntilUiText -Text $updatedAcceptanceNote -Contains -ExpectedInventory $ExpectedInventory | Out-Null
    Assert-LifecycleActionAbsent `
        -ItemId $targetItemId `
        -Action 'İlerleme' `
        -ExpectedInventory $ExpectedInventory

    $restartAction = Get-LifecycleAction `
        -ItemId $targetItemId `
        -Action 'Başlat' `
        -ExpectedInventory $ExpectedInventory
    Invoke-UiTap -Node $restartAction.node -ExpectedInventory $ExpectedInventory
    Wait-UiNode -Text 'İmalat başlatıldı.' -Contains | Out-Null
    $targetRevision += 1
    Assert-LifecycleCheckpoint `
        -TargetItemId $targetItemId `
        -ExpectedStatus 'Başladı' `
        -ExpectedRevision $targetRevision `
        -ExpectedProgress 'Raporlanmadı' `
        -ExpectedDate $reopenedTarget.plannedDate `
        -NeighborSnapshot $neighborSnapshot `
        -ExpectedInventory $ExpectedInventory | Out-Null

    $progress63Action = Get-LifecycleAction `
        -ItemId $targetItemId `
        -Action 'İlerleme' `
        -ExpectedInventory $ExpectedInventory
    Invoke-UiTap -Node $progress63Action.node -ExpectedInventory $ExpectedInventory
    Wait-UiNode -Text 'İlerlemeyi güncelle' -Contains | Out-Null
    Replace-OnlyEditableText -Value '63' -ExpectedInventory $ExpectedInventory
    Hide-Keyboard -ExpectedInventory $ExpectedInventory
    Tap-KaydetWithObservability `
        -CallerLabel 'progress_63_save' `
        -FlowLabel 'Run-LivingPlanAcceptanceFlow' `
        -PrecedingCheckpoint 'progress_63_value_entered_keyboard_dismissed' `
        -ExpectedInventory $ExpectedInventory
    Wait-UiNode -Text 'İlerleme %63 olarak kaydedildi.' -Contains | Out-Null
    $targetRevision += 1
    Assert-LifecycleCheckpoint `
        -TargetItemId $targetItemId `
        -ExpectedStatus 'Başladı' `
        -ExpectedRevision $targetRevision `
        -ExpectedProgress '%63' `
        -ExpectedDate $reopenedTarget.plannedDate `
        -NeighborSnapshot $neighborSnapshot `
        -ExpectedInventory $ExpectedInventory | Out-Null

    return [pscustomobject]@{
        targetItemId = $targetItemId
        finalRevision = $targetRevision
        finalPlannedDate = $reopenedTarget.plannedDate
        finalProgress = 63
        neighborSnapshot = $neighborSnapshot
        intelligenceProof = $intelligenceProof
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
        -ExpectedStatus 'Başladı' `
        -ExpectedRevision $FlowResult.finalRevision `
        -ExpectedProgress '%63' `
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
    $script:activeAcceptanceCheckpoint = 'apk_contract'
    $artifactContract = Assert-ApkContract -Apk $artifact
    $script:lastSuccessfulAcceptanceStep = $script:activeAcceptanceCheckpoint
    $script:activeAcceptanceCheckpoint = 'device_preflight'
    Assert-DevicePreflight
    $script:lastSuccessfulAcceptanceStep = $script:activeAcceptanceCheckpoint
    $script:activeAcceptanceCheckpoint = 'six_package_baseline'
    $beforeInstall = Get-SixPackageInventory
    foreach ($packageName in $allPackages) {
        Write-Output "BASELINE $(Convert-InventoryToJson $beforeInstall[$packageName])"
    }
    $script:lastSuccessfulAcceptanceStep = $script:activeAcceptanceCheckpoint

    $script:activeAcceptanceCheckpoint = 'acceptance_install_r'
    Invoke-Adb -Arguments @('install', '-r', $artifact) | Write-Output
    $script:lastSuccessfulAcceptanceStep = $script:activeAcceptanceCheckpoint
    $script:activeAcceptanceCheckpoint = 'post_install_isolation'
    $afterInstall = Get-SixPackageInventory
    Assert-NonTargetInventory -Expected $beforeInstall -Actual $afterInstall
    if (-not $afterInstall[$acceptancePackage].installed) {
        throw 'Şefim acceptance package was not installed.'
    }
    $expectedInventory = $afterInstall
    Assert-AllPackageInventory -Expected $expectedInventory
    $script:lastSuccessfulAcceptanceStep = $script:activeAcceptanceCheckpoint

    Invoke-IsolatedDeviceMutation -Arguments @(
        'shell', 'am', 'start', '-W', '-n',
        "$acceptancePackage/$($artifactContract.launchableActivity)"
    ) -ExpectedInventory $expectedInventory | Out-Null
    Start-Sleep -Seconds 2
    if ($DeviceScenario -eq 'CleanRelaunch') {
        $stageAResult = @(
            Run-CleanAcceptanceRelaunchScenario `
                -LaunchableActivity $artifactContract.launchableActivity `
                -ExpectedInventory $expectedInventory
        )[-1]
        $script:activeAcceptanceCheckpoint = 'clean_relaunch_fatal_diagnostics'
        Assert-NoFatalDiagnostics
        $script:lastSuccessfulAcceptanceStep = $script:activeAcceptanceCheckpoint
        $script:activeAcceptanceCheckpoint = 'clean_relaunch_final_isolation'
        Assert-AllPackageInventory -Expected $expectedInventory
        $script:lastSuccessfulAcceptanceStep = $script:activeAcceptanceCheckpoint
        Write-Output "PASS clean_acceptance_stage_a=true target_item=$($stageAResult.targetItemId) status=$($stageAResult.status) progress=$($stageAResult.progress) revision=$($stageAResult.revision) planned_date=$($stageAResult.plannedDate) active_window_start=$($stageAResult.activeWindowStart) item_count=$($stageAResult.itemCount)"
        Write-Output "PASS artifact=$([IO.Path]::GetFileName($artifact)) sha256=$($artifactContract.sha256) abi=arm64-v8a"
        return
    }    $script:activeAcceptanceCheckpoint = 'living_plan_full_flow'


    $flowResult = Run-LivingPlanAcceptanceFlow -ExpectedInventory $expectedInventory
    $script:lastSuccessfulAcceptanceStep = $script:activeAcceptanceCheckpoint
    $script:activeAcceptanceCheckpoint = 'relaunch_persistence'
    Assert-RelaunchPersistence `
        -LaunchableActivity $artifactContract.launchableActivity `
        -ExpectedInventory $expectedInventory `
        -FlowResult $flowResult
    $script:lastSuccessfulAcceptanceStep = $script:activeAcceptanceCheckpoint
    $script:activeAcceptanceCheckpoint = 'relaunch_intelligence'
    $relaunchIntelligenceProof = Assert-LivingPlanIntelligenceReadOnly `
        -ExpectedInventory $expectedInventory
    if ($relaunchIntelligenceProof.itemId -ne $flowResult.intelligenceProof.itemId -or
        $relaunchIntelligenceProof.revision -ne $flowResult.intelligenceProof.revision -or
        $relaunchIntelligenceProof.progress -ne $flowResult.intelligenceProof.progress -or
        $relaunchIntelligenceProof.plannedDate -ne $flowResult.intelligenceProof.plannedDate) {
        throw 'Acceptance intelligence source progress/persistence changed after relaunch.'
    }
    $script:lastSuccessfulAcceptanceStep = $script:activeAcceptanceCheckpoint
    $script:activeAcceptanceCheckpoint = 'fatal_diagnostics'
    Assert-NoFatalDiagnostics
    $script:lastSuccessfulAcceptanceStep = $script:activeAcceptanceCheckpoint
    $script:activeAcceptanceCheckpoint = 'final_six_package_isolation'
    Assert-AllPackageInventory -Expected $expectedInventory
    $script:lastSuccessfulAcceptanceStep = $script:activeAcceptanceCheckpoint

    Write-Output "PASS acceptance_package=$acceptancePackage label=$acceptanceLabel"
    Write-Output "PASS artifact=$([IO.Path]::GetFileName($artifact)) sha256=$($artifactContract.sha256) abi=arm64-v8a"
    Write-Output "PASS target_item=$($flowResult.targetItemId) final_revision=$($flowResult.finalRevision) final_progress=$($flowResult.finalProgress) final_date=$($flowResult.finalPlannedDate)"
    Write-Output "PASS intelligence_item=$($relaunchIntelligenceProof.itemId) progress=$($relaunchIntelligenceProof.progress) read_only_detail=true"
    Write-Output 'PASS six_package_isolation=true full_flow=true persistence_after_relaunch=true intelligence_after_relaunch=true fatal_diagnostics=false'
} catch {
    $deviceFailure = $_
    if ($Mode -eq 'Device') {
        Write-DeviceFailureDiagnostics -Failure $deviceFailure
    }
    throw $deviceFailure
} finally {
    $env:CSE_ACCEPTANCE_HARNESS = $previousAcceptanceHarness
}
