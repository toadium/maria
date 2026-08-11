# internal/fuzzy

模糊子串匹配 — 在文本中查找模式并返回匹配位置、长度及所在行范围。

## Overview

- `find_match(pattern, text)`：在 text 中模糊匹配 pattern
- `MatchResult`：匹配结果（position、length、start_line、end_line）

## Usage

```mbt nocheck
///|
let result = @fuzzy.find_match("foo", "line1\nfoo bar\nline3")
guard result is Some(m) else { fail("no match") }
inspect(m.position, content="6")
inspect(m.start_line, content="2")
inspect(m.end_line, content="2")
```

## API Reference

```mbt nocheck
///|
pub struct MatchResult {
  position : Int
  length : Int
  start_line : Int
  end_line : Int
} derive(ToJson)

///|
pub fn find_match(pattern : String, text : String) -> MatchResult?
```

## Integration

- 被 `@tools/replace_in_file` 用于模糊匹配待替换文本
- 支持在用户提供的文本与实际文件内容有细微差异时仍能定位