# Bundled CodexMeter Package Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Поместить проверенный установщик CodexMeter 1.1.1 непосредственно в приватный пакет Best Practice, чтобы другие компьютеры получали и проверяли его из одного репозитория.

**Architecture:** Каталог `packages/CodexMeter` содержит ровно одну актуальную сборку, её версию, SHA-256 и самодостаточную инструкцию. Отдельный PowerShell-контракт проверяет происхождение, целостность, Windows GUI subsystem и согласованность документации; финальный тест повторяет получение из чистого локального клона и безопасный `/quiet /whatif`.

**Tech Stack:** Git, Windows PowerShell 5.1, SHA-256, PE/COFF, Markdown, существующий детерминированный `CodexMeter-Setup.exe`.

## Global Constraints

- Источник payload: приватный репозиторий CodexMeter, тег `v1.1.1`, commit `804d30d8f77a5f9addd2db3c2156b0c832e2a585`.
- Ожидаемый SHA-256: `2AE0BF6815ABC50E100EA7852E3556F6A96AAB105DEE971FC557D6F1C707064E`.
- В Best Practice хранится только одна актуальная версия установщика; предыдущие доступны через историю Git.
- Не копировать `codex.exe`, учётные данные, токены, логи, app-server responses, реестр или машинные пути.
- Не запускать реальную установку и не останавливать действующий виджет; допустим только `/quiet /whatif`.
- Best Practice меняет версию с `2.2.0` на `2.2.1`; `AGENTS_CORE.md` и `SYNC.md` не меняются.
- Все текстовые файлы — UTF-8, diff без хвостовых пробелов; EXE остаётся бинарным.
- Проверочный контракт до перечисления дочерних элементов подтверждает, что `packages` и `packages/CodexMeter` — настоящие контейнеры без `ReparsePoint`; все release text files, включая `.gitattributes`, contract, metadata, инструкции, release records, design и этот plan, декодируются как strict UTF-8 без BOM.
- Все GUI вызовы bootstrapper используют `Start-Process -Wait -PassThru`; обновление существующего Best Practice clone fail-closed проверяет `git pull --ff-only` и явный корень из `git rev-parse --show-toplevel`.

---

## File Map

- Create: `packages/CodexMeter/CodexMeter-Setup.exe` — единственный переносимый bootstrapper.
- Create: `packages/CodexMeter/CodexMeter-Setup.exe.sha256` — ожидаемый хэш EXE одной строкой.
- Create: `packages/CodexMeter/VERSION` — версия, исходный тег и полный commit.
- Create: `packages/CodexMeter/INSTALL.md` — первая установка, обновление, проверка и SmartScreen.
- Create: `tests/CodexMeterPackage.Tests.ps1` — детерминированный контракт пакета.
- Create: `.gitattributes` — явная бинарная обработка EXE и единый LF для package metadata/tests.
- Modify: `memory/PROJECT_APPLICATIONS.md` — канонический сценарий через встроенный пакет.
- Modify: `README.md` — короткий указатель на локальный пакет.
- Modify: `CHANGELOG.md` — выпуск Best Practice 2.2.1.
- Modify: `VERSION` — версия Best Practice 2.2.1 и дата 2026-09-03.

---

### Task 1: Package integrity contract and CodexMeter payload

**Files:**
- Create: `tests/CodexMeterPackage.Tests.ps1`
- Create: `.gitattributes`
- Create: `packages/CodexMeter/CodexMeter-Setup.exe`
- Create: `packages/CodexMeter/CodexMeter-Setup.exe.sha256`
- Create: `packages/CodexMeter/VERSION`
- Create: `packages/CodexMeter/INSTALL.md`

**Interfaces:**
- Consumes: `CodexMeter/release/CodexMeter-Setup.exe` from exact source commit `804d30d8f77a5f9addd2db3c2156b0c832e2a585`.
- Produces: package directory with a stable four-file contract; `tests/CodexMeterPackage.Tests.ps1 -RepoRoot <path>` exits 0 only for a coherent package.

- [ ] **Step 1: Write the failing package contract**

Create `tests/CodexMeterPackage.Tests.ps1`:

