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

function Assert-ThrowsLike {
    param([scriptblock]$Action, [string]$Pattern, [string]$Message)
    try {
        & $Action
        throw "Expected failure did not occur: $Message"
    } catch {
        if ($_.Exception.Message -like 'Expected failure did not occur:*') { throw }
        Assert-True ($_.Exception.Message -like $Pattern) "$Message. Actual: $($_.Exception.Message)"
    }
}

$integrationScript = Join-Path $RepoRoot 'scripts\Integrate-UsageOptimization.ps1'
Assert-True (Test-Path -LiteralPath $integrationScript -PathType Leaf) 'Missing scripts/Integrate-UsageOptimization.ps1.'

$fixtureRoot = Join-Path ([IO.Path]::GetTempPath()) ("usage-profile-test-" + [guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Path $fixtureRoot | Out-Null

try {
    $utf8 = [Text.UTF8Encoding]::new($false)
    $core = [IO.File]::ReadAllText((Join-Path $RepoRoot 'AGENTS_CORE.md'), [Text.Encoding]::UTF8)
    $begin = '<!-- BEGIN BEST-PRACTICE MANAGED CORE -->'
    $end = '<!-- END BEST-PRACTICE MANAGED CORE -->'
    $beginIndex = $core.IndexOf($begin, [StringComparison]::Ordinal)
    $endIndex = $core.IndexOf($end, [StringComparison]::Ordinal)
    $managed = $core.Substring($beginIndex, $endIndex + $end.Length - $beginIndex)

    $agentsPath = Join-Path $fixtureRoot 'AGENTS.md'
    $configPath = Join-Path $fixtureRoot 'config.toml'
    $localOverride = "<!-- BEGIN LOCAL OVERRIDES -->`nlocal-only-value`n<!-- END LOCAL OVERRIDES -->"
    [IO.File]::WriteAllText($agentsPath, "prefix`n$managed`n`n$localOverride`n", $utf8)
    [IO.File]::WriteAllText($configPath, @'
model = "old-model"
model_reasoning_effort = "low"
service_tier = "priority"

[agents]
custom_agent_setting = true

[plugins.example]
enabled = true
'@, $utf8)

    $preview = & $integrationScript -RepoRoot $RepoRoot -Component Both `
        -AgentsPath $agentsPath -ConfigPath $configPath `
        -SupportedModels @('gpt-6-sol', 'gpt-6-luna')

    Assert-True (([regex]::Matches($preview.ProposedConfigText, '(?m)^\[agents\]\s*$')).Count -eq 1) 'Merge must keep exactly one [agents] table.'
    Assert-True ($preview.ProposedConfigText.Contains('custom_agent_setting = true')) 'Merge must preserve unrelated [agents] keys.'
    Assert-True ($preview.ProposedConfigText.Contains('[plugins.example]')) 'Merge must preserve unrelated tables.'
    Assert-True ($preview.ProposedConfigText.Contains('max_concurrent_threads_per_session = 2')) 'Merge must add the thread cap.'
    Assert-True ($preview.ProposedAgentsText.Contains($localOverride)) 'Managed-block preview must preserve local overrides.'

    Assert-ThrowsLike -Action {
        & $integrationScript -RepoRoot $RepoRoot -Component Config `
            -ConfigPath $configPath -SupportedModels @('gpt-6-sol') | Out-Null
    } -Pattern '*Unsupported model: gpt-6-luna*' -Message 'Unsupported model must stop with its exact value'

    $duplicateAgentsPath = Join-Path $fixtureRoot 'AGENTS-duplicate.md'
    [IO.File]::WriteAllText($duplicateAgentsPath, "$begin`n$managed`n$end`n$begin", $utf8)
    Assert-ThrowsLike -Action {
        & $integrationScript -RepoRoot $RepoRoot -Component Agents -AgentsPath $duplicateAgentsPath | Out-Null
    } -Pattern '*Expected exactly one BEGIN marker*' -Message 'Duplicate markers must stop before write'

    $reversedAgentsPath = Join-Path $fixtureRoot 'AGENTS-reversed.md'
    [IO.File]::WriteAllText($reversedAgentsPath, "$end`nvalue`n$begin", $utf8)
    Assert-ThrowsLike -Action {
        & $integrationScript -RepoRoot $RepoRoot -Component Agents -AgentsPath $reversedAgentsPath | Out-Null
    } -Pattern '*BEGIN marker must precede END marker*' -Message 'Reversed markers must stop before write'

    $oldHash = $preview.ConfigSha256
    [IO.File]::AppendAllText($configPath, "`nchanged_after_preview = true`n", $utf8)
    Assert-ThrowsLike -Action {
        & $integrationScript -RepoRoot $RepoRoot -Component Config -Apply `
            -ConfigPath $configPath -SupportedModels @('gpt-6-sol', 'gpt-6-luna') `
            -ExpectedConfigSha256 $oldHash | Out-Null
    } -Pattern '*Config changed after preview*' -Message 'Changed config hash must stop before write'

    [IO.File]::WriteAllText($configPath, @'
model = "old-model"
model_reasoning_effort = "low"
service_tier = "priority"

[agents]
custom_agent_setting = true

[plugins.example]
enabled = true
'@, $utf8)
    $cleanPreview = & $integrationScript -RepoRoot $RepoRoot -Component Both `
        -AgentsPath $agentsPath -ConfigPath $configPath `
        -SupportedModels @('gpt-6-sol', 'gpt-6-luna')
    $applied = & $integrationScript -RepoRoot $RepoRoot -Component Both -Apply `
        -AgentsPath $agentsPath -ConfigPath $configPath `
        -SupportedModels @('gpt-6-sol', 'gpt-6-luna') `
        -ExpectedAgentsSha256 $cleanPreview.AgentsSha256 `
        -ExpectedConfigSha256 $cleanPreview.ConfigSha256

    $appliedConfig = [IO.File]::ReadAllText($configPath, [Text.Encoding]::UTF8)
    $appliedAgents = [IO.File]::ReadAllText($agentsPath, [Text.Encoding]::UTF8)
    Assert-True ($applied.Applied) 'Successful integration must report Applied=true.'
    Assert-True ($appliedConfig.Contains('custom_agent_setting = true')) 'Applied config must preserve unrelated agent settings.'
    Assert-True ($appliedConfig.Contains('[plugins.example]')) 'Applied config must preserve unrelated tables.'
    Assert-True ($appliedAgents.Contains($localOverride)) 'Applied AGENTS must preserve local overrides.'
    Assert-True (@(Get-ChildItem -LiteralPath $fixtureRoot -Filter 'AGENTS.md.backup-*').Count -eq 1) 'AGENTS apply must create one backup.'
    Assert-True (@(Get-ChildItem -LiteralPath $fixtureRoot -Filter 'config.toml.backup-*').Count -eq 1) 'Config apply must create one backup.'
} finally {
    $resolvedFixture = [IO.Path]::GetFullPath($fixtureRoot)
    $resolvedTemp = [IO.Path]::GetFullPath([IO.Path]::GetTempPath())
    if (-not $resolvedFixture.StartsWith($resolvedTemp, [StringComparison]::OrdinalIgnoreCase)) {
        throw "Refusing to remove fixture outside temp: $resolvedFixture"
    }
    if (Test-Path -LiteralPath $fixtureRoot) {
        Remove-Item -LiteralPath $fixtureRoot -Recurse -Force
    }
}

Write-Output 'PASS usage profile integration fixtures'
