[CmdletBinding()]
param(
    [string]$RepoRoot,
    [ValidateSet('Agents', 'Config', 'Both')]
    [string]$Component = 'Both',
    [string]$AgentsPath,
    [string]$ConfigPath,
    [string[]]$SupportedModels = @(),
    [switch]$Apply,
    [string]$ExpectedAgentsSha256,
    [string]$ExpectedConfigSha256
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

if ([string]::IsNullOrWhiteSpace($RepoRoot)) {
    $RepoRoot = Split-Path -Parent $PSScriptRoot
}

$beginMarker = '<!-- BEGIN BEST-PRACTICE MANAGED CORE -->'
$endMarker = '<!-- END BEST-PRACTICE MANAGED CORE -->'
$utf8Strict = [Text.UTF8Encoding]::new($false, $true)
$utf8NoBom = [Text.UTF8Encoding]::new($false)

function Read-StrictUtf8 {
    param([string]$Path)
    $bytes = [IO.File]::ReadAllBytes($Path)
    return $utf8Strict.GetString($bytes)
}

function Get-FileSha256 {
    param([string]$Path)
    return (Get-FileHash -Algorithm SHA256 -LiteralPath $Path).Hash
}

function Get-ValidatedManagedRange {
    param([string]$Text, [string]$Description)

    $beginCount = ([regex]::Matches($Text, [regex]::Escape($beginMarker))).Count
    $endCount = ([regex]::Matches($Text, [regex]::Escape($endMarker))).Count
    if ($beginCount -ne 1) { throw "${Description}: Expected exactly one BEGIN marker; found $beginCount." }
    if ($endCount -ne 1) { throw "${Description}: Expected exactly one END marker; found $endCount." }

    $beginIndex = $Text.IndexOf($beginMarker, [StringComparison]::Ordinal)
    $endIndex = $Text.IndexOf($endMarker, [StringComparison]::Ordinal)
    if ($beginIndex -ge $endIndex) { throw "${Description}: BEGIN marker must precede END marker." }

    [pscustomobject]@{
        Start = $beginIndex
        EndExclusive = $endIndex + $endMarker.Length
        Text = $Text.Substring($beginIndex, $endIndex + $endMarker.Length - $beginIndex)
    }
}

function Get-ProfileValues {
    param([string]$ProfileText)

    $values = @{}
    $section = ''
    foreach ($line in ($ProfileText -split "`r?`n")) {
        if ($line -match '^\s*\[([^]]+)\]\s*$') {
            $section = $Matches[1]
            continue
        }
        if ($line -match '^\s*([A-Za-z0-9_]+)\s*=\s*(.+?)\s*$') {
            $name = if ($section) { "$section.$($Matches[1])" } else { $Matches[1] }
            if ($values.ContainsKey($name)) { throw "Duplicate profile key: $name" }
            $values[$name] = $Matches[2]
        }
    }

    $expected = @(
        'model',
        'model_reasoning_effort',
        'service_tier',
        'agents.max_concurrent_threads_per_session',
        'agents.default_subagent_model',
        'agents.default_subagent_reasoning_effort'
    )
    $actual = @($values.Keys | Sort-Object)
    $wanted = @($expected | Sort-Object)
    if (($actual -join "`n") -cne ($wanted -join "`n")) {
        throw "Profile must contain exactly the six allowlisted keys. Actual: $($actual -join ', ')"
    }
    return $values
}

function Get-UnquotedTomlString {
    param([string]$Value)
    if ($Value -notmatch '^"([^"\\]*)"$') { throw "Expected a simple TOML string, got: $Value" }
    return $Matches[1]
}

function Merge-ConfigText {
    param([string]$ConfigText, [hashtable]$Values)

    $newline = if ($ConfigText.Contains("`r`n")) { "`r`n" } else { "`n" }
    $lines = [Collections.Generic.List[string]]::new()
    foreach ($line in ($ConfigText -split "`r?`n", -1)) { $lines.Add($line) }

    $rootKeys = @('model', 'model_reasoning_effort', 'service_tier')
    foreach ($key in $rootKeys) {
        $firstSection = $lines.Count
        for ($i = 0; $i -lt $lines.Count; $i++) {
            if ($lines[$i] -match '^\s*\[[^]]+\]\s*$') { $firstSection = $i; break }
        }
        $foundIndices = @()
        for ($i = 0; $i -lt $firstSection; $i++) {
            if ($lines[$i] -match ('^\s*' + [regex]::Escape($key) + '\s*=')) { $foundIndices += $i }
        }
        if ($foundIndices.Count -gt 1) { throw "Duplicate root config key: $key" }
        $replacement = "$key = $($Values[$key])"
        if ($foundIndices.Count -eq 1) { $lines[$foundIndices[0]] = $replacement }
        else { $lines.Insert($firstSection, $replacement) }
    }

    $agentHeaders = @()
    for ($i = 0; $i -lt $lines.Count; $i++) {
        if ($lines[$i] -match '^\s*\[agents\]\s*$') { $agentHeaders += $i }
    }
    if ($agentHeaders.Count -gt 1) { throw 'Duplicate [agents] tables in local config.' }
    if ($agentHeaders.Count -eq 0) {
        if ($lines.Count -gt 0 -and $lines[$lines.Count - 1] -ne '') { $lines.Add('') }
        $lines.Add('[agents]')
        $agentHeader = $lines.Count - 1
    } else {
        $agentHeader = $agentHeaders[0]
    }

    foreach ($key in @('max_concurrent_threads_per_session', 'default_subagent_model', 'default_subagent_reasoning_effort')) {
        $sectionEnd = $lines.Count
        for ($i = $agentHeader + 1; $i -lt $lines.Count; $i++) {
            if ($lines[$i] -match '^\s*\[[^]]+\]\s*$') { $sectionEnd = $i; break }
        }
        $foundIndices = @()
        for ($i = $agentHeader + 1; $i -lt $sectionEnd; $i++) {
            if ($lines[$i] -match ('^\s*' + [regex]::Escape($key) + '\s*=')) { $foundIndices += $i }
        }
        if ($foundIndices.Count -gt 1) { throw "Duplicate [agents] config key: $key" }
        $replacement = "$key = $($Values["agents.$key"])"
        if ($foundIndices.Count -eq 1) { $lines[$foundIndices[0]] = $replacement }
        else { $lines.Insert($sectionEnd, $replacement) }
    }

    return ($lines -join $newline)
}

$doAgents = $Component -eq 'Agents' -or $Component -eq 'Both'
$doConfig = $Component -eq 'Config' -or $Component -eq 'Both'
$proposedAgents = $null
$proposedConfig = $null
$agentsSha = $null
$configSha = $null

if ($doAgents) {
    if ([string]::IsNullOrWhiteSpace($AgentsPath)) { throw 'AgentsPath is required.' }
    $coreText = Read-StrictUtf8 (Join-Path $RepoRoot 'AGENTS_CORE.md')
    $targetText = Read-StrictUtf8 $AgentsPath
    $coreRange = Get-ValidatedManagedRange $coreText 'AGENTS_CORE.md'
    $targetRange = Get-ValidatedManagedRange $targetText $AgentsPath
    $proposedAgents = $targetText.Substring(0, $targetRange.Start) + $coreRange.Text +
        $targetText.Substring($targetRange.EndExclusive)
    $agentsSha = Get-FileSha256 $AgentsPath
}

if ($doConfig) {
    if ([string]::IsNullOrWhiteSpace($ConfigPath)) { throw 'ConfigPath is required.' }
    if ($SupportedModels.Count -eq 0) { throw 'SupportedModels is required for config integration.' }
    $profileText = Read-StrictUtf8 (Join-Path $RepoRoot 'config\USAGE_PROFILE.toml')
    $values = Get-ProfileValues $profileText
    foreach ($key in @('model', 'agents.default_subagent_model')) {
        $model = Get-UnquotedTomlString $values[$key]
        if ($SupportedModels -notcontains $model) { throw "Unsupported model: $model" }
    }
    $configText = Read-StrictUtf8 $ConfigPath
    $proposedConfig = Merge-ConfigText $configText $values
    $configSha = Get-FileSha256 $ConfigPath
}

if ($Apply) {
    if ($doAgents) {
        if ([string]::IsNullOrWhiteSpace($ExpectedAgentsSha256)) { throw 'ExpectedAgentsSha256 is required for apply.' }
        if ((Get-FileSha256 $AgentsPath) -cne $ExpectedAgentsSha256) { throw 'AGENTS changed after preview.' }
    }
    if ($doConfig) {
        if ([string]::IsNullOrWhiteSpace($ExpectedConfigSha256)) { throw 'ExpectedConfigSha256 is required for apply.' }
        if ((Get-FileSha256 $ConfigPath) -cne $ExpectedConfigSha256) { throw 'Config changed after preview.' }
    }

    $stamp = Get-Date -Format 'yyyyMMdd-HHmmss-fff'
    $agentsBackup = if ($doAgents) { "$AgentsPath.backup-$stamp" } else { $null }
    $configBackup = if ($doConfig) { "$ConfigPath.backup-$stamp" } else { $null }
    try {
        if ($doAgents) {
            Copy-Item -LiteralPath $AgentsPath -Destination $agentsBackup -ErrorAction Stop
            [IO.File]::WriteAllText($AgentsPath, $proposedAgents, $utf8NoBom)
        }
        if ($doConfig) {
            Copy-Item -LiteralPath $ConfigPath -Destination $configBackup -ErrorAction Stop
            [IO.File]::WriteAllText($ConfigPath, $proposedConfig, $utf8NoBom)
        }
    } catch {
        if ($doAgents -and $agentsBackup -and (Test-Path -LiteralPath $agentsBackup)) {
            Copy-Item -LiteralPath $agentsBackup -Destination $AgentsPath -Force
        }
        if ($doConfig -and $configBackup -and (Test-Path -LiteralPath $configBackup)) {
            Copy-Item -LiteralPath $configBackup -Destination $ConfigPath -Force
        }
        throw
    }
}

[pscustomobject]@{
    Component = $Component
    Applied = [bool]$Apply
    AgentsSha256 = $agentsSha
    ConfigSha256 = $configSha
    ProposedAgentsText = $proposedAgents
    ProposedConfigText = $proposedConfig
}
