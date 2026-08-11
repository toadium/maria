# tool

Tool definition and execution — `Tool`, `ToolDesc`, `ToolResult`, `JsonSchema`.

## Overview

- `Tool`: struct holding `desc : ToolDesc` + `call : ToolFn`
- `ToolDesc`: `name` / `description` / `schema : JsonSchema` / `permissions : Array[Permission]`
- `ToolResult`: `Success(Json)` / `Failed(String)` / `Error(Error)`
- `JsonSchema`: wrapper over `Json` for JSON Schema validation
- `Tool` implements `@component.ToolComponent` trait

## Usage

```mbt nocheck
///|
let schema : @tool.JsonSchema = @tool.JsonSchema::from_json({
  "type": "object",
  "properties": { "path": { "type": "string" } },
  "required": ["path"],
})

///|
let read_tool : @tool.Tool = @tool.new(
  name="read_file",
  description="Read a file",
  schema~,
  @tool.ToolFn(args => {
    guard args is { "path": String(path), .. } else {
      return @tool.failed("Invalid args")
    }
    @tool.success(({ "content": "file contents" } : Json))
  }),
)
```

## ToolResult

```mbt nocheck
///|
pub(all) enum ToolResult {
  Success(Json)
  Failed(String)
  Error(Error)
} derive(ToJson, Debug)

///|
pub fn success(result : Json) -> ToolResult

///|
pub fn failed(message : String) -> ToolResult
```

## Permissions

Tools declare required permissions via `ToolDesc.permissions`. The `Sandbox` checks these before execution:

```mbt nocheck
///|
let desc : @tool.ToolDesc = {
  name: "write_file",
  description: "Write a file",
  schema: write_schema,
  permissions: [@perm.Permission::FileAccess(".", @perm.Access::Write)],
}
```