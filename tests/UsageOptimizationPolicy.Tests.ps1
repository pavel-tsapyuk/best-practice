[CmdletBinding()]
param([string]$RepoRoot)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
if ([string]::IsNullOrWhiteSpace($RepoRoot)) {
    $RepoRoot = Split-Path -Parent $PSScriptRoot
}

function Assert-True {
    param([bool]$Condition, [string]$Message)
    if (-not $Condition) { throw $Message }
}

function Assert-StrictUtf8NoBom {
    param([string]$Path, [string]$Description)
    $bytes = [IO.File]::ReadAllBytes($Path)
    $hasBom = $bytes.Length -ge 3 -and $bytes[0] -eq 0xEF -and
        $bytes[1] -eq 0xBB -and $bytes[2] -eq 0xBF
    Assert-True (-not $hasBom) "$Description must not contain a UTF-8 BOM: $Path"
    $strict = [Text.UTF8Encoding]::new($false, $true)
    try { $null = $strict.GetString($bytes) }
    catch { throw "$Description is not valid strict UTF-8: $Path" }
}

function ConvertFrom-Utf8Base64 {
    param([string]$Value)
    return [Text.Encoding]::UTF8.GetString([Convert]::FromBase64String($Value))
}

function Test-ContainsOrdinalIgnoreCase {
    param([string]$Text, [string]$Value)
    return $Text.IndexOf($Value, [StringComparison]::OrdinalIgnoreCase) -ge 0
}

$corePath = Join-Path $RepoRoot 'AGENTS_CORE.md'
$policyPath = Join-Path $RepoRoot 'memory\USAGE_OPTIMIZATION.md'
Assert-True (Test-Path -LiteralPath $policyPath -PathType Leaf) 'Missing memory/USAGE_OPTIMIZATION.md.'

$core = Get-Content -Raw -LiteralPath $corePath -Encoding UTF8
$policy = Get-Content -Raw -LiteralPath $policyPath -Encoding UTF8

Assert-True (([regex]::Matches($core, '<!-- BEGIN BEST-PRACTICE MANAGED CORE -->')).Count -eq 1) 'Core must have one BEGIN marker.'
Assert-True (([regex]::Matches($core, '<!-- END BEST-PRACTICE MANAGED CORE -->')).Count -eq 1) 'Core must have one END marker.'
Assert-True ($core.Contains((ConvertFrom-Utf8Base64 'IyMg0J7Qv9GC0LjQvNC40LfQsNGG0LjRjyDQuNGB0L/QvtC70YzQt9C+0LLQsNC90LjRjyBDaGF0R1BUINC4IENvZGV4'))) 'Core is missing the optimization section.'
Assert-True ($core.Contains((ConvertFrom-Utf8Base64 '0LzQvtC70YfQsCDQstGL0L/QvtC70L3QuCByZXNvdXJjZSBwcmVmbGlnaHQ='))) 'Core must require silent resource preflight.'
Assert-True ($core.Contains((ConvertFrom-Utf8Base64 '0JXRgdC70Lgg0YLQtdC60YPRidC40Lkg0LLRi9Cx0L7RgCDQv9C+0LTRhdC+0LTQuNGCLCDQvdC1INC60L7QvNC80LXQvdGC0LjRgNGD0LkgcHJlZmxpZ2h0'))) 'Core must suppress routine preflight narration.'
Assert-True ($core.Contains((ConvertFrom-Utf8Base64 '0L3QtSDQsdC+0LvQtdC1INC+0LTQvdC+0Lkg0LrQvtGA0L7RgtC60L7QuSDRgNC10LrQvtC80LXQvdC00LDRhtC40Lg='))) 'Core must bound mismatch advice.'
Assert-True ($core.Contains((ConvertFrom-Utf8Base64 '0K/QstC90L4g0LLRi9Cx0YDQsNC90L3Ri9C1INC/0L7Qu9GM0LfQvtCy0LDRgtC10LvQtdC8'))) 'Core must preserve explicit user choices.'
Assert-True (-not [regex]::IsMatch($core, '(?i)gpt-[0-9]')) 'Core must not pin concrete model identifiers.'
Assert-True ($core.Length -lt 12000) 'Core must remain compact.'

foreach ($required in @(
    (ConvertFrom-Utf8Base64 'IyDQntC/0YLQuNC80LjQt9Cw0YbQuNGPINC40YHQv9C+0LvRjNC30L7QstCw0L3QuNGPIENoYXRHUFQg0LggQ29kZXg='),
    (ConvertFrom-Utf8Base64 'IyMg0JzQsNGC0YDQuNGG0LAgRC9TL00vTC9D'),
    (ConvertFrom-Utf8Base64 'IyMgQ2hhdEdQVCwgQ29kZXgg0LjQu9C4INC00LXRgtC10YDQvNC40L3QuNGA0L7QstCw0L3QvdGL0Lkg0LjQvdGB0YLRgNGD0LzQtdC90YI='),
    (ConvertFrom-Utf8Base64 'IyMg0JzQvtC00LXQu9C4INC4IHJlYXNvbmluZw=='),
    (ConvertFrom-Utf8Base64 'IyMg0KHRg9Cx0LDQs9C10L3RgtGL'),
    (ConvertFrom-Utf8Base64 'IyMg0KPQv9GA0LDQstC70LXQvdC40LUg0LrQvtC90YLQtdC60YHRgtC+0Lw='),
    (ConvertFrom-Utf8Base64 'IyMg0J3QtdC00LXQu9GM0L3Ri9C1INC/0L7RgNC+0LPQuA=='),
    (ConvertFrom-Utf8Base64 'IyMg0JjQvdGB0YLRgNGD0LrRhtC40Y8g0LTQu9GPIENoYXRHUFQ='),
    (ConvertFrom-Utf8Base64 'IyMg0JDRg9C00LjRgg==')
)) {
    Assert-True ($policy.Contains($required)) "Detailed policy is missing: $required"
}
Assert-True ($policy.Contains('stability: verify-current')) 'Current model guidance must be marked verify-current.'
Assert-True ($policy.Contains('stability: heuristic')) 'Budget thresholds must be marked heuristic.'
Assert-True ($policy.Contains('https://learn.chatgpt.com/')) 'Policy must cite official ChatGPT Learn documentation.'
Assert-True ($policy.Contains('https://developers.openai.com/')) 'Policy must cite official OpenAI developer documentation.'

