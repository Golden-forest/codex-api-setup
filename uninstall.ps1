$ErrorActionPreference = "Stop"

$CodexApiHome = if ($env:CODEX_API_HOME) { $env:CODEX_API_HOME } else { Join-Path $HOME ".codex-api" }
$CodexCommand = Get-Command codex -ErrorAction SilentlyContinue
$CodexPath = if ($CodexCommand) { $CodexCommand.Source } else { $null }
if ([string]::IsNullOrWhiteSpace($CodexPath) -and $CodexCommand) { $CodexPath = $CodexCommand.Path }
$BinDir = if ($env:CODEX_API_BIN_DIR) {
    $env:CODEX_API_BIN_DIR
} elseif (-not [string]::IsNullOrWhiteSpace($CodexPath)) {
    Split-Path -Parent $CodexPath
} else {
    Join-Path $HOME ".local\bin"
}

if (Test-Path $CodexApiHome) {
    $stamp = Get-Date -Format "yyyyMMdd-HHmmss"
    $backup = Join-Path $HOME ".codex-api-backup\uninstall-$stamp"
    New-Item -ItemType Directory -Force -Path (Split-Path $backup) | Out-Null
    Move-Item $CodexApiHome $backup
    Write-Host "API-mode files moved to $backup"
}

Remove-Item -Force -ErrorAction SilentlyContinue (Join-Path $BinDir "codex-api.ps1")
Remove-Item -Force -ErrorAction SilentlyContinue (Join-Path $BinDir "codex-api.cmd")
if (-not $env:CODEX_API_BIN_DIR) {
    $OldBinDir = Join-Path $HOME ".local\bin"
    if ($OldBinDir -ne $BinDir) {
        Remove-Item -Force -ErrorAction SilentlyContinue (Join-Path $OldBinDir "codex-api.ps1")
        Remove-Item -Force -ErrorAction SilentlyContinue (Join-Path $OldBinDir "codex-api.cmd")
    }
}
Write-Host "Removed codex-api mode. The official Codex CLI and ~/.codex were not changed."
