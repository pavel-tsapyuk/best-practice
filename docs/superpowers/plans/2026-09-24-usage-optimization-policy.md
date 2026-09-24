# Unified ChatGPT and Codex Usage Optimization Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add one synchronized, resource-aware operating policy for ChatGPT and Codex, then safely integrate it on three computers without overwriting machine-specific settings.

**Architecture:** Keep the always-loaded behavior short and model-agnostic in `AGENTS_CORE.md`; place detailed routing, current model mappings, budget heuristics, and the ChatGPT instruction snippet in `memory/USAGE_OPTIMIZATION.md`; keep recommended machine settings in a narrow `config/USAGE_PROFILE.toml`. Extend `SYNC.md` so the managed AGENTS block and the allowlisted config keys have separate compatibility checks, diffs, approvals, integrations, and verification.

**Tech Stack:** Markdown, TOML, PowerShell 5.1+, Git, Codex global `AGENTS.md` and `config.toml`.

**Spec:** `docs/superpowers/specs/2026-09-24-usage-optimization-policy-design.md`

## Global Constraints

- The resource preflight is silent when the current tool, model, reasoning, speed, and agent count are appropriate.
- The active core uses model roles and must not contain concrete model identifiers such as `gpt-6-sol` or `gpt-6-luna`.
- Detailed guidance is loaded only for expensive tasks, routing decisions, threshold handling, or audits.
- `config/USAGE_PROFILE.toml` is a recommendation source, never a whole-file replacement for local `~/.codex/config.toml`.
- Managed AGENTS integration and config integration have independent approval gates.
- Local paths, notifications, MCP servers, plugins, permissions, projects, hardware instructions, and automations are preserved.
- An unsupported Codex version, model, or config key stops config integration and requires a user decision.
- No GitHub publication occurs before review of the implementation diff and explicit user confirmation.
- The release version is `2.3.0` dated `2026-09-24`.
- All maintained text files are strict UTF-8 without BOM and contain no credentials or machine-specific user paths.

## Review Focus

1. **Existing `[agents]` table in local config:** merge the four allowlisted keys into that table without creating a duplicate table or replacing unrelated keys; Task 6 verifies this against a temporary fixture.
2. **Unsupported model or config key:** compatibility check must stop before writing and report the exact unsupported value; Task 6 tests a deliberately unsupported profile.
3. **Repeated or malformed managed markers:** AGENTS integration must stop before writing; Task 6 tests duplicate start markers.
4. **Local config changes after diff:** integration must compare a pre-write SHA-256 and stop on mismatch; Task 6 tests a changed fixture.
5. **Simple tasks becoming noisier:** the core must explicitly suppress routine preflight narration; Tasks 1 and 2 pin the exact behavior with contract assertions.

---

### Task 1: Add the active-policy contract tests

**Files:**
- Create: `tests/UsageOptimizationPolicy.Tests.ps1`
- Test: `tests/UsageOptimizationPolicy.Tests.ps1`

**Interfaces:**
- Consumes: repository root supplied through optional `-RepoRoot`.
- Produces: a PowerShell contract that exits successfully only when the core and detailed policy meet the approved structure.

- [ ] **Step 1: Write the failing contract test**

Create `tests/UsageOptimizationPolicy.Tests.ps1` with this initial content:

```powershell
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

$corePath = Join-Path $RepoRoot 'AGENTS_CORE.md'
$policyPath = Join-Path $RepoRoot 'memory\USAGE_OPTIMIZATION.md'
Assert-True (Test-Path -LiteralPath $policyPath -PathType Leaf) 'Missing memory/USAGE_OPTIMIZATION.md.'

$core = Get-Content -Raw -LiteralPath $corePath
$policy = Get-Content -Raw -LiteralPath $policyPath

Assert-True (([regex]::Matches($core, '<!-- BEGIN BEST-PRACTICE MANAGED CORE -->')).Count -eq 1) 'Core must have one BEGIN marker.'
Assert-True (([regex]::Matches($core, '<!-- END BEST-PRACTICE MANAGED CORE -->')).Count -eq 1) 'Core must have one END marker.'
Assert-True ($core.Contains('## Оптимизация использования ChatGPT и Codex')) 'Core is missing the optimization section.'
Assert-True ($core.Contains('молча выполни resource preflight')) 'Core must require silent resource preflight.'
Assert-True ($core.Contains('Если текущий выбор подходит, не комментируй preflight')) 'Core must suppress routine preflight narration.'
Assert-True ($core.Contains('не более одной короткой рекомендации')) 'Core must bound mismatch advice.'
Assert-True ($core.Contains('Явно выбранные пользователем')) 'Core must preserve explicit user choices.'
Assert-True (-not [regex]::IsMatch($core, '(?i)gpt-[0-9]')) 'Core must not pin concrete model identifiers.'
Assert-True ($core.Length -lt 12000) 'Core must remain compact.'

foreach ($required in @(
    '# Оптимизация использования ChatGPT и Codex',
    '## Матрица D/S/M/L/C',
    '## ChatGPT, Codex или детерминированный инструмент',
    '## Модели и reasoning',
    '## Субагенты',
    '## Управление контекстом',
    '## Недельные пороги',
    '## Инструкция для ChatGPT',
    '## Аудит'
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
```

