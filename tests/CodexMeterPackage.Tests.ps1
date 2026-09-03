[CmdletBinding()]
param(
    [string]$RepoRoot
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

if ([string]::IsNullOrWhiteSpace($RepoRoot)) {
    $RepoRoot = Split-Path -Parent $PSScriptRoot
}

function Assert-True {
    param([bool]$Condition, [string]$Message)
    if (-not $Condition) { throw $Message }
}

function Assert-RealContainer {
    param([string]$Path, [string]$Description)

    $item = Get-Item -LiteralPath $Path -Force
    Assert-True $item.PSIsContainer "$Description must be a container: $Path"
    Assert-True (($item.Attributes -band [IO.FileAttributes]::ReparsePoint) -eq 0) "$Description must not be a reparse point: $Path"
}

function Assert-StrictUtf8NoBom {
    param([string]$Path, [string]$Description)

    $textBytes = [IO.File]::ReadAllBytes($Path)
    $hasUtf8Bom = $textBytes.Length -ge 3 -and
        $textBytes[0] -eq 0xEF -and $textBytes[1] -eq 0xBB -and $textBytes[2] -eq 0xBF
    Assert-True (-not $hasUtf8Bom) "$Description must not contain a UTF-8 BOM: $Path"
    try {
        $null = $utf8Strict.GetString($textBytes)
    } catch {
        throw "$Description is not valid strict UTF-8: $Path"
    }
}

$utf8Strict = [Text.UTF8Encoding]::new($false, $true)
$packagesRoot = Join-Path $RepoRoot 'packages'
$packageRoot = Join-Path $RepoRoot 'packages\CodexMeter'
Assert-RealContainer -Path $packagesRoot -Description 'Packages root'
Assert-RealContainer -Path $packageRoot -Description 'CodexMeter package root'
$requiredNames = @(
    'CodexMeter-Setup.exe',
    'CodexMeter-Setup.exe.sha256',
    'VERSION',
    'INSTALL.md'
)

foreach ($name in $requiredNames) {
    $path = Join-Path $packageRoot $name
    Assert-True (Test-Path -LiteralPath $path -PathType Leaf) "Missing required package file: $name"
    $tracked = @(& git -C $RepoRoot ls-files --error-unmatch -- "packages/CodexMeter/$name" 2>$null)
    Assert-True ($LASTEXITCODE -eq 0 -and $tracked.Count -eq 1) "Package file is not tracked exactly once: $name"
}
$packageEntries = @(Get-ChildItem -LiteralPath $packageRoot -Force)
foreach ($entry in $packageEntries) {
    Assert-True (-not $entry.PSIsContainer) "CodexMeter package must not contain directories: $($entry.Name)"
    Assert-True (($entry.Attributes -band [IO.FileAttributes]::ReparsePoint) -eq 0) "CodexMeter package must not contain reparse points: $($entry.Name)"
}
$actualNames = @($packageEntries | Select-Object -ExpandProperty Name | Sort-Object)
$expectedNames = @($requiredNames | Sort-Object)
Assert-True (($actualNames -join "`n") -ceq ($expectedNames -join "`n")) 'CodexMeter package must contain exactly the four approved files.'

foreach ($metadataName in @('CodexMeter-Setup.exe.sha256', 'VERSION', 'INSTALL.md')) {
    $metadataPath = Join-Path $packageRoot $metadataName
    Assert-StrictUtf8NoBom -Path $metadataPath -Description "Package metadata $metadataName"
}

$versionText = (Get-Content -Raw -LiteralPath (Join-Path $packageRoot 'VERSION')).Trim()
$expectedVersion = @'
CodexMeter-Version: 1.1.1
Source-Tag: v1.1.1
Source-Commit: 804d30d8f77a5f9addd2db3c2156b0c832e2a585
'@.Trim()
Assert-True ($versionText -ceq $expectedVersion) 'Package VERSION does not identify the approved CodexMeter release.'

$hashPath = Join-Path $packageRoot 'CodexMeter-Setup.exe.sha256'
$expectedHash = (Get-Content -Raw -LiteralPath $hashPath).Trim()
Assert-True ($expectedHash -cmatch '^[0-9A-F]{64}$') 'SHA-256 file must contain one uppercase 64-hex digest.'
Assert-True ($expectedHash -ceq '2AE0BF6815ABC50E100EA7852E3556F6A96AAB105DEE971FC557D6F1C707064E') 'Package digest is not the approved v1.1.1 digest.'

$exePath = Join-Path $packageRoot 'CodexMeter-Setup.exe'
$actualHash = (Get-FileHash -Algorithm SHA256 -LiteralPath $exePath).Hash
Assert-True ($actualHash -ceq $expectedHash) 'CodexMeter bootstrapper SHA-256 mismatch.'
$exeInfo = Get-Item -LiteralPath $exePath
Assert-True ($exeInfo.Length -gt 0 -and $exeInfo.Length -lt 100MB) 'CodexMeter bootstrapper size is invalid.'

$bytes = [IO.File]::ReadAllBytes($exePath)
Assert-True ($bytes.Length -ge 256 -and $bytes[0] -eq 0x4D -and $bytes[1] -eq 0x5A) 'CodexMeter bootstrapper is not an MZ executable.'
$peOffset = [BitConverter]::ToInt32($bytes, 0x3C)
Assert-True ($peOffset -gt 0 -and $peOffset + 96 -lt $bytes.Length) 'CodexMeter bootstrapper has an invalid PE header offset.'
Assert-True ($bytes[$peOffset] -eq 0x50 -and $bytes[$peOffset + 1] -eq 0x45 -and $bytes[$peOffset + 2] -eq 0 -and $bytes[$peOffset + 3] -eq 0) 'CodexMeter bootstrapper has no PE signature.'
$optionalHeader = $peOffset + 24
$magic = [BitConverter]::ToUInt16($bytes, $optionalHeader)
Assert-True ($magic -eq 0x10B -or $magic -eq 0x20B) 'CodexMeter bootstrapper has an unsupported optional header.'
$subsystem = [BitConverter]::ToUInt16($bytes, $optionalHeader + 68)
Assert-True ($subsystem -eq 2) 'CodexMeter bootstrapper must use the Windows GUI subsystem.'

$install = Get-Content -Raw -LiteralPath (Join-Path $packageRoot 'INSTALL.md')
foreach ($required in @('git pull --ff-only', 'Get-FileHash', 'CodexMeter-Setup.exe.sha256', 'CodexMeter-Setup.exe', "'/quiet', '/whatif'", 'SmartScreen', '1.1.1')) {
    Assert-True ($install.Contains($required)) "INSTALL.md is missing required content: $required"
}

$requiredUpdateBlock = @'
$ErrorActionPreference = 'Stop'
git pull --ff-only
if ($LASTEXITCODE -ne 0) { throw "Best Practice update failed: $LASTEXITCODE" }
$repoRoot = (& git rev-parse --show-toplevel).Trim()
if ($LASTEXITCODE -ne 0 -or -not $repoRoot) { throw 'Best Practice repository root was not found.' }
Set-Location -LiteralPath (Join-Path $repoRoot 'packages\CodexMeter') -ErrorAction Stop
'@.Trim()
$requiredPreflightBlock = @'
$process = Start-Process -FilePath .\CodexMeter-Setup.exe `
    -ArgumentList @('/quiet', '/whatif') -Wait -PassThru
if ($process.ExitCode -ne 0) {
    throw "CodexMeter preflight failed: $($process.ExitCode)"
}
'@.Trim()
$requiredInstallBlock = @'
$process = Start-Process -FilePath .\CodexMeter-Setup.exe -Wait -PassThru
if ($process.ExitCode -ne 0) { throw "CodexMeter installation failed: $($process.ExitCode)" }
'@.Trim()

$text = $versionText + "`n" + $expectedHash + "`n" + $install
foreach ($pattern in @('(?i)C:\\Users\\[^\\\s]+', '(?i)ghp_[A-Za-z0-9]{20,}', '(?i)sk-[A-Za-z0-9]{20,}', '(?i)Bearer\s+[A-Za-z0-9._-]{20,}')) {
    Assert-True (-not [regex]::IsMatch($text, $pattern)) "Package metadata contains a forbidden machine path or credential pattern: $pattern"
}

$readme = Get-Content -Raw -LiteralPath (Join-Path $RepoRoot 'README.md')
$applications = Get-Content -Raw -LiteralPath (Join-Path $RepoRoot 'memory\PROJECT_APPLICATIONS.md')
$implementationPlan = Get-Content -Raw -LiteralPath (Join-Path $RepoRoot 'docs\superpowers\plans\2026-09-03-bundled-codexmeter-package.md')
$bestPracticeVersion = Get-Content -Raw -LiteralPath (Join-Path $RepoRoot 'VERSION')
$changelog = Get-Content -Raw -LiteralPath (Join-Path $RepoRoot 'CHANGELOG.md')

Assert-True ($readme.Contains('packages/CodexMeter/INSTALL.md')) 'README does not link to the bundled CodexMeter package.'
Assert-True ($applications.Contains('packages/CodexMeter')) 'PROJECT_APPLICATIONS does not use the bundled CodexMeter package.'
Assert-True ($applications.Contains('CodexMeter 1.1.1')) 'PROJECT_APPLICATIONS does not identify the bundled CodexMeter version.'
Assert-True ($bestPracticeVersion.Contains('Version: 2.2.1')) 'Best Practice VERSION was not raised to 2.2.1.'
Assert-True ($bestPracticeVersion.Contains('Date: 2026-09-03')) 'Best Practice VERSION has the wrong release date.'
Assert-True ($changelog.Contains('## 2.2.1 — 2026-09-03')) 'CHANGELOG is missing the 2.2.1 release.'

foreach ($document in @(
    @{ Name = 'INSTALL.md'; Text = $install },
    @{ Name = 'PROJECT_APPLICATIONS.md'; Text = $applications },
    @{ Name = 'bundled CodexMeter implementation plan'; Text = $implementationPlan }
)) {
    Assert-True ($document.Text.Contains($requiredUpdateBlock)) "$($document.Name) does not contain the required fail-closed repository update block."
    Assert-True ($document.Text.Contains($requiredPreflightBlock)) "$($document.Name) does not contain the required synchronous preflight block."
    Assert-True ($document.Text.Contains($requiredInstallBlock)) "$($document.Name) does not contain the required synchronous installation block."
}

foreach ($releaseTextPath in @(
    '.gitattributes',
    'tests\CodexMeterPackage.Tests.ps1',
    'packages\CodexMeter\CodexMeter-Setup.exe.sha256',
    'packages\CodexMeter\VERSION',
    'packages\CodexMeter\INSTALL.md',
    'README.md',
    'CHANGELOG.md',
    'VERSION',
    'memory\PROJECT_APPLICATIONS.md',
    'docs\superpowers\specs\2026-09-02-bundled-codexmeter-package-design.md',
    'docs\superpowers\plans\2026-09-03-bundled-codexmeter-package.md'
)) {
    Assert-StrictUtf8NoBom -Path (Join-Path $RepoRoot $releaseTextPath) -Description 'Release text'
}

Write-Output 'PASS CodexMeter package contract'