```powershell
[CmdletBinding()]
param(
    [string]$RepoRoot = (Split-Path -Parent $PSScriptRoot)
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

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
    $tracked = & git -C $RepoRoot ls-files --error-unmatch -- "packages/CodexMeter/$name" 2>$null
    Assert-True ($LASTEXITCODE -eq 0 -and $tracked.Count -eq 1) "Package file is not tracked exactly once: $name"
}
$actualNames = @(Get-ChildItem -LiteralPath $packageRoot -File | Select-Object -ExpandProperty Name | Sort-Object)
$expectedNames = @($requiredNames | Sort-Object)
Assert-True (($actualNames -join "`n") -ceq ($expectedNames -join "`n")) 'CodexMeter package must contain exactly the four approved files.'

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
foreach ($required in @('git pull --ff-only', 'Get-FileHash', 'CodexMeter-Setup.exe.sha256', 'CodexMeter-Setup.exe', '/quiet /whatif', 'SmartScreen', '1.1.1')) {
    Assert-True ($install.Contains($required)) "INSTALL.md is missing required content: $required"
}

$text = $versionText + "`n" + $expectedHash + "`n" + $install
foreach ($pattern in @('(?i)C:\\Users\\[^\\\s]+', '(?i)ghp_[A-Za-z0-9]{20,}', '(?i)sk-[A-Za-z0-9]{20,}', '(?i)Bearer\s+[A-Za-z0-9._-]{20,}')) {
    Assert-True (-not [regex]::IsMatch($text, $pattern)) "Package metadata contains a forbidden machine path or credential pattern: $pattern"
}

Write-Output 'PASS CodexMeter package contract'
```

- [ ] **Step 2: Run the contract and record RED**

