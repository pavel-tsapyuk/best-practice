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