- [ ] **Step 2: Run the test and verify the intended failure**

Run:

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\tests\UsageOptimizationPolicy.Tests.ps1
```

Expected: FAIL with `Missing memory/USAGE_OPTIMIZATION.md.`

- [ ] **Step 3: Commit the failing test**

```powershell
git add -- tests/UsageOptimizationPolicy.Tests.ps1
git -c user.name="Pavel Tsapyuk" -c user.email="pawlick@pawlick.ru" commit -m "test: define usage optimization policy contract"
```

### Task 2: Implement the short core and detailed policy

**Files:**
- Modify: `AGENTS_CORE.md`
- Create: `memory/USAGE_OPTIMIZATION.md`
- Test: `tests/UsageOptimizationPolicy.Tests.ps1`

**Interfaces:**
- Consumes: the approved behavior in the design specification and the existing managed-core markers.
- Produces: an always-loaded model-agnostic policy plus a progressively disclosed detailed decision guide.

- [ ] **Step 1: Add the compact active section to `AGENTS_CORE.md`**

Insert the following section immediately after `## Обязательный рабочий процесс` and before `## Области действия и конфликты`:

```markdown
## Оптимизация использования ChatGPT и Codex

1. Перед каждой задачей молча выполни resource preflight: нужен ли LLM,
   какой инструмент подходит, и какие минимальные модель, reasoning,
   скорость и число агентов достаточны для criteria of done.
2. По умолчанию предпочитай детерминированный инструмент, standard/default
   speed, одного агента и low/medium reasoning. Более дорогой режим требует
   конкретной пользы для текущей задачи.
3. Используй лёгкую модель для чётких повторяемых операций, рабочую — для
   обычной разработки и исследования, старшую — для неоднозначной,
   критичной или доказанно сложной работы.
4. Не создавай субагента для одиночного поиска, чтения файла, простой
   проверки или детерминированной операции. Перед делегированием проверь,
   что ветвь действительно независима.
5. Если текущий режим существенно избыточен, перед дорогой работой выдай
   не более одной короткой рекомендации с конкретной альтернативой. Если
   текущий выбор подходит, не комментируй preflight и сразу выполняй задачу.
6. Для долгой задачи заранее задай критерии готовности, лимит попыток,
   STOP-условие и требуемую краткость результата.
7. Проверяй текущий расход перед потенциально дорогой работой, при известном
   приближении к бюджетному порогу или по запросу, но не перед каждой мелкой
   задачей.
8. Явно выбранные пользователем инструмент, модель, reasoning или скорость
   не меняй молча; при существенном перерасходе один раз предложи альтернативу.
```

- [ ] **Step 2: Create `memory/USAGE_OPTIMIZATION.md` with the approved structure**

Use these exact top-level sections and metadata boundaries:

````markdown
# Оптимизация использования ChatGPT и Codex

Проверено по официальной документации OpenAI: 2026-09-24.

## Устойчивые правила

```yaml
scope: shared
stability: stable
conflict: enforce-shared
```

Перед каждой задачей молча определи, нужен ли LLM, какой инструмент подходит
и какие минимальные модель, reasoning, скорость и число агентов достаточны.
Если задачу надёжно решает обычный код, CLI, тест или расписание, предпочти
детерминированный маршрут.

Если текущий режим подходит, сразу выполняй задачу без формального отчёта о
preflight. Если режим существенно избыточен, перед дорогой работой дай не
более одной короткой рекомендации с конкретной альтернативой. Явный выбор
пользователя не меняй молча.

