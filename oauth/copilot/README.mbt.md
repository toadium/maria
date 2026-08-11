# oauth/copilot

GitHub Copilot 设备授权流程 (Device Flow) — 设备码请求、轮询令牌、Copilot 令牌交换与凭证持久化。

## Overview

- `Credentials`：Copilot 凭证（github_token、copilot_token、copilot_token_expires_at）
- `DeviceCodeResponse`：设备码响应（device_code、user_code、verification_uri、expires_in、interval）
- `CopilotTokenResponse`：Copilot 令牌响应（token、expires_at）
- `start_oauth_flow()`：完整设备授权流程入口

## Usage

```mbt nocheck
///|
let creds = @copilot.start_oauth_flow()
println("GitHub token: \{creds.github_token}")
if creds.is_token_valid(@async.now().to_int64()) {
  // token still valid
}
let refreshed = @copilot.refresh_and_save_credentials()
```

## API Reference

```mbt nocheck
///|
pub(all) struct Credentials {
  github_token : String
  copilot_token : String
  copilot_token_expires_at : Int64
} derive(ToJson, Debug, FromJson)

///|
pub fn Credentials::is_token_valid(self : Credentials, now : Int64) -> Bool

///|
pub struct DeviceCodeResponse {
  device_code : String
  user_code : String
  verification_uri : String
  expires_in : Int
  interval : Int
}

///|
pub struct CopilotTokenResponse {
  token : String
  expires_at : Int64
}

///|
pub async fn start_oauth_flow() -> Credentials
pub async fn request_device_code() -> DeviceCodeResponse
pub async fn poll_for_access_token(device_code : String, interval : Int, expires_in : Int) -> String
pub async fn get_copilot_token(github_token : String) -> CopilotTokenResponse
pub async fn credentials_exist() -> Bool
pub async fn load_credentials() -> Credentials
pub async fn save_credentials(creds : Credentials) -> Unit
pub async fn delete_credentials() -> Unit
pub async fn refresh_and_save_credentials() -> Credentials
pub async fn get_valid_credentials() -> Credentials
```

## Integration

- 被 `@cmd/daemon` 用于 Copilot 授权
- 设备流程：用户在浏览器输入 user_code 完成授权
- 凭证持久化到 `~/.moonagent/` 目录