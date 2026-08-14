# Best Practice v2 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Перестроить `best-practice` v1 в версионируемую v2-базу с коротким общим ядром, релевантно читаемой памятью и безопасной синхронизацией нескольких установок Codex.

**Architecture:** Репозиторий разделяется на инструкции сопровождения, каноническое общее ядро и справочные материалы. Синхронизация обновляет только размеченный управляемый блок локального `~/.codex/AGENTS.md`, сохраняет локальные переопределения и останавливается при неоднозначном конфликте.

**Tech Stack:** Markdown, YAML metadata blocks, JSON state example, Git, PowerShell validation.

## Global Constraints

- Неоднозначный конфликт сохраняет локальное значение и требует решения пользователя.
- Новое содержимое репозитория не активируется автоматически.
- Проектные правила не переносятся в глобальное ядро.
- Локальные уведомления, пути, плагины, разрешения и особенности машины не унифицируются принудительно.
- Изменчивые сведения проверяются перед применением.
- Репозиторий и state-файл не содержат секретов.
- Версия результата: `2.0.0`.

---

### Task 1: Активное ядро и правила сопровождения

**Files:**
- Create: `AGENTS_CORE.md`
- Modify: `AGENTS.md`

**Interfaces:**
- Consumes: согласованную матрицу уровней и конфликтов из спецификации.
- Produces: каноническое ядро для управляемого блока `~/.codex/AGENTS.md` и правила редактирования репозитория.

- [ ] **Step 1: Переписать `AGENTS.md`**

Оставить только правила сопровождения: разделение ядра и справочника, обязательная классификация, проверка источников, changelog, запрет секретов и запрет автоматической активации.

- [ ] **Step 2: Создать `AGENTS_CORE.md`**

Включить маркеры `BEGIN/END BEST-PRACTICE MANAGED CORE` и короткие универсальные правила: skills, criteria of done, границы, минимальная сложность, релевантное чтение памяти, проверка изменчивых сведений и результата.

- [ ] **Step 3: Проверить размер и отсутствие дублирования**

Run: `rg -n "^## " AGENTS.md AGENTS_CORE.md; (Get-Content AGENTS_CORE.md | Measure-Object -Line)`

Expected: роли файлов различимы; ядро занимает не более 100 строк.

- [ ] **Step 4: Commit**

Run: `git add AGENTS.md AGENTS_CORE.md && git commit -m "Split shared core from repository rules"`

### Task 2: Валидность и синхронизация

**Files:**
- Create: `memory/VALIDITY.md`
- Create: `SYNC.md`

**Interfaces:**
- Consumes: метки `scope`, `stability`, `conflict` и маркеры управляемого/локального блоков.
- Produces: единый словарь меток и повторяемый workflow `fetch → diff → classify → review → integration → report`.

- [ ] **Step 1: Создать `memory/VALIDITY.md`**

Описать допустимые значения, семантику комбинаций и безопасное поведение при отсутствующих или конфликтующих метках.

- [ ] **Step 2: Создать `SYNC.md`**

Описать первичную установку, регулярную синхронизацию, формат `best-practice-state.json`, резервную копию, проверку маркеров, отчёт и восстановление после ошибки.

- [ ] **Step 3: Проверить полноту словаря**

Run: `rg -n "shared|local-default|project|stable|verify-current|project-specific|heuristic|enforce-shared|preserve-local|ask" memory/VALIDITY.md SYNC.md`

Expected: все допустимые значения определены, а `SYNC.md` ссылается на политику конфликтов.

- [ ] **Step 4: Commit**

Run: `git add memory/VALIDITY.md SYNC.md && git commit -m "Document validity and synchronization policy"`

### Task 3: Классификация существующей памяти

**Files:**
- Modify: `memory/SUPERPOWERS.md`
- Modify: `memory/PRINCIPLES.md`
- Modify: `memory/TOOLS.md`
- Modify: `memory/PATTERNS.md`
- Modify: `memory/PROJECT_APPLICATIONS.md`