Для долгой задачи до исполнения определи criteria of done, максимум две
попытки одной гипотезы, STOP-условие и краткий формат результата. Завершение
подтверждай фактической проверкой, а не заявлением модели.

## Матрица D/S/M/L/C

```yaml
scope: shared
stability: heuristic
conflict: ask
```

| Класс | Работа | Маршрут |
|---|---|---|
| D | Бэкап, сортировка, точное сравнение, тест, хеширование, расписание | Код/CLI/Task Scheduler/CI без LLM |
| S | Короткая чёткая операция, извлечение, форматирование, небольшой файл | Лёгкая модель, low/medium, один агент |
| M | Обычная разработка, диагностика, исследование с проверкой | Рабочая модель, medium, один агент |
| L | Неоднозначная архитектура, сложный межсистемный анализ | Рабочая high или старшая medium; до двух независимых субагентов |
| C | Критический аудит или высокая цена ошибки | Сильная модель и отдельная проверка по явным критериям |

## ChatGPT, Codex или детерминированный инструмент
## Модели и reasoning
## Скорость
## Субагенты
## Browser, Computer Use и MCP
## Управление контекстом
## Недельные пороги
## Инструкция для ChatGPT
## Аудит
## Источники
````

Fill the remaining named sections with these exact decisions:

- `ChatGPT, Codex или детерминированный инструмент`: ChatGPT формулирует задачу, сравнивает варианты и объясняет; Codex читает реальные файлы, меняет их и запускает проверки; код/CLI выполняет точные операции. Передача ChatGPT → Codex содержит только выбранное решение, criteria of done, ограничения и ссылки на входные файлы.
- `Скорость`: `default` является нормой; fast mode допустим только когда выигрыш времени важнее повышенного расхода и пользователь сделал осознанный выбор.
- `Субагенты`: один агент по умолчанию; максимум два параллельных субагента; ветвь должна быть независимой; одиночный поиск, чтение файла и простая проверка не делегируются.
- `Browser, Computer Use и MCP`: сначала специализированный коннектор, API, CLI или локальный файл; браузер и computer use применяются только когда семантического интерфейса нет; результаты инструментов ограничиваются нужными полями.
- `Управление контекстом`: одна устойчивая цель на задачу; `/side` для бокового вопроса; `/compact` после завершённого этапа той же цели; новая задача или fork при смене цели; между компьютерами передавать Git diff/commit и короткий handoff вместо полного разговора.
- `Аудит`: для крупных задач записывать дату, машину, класс, инструмент, модель, reasoning, speed, число субагентов, repair rounds и проверенный исход; сравнивать одинаковую точку двух последовательных недельных окон.

Under `## Модели и reasoning`, add this metadata block and routing table:

````markdown
```yaml
scope: local-default
stability: verify-current
conflict: preserve-local
```

| Класс задачи | Модель | Reasoning |
|---|---|---|
| S | GPT-6 Luna | low/medium |
| M | GPT-6 Sol | medium |
| L | GPT-6 Sol high или GPT-6 Astra medium | high/medium |
| C | GPT-6 Astra или GPT-6 Sol с отдельной проверкой | high |

Перед применением проверь актуальную документацию, доступность модели и
поддерживаемые уровни reasoning на конкретной установке.
````

Under `## Недельные пороги`, add a `shared/heuristic/ask` metadata block and include the 0–50, 50–70, 70–85, and >85 percent table verbatim from the spec. Under `## Инструкция для ChatGPT`, include the exact five-line instruction from spec section 4.4.

- [ ] **Step 3: Add only official sources**

The `## Источники` section must contain:

```markdown
- [Customization](https://learn.chatgpt.com/docs/customization/overview)
- [Subagents](https://learn.chatgpt.com/docs/agent-configuration/subagents)
- [Configuration Reference](https://learn.chatgpt.com/docs/config-file/config-reference)
- [Model selection](https://developers.openai.com/api/docs/guides/model-selection)
- [Pricing and usage](https://learn.chatgpt.com/docs/pricing)
```

- [ ] **Step 4: Run the policy contract**

