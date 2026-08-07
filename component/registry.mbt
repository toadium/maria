// Copyright 2025 International Digital Economy Academy
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

///|
struct ComponentEntry {
  component : Component
  mut enabled : Bool
}

///|
pub struct ComponentRegistry {
  priv entries : Map[String, ComponentEntry]
}

///|
pub fn ComponentRegistry::new() -> ComponentRegistry {
  ComponentRegistry::{ entries: Map([]) }
}

///|
pub fn ComponentRegistry::register(
  self : ComponentRegistry,
  component~ : Component,
) -> Unit {
  let name = component.name()
  self.entries[name] = ComponentEntry::{
    component,
    enabled: component.enabled(),
  }
}

///|
pub fn ComponentRegistry::unregister(
  self : ComponentRegistry,
  name : String,
) -> Unit {
  self.entries.remove(name)
}

///|
pub fn ComponentRegistry::get(
  self : ComponentRegistry,
  name : String,
) -> Component? {
  match self.entries.get(name) {
    Some(entry) => Some(entry.component)
    None => None
  }
}

///|
pub fn ComponentRegistry::list(self : ComponentRegistry) -> Array[String] {
  let names = []
  for name, _ in self.entries {
    names.push(name)
  }
  names
}

///|
pub fn ComponentRegistry::list_by_type(
  self : ComponentRegistry,
  type~ : ComponentType,
) -> Array[String] {
  let names = []
  for name, entry in self.entries {
    if entry.component.component_type() == type {
      names.push(name)
    }
  }
  names
}


///|
pub fn ComponentRegistry::set_enabled(
  self : ComponentRegistry,
  name : String,
  enabled~ : Bool,
) -> Unit {
  for n, entry in self.entries {
    if n == name {
      entry.enabled = enabled
    }
  }
}

///|
pub fn ComponentRegistry::set_enabled_names(
  self : ComponentRegistry,
  names : Set[String],
) -> Unit {
  for name, entry in self.entries {
    if names.contains(name) {
      entry.enabled = true
    } else {
      entry.enabled = false
    }
  }
}

///|
pub fn ComponentRegistry::is_enabled(
  self : ComponentRegistry,
  name : String,
) -> Bool {
  match self.entries.get(name) {
    Some(entry) => entry.enabled
    None => false
  }
}
