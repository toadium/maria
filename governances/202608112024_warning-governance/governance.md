# Warning 治理跟踪

项目根目录：D:/CodeWorkspace/forMoonbitMaria/maria
治理启动时间：2026-08-11 20:32

## 基线
检查报告：D:/CodeWorkspace/forMoonbitMaria/maria/governances/202608112024_warning-governance/check_v1.md | 总warning数：34 | 分布：unused_field=11, unused_value=10, unused_package=4, reserved_keyword=4, unused_variable=2, unused_constructor=2, deprecated=1

---

## R1 PLAN unused_package + unused_variable 清理
策略：删除未使用的包导入和未使用变量，严格依据 warning_guidelines.md 中"Unused Import"与"Unused Variable"两类处理原则 | 目标warning：unused_package, unused_variable | 预估修复数：6 | 理由：这两类在指导原则中有明确处理策略（直接删除/弃元），风险低、改动隔离在 moon.pkg 与单文件 http_sse_transport.mbt，不涉及逻辑变更，适合作为首批增量治理