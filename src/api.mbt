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
    "\{config.base_url}/sessions",
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
    "\{config.base_url}/sessions",
    @http.Body::Json({
      "id": "",
      "project_id": "",
      "title": "New Session",
      "directory": "",
      "created_at": 0,
      "updated_at": 0,
    }),
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
    "\{config.base_url}/sessions/\{session_id}",
    expect=@http.Text(fn(result) {
      match result {
        Ok(_) => dispatch(SSESessionDeleted(session_id))
        Err(msg) => dispatch(GotSessions(Err(msg)))
      }
    }),
  )
}

// --- Agents ---

///|
pub fn api_load_agents(
  dispatch : @cmd.Dispatch[Msg],
  config : ServerConfig,
) -> @cmd.Cmd {
  @http.get(
    "\{config.base_url}/agents",
    expect=@http.Json(
      fn(result) {
        match result {
          Ok(json) =>
            match decode_agents(json) {
              Ok(agents) => dispatch(GotAgents(Ok(agents)))
              Err(e) => dispatch(GotAgents(Err(e)))
            }
          Err(msg) => dispatch(GotAgents(Err(msg)))
        }
      },
      fn(json) { Ok(json) },
    ),
  )
}

// --- Projects ---

///|
pub fn api_load_projects(
  dispatch : @cmd.Dispatch[Msg],
  config : ServerConfig,
) -> @cmd.Cmd {
  @http.get(
    "\{config.base_url}/projects",
    expect=@http.Json(
      fn(result) {
        match result {
          Ok(json) =>
            match decode_projects(json) {
              Ok(projects) => dispatch(GotProjects(Ok(projects)))
              Err(e) => dispatch(GotProjects(Err(e)))
            }
          Err(msg) => dispatch(GotProjects(Err(msg)))
        }
      },
      fn(json) { Ok(json) },
    ),
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
    "\{config.base_url}/sessions/\{session_id}/messages",
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
    "\{config.base_url}/sessions/\{session_id}/messages",
    @http.Body::Json({ "content": text, "role": "user", "agent_name": agent }),
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
