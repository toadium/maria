///|
struct ComponentEntry {
  component : &Component
  mut enabled : Bool
}

///|
pub struct ComponentRegistry {
  priv entries : Map[String, ComponentEntry]
}

///|
/// 创建空注册表。
pub fn ComponentRegistry::new() -> ComponentRegistry {
  ComponentRegistry::{ entries: Map([]) }
}

///|
/// 注册组件（以 component.name() 作为索引 key，ComponentEntry.enabled 初始值取自 component.enabled()）。
/// 重复注册（同 name）覆盖旧 entry。
pub fn ComponentRegistry::register(
  self : ComponentRegistry,
  component~ : &Component,
) -> Unit {
  let name = component.name()
  self.entries[name] = ComponentEntry::{
    component,
    enabled: component.enabled(),
  }
}

///|
/// 注销组件（按名称删除 entry，不存在时无操作）。
pub fn ComponentRegistry::unregister(
  self : ComponentRegistry,
  name : String,
) -> Unit {
  self.entries.remove(name)
}

///|
/// 按名称查询（返回 boxed trait object 值的 Option）。
pub fn ComponentRegistry::get(
  self : ComponentRegistry,
  name : String,
) -> &Component? {
  match self.entries.get(name) {
    Some(entry) => Some(entry.component)
    None => None
  }
}

///|
/// 列出所有组件名称。
pub fn ComponentRegistry::list(self : ComponentRegistry) -> Array[String] {
  let names = []
  for name, _ in self.entries {
    names.push(name)
  }
  names
}

///|
/// 按类型查询（遍历过滤，调用 component_type() 方法匹配，返回 component.name()）。
pub fn ComponentRegistry::list_by_type(
  self : ComponentRegistry,
  ctype~ : ComponentType,
) -> Array[String] {
  let names = []
  for name, entry in self.entries {
    if entry.component.component_type() == ctype {
      names.push(name)
    }
  }
  names
}

///|
/// 启用/禁用指定组件（修改 ComponentEntry.enabled 字段，不存在时无操作）。
pub fn ComponentRegistry::set_enabled(
  self : ComponentRegistry,
  name : String,
  enabled~ : Bool,
) -> Unit {
  match self.entries.get(name) {
    Some(entry) => entry.enabled = enabled
    None => ()
  }
}

///|
/// 全量覆盖语义：启用 names 中的组件，禁用不在 names 中的所有其他组件。
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
/// 查询启用状态（返回 ComponentEntry.enabled 字段值，不存在时返回 false）。
pub fn ComponentRegistry::is_enabled(
  self : ComponentRegistry,
  name : String,
) -> Bool {
  match self.entries.get(name) {
    Some(entry) => entry.enabled
    None => false
  }
}