Run:

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\tests\UsageOptimizationPolicy.Tests.ps1
```

Expected: `PASS usage optimization policy contract`.

- [ ] **Step 5: Inspect the active-core size and concrete-model exclusion**

Run:

```powershell
$core = Get-Content -Raw -LiteralPath .\AGENTS_CORE.md
[pscustomobject]@{
    Bytes = [Text.Encoding]::UTF8.GetByteCount($core)
    ConcreteModelIds = ([regex]::Matches($core, '(?i)gpt-[0-9]')).Count
}
```

Expected: `Bytes` below 12000 and `ConcreteModelIds` equal to `0`.

- [ ] **Step 6: Commit the policy files**

```powershell
git add -- AGENTS_CORE.md memory/USAGE_OPTIMIZATION.md
git -c user.name="Pavel Tsapyuk" -c user.email="pawlick@pawlick.ru" commit -m "feat: add shared usage optimization policy"
```

### Task 3: Add the canonical TOML profile and safe sync contract

**Files:**
- Create: `config/USAGE_PROFILE.toml`
- Modify: `SYNC.md`
- Modify: `tests/UsageOptimizationPolicy.Tests.ps1`

**Interfaces:**
- Consumes: model and agent defaults from the approved spec.
- Produces: a six-key profile and documented allowlist integration with independent approval.

- [ ] **Step 1: Extend the test before creating the profile**

Insert before the final `Write-Output` in `tests/UsageOptimizationPolicy.Tests.ps1`:

```powershell
$profilePath = Join-Path $RepoRoot 'config\USAGE_PROFILE.toml'
$syncPath = Join-Path $RepoRoot 'SYNC.md'
Assert-True (Test-Path -LiteralPath $profilePath -PathType Leaf) 'Missing config/USAGE_PROFILE.toml.'

$profile = Get-Content -Raw -LiteralPath $profilePath
$sync = Get-Content -Raw -LiteralPath $syncPath
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
Assert-True ($sync.Contains('## Синхронизация профиля использования')) 'SYNC is missing usage-profile integration.'
Assert-True ($sync.Contains('независимое подтверждение')) 'AGENTS and config must have independent approvals.'
Assert-True ($sync.Contains('не заменять `config.toml` целиком')) 'SYNC must forbid whole-file config replacement.'
Assert-True ($sync.Contains('SHA-256')) 'SYNC must detect local changes after the diff.'
Assert-True ($sync.Contains('модель или ключ не поддерживается')) 'SYNC must stop on incompatible values.'
Assert-StrictUtf8NoBom -Path $profilePath -Description 'Usage profile'
```

- [ ] **Step 2: Run the test and verify failure**

Run:

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\tests\UsageOptimizationPolicy.Tests.ps1
```

Expected: FAIL with `Missing config/USAGE_PROFILE.toml.`

- [ ] **Step 3: Create the exact profile**

Create `config/USAGE_PROFILE.toml`:

```toml
model = "gpt-6-sol"
model_reasoning_effort = "medium"
service_tier = "default"

[agents]
max_concurrent_threads_per_session = 2
default_subagent_model = "gpt-6-luna"
default_subagent_reasoning_effort = "medium"
```

- [ ] **Step 4: Extend `SYNC.md` with a separate config phase**

Add `## Синхронизация профиля использования` after `## Регулярная синхронизация`. State these exact requirements:

```markdown
Интеграция managed-блока `AGENTS.md` и интеграция профиля использования
требуют независимое подтверждение. Не заменять `config.toml` целиком.

1. Проверить версию Codex и поддержку каждой модели и каждого ключа.
2. Если модель или ключ не поддерживается, ничего не записывать и запросить решение.
3. Сравнивать только шесть ключей из `config/USAGE_PROFILE.toml`.
4. Сохранить SHA-256 локального `config.toml` вместе с предлагаемым diff.
5. Перед записью пересчитать SHA-256; при изменении остановиться и построить diff заново.
6. Сохранить все остальные таблицы, ключи, комментарии и порядок локального файла.
7. Создать резервную копию, применить подтверждённые ключи и проверить загрузку.
8. При ошибке восстановить резервную копию и не обновлять state-файл.
```

Update the process diagram to include compatibility check, config diff, independent approval, integration, and verification. Extend the report section with old/new allowlisted values, preserved local sections, incompatible values, and verification results.

- [ ] **Step 5: Run the contract**

