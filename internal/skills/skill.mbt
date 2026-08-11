///|
pub struct Skill {
  name : String
  description : String
  license : String?
  compatibility : String?
  /// - A space-delimited list of tools that are pre-approved to run
  /// - Experimental. Support for this field may vary between agent implementations
  allowed_tools : Array[String]
  metadata : Json?
  location : String
} derive(Debug, ToJson)

///|
fn validate_name(
  name : String,
  directory~ : String,
) -> Unit raise SkillFormatError {
  if name.is_empty() {
    raise SkillFormatError("Field 'name' must be a non-empty string")
  }
  if name.length() > 64 {
    raise SkillFormatError("Skill name exceeds 64 character limit")
  }
  if name.has_prefix("-") || name.has_suffix("-") {
    raise SkillFormatError("Skill name cannot start or end with a hyphen")
  }
  if name.contains("--") {
    raise SkillFormatError("Skill name cannot contain consecutive hyphens")
  }
  if !directory.is_empty() && directory != name {
    raise SkillFormatError("Directory name must match skill name")
  }
}

///|
fn validate_description(desc : String) -> Unit raise SkillFormatError {
  if desc.is_empty() {
    raise SkillFormatError("Field 'description' must be a non-empty string")
  }
  if desc.length() > 1024 {
    raise SkillFormatError("Description exceeds 1024 character limit")
  }
}

///|
priv suberror SkillFormatError {
  SkillFormatError(String)
} derive(Debug, ToJson)

///|
/// Parses a skill definition from YAML frontmatter content and creates a
/// `Skill` object.
///
/// Parameters:
///
/// * `content` : The YAML frontmatter content containing skill metadata and
///   description.
/// * `directory` : The directory name where the skill file is located, used for
///   validation against the skill name.
/// * `location` : The file path where the skill is located.
///
/// Returns a `Skill` object populated with the parsed metadata and content.
///
/// Throws an error of type `SkillFormatError` if:
///
/// * Required fields (`name` or `description`) are missing from the frontmatter
/// * Field types are incorrect (e.g., `name` or `description` is not a string)
/// * The skill name fails validation (empty, too long, invalid format, or
///   doesn't match directory name)
/// * The description fails validation (empty or too long)
/// * The `allowed-tools` field is neither a space-delimited string nor a valid
///   JSON array of strings
fn parse_skill_from_content(
  content : String,
  directory~ : String,
  location~ : String,
) -> Skill raise {
  let doc = @yamd.parse(content)
  // Extract frontmatter
  let meta = doc.meta
  let name = match meta.get("name") {
    Some(String(s)) => s
    Some(s) =>
      raise SkillFormatError(
        "Field 'name' must be a string, got \{s.stringify()}",
      )
    None => raise SkillFormatError("Missing field 'name'")
  }
  validate_name(name, directory~)
  let description = match meta.get("description") {
    Some(String(s)) => s
    Some(s) =>
      raise SkillFormatError(
        "Field 'description' must be a string, got \{s.stringify()}",
      )
    None => raise SkillFormatError("Missing field 'description'")
  }
  validate_description(description)
  let license = match meta.get("license") {
    Some(String(s)) => Some(s)
    _ => None
  }
  let compatibility = match meta.get("compatibility") {
    Some(String(s)) => Some(s)
    _ => None
  }
  let allowed_tools : Array[String] = match meta.get("allowed-tools") {
    Some(String(s)) => s.split(" ").map(tool => tool.to_owned()).collect()
    Some(s) =>
      @json.from_json(s) catch {
        _ =>
          raise SkillFormatError(
            "Field 'allowed-tools' must be a space-delimited string or array of strings, got \{s.stringify()}",
          )
      }
    _ => []
  }
  let metadata : Json? = meta.get("metadata")
  Skill::{
    name,
    description,
    license,
    compatibility,
    allowed_tools,
    metadata,
    location,
  }
}

///|
/// 公开构造函数，使 blackbox 测试和 ComponentRegistry 场景可手动构造 Skill 实例。
/// 不验证字段约束（name 非空、长度限制等），调用者负责保证不变量；
/// 文件加载路径 parse_skill_from_content 会验证。
pub fn Skill::new(
  name~ : String,
  description~ : String,
  location~ : String,
  license? : String,
  compatibility? : String,
  allowed_tools? : Array[String] = [],
  metadata? : Json,
) -> Skill {
  Skill::{
    name,
    description,
    location,
    license,
    compatibility,
    allowed_tools,
    metadata,
  }
}

///|
/// Skill 实现 Component trait，暴露技能组件元信息。
/// version 硬编码 "0.2.0"（当前模块版本，moon.mod 中 version = "0.2.0"）。
pub impl @component.Component for Skill with fn component_type(self) {
  ignore(self)
  @component.ComponentType::Skill
}

///|
pub impl @component.Component for Skill with fn name(self) {
  self.name
}

///|
pub impl @component.Component for Skill with fn version(self) {
  ignore(self)
  "0.2.0"
}

///|
pub impl @component.Component for Skill with fn input_schema(self) {
  ignore(self)
  @tool.JsonSchema(Json::empty_object())
}

///|
pub impl @component.Component for Skill with fn output_schema(self) {
  ignore(self)
  @tool.JsonSchema(Json::empty_object())
}

///|
pub impl @component.Component for Skill with fn enabled(self) {
  ignore(self)
  true
}

///|
/// Skill 实现 SkillComponent trait，apply 返回 async 函数值变换 messages。
/// 生成单 skill XML（不含 SKILLS 说明 preamble）追加到 system message。
/// preamble 由上层 ComponentRegistry/Agent 统一注入，避免每个 skill 重复注入。
pub impl @component.SkillComponent for Skill with fn apply(self : Skill) -> async (
  Array[@ai.Message],
) -> Unit {
  messages => self.apply_to_messages(messages)
}

///|
/// 生成单 skill XML（不含 SKILLS 说明 preamble）。
/// 格式：<available_skills>\n  <skill>\n    <name>...</name>\n    <description>...</description>\n    <location>...</location>\n  </skill>\n</available_skills>
fn Skill::format_prompt(self : Skill) -> String {
  let sb = StringBuilder::new()
  sb.write_string("<available_skills>\n")
  sb.write_string("  <skill>\n")
  sb.write_string("    <name>")
  sb.write_string(self.name)
  sb.write_string("</name>\n")
  sb.write_string("    <description>")
  sb.write_string(self.description)
  sb.write_string("</description>\n")
  sb.write_string("    <location>")
  sb.write_string(self.location)
  sb.write_string("</location>\n")
  sb.write_string("  </skill>\n")
  sb.write_string("</available_skills>")
  sb.to_string()
}

///|
/// 将自身描述信息以单 skill XML 格式追加到 messages 的 system message。
/// 找到 System message 则追加 "\n\n" + skill_prompt，未找到则 insert(0) 新建 System message。
/// 多个 System message 时仅处理第一个（与 Loader::apply 行为一致）。
fn Skill::apply_to_messages(
  self : Skill,
  messages : Array[@ai.Message],
) -> Unit {
  let skill_prompt = self.format_prompt()
  for i, msg in messages {
    if msg is System(sys_msg) {
      messages[i] = @ai.system_message(content=sys_msg + "\n\n" + skill_prompt)
      return
    }
  } nobreak {
    messages.insert(0, @ai.system_message(content=skill_prompt))
    return
  }
}
