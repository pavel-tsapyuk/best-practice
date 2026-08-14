# Tool Radar

Это радар кандидатов, а не список обязательных зависимостей.

```yaml
scope: shared
stability: verify-current
conflict: ask
```

Перед выбором проверь актуальные возможности, поддержку, лицензию, тарифы, безопасность и совокупную стоимость. Наличие инструмента в этом файле само по себе не является рекомендацией к внедрению.

## Codex / разработка / agent engineering

- **Infisical** — secrets/API keys/access management.
- **shadcn/improve** — двухступенчатый подход: сильная модель планирует изменения, более дешёвая исполняет.
- **OpenHands** — open-source coding agent.
- **Continue** — open-source coding agent для IDE/терминала/CI.
- **Langfuse** — трассировка промптов, ответов, расходов, ошибок и агентных цепочек.
- **Anthropic Agent Skills** — официальные примеры skills.
- **Awesome Agent Skills** — каталог skills для Claude Code, Codex, Cursor, Copilot.
- **Awesome MCP Servers** — каталог MCP-серверов.
- **Official MCP Servers** — эталонные реализации MCP.
- **Awesome Copilot** — агенты, skills, инструкции, hooks и сценарии.
- **DESIGN.md** — потенциальный формат связи дизайн-решений и кода.
- **Obsidian + agent** — возможный внешний слой проектной памяти/dashboard.
- **Hermes Agent** — источник архитектур и каталога практических агентных кейсов.
- **OpenClaw** — агентная платформа; использовать только при обоснованной необходимости автономности.

## Автоматизация и интеграции

- **n8n** — основной кандидат для self-hosted business automation и Bitrix24-интеграций.
- **Activepieces** — альтернатива n8n/Zapier/Make.
- **Trigger.dev** — фоновые и долгие задачи/workflows/agents.
- **Composio** — интеграционный слой агентов с Gmail, Slack, GitHub, Notion, календарями и др.
- **Apify** — web automation, scraping, actors.
- **Orkes / VoltAgent** — более серьёзная серверная оркестрация и наблюдаемость.

## Backend / deploy / data

- **PocketBase** — компактный backend-in-a-file для небольших приложений.
- **Supabase** — DB/auth/storage/API/vector search.
- **Coolify** — self-hosted deploy на VPS.
- **NocoDB** — визуальный интерфейс поверх SQL.
- **Baserow** — no-code database/internal tools.

## RAG / модели / AI приложения

- **Dify** — конструктор AI-apps/agents/RAG.
- **Flowise / LangFlow** — визуальные RAG/LLM pipelines.
- **aiXplain** — оркестрация/переключение моделей.
- **Ollama / Ollama Cloud** — локальные/облачные открытые модели.
- **OpenRouter** — маршрутизация между моделями; следить за фактической ценой.
- **Perplexica** — self-hosted AI search.
- **NotebookLM** — работа с большими наборами источников и документов.
- **AppFlowy** — self-hosted workspace/knowledge base.

## Аналитика

- **PostHog** — product analytics, session replay, feature flags, A/B tests.
- **Metabase** — BI/dashboard поверх БД.
- **Plausible Analytics** — privacy-friendly web analytics.

## Аудио / видео / контент

- **Whisper** — локальная транскрибация.
- **Meetily** — запись/транскрибация/саммари встреч.
- **Chatterbox TTS** — TTS/voice cloning.
- **Presenton** — генерация презентаций.
- **MoneyPrinterTurbo** — автоматизированная сборка видео.
- **OpenShorts** — нарезка длинных видео/UGC.
- **ViMax** — многосценовая AI-генерация видео.
- **Open SEO** — SEO-контент + WordPress.
- **yt-dlp** — видео/аудио/субтитры там, где использование правомерно.

## Бизнес / внутренние системы

- **Twenty** — open-source CRM.
- **Chatwoot** — омниканальная поддержка.
- **Plane** — project management.
- **Listmonk** — self-hosted email campaigns.
- **Zulip** — self-hosted threaded team chat.
- **Immich** — self-hosted photo/video library.

## Каталоги

- **free-for-dev** — каталог бесплатных dev-сервисов.
- **Agent-Reach** — доступ агентов к внешним площадкам/источникам.

## Правило выбора

Не выбирать инструмент из этого файла автоматически. Сравнивать:
- fit к задаче;
- стоимость эксплуатации;
- зрелость;
- безопасность;
- сложность поддержки;
- необходимость self-hosting;
- наличие более простого решения.
