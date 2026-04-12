///|
extern "js" fn js_window_location_origin() -> String? =
  #|() => { try { var o = window.location.origin; return (o && typeof o === 'string') ? o : null } catch(e) { return null } }

///|
extern "js" fn js_console_log(msg : String) -> Unit =
  #|(msg) => { try { console.log("[moonxi]", msg) } catch(e) {} }

///|
pub fn log_error(msg : String) -> Unit {
  js_console_log("ERROR: " + msg)
}

///|
extern "js" fn js_localstorage_get(key : String) -> String? =
  #|(key) => { try { var v = localStorage.getItem(key); return (v !== null && v !== undefined && v !== '') ? v : null } catch(e) { return null } }

///|
extern "js" fn js_localstorage_set(key : String, val : String) -> Unit =
  #|(key, val) => { try { localStorage.setItem(key, val) } catch(e) {} }

///|
pub fn base_url() -> String {
  let stored = js_localstorage_get("moonxi_base_url")
  match stored {
    Some(url) => url
    None => {
      let origin = js_window_location_origin()
      match origin {
        Some(o) => o
        None => "http://localhost:4096"
      }
    }
  }
}

///|
pub fn save_base_url(url : String) -> Unit {
  js_localstorage_set("moonxi_base_url", url)
}

///|
pub fn toggle_star(
  sessions : Array[@types.Session],
  id : String,
) -> Array[@types.Session] {
  sessions.map(fn(s) {
    if s.id == id {
      @types.make_session(
        s.id,
        s.project_id,
        s.title,
        s.directory,
        s.status,
        s.created_at,
        s.updated_at,
        s.agent_name,
        !s.is_starred,
        s.unread_count,
      )
    } else {
      s
    }
  })
}

///|
pub fn update_session(
  sessions : Array[@types.Session],
  updated : @types.Session,
) -> Array[@types.Session] {
  sessions.map(fn(s) { if s.id == updated.id { updated } else { s } })
}

///|
pub fn update_session_status(
  sessions : Array[@types.Session],
  id : String,
  status : @types.SessionStatus,
) -> Array[@types.Session] {
  sessions.map(fn(s) {
    if s.id == id {
      @types.make_session(
        s.id,
        s.project_id,
        s.title,
        s.directory,
        status,
        s.created_at,
        s.updated_at,
        s.agent_name,
        s.is_starred,
        s.unread_count,
      )
    } else {
      s
    }
  })
}

///|
pub fn append_message(
  model : Model,
  session_id : String,
  msg : @types.ChatMessage,
) -> Model {
  match model.messages.get(session_id) {
    Some(@util.Success(existing)) => {
      let _ = model.messages.set(session_id, @util.Success(existing + [msg]))
      { ..model, messages: model.messages }
    }
    _ => {
      let _ = model.messages.set(session_id, @util.Success([msg]))
      { ..model, messages: model.messages }
    }
  }
}

///|
pub fn active_session_title(model : Model) -> String {
  match model.sessions {
    @util.Success(sessions) => {
      let found = sessions.filter(fn(s) { s.id == model.active_session_id })
      if found.length() > 0 {
        found[0].title
      } else {
        "No session"
      }
    }
    @util.Loading | @util.Failed(_) => "No session"
  }
}

///|
pub fn find_agent_by_name(
  agents : Array[@types.Agent],
  name : String,
) -> @types.Agent? {
  let found = agents.filter(fn(a) { a.name == name })
  if found.length() > 0 {
    Some(found[0])
  } else {
    None
  }
}

///|
pub fn connection_label(conn : @types.ConnectionStatus) -> String {
  match conn {
    @types.Disconnected => "○ Disconnected"
    @types.Connecting => "◐ Connecting"
    @types.Connected => "● Connected"
    @types.Error(msg) => "✗ \{msg}"
  }
}

///|
pub fn agent_mode_label(mode : @types.AgentMode) -> String {
  match mode {
    @types.Primary => "Primary"
    @types.Subagent => "Subagent"
    @types.All => "All"
  }
}

///|
pub fn status_label(model : Model) -> String {
  let conn = connection_label(model.connection)
  let session_count = match model.sessions {
    @util.Success(s) => "\{s.length()}"
    @util.Loading => "Loading..."
    @util.Failed(_) => "Error"
  }
  let agent_count = match model.agents {
    @util.Success(a) => "\{a.length()}"
    @util.Loading => "Loading..."
    @util.Failed(_) => "Error"
  }
  "\{conn} | Sessions: \{session_count} | Agents: \{agent_count}"
}
