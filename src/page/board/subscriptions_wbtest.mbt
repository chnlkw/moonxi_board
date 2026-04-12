///|
test "parse_sse_event returns SSEConnected for session.created" {
  let result = parse_sse_event("session.created", "")
  assert_true(result is Some(_))
  // Verify it's SSEConnected
  match result {
    Some(SSEConnected) => () // pass
    _ => assert_true(false) // fail
  }
}

///|
test "parse_sse_event returns SSEConnected for heartbeat" {
  let result = parse_sse_event("server.heartbeat", "")
  assert_true(result is Some(_))
}

///|
test "parse_sse_event returns SSESessionDeleted for session.deleted" {
  let result = parse_sse_event("session.deleted", "ses_123")
  match result {
    Some(SSESessionDeleted(id)) => assert_eq(id, "ses_123")
    _ => assert_true(false)
  }
}

///|
test "parse_sse_event returns SSEDisconnected for error" {
  let result = parse_sse_event("error", "")
  match result {
    Some(SSEDisconnected) => () // pass
    _ => assert_true(false)
  }
}

///|
test "parse_sse_event returns None for unknown event" {
  let result = parse_sse_event("unknown.event", "data")
  assert_true(result is None)
}
