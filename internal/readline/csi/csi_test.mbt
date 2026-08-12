///|
test "csi/build escape sequence" {
  assert_eq(@csi.csi(b"2K"), b"\x1b[2K")
  assert_eq(@csi.csi(b"0J"), b"\x1b[0J")
  assert_eq(@csi.csi(b"1K"), b"\x1b[1K")
  assert_eq(@csi.csi(b""), b"\x1b[")
}

///|
test "csi/constants match csi function" {
  assert_eq(@csi.ClearLine, b"\x1b[2K")
  assert_eq(@csi.ClearScreenDown, b"\x1b[0J")
  assert_eq(@csi.ClearToLineBeginning, b"\x1b[1K")
  assert_eq(@csi.ClearToLineEnd, b"\x1b[0K")
  assert_eq(@csi.Escape, b'\x1b')
}
