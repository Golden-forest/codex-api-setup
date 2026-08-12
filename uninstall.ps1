$ErrorActionPreference = "Stop"

$CodexApiHome = if ($env:CODEX_API_HOME) { $env:CODEX_API_HOME } else { Join-Path $HOME ".codex-api" }
$BinDir = if ($env:CODEX_API_BIN_DIR) { $env:CODEX_API_BIN_DIR } else { Join-Path $HOME ".local\bin" }

if (Test-Path $CodexApiHome) {
    $stamp = Get-Date -Format "yyyyMMdd-HHmmss"
    $backup = Join-Path $HOME ".codex-api-backup\uninstall-$stamp"
    New-Item -ItemType Directory -Force -Path (Split-Path $backup) | Out-Null
    Move-Item $CodexApiHome $backup
    Write-Host "API-mode files moved to $backup"
}

Remove-Item -Force -ErrorAction SilentlyContinue (Join-Path $BinDir "codex-api.ps1")
Remove-Item -Force -ErrorAction SilentlyContinue (Join-Path $BinDir "codex-api.cmd")
Write-Host "Removed codex-api mode. The official Codex CLI and ~/.codex were not changed."

