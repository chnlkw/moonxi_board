// === OpenCode Serve API ===

// --- Health Check ---

///|
pub fn api_health_check(
  dispatch : @cmd.Dispatch[Msg],
  config : ServerConfig,
) -> @cmd.Cmd {
  @http.get(
    "\{config.base_url}/global/health",
    expect=@http.Text(fn(result) {
      match result {
        Ok(_) => dispatch(GotHealth(Ok("ok")))
        Err(msg) => dispatch(GotHealth(Err(msg)))
      }
    }),
  )
}

// --- Sessions ---

///|
pub fn api_load_sessions(
  dispatch : @cmd.Dispatch[Msg],
  config : ServerConfig,
) -> @cmd.Cmd {
  @http.get(
    "\{config.base_url}/session",
    expect=@http.Json(
      fn(result) {
        match result {
          Ok(json) =>
            match decode_sessions(json) {
              Ok(sessions) => dispatch(GotSessions(Ok(sessions)))
              Err(e) => dispatch(GotSessions(Err(e)))
            }
          Err(msg) => dispatch(GotSessions(Err(msg)))
        }
      },
      fn(json) { Ok(json) },
    ),
  )
}

///|
pub fn api_create_session(
  dispatch : @cmd.Dispatch[Msg],
  config : ServerConfig,
) -> @cmd.Cmd {
  @http.post(
    "\{config.base_url}/session",
    @http.Body::Json({ "title": "New Session" }),
    expect=@http.Json(
      fn(result) {
        match result {
          Ok(json) =>
            match decode_session(json) {
              Ok(session) => dispatch(GotSessions(Ok([session])))
              Err(e) => dispatch(GotSessions(Err(e)))
            }
          Err(msg) => dispatch(GotSessions(Err(msg)))
        }
      },
      fn(json) { Ok(json) },
    ),
  )
}

///|
pub fn api_delete_session(
  dispatch : @cmd.Dispatch[Msg],
  config : ServerConfig,
  session_id : String,
) -> @cmd.Cmd {
  @http.delete(
    "\{config.base_url}/session/\{session_id}",
    expect=@http.Text(fn(result) {
      match result {
        Ok(_) => dispatch(SSESessionDeleted(session_id))
        Err(msg) => dispatch(GotSessions(Err(msg)))
      }
    }),
  )
}

// --- Messages ---

///|
pub fn api_load_messages(
  dispatch : @cmd.Dispatch[Msg],
  config : ServerConfig,
  session_id : String,
) -> @cmd.Cmd {
  @http.get(
    "\{config.base_url}/session/\{session_id}/message",
    expect=@http.Json(
      fn(result) {
        match result {
          Ok(json) =>
            match decode_messages(json) {
              Ok(messages) => dispatch(GotMessages(session_id, Ok(messages)))
              Err(e) => dispatch(GotMessages(session_id, Err(e)))
            }
          Err(msg) => dispatch(GotMessages(session_id, Err(msg)))
        }
      },
      fn(json) { Ok(json) },
    ),
  )
}

///|
pub fn api_send_message(
  dispatch : @cmd.Dispatch[Msg],
  config : ServerConfig,
  session_id : String,
  text : String,
  agent : String,
) -> @cmd.Cmd {
  @http.post(
    "\{config.base_url}/session/\{session_id}/message",
    @http.Body::Json({
      "parts": [{ "type": "text", "text": text }],
      "agent": agent,
    }),
    expect=@http.Json(
      fn(result) {
        match result {
          Ok(json) =>
            match decode_messages(json) {
              Ok(messages) => dispatch(MessageSent(Ok(messages)))
              Err(e) => dispatch(MessageSent(Err(e)))
            }
          Err(msg) => dispatch(MessageSent(Err(msg)))
        }
      },
      fn(json) { Ok(json) },
    ),
  )
}
