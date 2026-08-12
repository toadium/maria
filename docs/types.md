# 核心类型

> Maria UI 与 Daemon 之间通信使用的 JSON / TypeScript 类型定义。

📚 **导航**：[docs/](.) · [任务事件](events.md) · [HTTP 端点](http.md) · [模型选择](model-selection.md)

---

本文档描述 Maria UI 与 daemon 及宿主环境（web、VS Code、Electron）通信时使用的核心类型。所有类型在 HTTP / SSE 边界上使用 OpenAI 风格的 JSON 结构。

## 类型索引

| 类型 | 说明 | 文档 |
|------|------|------|
| `Message` | 会话消息（user / system / assistant / tool） | [→](types/Message.md) |
| `QueuedMessage` | 排队消息（任务繁忙时缓存） | [→](types/QueuedMessage.md) |
| `TaskOverview` | 任务概览（列表/同步用） | [→](types/TaskOverview.md) |
| `Todo` | TODO 项（Agent 待办列表） | [→](types/Todo.md) |
| `Status` | 任务状态（`"idle"` / `"generating"`） | [→](types/Status.md) |
