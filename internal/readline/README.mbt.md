# internal/readline

交互式终端行编辑与按键读取 — 支持提示符、行历史、补全、原始按键事件解析。

## Overview

- `Interface`：终端交互接口，封装输入/输出流
- `Key` / `KeyName`：按键事件解析（Escape/Enter/Backspace/Up/Down/Tab/F1-F12 等）
- `CompletionResult`：补全结果（completions + complete_on）
- `Aborted`：用户 Ctrl+C 中止子错误

## Usage

```mbt nocheck
///|
let iface = @readline.interface(input=@stdio.stdin, output=@stdio.stdout)
iface.set_prompt(b"> ")
iface.start()
let line = iface.read_line()
println("got: \{line}")
let key = iface.read_key()
match key.name {
  Enter => println("pressed enter")
  _ => ()
}
iface.close()
```

## API Reference

```mbt nocheck
///|
pub fn interface(input~ : @stdio.Input, output? : @stdio.Output) -> Interface raise

///|
pub async fn Interface::prompt(self : Interface, preserve_cursor? : Bool) -> Unit
pub async fn Interface::question(self : Interface, prompt : StringView) -> String
pub async fn Interface::read_line(self : Interface) -> String
pub async fn Interface::read_key(self : Interface) -> Key
pub fn Interface::set_prompt(self : Interface, prompt : Bytes) -> Unit
pub fn Interface::set_line(self : Interface, line : BytesView) -> Unit
pub async fn Interface::start(self : Interface) -> Unit
pub fn Interface::add_new_line_on_tty(self : Interface) -> Unit
pub fn Interface::close(self : Interface) -> Unit
```

## Integration

- 被 `cmd/main/interactive` 用于交互式 CLI
- 依赖 `@tty` 检测终端与设置原始模式
- 依赖 `@signal` 处理 SIGTSTP