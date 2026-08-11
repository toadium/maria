# internal/pino

pino 风格结构化日志 — 支持 Console/File/Channel/Callback/Sink 多种传输。

## Overview

- `Logger`：核心日志器，支持 level 过滤、子日志器派生、属性继承
- `Level`：Trace < Debug < Info < Warn < Error < Fatal 六级日志
- `Transport`：Console（stdout）/ File（追加写入）/ Channel（异步队列）/ Callback（自定义）/ Sink（丢弃）
- `Transport::parse("console:")` / `Transport::parse("file:/var/log/app.log")` 从字符串解析传输

## Usage

```mbt nocheck
///|
let log = @pino.logger("my-app", level=Debug, @pino.Transport::console())
log.info("ServerStarted", data={ "port": 8080 })
log.warn("SlowQuery", data={ "ms": 1500, "sql": "SELECT *" })

let file_transport = @pino.Transport::file("/var/log/app.log")
let file_log = @pino.logger("my-app", file_transport)
file_log.error("DiskFull")

let child = log.child({ "module": "auth" })
child.info("UserLogin", data={ "user": "alice" })
log.close()
```

## API Reference

```mbt nocheck
///|
pub fn logger(
  tag : String,
  level? : Level = Info,
  transport : Transport,
) -> Logger

///|
pub async fn Logger::log(
  self : Logger,
  level : Level,
  message : StringView,
  data? : Map[String, Json],
) -> Unit

///|
pub async fn Logger::info(self : Logger, message : StringView, data? : Map[String, Json]) -> Unit
pub async fn Logger::warn(self : Logger, message : StringView, data? : Map[String, Json]) -> Unit
pub async fn Logger::error(self : Logger, message : StringView, data? : Map[String, Json]) -> Unit
pub async fn Logger::debug(self : Logger, message : StringView, data? : Map[String, Json]) -> Unit

///|
pub fn Logger::child(self : Logger, properties : Map[String, Json]) -> Logger

///|
pub fn Logger::close(self : Logger) -> Unit

///|
pub fn Transport::console() -> Transport
pub fn Transport::file(path : StringView) -> Transport
pub fn Transport::sink() -> Transport
pub fn Transport::channel(queue : @aqueue.Queue[Json]) -> Transport
pub fn Transport::callback(callback : (Json) -> Unit) -> Transport
pub fn Transport::parse(transport : StringView) -> Transport raise
```

## Integration

- 被 `@agent`、`@mcp`、`@token_counter`、`@context_pruner` 等几乎所有包用作标准日志器
- 日志条目自动附加 `level`、`pid`、`hostname`、`time`、`tag` 字段
- File 传输自动创建父目录并以 0o644 权限追加写入