Run:

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\tests\UsageOptimizationPolicy.Tests.ps1
```

Expected: `PASS usage optimization policy contract`.

- [ ] **Step 6: Commit the profile and sync procedure**

```powershell
git add -- config/USAGE_PROFILE.toml SYNC.md tests/UsageOptimizationPolicy.Tests.ps1
git -c user.name="Pavel Tsapyuk" -c user.email="pawlick@pawlick.ru" commit -m "feat: add safe usage profile synchronization"
```

### Task 4: Publish the repository release metadata

**Files:**
- Modify: `README.md`
- Modify: `CHANGELOG.md`
- Modify: `VERSION`
- Modify: `tests/UsageOptimizationPolicy.Tests.ps1`

**Interfaces:**
- Consumes: completed policy and profile.
- Produces: discoverable version `2.3.0` documentation and release contract.

- [ ] **Step 1: Extend the release test first**

Insert before the final `Write-Output`:

```powershell
$readme = Get-Content -Raw -LiteralPath (Join-Path $RepoRoot 'README.md')
$version = Get-Content -Raw -LiteralPath (Join-Path $RepoRoot 'VERSION')
$changelog = Get-Content -Raw -LiteralPath (Join-Path $RepoRoot 'CHANGELOG.md')
Assert-True ($readme.Contains('memory/USAGE_OPTIMIZATION.md')) 'README must link the detailed policy.'
Assert-True ($readme.Contains('config/USAGE_PROFILE.toml')) 'README must link the usage profile.'
Assert-True ($version.Contains('Version: 2.3.0')) 'VERSION must be 2.3.0.'
Assert-True ($version.Contains('Date: 2026-09-24')) 'VERSION must use the release date.'
Assert-True ($changelog.Contains('## 2.3.0 — 2026-09-24')) 'CHANGELOG must describe release 2.3.0.'
foreach ($path in @(
    (Join-Path $RepoRoot 'README.md'),
    (Join-Path $RepoRoot 'CHANGELOG.md'),
    (Join-Path $RepoRoot 'VERSION'),
    (Join-Path $RepoRoot 'SYNC.md'),
    (Join-Path $RepoRoot 'tests\UsageOptimizationPolicy.Tests.ps1')
)) {
    Assert-StrictUtf8NoBom -Path $path -Description 'Release text'
}
```

- [ ] **Step 2: Run the test and verify the release failure**

Run the policy contract.

Expected: FAIL with `README must link the detailed policy.`

- [ ] **Step 3: Update `README.md`**

Add to `## Архитектура`:

```markdown
- `memory/USAGE_OPTIMIZATION.md` — подробная маршрутизация инструмента,
  модели, reasoning, скорости, субагентов и недельного бюджета.
- `config/USAGE_PROFILE.toml` — канонический рекомендуемый профиль общих
  ключей; применяется только через отдельный diff и approval по `SYNC.md`.
```

Add to `## Что одинаково на всех установках` the silent preflight and minimal sufficient resource rule. Add to `## Что остаётся локальным` that unsupported models and pre-existing local overrides are preserved until the user resolves them.

- [ ] **Step 4: Prepend release `2.3.0` to `CHANGELOG.md`**

Use:

```markdown
## 2.3.0 — 2026-09-24

### Что изменилось

- В общее ядро добавлен молчаливый resource preflight перед каждой задачей.
- Добавлена подробная политика маршрутизации ChatGPT, Codex,
  детерминированных инструментов, моделей, reasoning, скорости и субагентов.
- Добавлен канонический экономичный профиль и безопасная процедура его
  отдельной интеграции без замены локального `config.toml`.

### Почему

Статистика трёх установок показала перерасход общего недельного лимита из-за
массовых субагентов, повышенного reasoning, длинных итераций и тяжёлого
инструментального контекста.

### Ожидаемое изменение поведения

Codex молча выбирает минимально достаточный режим, предупреждает только о
существенном перерасходе, ограничивает субагентов и сохраняет локальные
настройки при синхронизации.
```

- [ ] **Step 5: Raise `VERSION`**

Set:

```text
Codex Best Practice
Version: 2.3.0
Date: 2026-09-24
Scope: managed shared memory for multiple Codex installations
```

