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

Write-Output 'PASS usage optimization policy contract'
