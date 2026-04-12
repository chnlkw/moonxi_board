///|
test "connection_label returns correct strings" {
  assert_eq(connection_label(@types.Disconnected), "○ Disconnected")
  assert_eq(connection_label(@types.Connecting), "◐ Connecting")
  assert_eq(connection_label(@types.Connected), "● Connected")
  assert_eq(connection_label(@types.Error("err")), "✗ err")
}

///|
test "agent_mode_label returns correct strings" {
  assert_eq(agent_mode_label(@types.Primary), "Primary")
  assert_eq(agent_mode_label(@types.Subagent), "Subagent")
  assert_eq(agent_mode_label(@types.All), "All")
}