**Interfaces:**
- Consumes: словарь из `memory/VALIDITY.md`.
- Produces: справочные разделы с явной областью действия, стабильностью и политикой конфликтов.

- [ ] **Step 1: Разметить стабильные общие принципы**

Добавить компактные metadata-блоки к логически однородным разделам `SUPERPOWERS.md`, `PRINCIPLES.md` и `PATTERNS.md`.

- [ ] **Step 2: Разметить инструменты как изменчивые**

Пометить разделы `TOOLS.md` как `verify-current`, `heuristic` и `ask`; явно запретить выбор инструмента только по наличию в радаре.

- [ ] **Step 3: Разметить проектные применения**

Пометить разделы `PROJECT_APPLICATIONS.md` как `project`, `project-specific` и `ask`.

- [ ] **Step 4: Проверить покрытие верхнеуровневых разделов**

Run: `rg -n "^scope:|^stability:|^conflict:" memory/*.md`

Expected: все пять существующих файлов имеют применимые metadata-блоки; значения входят в словарь.

- [ ] **Step 5: Commit**

Run: `git add memory/*.md && git commit -m "Classify shared memory validity"`

### Task 4: Документация выпуска v2

**Files:**
- Create: `CHANGELOG.md`
- Modify: `README.md`
- Modify: `VERSION`

**Interfaces:**
- Consumes: итоговую структуру и процесс синхронизации.
- Produces: понятную инструкцию эксплуатации, журнал существенных изменений и машиночитаемую версию.

- [ ] **Step 1: Создать `CHANGELOG.md`**

Записать выпуск `2.0.0`, причины архитектурного изменения, ожидаемое изменение поведения и инструкцию миграции с v1.

- [ ] **Step 2: Переписать `README.md`**

Объяснить роли файлов, модель одной машины-редактора и нескольких синхронизируемых установок, релевантное чтение `memory/` и безопасную команду синхронизации.

- [ ] **Step 3: Обновить `VERSION`**

Установить `Version: 2.0.0`, дату `2026-08-14` и область применения управляемой общей памяти.

- [ ] **Step 4: Проверить ссылки и версию**

Run: `rg -n "AGENTS_CORE.md|CHANGELOG.md|SYNC.md|VALIDITY.md|2.0.0" README.md CHANGELOG.md VERSION`

Expected: все новые файлы и версия упомянуты.

- [ ] **Step 5: Commit**

Run: `git add README.md CHANGELOG.md VERSION && git commit -m "Release shared memory v2 documentation"`

### Task 5: Репозиторная валидация и публикация

**Files:**
- Verify: все Markdown-файлы и `VERSION`

**Interfaces:**
- Consumes: результат Tasks 1–4.
- Produces: проверенный commit v2 в `origin/main`.

- [ ] **Step 1: Проверить структуру и UTF-8**

Run: PowerShell-проверка обязательных файлов, строгого UTF-8 и отсутствия пустых документов.

Expected: все обязательные файлы существуют и декодируются без ошибок.

- [ ] **Step 2: Проверить metadata и маркеры**

Run: PowerShell-проверка допустимых значений `scope`, `stability`, `conflict`, ровно одной пары managed-маркеров и отсутствия managed-маркеров в локальном блоке.

Expected: нарушений нет.

- [ ] **Step 3: Проверить документацию и секреты**

Run: `git diff --check` и `rg` по шаблонам присваивания секретов.

Expected: whitespace-ошибок и явных секретов нет.

- [ ] **Step 4: Сверить реализацию со спецификацией**

Run: ручная таблица покрытия десяти критериев готовности из design spec.

Expected: каждый критерий подтверждён конкретным файлом или проверкой.

- [ ] **Step 5: Опубликовать**

Run: `git push origin main`, затем сравнить `git rev-parse HEAD` с `git ls-remote origin refs/heads/main`.

Expected: локальный и удалённый SHA совпадают.
