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

$packageRoot = Join-Path $RepoRoot 'packages\CodexMeter'
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
$actualNames = @(Get-ChildItem -LiteralPath $packageRoot -File | Select-Object -ExpandProperty Name | Sort-Object)
$expectedNames = @($requiredNames | Sort-Object)
Assert-True (($actualNames -join "`n") -ceq ($expectedNames -join "`n")) 'CodexMeter package must contain exactly the four approved files.'

$versionText = (Get-Content -Raw -LiteralPath (Join-Path $packageRoot 'VERSION')).Trim()
$expectedVersion = @'
CodexMeter-Version: 1.1.0
Source-Tag: v1.1.0
Source-Commit: c1066dd3ce2bb3847e4637b80327055ac5638601
'@.Trim()
Assert-True ($versionText -ceq $expectedVersion) 'Package VERSION does not identify the approved CodexMeter release.'

$hashPath = Join-Path $packageRoot 'CodexMeter-Setup.exe.sha256'
$expectedHash = (Get-Content -Raw -LiteralPath $hashPath).Trim()
Assert-True ($expectedHash -cmatch '^[0-9A-F]{64}$') 'SHA-256 file must contain one uppercase 64-hex digest.'
Assert-True ($expectedHash -ceq '32DBDDA950F003FACF9F3A6F909E419391AE91A76956A5A3C12101DCDDFC7C17') 'Package digest is not the approved v1.1.0 digest.'

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
foreach ($required in @('git pull --ff-only', 'Get-FileHash', 'CodexMeter-Setup.exe.sha256', 'CodexMeter-Setup.exe', '/quiet /whatif', 'SmartScreen', '1.1.0')) {
    Assert-True ($install.Contains($required)) "INSTALL.md is missing required content: $required"
}

$text = $versionText + "`n" + $expectedHash + "`n" + $install
foreach ($pattern in @('(?i)C:\\Users\\[^\\\s]+', '(?i)ghp_[A-Za-z0-9]{20,}', '(?i)sk-[A-Za-z0-9]{20,}', '(?i)Bearer\s+[A-Za-z0-9._-]{20,}')) {
    Assert-True (-not [regex]::IsMatch($text, $pattern)) "Package metadata contains a forbidden machine path or credential pattern: $pattern"
}

Write-Output 'PASS CodexMeter package contract'
