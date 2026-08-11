# 治理计划（v1）

## 概述
本轮为首轮增量治理，聚焦 warning_guidelines.md 中明确覆盖的两类 warning：unused_package（对应"Unused Import"原则）与 unused_variable（对应"Unused Variable"原则）。共 6 个 warning，改动范围小且互不耦合，可作为安全起步。

## 批次策略
采用"删除优先"策略，严格遵循指导原则：
- unused_package：直接从 moon.pkg 的 import 块中删除未使用的包行。
- unused_variable：优先删除未使用变量；若为方法签名中的 self 参数不可删除，则改用弃元 `_`。

理由：这两类 warning 在指导原则中有明确处理方式，改动局限于依赖声明文件和单个源文件的参数签名，不涉及业务逻辑，回归风险极低。

## 修复清单

### unused_package

| 文件 | 行号 | Warning内容 |
|------|------|------------|
| _trait_probe/moon.pkg | 3 | Unused package 'moonbitlang/maria/sandbox' |
| agent/moon.pkg | 16 | Unused package 'moonbitlang/maria/internal/perm' |
| mcp/moon.pkg | 10 | Unused package 'moonbitlang/async' |
| mcp/moon.pkg | 12 | Unused package 'moonbitlang/maria/internal/mock' |

### unused_variable

| 文件 | 行号 | Warning内容 |
|------|------|------------|
| mcp/http_sse_transport.mbt | 57 | Unused variable 'self' |
| mcp/http_sse_transport.mbt | 71 | Unused variable 'self' |

## 排除项
以下 warning 不在 warning_guidelines.md 当前处理范围内，本轮不修复：
- unused_field（11）：指导原则未覆盖，字段可能属于预留结构，需逐案确认。
- unused_value（10）：未使用函数与 trait 实现，不属于指导原则中的"Unused Variable"（MoonBit 中 warning code 0001 与 0002 为不同类别），暂不处理。
- reserved_keyword（4）：`method` 保留字问题涉及字段命名重构，指导原则未覆盖。
- unused_constructor（2）：未使用变体可能属于预留 API，指导原则未覆盖。
- deprecated（1）：Show→Debug 迁移涉及测试输出格式变更，指导原则未覆盖。

## 预期效果
预期消除 6 个 warning（unused_package ×4 + unused_variable ×2），剩余 28 个 warning 均为指导原则未覆盖类别。下轮方向：若后续扩展指导原则覆盖范围，可依次处理 unused_value（测试桩清理）与 unused_field（预留字段确认）。