# Project Applications

```yaml
scope: project
stability: project-specific
conflict: ask
```

Эти рекомендации применяются только после проверки контекста конкретного проекта и не переносятся в глобальное ядро автоматически.

## Bitrix24 / пресейл

- Ищем узкую рутинную операцию с измеримым ROI, а не продаём клиенту слово «агент».
- Основной кандидат для self-hosted интеграций: n8n.
- Trigger.dev использовать для долгих программных процессов.
- Composio — когда полезен готовый слой множества внешних интеграций.
- Activepieces — сравнивать с n8n по конкретной задаче.
- Перспективный pipeline: встреча → требования → состав работ → риски → оценка → КП/ТЗ → human approval.

## АРМ РП B24

- Архитектура должна оставаться максимально детерминированной.
- Не использовать LLM для обычных фильтров, сортировок, прав, сроков, CRUD и API-вызовов Bitrix24.
- Агентность добавлять только для действительно неоднозначных действий.
- PocketBase/Supabase — кандидаты на backend при необходимости собственного слоя данных.
- Coolify — кандидат для self-hosted deployment.
- PostHog — при необходимости анализировать использование интерфейса.
- Metabase — для внутренних аналитических отчётов.

## Codex

Перед работой:
1. **Using superpowers — обязательно.**
2. Прочитать проектный и общий `AGENTS.md`.
3. Сформулировать criteria of done.
4. Определить границы файлов/компонентов.
5. Определить разрешённые и запрещённые изменения.
6. Найти существующие тесты.
7. Выполнить задачу.
8. Проверить результат тестами/сборкой/ручным сценарием.
9. Сообщить непроверенные допущения и риски.

### CodexMeter

CodexMeter — приватный Windows-виджет для постоянного отображения остатка недельного лимита Codex и даты следующего сброса.

Совместимость и подготовка:

- Windows 10 Pro 22H2 x64, build 19045.6456, физически проверена 2026-08-23.
- Windows 11 x64 поддерживается контрактом платформы и архитектуры.
- Нужны .NET Framework 4.8.1 и установленное приложение OpenAI Codex с выполненным входом в учётную запись.

Best Practice включает проверенный CodexMeter 1.1.0 в [`packages/CodexMeter`](../packages/CodexMeter/INSTALL.md). На другом компьютере нужен доступ только к приватному репозиторию Best Practice; отдельный клон CodexMeter не требуется.

Первая установка или обновление:

```powershell
git pull --ff-only
Set-Location .\packages\CodexMeter
$expected = (Get-Content -Raw .\CodexMeter-Setup.exe.sha256).Trim()
$actual = (Get-FileHash -Algorithm SHA256 .\CodexMeter-Setup.exe).Hash
if ($actual -cne $expected) { throw "SHA-256 mismatch: $actual" }
& .\CodexMeter-Setup.exe
```

Безопасная проверка без установки: `& .\CodexMeter-Setup.exe /quiet /whatif`. Полная инструкция, включая предупреждение SmartScreen: [`packages/CodexMeter/INSTALL.md`](../packages/CodexMeter/INSTALL.md).

Удаление установленного виджета:

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "$env:LOCALAPPDATA\CodexMeter\Uninstall-CodexMeter.ps1"
```

Bootstrapper не содержит учётную запись владельца, токены, логи или `codex.exe`. На каждом компьютере он находит локальную официальную установку Codex и использует учётную запись вошедшего пользователя.

Лимит читается локально через `codex app-server --stdio` и `account/rateLimits/read`, без парсинга страницы usage. Логи (`%LOCALAPPDATA%\CodexMeter\CodexMeter.log`), живые ответы, снимки, учётные данные, токены и другие секреты остаются только локально и не добавляются в Best Practice.

## Клиентские документы

Стандартный кандидат:
vision + fuzzy matching + структурированный эталон + строгая программная проверка.

## Вебинары и записи

- Whisper — основной кандидат для транскрибации.
- Meetily — если нужен полный meeting workflow.

## База знаний / RAG

Смотреть по задаче:
- NotebookLM — исследование набора источников;
- Dify — прикладное RAG/AI приложение;
- AppFlowy — self-hosted knowledge workspace;
- Flowise/LangFlow — визуальный pipeline.

## pawlick.ru

- Plausible — предпочтительный простой кандидат на веб-аналитику.
- Coolify — возможный self-hosted deploy.
- PostHog — только если появятся реальные продуктовые сценарии, требующие более глубокой аналитики.
- yt-dlp — только при правомерном использовании.

## Общая инфраструктура

- Infisical — secrets management.
- PocketBase — малые приложения.
- Supabase — более серьёзный backend.
- Coolify — deploy.
- PostHog/Metabase — продуктовая и бизнес-аналитика.

## Self-hosted

Self-hosted — средство, не цель.
Не заменять работающий SaaS только ради собственного сервера.
Всегда считать TCO.
