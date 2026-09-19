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
- **fx** — экспериментальный минимальный coding-agent harness на Zig; кандидат для исследований, sandbox/eval и встраивания, не готовая замена Codex ([source](https://github.com/vercel-labs/fx)).
- **OpenViking** — контекстная база, разделяющая resources, memories и skills и загружающая детали по необходимости; оценивать только через пилот на собственных сценариях памяти ([source](https://github.com/volcengine/OpenViking)).
- **Cloudflare Computer** — preview-среда выполнения и базовый набор файловых/командных инструментов для агентов; кандидат только для экспериментов и прототипов облачных изолированных задач ([source](https://github.com/cloudflare/computer)).
- **Semantica** — графовый слой происхождения данных и аудита решений; уместен главным образом там, где объяснимость и воспроизводимость решений являются требованиями ([source](https://github.com/semantica-agi/semantica)).
- **FreeToken** — экспериментальная система локального запуска MoE-моделей с распределением работы между CPU/GPU и повторным использованием состояния агента; аппаратную совместимость и заявленную скорость проверять отдельно ([paper](https://arxiv.org/abs/2608.16157)).
- **Godogen** — открытый пример автономного цикла разработки игр с запуском, снимками экрана и визуальным исправлением; использовать прежде всего как источник паттернов проверки ([source](https://github.com/htdt/godogen)).
- **Browser Use macOS Harness** — тонкая обвязка управления macOS и авторизованным браузером с возможностью дописывать Python-логику по ходу задачи; только для изолированного пилота с review разрешений и телеметрии ([source](https://github.com/browser-use/macos-harness)).
- **Apache Maka** — инкубационный local-first agent workspace с append-only журналом runtime events, единым Runtime Host, eval и восстановлением; использовать прежде всего как архитектурный референс, поскольку форматы и команды ещё меняются ([source](https://github.com/apache/maka)).
- **tgrep** — trigram-indexed поиск Microsoft для многократных запросов по очень большим репозиториям; обычным проектам достаточно `rg`, а целесообразность индекса и фонового сервера нужно подтвердить benchmark на своём monorepo ([source](https://github.com/microsoft/tgrep)).

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
- **NVIDIA Parakeet TDT** — кандидат для локальной потоковой транскрибации; аппаратную совместимость, качество русского языка и требования конкретной реализации проверять экспериментом.
- **Meetily** — запись/транскрибация/саммари встреч.
- **Chatterbox TTS** — TTS/voice cloning.
- **Presenton** — генерация презентаций.
- **MoneyPrinterTurbo** — автоматизированная сборка видео.
- **OpenShorts** — нарезка длинных видео/UGC.
- **ViMax** — многосценовая AI-генерация видео.
- **Open SEO** — SEO-контент + WordPress.
- **yt-dlp** — видео/аудио/субтитры там, где использование правомерно.

## UI / игры / визуальная разработка

- **ui-skills** — каталог design-engineering skills; выбирать отдельные релевантные правила, а не подключать весь каталог без оценки ([source](https://ui-skills.com/)).
- **screenshot-to-code** — стартовая реконструкция интерфейса по снимку; использовать только вместе с визуальным замкнутым циклом, проверкой доступности и ручным review ([source](https://github.com/abi/screenshot-to-code)).
- **Unity Agent Plugin** — официальный набор Unity skills для проектной работы со сценами, физикой, графикой, аудио и тестами; не активировать вне Unity-проектов ([source](https://github.com/Unity-Technologies/unity-agent-plugin)).

## Локальный inference и физические устройства

- **NVIDIA Personal AI Router** — beta-маршрутизация локального inference между совместимыми компьютерами; кандидат только при наличии подходящего оборудования и измеримого сценария ([source](https://www.nvidia.com/en-us/ai-on-rtx/personal-ai-router/)).
- **Model Hardware Standard** — research preview интерфейса управления лабораторным и промышленным оборудованием; до практического применения требуются аппаратные interlocks, аварийная остановка, строгие разрешения и независимая проверка ([source](https://www.anthropic.com/news/model-hardware-standard-research-preview)).

## Обучающие материалы

- **CMU 11-768 AI Agents** — открытый курс по agent harness, tools, context, skills, memory, evals, RL, sandboxing и безопасности ([source](https://www.cmu-agents.com/)).
- **Stanford CS329Z Engineering AI Agents** — курс по архитектуре, данным, оценке, guardrails, coding agents и proactive agents ([source](https://cs329z.stanford.edu/)).

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