- [ ] **Step 6: Run both repository contracts**

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\tests\UsageOptimizationPolicy.Tests.ps1
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\tests\CodexMeterPackage.Tests.ps1
```

Expected: both print `PASS` and exit `0`.

- [ ] **Step 7: Commit the release metadata**

```powershell
git add -- README.md CHANGELOG.md VERSION tests/UsageOptimizationPolicy.Tests.ps1
git -c user.name="Pavel Tsapyuk" -c user.email="pawlick@pawlick.ru" commit -m "docs: release usage optimization policy 2.3.0"
```

### Task 5: Verify the repository and present the implementation diff

**Files:**
- Verify: all files changed since design commit `6f38dfd`

**Interfaces:**
- Consumes: Tasks 1–4.
- Produces: evidence-backed diff for the mandatory publication and local-integration approval gate.

- [ ] **Step 1: Run all PowerShell contracts**

```powershell
Get-ChildItem -LiteralPath .\tests -Filter '*.Tests.ps1' | ForEach-Object {
    powershell.exe -NoProfile -ExecutionPolicy Bypass -File $_.FullName
    if ($LASTEXITCODE -ne 0) { throw "Contract failed: $($_.Name)" }
}
```

Expected: every contract prints `PASS` and the command exits `0`.

- [ ] **Step 2: Run repository hygiene checks**

```powershell
git diff --check 6f38dfd..HEAD
git status --short
git diff --stat 6f38dfd..HEAD
git log --oneline 6f38dfd..HEAD
rg -n "(?i)(ghp_[A-Za-z0-9]{20,}|sk-[A-Za-z0-9]{20,}|Bearer\s+[A-Za-z0-9._-]{20,})" AGENTS_CORE.md memory config SYNC.md README.md CHANGELOG.md VERSION tests
```

Expected: no diff-check errors, clean status, only intended commits/files, and no credential matches.

- [ ] **Step 3: Compare spec coverage**

Confirm each spec section maps to the implementation:

```text
4.1 → AGENTS_CORE.md
4.2, 5, 6, 7 → memory/USAGE_OPTIMIZATION.md
4.3 → config/USAGE_PROFILE.toml
4.4 → memory/USAGE_OPTIMIZATION.md ChatGPT instruction
8 → SYNC.md
9–10 → README.md, CHANGELOG.md, VERSION, tests
```

Expected: no uncovered requirement.

- [ ] **Step 4: Present the full diff and stop for explicit approval**

Show the user:

```powershell
git diff --find-renames 6f38dfd..HEAD
```

Do not push and do not modify global `AGENTS.md` or `config.toml` yet. Obtain separate confirmation for:

1. publishing Best Practices;
2. integrating the managed AGENTS block on this machine;
3. integrating the six config keys on this machine.

### Task 6: Integrate and verify the current computer after approval

**Files:**
- Modify after approval: `C:\Users\user\.codex\AGENTS.md`
- Modify after separate approval: `C:\Users\user\.codex\config.toml`
- Modify after successful verification: `C:\Users\user\.codex\best-practice-state.json`
- Create: timestamped backups beside each modified local file

**Interfaces:**
- Consumes: `AGENTS_CORE.md`, `config/USAGE_PROFILE.toml`, current local files, and separate approvals.
- Produces: an active managed core and compatible allowlisted config values while preserving all local overrides.

- [ ] **Step 1: Test the four Review Focus failure modes with temporary fixtures**

Create a temporary directory with `New-Item -ItemType Directory` under `$env:TEMP`. Copy sanitized fixture content into it and verify:

```powershell
# Existing [agents]: merged result has exactly one [agents] table.
# Unsupported profile: compatibility result is STOP before write.
# Duplicate BEGIN marker: AGENTS result is STOP before write.
# Changed SHA-256: config result is STOP before write.
```

Use only temporary fixture files; do not test failure paths against live configuration. Remove the explicit temporary directory with `Remove-Item -LiteralPath $fixtureRoot -Recurse -Force` only after validating that its resolved path starts with `[IO.Path]::GetTempPath()`.

- [ ] **Step 2: Build and show the managed-block diff**

Read the current local `AGENTS.md`, replace only the text between the single managed markers with the corresponding block from `AGENTS_CORE.md`, and preserve `LOCAL OVERRIDES` byte-for-byte. Show the diff before writing.

Expected: only the managed block gains the optimization section.

- [ ] **Step 3: Back up and write the approved AGENTS integration**

Create `AGENTS.md.backup-YYYYMMDD-HHMMSS`, write strict UTF-8 without BOM, then verify one BEGIN marker, one END marker, and an unchanged local-overrides SHA-256.

- [ ] **Step 4: Perform config compatibility and diff checks**

Verify the installed Codex version and available model identifiers. Parse only:

```text
model
model_reasoning_effort
service_tier
agents.max_concurrent_threads_per_session
agents.default_subagent_model
agents.default_subagent_reasoning_effort
```

Record SHA-256 of live `config.toml`, construct the minimal proposed diff, and show it. Preserve every other key, table, comment, and order.

- [ ] **Step 5: Back up and write config after its separate approval**

Recalculate the live SHA-256 and stop if it differs. Create `config.toml.backup-YYYYMMDD-HHMMSS`, apply only approved keys, and verify there is exactly one `[agents]` table and all unrelated section hashes remain unchanged.

- [ ] **Step 6: Smoke-test the local installation**

Start a fresh local task and verify reported model, medium reasoning, default service tier, and maximum two subagents. Do not spawn two agents merely for the test; inspect resolved configuration where possible and use one minimal bounded test only if runtime validation requires it.

- [ ] **Step 7: Update local state only after success**

Set `installed_version` to `2.3.0`, `installed_commit` to the verified release commit, `synced_at` to the current UTC timestamp, and preserve `local_profile` exactly.

### Task 7: Publish and roll out to the other two computers

**Files:**
- Publish after approval: Best Practices `main`
- Modify on each remote computer through its own reviewed sync: global `AGENTS.md`, `config.toml`, and `best-practice-state.json`

**Interfaces:**
- Consumes: verified local release commit and the `SYNC.md` procedure.
- Produces: functionally identical policy and compatible profile on HP, PC, and Redmi.

- [ ] **Step 1: Push only the approved release commits**

```powershell
git status --short
git log --oneline origin/main..main
git push origin main
```

Expected: clean status and successful fast-forward publication.

- [ ] **Step 2: Send the canonical sync request to each other computer**

Use this message in the `computers` room:

```text
Обнови локальную копию https://github.com/pavel-tsapyuk/best-practice до
версии 2.3.0 по SYNC.md. Сначала fetch и diff от installed_commit, ничего
не меняй до показа плана. Отдельно покажи diff managed-блока AGENTS.md и
diff шести ключей USAGE_PROFILE.toml. Проверь совместимость версии Codex и
моделей. Сохрани LOCAL OVERRIDES, MCP, plugins, permissions, paths, projects
и остальные локальные настройки. AGENTS и config применяй только после
отдельных подтверждений. После интеграции проверь результат и пришли отчёт.
```

- [ ] **Step 3: Review both remote reports**

For each machine confirm:

```text
installed version and commit
Codex version
resolved main model/reasoning/service tier
resolved subagent model/reasoning/thread cap
preserved local settings
backup paths
verification outcome
deferred incompatibilities
```

Expected: identical behavioral policy; config differences exist only when documented compatibility requires a preserved local value.

- [ ] **Step 4: Apply the ChatGPT account instruction once**

After confirming its account-wide scope, add the exact snippet from `memory/USAGE_OPTIMIZATION.md` to ChatGPT Custom Instructions or the selected ChatGPT Project. Do not duplicate it per computer if the account setting already propagates.

### Task 8: Measure the two-week result

**Files:**
- Create locally, not in Git: a small usage ledger chosen during rollout
- Do not store conversation content, credentials, or raw logs in Best Practices

**Interfaces:**
- Consumes: daily account usage and per-major-task classification.
- Produces: a two-week decision on whether the policy reaches the 80–85% target without quality loss.

- [ ] **Step 1: Record only minimal fields for major tasks**

Use this schema:

```text
date | machine | task class | tool | model | reasoning | speed |
subagents | repair rounds | verified outcome
```

- [ ] **Step 2: Review after the first full weekly window**

Compare the same elapsed point in the window with the 2026-09-24 baseline. Identify the five tasks with the most subagents, repair rounds, or expensive modes.

- [ ] **Step 3: Review after the second full weekly window**

Success criteria:

```text
weekly usage finishes at or below 85%
no planned reset credit is consumed
verified completion rate does not decline materially
routine tasks do not generate visible preflight commentary
no machine-specific settings are lost
```

- [ ] **Step 4: Adjust only from evidence**

If usage remains above 85%, propose one reviewed change at a time: reduce subagent cap from two to one, move more S tasks to Luna, lower routine reasoning, or move another deterministic automation out of LLM. Do not change all controls simultaneously because the effect would be impossible to attribute.
