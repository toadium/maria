# oauth/codex

OpenAI Codex (ChatGPT) OAuth 2.0 + PKCE 授权流程 — 凭证加载/保存/刷新与 ID Token 声明解析。

## Overview

- `Credentials`：Codex 凭证（idToken、accessToken、refreshToken、accountId）
- `PkceCodes`：PKCE 码对（code_verifier + code_challenge）
- `TokenResponse`：令牌端点响应
- `IdTokenClaims`：ID Token 解析后的声明（email、chatgptAccountId、chatgptPlanType）
- `start_oauth_flow()`：完整授权流程入口

## Usage

```mbt nocheck
///|
let creds = @codex.start_oauth_flow()
println("Account: \{creds.accountId}")
// 后续自动刷新
let refreshed = @codex.refresh_and_save_credentials()
```

## API Reference

```mbt nocheck
///|
pub(all) struct Credentials {
  idToken : String
  accessToken : String
  refreshToken : String
  accountId : String
} derive(ToJson, Debug, FromJson)

///|
pub struct PkceCodes {
  code_verifier : String
  code_challenge : String
}

///|
pub struct IdTokenClaims {
  email : String
  chatgptAccountId : String
  chatgptPlanType : String
}

///|
pub fn generate_pkce() -> PkceCodes
pub fn generate_state() -> String
pub fn build_authorize_url(pkce : PkceCodes, state : String, redirect_uri? : String) -> String
pub async fn exchange_code_for_tokens(code : String, pkce : PkceCodes, redirect_uri? : String) -> TokenResponse
pub fn extract_token_claims(id_token : String) -> IdTokenClaims raise

///|
pub async fn start_oauth_flow() -> Credentials
pub async fn credentials_exist() -> Bool
pub async fn load_credentials() -> Credentials
pub async fn save_credentials(creds : Credentials) -> Unit
pub async fn delete_credentials() -> Unit
pub async fn refresh_and_save_credentials() -> Credentials
```

## Integration

- 被 `@cmd/daemon` 用于 Codex 后端授权
- 凭证持久化到 `~/.moonagent/` 目录
- 使用 PKCE (S256) 增强授权安全性