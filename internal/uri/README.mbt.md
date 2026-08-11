# internal/uri

URI 解析器 — 将字符串解析为 scheme、authority、path、query、fragment 组件。

## Overview

- `Uri`：解析后的 URI 结构（scheme、authority、path、query、fragment）
- `Authority`：授权部分（userinfo、host、port）
- `Uri::parse(uri)`：从字符串解析 URI

## Usage

```mbt nocheck
///|
let uri = @uri.Uri::parse("https://user@example.com:8080/path?q=1#frag")
inspect(uri.scheme, content="https")
guard uri.authority is Some(auth) else { fail("no authority") }
inspect(auth.host, content="example.com")
inspect(auth.port, content="Some(8080)")
inspect(uri.path, content="[/path]")
inspect(uri.query, content="Some(q=1)")
inspect(uri.fragment, content="Some(frag)")
```

## API Reference

```mbt nocheck
///|
pub struct Uri {
  mut scheme : StringView
  mut authority : Authority?
  path : Array[StringView]
  mut query : StringView?
  mut fragment : StringView?
} derive(Eq, Debug)

///|
pub struct Authority {
  mut userinfo : StringView?
  mut host : StringView
  mut port : Int?
} derive(Eq, Debug)

///|
pub fn Uri::parse(uri : StringView) -> Uri raise ParseError
```

## Integration

- 当前为孤儿包，尚未被项目中其他包导入
- 可供未来 HTTP/MCP URL 处理使用