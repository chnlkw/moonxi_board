///|
test "connection_label returns correct strings" {
  assert_eq(connection_label(Disconnected), "○ Disconnected")
  assert_eq(connection_label(Connecting), "◐ Connecting")
  assert_eq(connection_label(Connected), "● Connected")
  assert_eq(connection_label(Error("err")), "✗ err")
}

///|
test "agent_mode_label returns correct strings" {
  assert_eq(agent_mode_label(Primary), "Primary")
  assert_eq(agent_mode_label(Subagent), "Subagent")
  assert_eq(agent_mode_label(All), "All")
}
