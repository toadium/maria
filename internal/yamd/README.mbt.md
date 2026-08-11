# internal/yamd

YAML 文档解析 — 提取文档的 meta（元数据映射）与 text（正文）两部分。

## Overview

- `Document`：解析结果（meta: frontmatter 映射 + text: 正文字符串）
- `parse(content)`：从 YAML 字符串解析文档

## Usage

```mbt nocheck
///|
let doc = @yamd.parse("---\ndescription: My Rule\nglobs: [\"*.ts\"]\n---\nRule body text here")
inspect(doc.meta["description"], content="String(My Rule)")
inspect(doc.text, content="Rule body text here")
```

## API Reference

```mbt nocheck
///|
pub struct Document {
  meta : Map[String, Json]
  text : String
}

///|
pub fn parse(content : String) -> Document raise @yaml.YamlError
```

## Integration

- 被 `@internal/rules` 用于解析规则文件的 YAML frontmatter
- 被 `@internal/skills` 用于解析 skill 定义文件
- 依赖 `@yaml` 包进行 YAML 解析