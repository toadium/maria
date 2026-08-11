# tools/todo

Todo management tool — tracks task lists within a markdown file for agent self-organization.

## API

```mbt nocheck
pub fn new(uuid~ : @uuid.Generator, clock? : &@clock.Clock, cwd~ : StringView) -> Todo
pub fn new_tool(Todo) -> @tool.Tool
pub fn parse_todo_args(Json) -> TodoArgs raise TodoArgsError
```

Creates a todo management system backed by a markdown file. Supports add/update/remove/list operations for task tracking during agent conversations.