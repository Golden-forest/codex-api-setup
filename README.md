# Codex API Mode Setup

在不影响现有 ChatGPT/Codex 登录的前提下，为 Codex CLI 增加一个独立的 API Key 模式。

- `codex`：继续使用原来的 ChatGPT/账号模式。
- `codex-api`：使用你填写的 Base URL、API Key 和模型。
- Codex CLI 始终通过 OpenAI 官方安装器安装，本仓库不分发二进制文件。
- API Key 只保存在本机：macOS 使用 Keychain；Windows 为优先保证兼容性，直接保存在本机配置文件中。
- API 模式使用独立的 `~/.codex-api`，不会覆盖 `~/.codex`。

> 自定义服务必须兼容 OpenAI Responses API。只支持 `/v1/chat/completions` 的服务无法直接用于当前 Codex custom provider。

## macOS

下载或克隆本仓库，然后在 Terminal 中运行：

```sh
chmod +x install.sh
./install.sh
```

脚本检测不到 Codex 时，会调用 OpenAI 官方安装命令：

```sh
curl -fsSL https://chatgpt.com/codex/install.sh | sh
```

## Windows

下载或克隆本仓库，然后在 PowerShell 中运行：

```powershell
powershell -ExecutionPolicy Bypass -File .\install.ps1
```

脚本检测不到 Codex 时，会调用 OpenAI 官方安装命令：

```powershell
powershell -ExecutionPolicy Bypass -c "irm https://chatgpt.com/codex/install.ps1 | iex"
```

Windows 默认使用官方推荐的 `elevated` 原生沙箱。如果设备策略不允许初始化，可在 `%USERPROFILE%\.codex-api\config.toml` 中改为 `unelevated`。

## 安装时需要填写

向导会依次询问：

1. API Base URL。
2. 服务商提供的模型 ID。
3. Reasoning effort，默认 `high`。
4. API Key。

真实 Base URL、模型和 Key 都不会写入本仓库。macOS Key 存入系统 Keychain；Windows Key 以明文保存在 `%USERPROFILE%\.codex-api\config.toml`。请不要分享、上传或截图这个文件。

## 使用

```sh
# 原账号模式
codex

# 独立 API 模式
codex-api
```

Windows 启动器会直接安装到现有 `codex` 命令所在目录，因此安装完成后可直接运行 `codex-api`。若旧终端仍缓存了命令路径，关闭并重新打开终端再试。

如果仍提示找不到命令，可以在安装完成信息中找到 `Launcher:` 的完整路径，先直接运行该路径确认。例如：

```powershell
& "C:\完整路径\codex-api.cmd"
```

## 更新

重新运行对应平台的安装脚本即可更新配置。脚本会先备份已有 `.codex-api`。

Codex CLI 本体的更新仍使用 OpenAI 官方安装器；本仓库不锁定 Codex 版本。

## 卸载 API 模式

macOS：

```sh
chmod +x uninstall.sh
./uninstall.sh
```

Windows：

```powershell
powershell -ExecutionPolicy Bypass -File .\uninstall.ps1
```

卸载只移除 `codex-api` 启动器并备份 API 模式目录，不会卸载 Codex，也不会修改 `~/.codex`。

## 安全说明

- 不要把 `~/.codex-api`、`auth.json`、终端日志或凭据文件提交到 GitHub。Windows 的 `config.toml` 包含明文 API Key。
- 运行远程脚本前应先下载并检查内容。
- API Key 费用由对应 API 服务商计费，与 ChatGPT 套餐额度分开。
- 自定义 Base URL 会接收你的提示词、代码上下文和模型请求，请只使用可信服务。

## 官方资料

- [Codex CLI](https://learn.chatgpt.com/docs/codex/cli)
- [Authentication](https://learn.chatgpt.com/docs/auth)
- [Configuration reference](https://learn.chatgpt.com/docs/config-file/config-reference)
- [AGENTS.md](https://learn.chatgpt.com/docs/agent-configuration/agents-md)
