$ErrorActionPreference = "Stop"

if (-not $IsWindows -and $PSVersionTable.PSEdition -eq "Core") {
    throw "This installer is for Windows. macOS users should run install.sh."
}

$CodexApiHome = if ($env:CODEX_API_HOME) { $env:CODEX_API_HOME } else { Join-Path $HOME ".codex-api" }
$BinDir = if ($env:CODEX_API_BIN_DIR) { $env:CODEX_API_BIN_DIR } else { Join-Path $HOME ".local\bin" }
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

$BaseUrl = Read-Required "API Base URL (must support the Responses API)"
$Model = Read-Required "Model ID"
$Reasoning = Read-Host "Reasoning effort [high]"
if ([string]::IsNullOrWhiteSpace($Reasoning)) { $Reasoning = "high" }
if ($Reasoning -notin @("minimal", "low", "medium", "high", "xhigh")) {
    throw "Reasoning effort must be minimal, low, medium, high, or xhigh."
}
$SecureKey = Read-Host "API Key (encrypted for your Windows account)" -AsSecureString
$keyCheck = [pscredential]::new("codex-api", $SecureKey).GetNetworkCredential().Password
if ([string]::IsNullOrEmpty($keyCheck)) { throw "API Key cannot be empty." }
$keyCheck = $null

if (Test-Path $CodexApiHome) {
    $stamp = Get-Date -Format "yyyyMMdd-HHmmss"
    $backup = Join-Path $HOME ".codex-api-backup\$stamp"
    New-Item -ItemType Directory -Force -Path (Split-Path $backup) | Out-Null
    Copy-Item -Recurse -Force $CodexApiHome $backup
    Write-Host "Existing API-mode configuration backed up to $backup"
}

New-Item -ItemType Directory -Force -Path $CodexApiHome, $BinDir | Out-Null

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
env_key = "CODEX_API_KEY"
wire_api = "responses"
requires_openai_auth = false

[sandbox_workspace_write]
network_access = true

[windows]
sandbox = "elevated"
"@

Write-Utf8NoBom (Join-Path $CodexApiHome "config.toml") $config
Copy-Item -Force (Join-Path $ScriptDir "AGENTS.md") (Join-Path $CodexApiHome "AGENTS.md")
$SecureKey | ConvertFrom-SecureString | Set-Content -Encoding ascii (Join-Path $CodexApiHome "api-key.dpapi")

$launcher = @'
$ErrorActionPreference = "Stop"
$env:CODEX_HOME = if ($env:CODEX_API_HOME) { $env:CODEX_API_HOME } else { Join-Path $HOME ".codex-api" }
$encrypted = Get-Content -Raw (Join-Path $env:CODEX_HOME "api-key.dpapi")
$secure = ConvertTo-SecureString $encrypted
$credential = [pscredential]::new("codex-api", $secure)
$env:CODEX_API_KEY = $credential.GetNetworkCredential().Password
& codex @args
exit $LASTEXITCODE
'@
Write-Utf8NoBom (Join-Path $BinDir "codex-api.ps1") $launcher
Set-Content -Encoding ascii -Path (Join-Path $BinDir "codex-api.cmd") -Value '@powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0codex-api.ps1" %*'

$userPath = [Environment]::GetEnvironmentVariable("Path", "User")
$pathEntries = @($userPath -split ';' | Where-Object { $_ })
if ($BinDir -notin $pathEntries) {
    $newPath = (@($pathEntries) + $BinDir) -join ';'
    [Environment]::SetEnvironmentVariable("Path", $newPath, "User")
    $env:Path = "$BinDir;$env:Path"
}

$oldHome = $env:CODEX_HOME
try {
    $env:CODEX_HOME = $CodexApiHome
    codex features list | Out-Null
} finally {
    $env:CODEX_HOME = $oldHome
}

Write-Host "`nSetup complete."
Write-Host "Account mode: codex"
Write-Host "API mode:     codex-api"
