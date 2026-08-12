///|
test "apply_patch/parse AddFile hunk" {
  let patch = "*** Begin Patch\n*** Add File: hello.txt\n+Hello, World!\n+Second line\n*** End Patch"
  let parsed = @apply_patch.parse_patch(patch)
  inspect(parsed.hunks.length(), content="1")
  guard parsed.hunks[0] is AddFile(path~, contents~) else {
    fail("expected AddFile")
  }
  inspect(path, content="hello.txt")
  inspect(contents, content="Hello, World!\nSecond line\n")
}

///|
test "apply_patch/parse DeleteFile hunk" {
  let patch = "*** Begin Patch\n*** Delete File: old.txt\n*** End Patch"
  let parsed = @apply_patch.parse_patch(patch)
  inspect(parsed.hunks.length(), content="1")
  guard parsed.hunks[0] is DeleteFile(path~) else {
    fail("expected DeleteFile")
  }
  inspect(path, content="old.txt")
}

///|
test "apply_patch/parse UpdateFile with context" {
  let patch = "*** Begin Patch\n*** Update File: src/main.mbt\n@@ fn main\n fn main {\n-  println(\"old\")\n+  println(\"new\")\n }\n*** End Patch"
  let parsed = @apply_patch.parse_patch(patch)
  inspect(parsed.hunks.length(), content="1")
  guard parsed.hunks[0] is UpdateFile(path~, move_path~, chunks~) else {
    fail("expected UpdateFile")
  }
  inspect(path, content="src/main.mbt")
  debug_inspect(move_path, content="None")
  debug_inspect(chunks.length(), content="1")
  debug_inspect(
    chunks[0].old_lines,
    content="[\"fn main {\", \"  println(\\\"old\\\")\", \"}\"]",
  )
  debug_inspect(
    chunks[0].new_lines,
    content="[\"fn main {\", \"  println(\\\"new\\\")\", \"}\"]",
  )
  debug_inspect(chunks[0].is_end_of_file, content="false")
}

///|
test "apply_patch/parse UpdateFile with Move to" {
  let patch = "*** Begin Patch\n*** Update File: old.txt\n*** Move to: new.txt\n@@\n old\n+new\n*** End Patch"
  let parsed = @apply_patch.parse_patch(patch)
  guard parsed.hunks[0] is UpdateFile(path~, move_path~, ..) else {
    fail("expected UpdateFile")
  }
  inspect(path, content="old.txt")
  debug_inspect(move_path, content="Some(\"new.txt\")")
}

///|
test "apply_patch/parse UpdateFile with End of File" {
  let patch = "*** Begin Patch\n*** Update File: test.txt\n@@\n line1\n+line2\n*** End of File\n*** End Patch"
  let parsed = @apply_patch.parse_patch(patch)
  guard parsed.hunks[0] is UpdateFile(chunks~, ..) else {
    fail("expected UpdateFile")
  }
  inspect(chunks[0].is_end_of_file, content="true")
}

///|
test "apply_patch/parse multiple hunks" {
  let patch = "*** Begin Patch\n*** Add File: a.txt\n+content a\n*** Delete File: b.txt\n*** End Patch"
  let parsed = @apply_patch.parse_patch(patch)
  inspect(parsed.hunks.length(), content="2")
  guard parsed.hunks[0] is AddFile(path~, ..) else { fail("expected AddFile") }
  inspect(path, content="a.txt")
  guard parsed.hunks[1] is DeleteFile(path~) else {
    fail("expected DeleteFile")
  }
  inspect(path, content="b.txt")
}

///|
test "apply_patch/parse empty context marker" {
  let patch = "*** Begin Patch\n*** Update File: test.txt\n@@\n old\n+new\n*** End Patch"
  let parsed = @apply_patch.parse_patch(patch)
  guard parsed.hunks[0] is UpdateFile(chunks~, ..) else {
    fail("expected UpdateFile")
  }
  debug_inspect(chunks[0].change_context, content="None")
}

///|
test "apply_patch/parse missing Begin marker" {
  let patch = "*** Add File: hello.txt\n+Hello\n*** End Patch"
  try @apply_patch.parse_patch(patch) catch {
    InvalidPatch(msg) => inspect(msg.contains("Begin"), content="true")
    _ => fail("expected InvalidPatch")
  } noraise {
    _ => fail("expected error")
  }
}

///|
test "apply_patch/parse missing End marker" {
  let patch = "*** Begin Patch\n*** Add File: hello.txt\n+Hello"
  try @apply_patch.parse_patch(patch) catch {
    InvalidPatch(msg) => inspect(msg.contains("End"), content="true")
    _ => fail("expected InvalidPatch")
  } noraise {
    _ => fail("expected error")
  }
}

///|
test "apply_patch/parse too short patch" {
  let patch = "*** Begin Patch"
  try @apply_patch.parse_patch(patch) catch {
    InvalidPatch(_) => ()
    _ => fail("expected InvalidPatch")
  } noraise {
    _ => fail("expected error")
  }
}

///|
test "apply_patch/parse invalid hunk header" {
  let patch = "*** Begin Patch\n*** Unknown: test\n*** End Patch"
  try @apply_patch.parse_patch(patch) catch {
    InvalidHunk(message~, ..) =>
      inspect(message.contains("not a valid hunk header"), content="true")
    _ => fail("expected InvalidHunk")
  } noraise {
    _ => fail("expected error")
  }
}

///|
test "apply_patch/parse empty UpdateFile hunk" {
  let patch = "*** Begin Patch\n*** Update File: empty.txt\n*** End Patch"
  try @apply_patch.parse_patch(patch) catch {
    InvalidHunk(message~, ..) =>
      inspect(message.contains("empty"), content="true")
    _ => fail("expected InvalidHunk")
  } noraise {
    _ => fail("expected error")
  }
}

///|
test "apply_patch/ApplyResult summary" {
  let result = @apply_patch.ApplyResult::new()
  result.added.push("new.txt")
  result.modified.push("changed.txt")
  result.deleted.push("removed.txt")
  inspect(
    result.summary(),
    content=(
      #|Success. Updated the following files:
      #|A new.txt
      #|M changed.txt
      #|D removed.txt
    ),
  )
}

///|
test "apply_patch/ApplyResult empty summary" {
  let result = @apply_patch.ApplyResult::new()
  inspect(result.summary(), content="Success. Updated the following files:")
}