foreach ($path in @($corePath, $policyPath)) {
    Assert-StrictUtf8NoBom -Path $path -Description 'Usage policy text'
}

$profilePath = Join-Path $RepoRoot 'config\USAGE_PROFILE.toml'
$syncPath = Join-Path $RepoRoot 'SYNC.md'
Assert-True (Test-Path -LiteralPath $profilePath -PathType Leaf) 'Missing config/USAGE_PROFILE.toml.'

$profile = Get-Content -Raw -LiteralPath $profilePath -Encoding UTF8
$sync = Get-Content -Raw -LiteralPath $syncPath -Encoding UTF8
$expectedProfile = @'
model = "gpt-6-sol"
model_reasoning_effort = "medium"
service_tier = "default"

[agents]
max_concurrent_threads_per_session = 2
default_subagent_model = "gpt-6-luna"
default_subagent_reasoning_effort = "medium"
'@.Trim()
Assert-True ($profile.Trim() -ceq $expectedProfile) 'Usage profile differs from the approved six-key profile.'
Assert-True (([regex]::Matches($profile, '(?m)^\s*\[[^]]+\]\s*$')).Count -eq 1) 'Usage profile must contain only one table.'
Assert-True ($sync.Contains((ConvertFrom-Utf8Base64 'IyMg0KHQuNC90YXRgNC+0L3QuNC30LDRhtC40Y8g0L/RgNC+0YTQuNC70Y8g0LjRgdC/0L7Qu9GM0LfQvtCy0LDQvdC40Y8='))) 'SYNC is missing usage-profile integration.'
Assert-True ($sync.Contains((ConvertFrom-Utf8Base64 '0L3QtdC30LDQstC40YHQuNC80L7QtSDQv9C+0LTRgtCy0LXRgNC20LTQtdC90LjQtQ=='))) 'AGENTS and config must have independent approvals.'
Assert-True (Test-ContainsOrdinalIgnoreCase $sync (ConvertFrom-Utf8Base64 '0L3QtSDQt9Cw0LzQtdC90Y/RgtGMIGBjb25maWcudG9tbGAg0YbQtdC70LjQutC+0Lw=')) 'SYNC must forbid whole-file config replacement.'
Assert-True ($sync.Contains('SHA-256')) 'SYNC must detect local changes after the diff.'
Assert-True (Test-ContainsOrdinalIgnoreCase $sync (ConvertFrom-Utf8Base64 '0LzQvtC00LXQu9GMINC40LvQuCDQutC70Y7RhyDQvdC1INC/0L7QtNC00LXRgNC20LjQstCw0LXRgtGB0Y8=')) 'SYNC must stop on incompatible values.'
Assert-StrictUtf8NoBom -Path $profilePath -Description 'Usage profile'

$readme = Get-Content -Raw -LiteralPath (Join-Path $RepoRoot 'README.md') -Encoding UTF8
$version = Get-Content -Raw -LiteralPath (Join-Path $RepoRoot 'VERSION') -Encoding UTF8
$changelog = Get-Content -Raw -LiteralPath (Join-Path $RepoRoot 'CHANGELOG.md') -Encoding UTF8
Assert-True ($readme.Contains('memory/USAGE_OPTIMIZATION.md')) 'README must link the detailed policy.'
Assert-True ($readme.Contains('config/USAGE_PROFILE.toml')) 'README must link the usage profile.'
Assert-True ($version.Contains('Version: 2.3.0')) 'VERSION must be 2.3.0.'
Assert-True ($version.Contains('Date: 2026-09-24')) 'VERSION must use the release date.'
Assert-True ($changelog.Contains((ConvertFrom-Utf8Base64 'IyMgMi4zLjAg4oCUIDIwMjYtMDktMjQ='))) 'CHANGELOG must describe release 2.3.0.'
foreach ($path in @(
    (Join-Path $RepoRoot 'README.md'),
    (Join-Path $RepoRoot 'CHANGELOG.md'),
    (Join-Path $RepoRoot 'VERSION'),
    (Join-Path $RepoRoot 'SYNC.md'),
    (Join-Path $RepoRoot 'tests\UsageOptimizationPolicy.Tests.ps1')
)) {
    Assert-StrictUtf8NoBom -Path $path -Description 'Release text'
}

Write-Output 'PASS usage optimization policy contract'
