# internal/skills

Skill definition and loading — `Skill` as a `@component.Component`.

## Overview

- `Skill`: named skill with description, location, and optional system prompt
- Implements `@component.Component` trait (`ComponentType::Skill`)
- `Loader`: loads skill definitions from disk (YAML/JSON format)
- System assets: built-in skills bundled with maria

## Usage

```mbt nocheck
///|
let skill = @skills.Skill::new(
  name="code_review",
  description="Review code for issues",
  location="/skills/code_review",
)
inspect(@component.Component::name(skill), content="code_review")
inspect(@component.Component::version(skill), content="0.2.0")
```

## API Reference

```mbt nocheck
///|
pub(all) struct Skill {
  name : String
  description : String
  location : String
  system_prompt : String?
}

///|
pub fn Skill::new(
  name~ : String,
  description~ : String,
  location~ : String,
  system_prompt~ : String? = None,
) -> Skill
```

## Loader

The `Loader` scans configured directories for skill definitions and registers them with a `ComponentRegistry`:
- Reads `skill.yaml` or `skill.json` files
- Parses skill metadata (name, description, system prompt)
- Returns `Array[Skill]` for registration