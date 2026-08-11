# internal/git

Git 命令异步封装 — clone、commit、worktree 管理、忽略检查、diff 生成。

## Overview

- `clone(url, to~)`：克隆仓库（支持 depth 浅克隆）
- `init_(path)` / `commit(msg, files)`：初始化与提交
- `add_worktree(path, new_branch?)` / `remove_worktree(path)`：worktree 管理
- `with_worktree(path, fn)`：在临时 worktree 中执行操作
- `list_files()` / `check_ignore(files)` / `is_ignored(file)`：文件列表与忽略检查
- `find_repo_root(path)`：查找仓库根目录
- `generate_git_diff(original, modified)`：生成 git 风格 diff

## Usage

```mbt nocheck
///|
@git.clone("https://github.com/foo/bar.git", to="./bar", depth=1)
@git.init_("./myrepo")
@git.commit("Initial commit", ["README.md"])
let files = @git.list_files()
let ignored = @git.is_ignored("secret.env")
let root = @git.find_repo_root(".")
let diff = @git.generate_git_diff(original~="a\nb\n", modified~="a\nc\n")
```

## API Reference

```mbt nocheck
///|
pub async fn clone(url : String, to~ : StringView, cwd? : StringView, depth? : Int) -> Unit
pub async fn init_(path : String) -> Unit
pub async fn commit(message : StringView, files : Array[StringView], cwd? : StringView) -> Unit
pub async fn add_worktree(path : String, new_branch? : String, force_new_branch? : Bool, commit? : String, cwd? : StringView) -> Unit
pub async fn remove_worktree(path : String, force? : Bool, cwd? : StringView) -> Unit
pub async fn[T] with_worktree(path : String, new_branch? : String, force_new_branch? : Bool, commit? : String, cwd? : StringView, f : async () -> T) -> T
pub async fn list_files(cwd? : StringView) -> Array[String]
pub async fn check_ignore(files : Array[StringView], cwd? : StringView) -> Array[String]
pub async fn is_ignored(file : StringView, cwd? : StringView) -> Bool
pub async fn find_repo_root(path : StringView) -> String?
pub async fn generate_git_diff(original~ : String, modified~ : String, line_number? : Bool) -> String
```

## Integration

- 被 `@internal/skills` 用于 skill 仓库克隆
- 被 `@tools/search_files` 用于 git 忽略规则检查
- 被 `@cmd/jsonl2md` 用于 diff 生成