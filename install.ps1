$ErrorActionPreference = "Stop"

if (-not $IsWindows -and $PSVersionTable.PSEdition -eq "Core") {
    throw "This installer is for Windows. macOS users should run install.sh."
}

$CodexApiHome = if ($env:CODEX_API_HOME) { $env:CODEX_API_HOME } else { Join-Path $HOME ".codex-api" }
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path

function Read-Required([string]$Prompt) {
    do { $value = Read-Host $Prompt } while ([string]::IsNullOrWhiteSpace($value))
    return $value
}

if (-not (Get-Command codex -ErrorAction SilentlyContinue)) {
    Write-Host "Codex CLI is not installed. Installing it with the official OpenAI installer..."
    Invoke-RestMethod https://chatgpt.com/codex/install.ps1 | Invoke-Expression
    $env:Path = "$HOME\.local\bin;$env:Path"
}

if (-not (Get-Command codex -ErrorAction SilentlyContinue)) {
    throw "Codex was installed but is not visible in this terminal. Restart PowerShell and rerun this script."
}

codex --version
$CodexCommand = Get-Command codex -ErrorAction Stop
$CodexPath = $CodexCommand.Source
if ([string]::IsNullOrWhiteSpace($CodexPath)) { $CodexPath = $CodexCommand.Path }
if ([string]::IsNullOrWhiteSpace($CodexPath)) {
    throw "Could not determine where the codex command is installed."
}
$BinDir = if ($env:CODEX_API_BIN_DIR) { $env:CODEX_API_BIN_DIR } else { Split-Path -Parent $CodexPath }

$BaseUrl = Read-Required "API Base URL (must support the Responses API)"
$Model = Read-Required "Model ID"
$Reasoning = Read-Host "Reasoning effort [high]"
if ([string]::IsNullOrWhiteSpace($Reasoning)) { $Reasoning = "high" }
if ($Reasoning -notin @("minimal", "low", "medium", "high", "xhigh")) {
    throw "Reasoning effort must be minimal, low, medium, high, or xhigh."
}
Write-Warning "The API Key will be stored as plain text in $CodexApiHome\config.toml. Do not share or upload that file."
$ApiKey = Read-Required "API Key"
if ($ApiKey.Contains("`r") -or $ApiKey.Contains("`n")) { throw "API Key cannot contain a line break." }

if (Test-Path $CodexApiHome) {
    $stamp = Get-Date -Format "yyyyMMdd-HHmmss"
    $backup = Join-Path $HOME ".codex-api-backup\$stamp"
    New-Item -ItemType Directory -Force -Path (Split-Path $backup) | Out-Null
    Copy-Item -Recurse -Force $CodexApiHome $backup
    Write-Host "Existing API-mode configuration backed up to $backup"
}

New-Item -ItemType Directory -Force -Path $CodexApiHome | Out-Null

function Escape-Toml([string]$Value) {
    return $Value.Replace('\', '\\').Replace('"', '\"')
}

function Write-Utf8NoBom([string]$Path, [string]$Value) {
    $encoding = New-Object System.Text.UTF8Encoding($false)
    [System.IO.File]::WriteAllText($Path, $Value, $encoding)
}

$config = @"
model_provider = "custom"
model = "$(Escape-Toml $Model)"
model_reasoning_effort = "$Reasoning"
sandbox_mode = "workspace-write"
approval_policy = "on-request"

[model_providers.custom]
name = "Custom OpenAI-compatible provider"
base_url = "$(Escape-Toml $BaseUrl)"
experimental_bearer_token = "$(Escape-Toml $ApiKey)"
wire_api = "responses"
requires_openai_auth = false

[sandbox_workspace_write]
network_access = true

[windows]
sandbox = "elevated"
"@

Write-Utf8NoBom (Join-Path $CodexApiHome "config.toml") $config
Copy-Item -Force (Join-Path $ScriptDir "AGENTS.md") (Join-Path $CodexApiHome "AGENTS.md")
$ApiKey = $null

$launcher = @"
@echo off
setlocal
set "CODEX_HOME=$CodexApiHome"
call codex %*
exit /b %ERRORLEVEL%
"@
$LauncherPath = Join-Path $BinDir "codex-api.cmd"
Set-Content -Encoding ascii -Path $LauncherPath -Value $launcher

# Remove files created by versions that used the unreliable DPAPI/PowerShell launcher.
Remove-Item -Force -ErrorAction SilentlyContinue (Join-Path $CodexApiHome "api-key.dpapi")
Remove-Item -Force -ErrorAction SilentlyContinue (Join-Path $BinDir "codex-api.ps1")
if (-not $env:CODEX_API_BIN_DIR) {
    $OldBinDir = Join-Path $HOME ".local\bin"
    if ($OldBinDir -ne $BinDir) {
        Remove-Item -Force -ErrorAction SilentlyContinue (Join-Path $OldBinDir "codex-api.cmd")
        Remove-Item -Force -ErrorAction SilentlyContinue (Join-Path $OldBinDir "codex-api.ps1")
    }
}

$oldHome = $env:CODEX_HOME
try {
    $env:CODEX_HOME = $CodexApiHome
    codex features list | Out-Null
} finally {
    $env:CODEX_HOME = $oldHome
}

& $LauncherPath --version

Write-Host "`nSetup complete."
Write-Host "Account mode: codex"
Write-Host "API mode:     codex-api"
Write-Host "Launcher:     $LauncherPath"
