# CodexMeter 1.1.0

Этот каталог содержит актуальный неподписанный установщик CodexMeter для компьютеров владельца. Он не содержит чужую учётную запись, токены, логи или `codex.exe`; приложение использует локальную установку Codex и вошедшего на этом компьютере пользователя.

## Получение и проверка

Открой PowerShell в корне существующего клона Best Practice:

```powershell
git pull --ff-only
Set-Location .\packages\CodexMeter
$expected = (Get-Content -Raw .\CodexMeter-Setup.exe.sha256).Trim()
$actual = (Get-FileHash -Algorithm SHA256 .\CodexMeter-Setup.exe).Hash
if ($actual -cne $expected) { throw "SHA-256 mismatch: $actual" }
```

## Проверка без установки

```powershell
& .\CodexMeter-Setup.exe /quiet /whatif
if ($LASTEXITCODE -ne 0) { throw "CodexMeter preflight failed: $LASTEXITCODE" }
```

## Установка или обновление

```powershell
& .\CodexMeter-Setup.exe
```

Установщик работает без UAC и применяет тот же безопасный сценарий как для первой установки, так и для обновления. Поскольку цифровой подписи пока нет, Windows SmartScreen может показать `Unknown publisher`; сначала сверь SHA-256, затем используй стандартное действие **More info → Run anyway**.
