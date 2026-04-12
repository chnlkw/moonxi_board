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
pub fn toggle_star(sessions : Array[Session], id : String) -> Array[Session] {
  sessions.map(fn(s) {
    if s.id == id {
      { ..s, is_starred: !s.is_starred }
    } else {
      s
    }
  })
}

///|
pub fn update_session(
  sessions : Array[Session],
  updated : Session,
) -> Array[Session] {
  sessions.map(fn(s) { if s.id == updated.id { updated } else { s } })
}

///|
pub fn update_session_status(
  sessions : Array[Session],
  id : String,
  status : SessionStatus,
) -> Array[Session] {
  sessions.map(fn(s) { if s.id == id { { ..s, status, } } else { s } })
}

///|
pub fn append_message(
  model : Model,
  session_id : String,
  msg : ChatMessage,
) -> Model {
  match model.messages.get(session_id) {
    Some(Success(existing)) => {
      let _ = model.messages.set(session_id, Success(existing + [msg]))
      { ..model, messages: model.messages }
    }
    _ => {
      let _ = model.messages.set(session_id, Success([msg]))
      { ..model, messages: model.messages }
    }
  }
}

///|
pub fn active_session_title(model : Model) -> String {
  match model.sessions {
    Success(sessions) => {
      let found = sessions.filter(fn(s) { s.id == model.active_session_id })
      if found.length() > 0 {
        found[0].title
      } else {
        "No session"
      }
    }
    Loading | Failed(_) => "No session"
  }
}

///|
pub fn find_agent_by_name(agents : Array[Agent], name : String) -> Agent? {
  let found = agents.filter(fn(a) { a.name == name })
  if found.length() > 0 {
    Some(found[0])
  } else {
    None
  }
}

///|
pub fn connection_label(conn : ConnectionStatus) -> String {
  match conn {
    Disconnected => "○ Disconnected"
    Connecting => "◐ Connecting"
    Connected => "● Connected"
    Error(msg) => "✗ \{msg}"
  }
}

///|
pub fn agent_mode_label(mode : AgentMode) -> String {
  match mode {
    Primary => "Primary"
    Subagent => "Subagent"
    All => "All"
  }
}

///|
pub fn status_label(model : Model) -> String {
  let conn = connection_label(model.connection)
  let session_count = match model.sessions {
    Success(s) => "\{s.length()}"
    Loading => "Loading..."
    Failed(_) => "Error"
  }
  let agent_count = match model.agents {
    Success(a) => "\{a.length()}"
    Loading => "Loading..."
    Failed(_) => "Error"
  }
  "\{conn} | Sessions: \{session_count} | Agents: \{agent_count}"
}
