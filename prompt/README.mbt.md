# prompt

Prompt template management — `PromptTemplate` as a `@component.Component`.

## Overview

- `PromptTemplate`: named prompt template with variable substitution
- Implements `@component.Component` trait (`ComponentType::Prompt`)
- Registered in `@component.ComponentRegistry` alongside tools and skills

## Usage

```mbt nocheck
///|
let pt = @prompt.PromptTemplate::new(
  name="code_review",
  template="Review this code: {code}",
)
let rendered = pt.render({ "code": "fn main { println(1) }" })
inspect(@component.Component::name(pt), content="code_review")
inspect(@component.Component::version(pt), content="0.2.0")
```

## API Reference

```mbt nocheck
///|
pub(all) struct PromptTemplate {
  name : String
  template : String
}

///|
pub fn PromptTemplate::new(
  name~ : String,
  template~ : String,
) -> PromptTemplate

///|
pub fn PromptTemplate::render(
  self : PromptTemplate,
  vars : Map[String, String],
) -> String
```