Run:

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\tests\CodexMeterPackage.Tests.ps1
```

Expected: exit 1 with `Missing required package file: CodexMeter-Setup.exe`.

- [ ] **Step 3: Declare deterministic text/binary handling**

Create `.gitattributes`:

```gitattributes
*.md text eol=lf
VERSION text eol=lf
*.ps1 text eol=lf
packages/CodexMeter/*.sha256 text eol=lf
packages/CodexMeter/CodexMeter-Setup.exe binary
```

- [ ] **Step 4: Copy only the approved release payload**

Run from the Best Practice root. Use an isolated clone so the source is determined by the exact Git object rather than by a machine-specific working path:

```powershell
$sourceCommit = '804d30d8f77a5f9addd2db3c2156b0c832e2a585'
$sourceRoot = Join-Path $env:TEMP ('codexmeter-source-' + [guid]::NewGuid().ToString('N'))
try {
    git clone --quiet --no-checkout https://github.com/pavel-tsapyuk/CodexMeter.git $sourceRoot
    if ($LASTEXITCODE -ne 0) { throw 'CodexMeter source clone failed.' }
    $actualCommit = (& git -C $sourceRoot rev-parse 'v1.1.1^{}').Trim()
    if ($actualCommit -cne $sourceCommit) { throw "Unexpected CodexMeter source commit: $actualCommit" }
    git -C $sourceRoot checkout --quiet --detach $sourceCommit
    if ($LASTEXITCODE -ne 0) { throw 'CodexMeter source checkout failed.' }

    $sourceExe = Join-Path $sourceRoot 'release\CodexMeter-Setup.exe'
    $sourceHash = (Get-FileHash -Algorithm SHA256 -LiteralPath $sourceExe).Hash
    if ($sourceHash -cne '2AE0BF6815ABC50E100EA7852E3556F6A96AAB105DEE971FC557D6F1C707064E') {
        throw "Unexpected CodexMeter source hash: $sourceHash"
    }

    $packageRoot = Join-Path $PWD 'packages\CodexMeter'
    New-Item -ItemType Directory -Path $packageRoot -Force | Out-Null
    Copy-Item -LiteralPath $sourceExe -Destination (Join-Path $packageRoot 'CodexMeter-Setup.exe')
} finally {
    $resolvedSource = [IO.Path]::GetFullPath($sourceRoot)
    $resolvedTemp = [IO.Path]::GetFullPath($env:TEMP).TrimEnd('\') + '\'
    if ((Test-Path -LiteralPath $resolvedSource) -and
        $resolvedSource.StartsWith($resolvedTemp, [StringComparison]::OrdinalIgnoreCase) -and
        ([IO.Path]::GetFileName($resolvedSource)).StartsWith('codexmeter-source-', [StringComparison]::Ordinal)) {
        Remove-Item -LiteralPath $resolvedSource -Recurse -Force
    }
}
```

- [ ] **Step 5: Add package metadata**

Create `packages/CodexMeter/CodexMeter-Setup.exe.sha256`:

```text
2AE0BF6815ABC50E100EA7852E3556F6A96AAB105DEE971FC557D6F1C707064E
```

Create `packages/CodexMeter/VERSION`:

```text
CodexMeter-Version: 1.1.1
Source-Tag: v1.1.1
Source-Commit: 804d30d8f77a5f9addd2db3c2156b0c832e2a585
```

Create `packages/CodexMeter/INSTALL.md`:

````markdown
# CodexMeter 1.1.1

Этот каталог содержит актуальный неподписанный установщик CodexMeter для компьютеров владельца. Он не содержит чужую учётную запись, токены, логи или `codex.exe`; приложение использует локальную установку Codex и вошедшего на этом компьютере пользователя.

## Получение и проверка

Открой PowerShell в корне существующего клона Best Practice:

```powershell
$ErrorActionPreference = 'Stop'
git pull --ff-only
if ($LASTEXITCODE -ne 0) { throw "Best Practice update failed: $LASTEXITCODE" }
$repoRoot = (& git rev-parse --show-toplevel).Trim()
if ($LASTEXITCODE -ne 0 -or -not $repoRoot) { throw 'Best Practice repository root was not found.' }
Set-Location -LiteralPath (Join-Path $repoRoot 'packages\CodexMeter') -ErrorAction Stop
$expected = (Get-Content -Raw .\CodexMeter-Setup.exe.sha256).Trim()
$actual = (Get-FileHash -Algorithm SHA256 .\CodexMeter-Setup.exe).Hash
if ($actual -cne $expected) { throw "SHA-256 mismatch: $actual" }
```

## Проверка без установки

```powershell
$process = Start-Process -FilePath .\CodexMeter-Setup.exe `
    -ArgumentList @('/quiet', '/whatif') -Wait -PassThru
if ($process.ExitCode -ne 0) {
    throw "CodexMeter preflight failed: $($process.ExitCode)"
}
```

## Установка или обновление

```powershell
$process = Start-Process -FilePath .\CodexMeter-Setup.exe -Wait -PassThru
if ($process.ExitCode -ne 0) { throw "CodexMeter installation failed: $($process.ExitCode)" }
```

Установщик работает без UAC и применяет тот же безопасный сценарий как для первой установки, так и для обновления. Поскольку цифровой подписи пока нет, Windows SmartScreen может показать `Unknown publisher`; сначала сверь SHA-256, затем используй стандартное действие **More info → Run anyway**.
````

- [ ] **Step 6: Stage the new package and run GREEN**

Run:

```powershell
git add -- .gitattributes tests/CodexMeterPackage.Tests.ps1 packages/CodexMeter
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\tests\CodexMeterPackage.Tests.ps1
git diff --cached --check
```

Expected: `PASS CodexMeter package contract`; `git diff --cached --check` exits 0.

- [ ] **Step 7: Commit the independently valid package**

```powershell
git commit -m "feat: bundle CodexMeter 1.1.1 package"
```

Expected: one commit containing only `.gitattributes`, the package and its contract.

---

### Task 2: Best Practice release metadata and user-facing instructions

**Files:**
- Modify: `tests/CodexMeterPackage.Tests.ps1`
- Modify: `memory/PROJECT_APPLICATIONS.md`
- Modify: `README.md`
- Modify: `CHANGELOG.md`
- Modify: `VERSION`

**Interfaces:**
- Consumes: coherent `packages/CodexMeter` contract from Task 1.
- Produces: Best Practice 2.2.1 whose canonical CodexMeter workflow uses the bundled package rather than a second clone.

- [ ] **Step 1: Extend the contract with documentation assertions**

Append before the final `Write-Output` in `tests/CodexMeterPackage.Tests.ps1`:

```powershell
$readme = Get-Content -Raw -LiteralPath (Join-Path $RepoRoot 'README.md')
$applications = Get-Content -Raw -LiteralPath (Join-Path $RepoRoot 'memory\PROJECT_APPLICATIONS.md')
$bestPracticeVersion = Get-Content -Raw -LiteralPath (Join-Path $RepoRoot 'VERSION')
$changelog = Get-Content -Raw -LiteralPath (Join-Path $RepoRoot 'CHANGELOG.md')

Assert-True ($readme.Contains('packages/CodexMeter/INSTALL.md')) 'README does not link to the bundled CodexMeter package.'
Assert-True ($applications.Contains('packages/CodexMeter')) 'PROJECT_APPLICATIONS does not use the bundled CodexMeter package.'
Assert-True ($applications.Contains('CodexMeter 1.1.1')) 'PROJECT_APPLICATIONS does not identify the bundled CodexMeter version.'
Assert-True ($bestPracticeVersion.Contains('Version: 2.2.1')) 'Best Practice VERSION was not raised to 2.2.1.'
Assert-True ($bestPracticeVersion.Contains('Date: 2026-09-03')) 'Best Practice VERSION has the wrong release date.'
Assert-True ($changelog.Contains('## 2.2.1 — 2026-09-03')) 'CHANGELOG is missing the 2.2.1 release.'
```

- [ ] **Step 2: Run the extended contract and record RED**

Run:

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\tests\CodexMeterPackage.Tests.ps1
```

Expected: exit 1 with `README does not link to the bundled CodexMeter package.`

- [ ] **Step 3: Replace the project workflow with the bundled-package workflow**

In `memory/PROJECT_APPLICATIONS.md`, replace the complete `### CodexMeter` section through the line before `## Клиентские документы` with:

````markdown
### CodexMeter

CodexMeter — приватный Windows-виджет для постоянного отображения остатка недельного лимита Codex и даты следующего сброса.

Совместимость и подготовка:

- Windows 10 Pro 22H2 x64, build 19045.6456, физически проверена 2026-08-23.
- Windows 11 x64 поддерживается контрактом платформы и архитектуры.
- Нужны .NET Framework 4.8.1 и установленное приложение OpenAI Codex с выполненным входом в учётную запись.

Best Practice включает проверенный CodexMeter 1.1.1 в [`packages/CodexMeter`](../packages/CodexMeter/INSTALL.md). На другом компьютере нужен доступ только к приватному репозиторию Best Practice; отдельный клон CodexMeter не требуется.

Первая установка или обновление:

```powershell
$ErrorActionPreference = 'Stop'
git pull --ff-only
if ($LASTEXITCODE -ne 0) { throw "Best Practice update failed: $LASTEXITCODE" }
$repoRoot = (& git rev-parse --show-toplevel).Trim()
if ($LASTEXITCODE -ne 0 -or -not $repoRoot) { throw 'Best Practice repository root was not found.' }
Set-Location -LiteralPath (Join-Path $repoRoot 'packages\CodexMeter') -ErrorAction Stop
$expected = (Get-Content -Raw .\CodexMeter-Setup.exe.sha256).Trim()
$actual = (Get-FileHash -Algorithm SHA256 .\CodexMeter-Setup.exe).Hash
if ($actual -cne $expected) { throw "SHA-256 mismatch: $actual" }
$process = Start-Process -FilePath .\CodexMeter-Setup.exe -Wait -PassThru
if ($process.ExitCode -ne 0) { throw "CodexMeter installation failed: $($process.ExitCode)" }
```

Безопасная проверка без установки:

```powershell
$process = Start-Process -FilePath .\CodexMeter-Setup.exe `
    -ArgumentList @('/quiet', '/whatif') -Wait -PassThru
if ($process.ExitCode -ne 0) {
    throw "CodexMeter preflight failed: $($process.ExitCode)"
}
```

Полная инструкция, включая предупреждение SmartScreen: [`packages/CodexMeter/INSTALL.md`](../packages/CodexMeter/INSTALL.md).

Удаление установленного виджета:

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "$env:LOCALAPPDATA\CodexMeter\Uninstall-CodexMeter.ps1"
```

Bootstrapper не содержит учётную запись владельца, токены, логи или `codex.exe`. На каждом компьютере он находит локальную официальную установку Codex и использует учётную запись вошедшего пользователя.

Лимит читается локально через `codex app-server --stdio` и `account/rateLimits/read`, без парсинга страницы usage. Логи (`%LOCALAPPDATA%\CodexMeter\CodexMeter.log`), живые ответы, снимки, учётные данные, токены и другие секреты остаются только локально и не добавляются в Best Practice.
````

- [ ] **Step 4: Update README, changelog and Best Practice version**

Replace the README CodexMeter pointer with:

```markdown
Актуальный установщик приватного виджета лимита: [пакет CodexMeter](packages/CodexMeter/INSTALL.md). Архитектура и границы применения: [CodexMeter в проектных применениях](memory/PROJECT_APPLICATIONS.md#codexmeter).
```

Prepend to `CHANGELOG.md`:

```markdown
## 2.2.1 — 2026-09-03

### Что изменилось

- Проверенный установщик CodexMeter 1.1.1, его версия, SHA-256 и инструкция включены непосредственно в приватный пакет Best Practice.
- Добавлен контракт, который проверяет происхождение, целостность и согласованность переносимого пакета.

### Почему

Другие компьютеры владельца должны получать актуальный CodexMeter из одного приватного репозитория без отдельного доступа к репозиторию приложения.

### Ожидаемое изменение поведения

После обновления Best Practice Codex проверяет SHA-256 и устанавливает либо обновляет CodexMeter из `packages/CodexMeter`; локальная учётная запись и runtime в Git не переносятся.
```

Replace `VERSION` with:

```text
Codex Best Practice
Version: 2.2.1
Date: 2026-09-03
Scope: managed shared memory for multiple Codex installations
```

- [ ] **Step 5: Run focused and repository-wide documentation gates**

Run:

```powershell
git add -- README.md CHANGELOG.md VERSION memory/PROJECT_APPLICATIONS.md tests/CodexMeterPackage.Tests.ps1
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\tests\CodexMeterPackage.Tests.ps1
git diff --cached --check
rg -n "CodexMeter 1\.1\.0|packages/CodexMeter|2\.2\.1|2026-09-03" README.md CHANGELOG.md VERSION memory/PROJECT_APPLICATIONS.md packages/CodexMeter tests/CodexMeterPackage.Tests.ps1
rg -n "git clone https://github\.com/pavel-tsapyuk/CodexMeter" README.md memory/PROJECT_APPLICATIONS.md packages/CodexMeter
```

Expected: package contract passes; diff check passes; required references are found; the obsolete separate-clone command returns no matches.

- [ ] **Step 6: Commit the Best Practice release metadata**

```powershell
git commit -m "docs: publish bundled CodexMeter package"
```

Expected: one commit limited to the five listed documentation/contract files.

---

### Task 3: Clean-clone and no-mutation release verification

**Files:**
- Verify only; no tracked file changes.

**Interfaces:**
- Consumes: committed Best Practice 2.2.1 from Tasks 1 and 2.
- Produces: evidence that another computer can receive, validate and preflight the same package without changing this computer's installation.

- [ ] **Step 1: Capture live-state fingerprints before `/whatif`**

Run:

```powershell
$appRoot = Join-Path $env:LOCALAPPDATA 'CodexMeter'
$runKey = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Run'
$beforeProcesses = @(Get-CimInstance Win32_Process | Where-Object { $_.ExecutablePath -eq (Join-Path $appRoot 'CodexMeter.exe') } | Select-Object -ExpandProperty ProcessId | Sort-Object)
$beforeRun = (Get-Item -LiteralPath $runKey).GetValue('CodexMeter', $null, [Microsoft.Win32.RegistryValueOptions]::DoNotExpandEnvironmentNames)
$beforeExeHash = if (Test-Path -LiteralPath (Join-Path $appRoot 'CodexMeter.exe')) { (Get-FileHash -Algorithm SHA256 -LiteralPath (Join-Path $appRoot 'CodexMeter.exe')).Hash } else { $null }
```

- [ ] **Step 2: Make a fresh local clone and rerun the package contract**

Run from the Best Practice root:

```powershell
$verificationRoot = Join-Path $env:TEMP ('best-practice-codexmeter-' + [guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Path $verificationRoot | Out-Null
$clone = Join-Path $verificationRoot 'best-practice'
git -c core.autocrlf=true clone --no-hardlinks --local $PWD $clone
if ($LASTEXITCODE -ne 0) { throw 'Fresh clone failed.' }
powershell.exe -NoProfile -ExecutionPolicy Bypass -File (Join-Path $clone 'tests\CodexMeterPackage.Tests.ps1') -RepoRoot $clone
if ($LASTEXITCODE -ne 0) { throw 'Fresh-clone package contract failed.' }
```

Expected: clone succeeds and prints `PASS CodexMeter package contract`.

- [ ] **Step 3: Run the copied bootstrapper in no-mutation mode**

Run:

```powershell
$cloneExe = Join-Path $clone 'packages\CodexMeter\CodexMeter-Setup.exe'
$process = Start-Process -FilePath $cloneExe `
    -ArgumentList @('/quiet', '/whatif') -Wait -PassThru
if ($process.ExitCode -ne 0) { throw "Fresh-clone CodexMeter preflight failed: $($process.ExitCode)" }
```

Expected: exit 0 and a successful prerequisites/payload report; no installation is performed.

- [ ] **Step 4: Prove installed state was unchanged**

Run:

```powershell
$afterProcesses = @(Get-CimInstance Win32_Process | Where-Object { $_.ExecutablePath -eq (Join-Path $appRoot 'CodexMeter.exe') } | Select-Object -ExpandProperty ProcessId | Sort-Object)
$afterRun = (Get-Item -LiteralPath $runKey).GetValue('CodexMeter', $null, [Microsoft.Win32.RegistryValueOptions]::DoNotExpandEnvironmentNames)
$afterExeHash = if (Test-Path -LiteralPath (Join-Path $appRoot 'CodexMeter.exe')) { (Get-FileHash -Algorithm SHA256 -LiteralPath (Join-Path $appRoot 'CodexMeter.exe')).Hash } else { $null }

if (($beforeProcesses -join ',') -cne ($afterProcesses -join ',')) { throw 'WhatIf changed the running CodexMeter process set.' }
if ([string]$beforeRun -cne [string]$afterRun) { throw 'WhatIf changed CodexMeter autostart.' }
if ([string]$beforeExeHash -cne [string]$afterExeHash) { throw 'WhatIf changed the installed CodexMeter executable.' }
```

Expected: no exception.

- [ ] **Step 5: Verify repository and remove only the task-owned clone**

Run:

```powershell
git status --short --branch
git diff --check
git fsck --strict --no-dangling

$resolvedVerification = [IO.Path]::GetFullPath($verificationRoot)
$resolvedTemp = [IO.Path]::GetFullPath($env:TEMP).TrimEnd('\') + '\'
if (-not $resolvedVerification.StartsWith($resolvedTemp, [StringComparison]::OrdinalIgnoreCase) -or
    -not ([IO.Path]::GetFileName($resolvedVerification)).StartsWith('best-practice-codexmeter-', [StringComparison]::Ordinal)) {
    throw "Refusing to remove unexpected verification path: $resolvedVerification"
}
Remove-Item -LiteralPath $resolvedVerification -Recurse -Force
```

Expected: a clean branch summary (the exact ahead count depends on the already committed local Best Practice changes); diff and fsck pass; only the uniquely named temporary clone is removed.

---

## Final Acceptance

- `packages/CodexMeter` contains exactly the approved CodexMeter 1.1.1 installer plus its three text companions.
- SHA-256 equals `2AE0BF6815ABC50E100EA7852E3556F6A96AAB105DEE971FC557D6F1C707064E` in the source repo, Best Practice working tree and fresh clone.
- Best Practice reports version 2.2.1 and points users to its own bundled package.
- Windows PowerShell 5.1 contract passes from the main repository and fresh clone.
- `/quiet /whatif` waits for the GUI bootstrapper to exit, then returns success without changing the installed executable, exact process set or HKCU autostart value.
- Git status is clean; diff check and `git fsck --strict --no-dangling` pass.
