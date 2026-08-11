# component

Modular component architecture — unified `Component` trait and `ComponentRegistry` for tools, prompts, and skills.

## Overview

- `Component` trait: `component_type` / `name` / `version` / `input_schema` / `output_schema` / `enabled` / `execute`
- `ComponentType` enum: `Tool` / `Prompt` / `Skill`
- `ToolComponent` trait: extends `Component` with `execute(args : Json) -> async (Unit) -> ToolResult`
- `ComponentRegistry`: register / unregister / set_enabled / lookup by name

## Usage

```mbt nocheck
///|
let registry = @component.ComponentRegistry::new()
registry.register(tool)
registry.set_enabled("tool_name", false)
let enabled_tools = registry.get_enabled_tools()
```

## Component Trait

```mbt nocheck
///|
pub(open) trait Component {
  fn component_type(Self) -> ComponentType
  fn name(Self) -> String
  fn version(Self) -> String
  fn input_schema(Self) -> @tool.JsonSchema
  fn output_schema(Self) -> @tool.JsonSchema
  fn enabled(Self) -> Bool
}

///|
pub(open) trait ToolComponent: Component {
  fn execute(Self, args : Json) -> async (Unit) -> @tool.ToolResult
}
```

## Implemented By

- `@tool.Tool` — built-in tools (ToolComponent)
- `@prompt.PromptTemplate` — prompt templates (Component)
- `@skills.Skill` — skill definitions (Component)
- `@mcp.McpTool` — MCP remote tools (ToolComponent)