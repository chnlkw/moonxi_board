///|
test "init_model has correct defaults" {
  let config = {
    base_url: "http://localhost:4096",
    username: "opencode",
    password: "",
  }
  let model = init_model(config)
  assert_true(model.connection is Disconnected)
  assert_eq(model.projects.length(), 0)
  assert_eq(model.sessions.length(), 0)
  assert_eq(model.agents.length(), 0)
  assert_eq(model.active_session_id, "")
  assert_eq(model.active_project_id, "")
  assert_eq(model.selected_agent, "")
  assert_eq(model.sidebar_open, true)
  assert_eq(model.detail_open, false)
  assert_eq(model.input_text, "")
  assert_eq(model.search_query, "")
  assert_eq(model.sse_connected, false)
  assert_eq(model.stats.total_messages, 0)
  assert_eq(model.stats.combo_streak, 0)
  assert_eq(model.base_url_input, "http://localhost:4096")
}

///|
test "init_model stores config" {
  let config = {
    base_url: "http://example.com",
    username: "user",
    password: "pass",
  }
  let model = init_model(config)
  assert_eq(model.config.base_url, "http://example.com")
  assert_eq(model.config.username, "user")
  assert_eq(model.config.password, "pass")
  assert_eq(model.base_url_input, "http://example.com")
}
