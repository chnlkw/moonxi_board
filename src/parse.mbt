// === JSON Decoders for OpenCode Serve API (v1.4.x) ===

// --- Session ---
// Real API format:
// {"id","slug","projectID","directory","title","version","time":{"created":ms,"updated":ms},"summary":{...}}

///|
fn number_to_int(json : Json) -> Int {
  match json {
    Number(n) => n.to_int()
    _ => 0
  }
}

///|
fn extract_time_created(json : Json) -> Int {
  match json {
    ({ "created": Number(n), .. } : Json) => n.to_int()
    ({ "created": String(_), .. } : Json) => 0
    _ => 0
  }
}

///|
fn extract_time_updated(json : Json) -> Int {
  match json {
    ({ "updated": Number(n), .. } : Json) => n.to_int()
    ({ "updated": String(_), .. } : Json) => 0
    _ => 0
  }
}

///|
pub fn decode_session(json : Json) -> Result[Session, String] {
  match json {
    ({
      "id": String(id),
      "projectID": String(pid),
      "title": String(title),
      "directory": String(dir),
      "time": time_json,
      ..
    } : Json) => {
      let created_at = extract_time_created(time_json)
      let updated_at = extract_time_updated(time_json)
      Ok({
        id,
        project_id: pid,
        title,
        directory: dir,
        status: Idle,
        created_at,
        updated_at,
        agent_name: "",
        is_starred: false,
        unread_count: 0,
      })
    }
    // Fallback: try snake_case fields (old format)
    ({
      "id": String(id),
      "project_id": String(pid),
      "title": String(title),
      "directory": String(dir),
      "created_at": Number(ca),
      "updated_at": Number(ua),
      ..
    } : Json) =>
      Ok({
        id,
        project_id: pid,
        title,
        directory: dir,
        status: Idle,
        created_at: ca.to_int(),
        updated_at: ua.to_int(),
        agent_name: "",
        is_starred: false,
        unread_count: 0,
      })
    _ => Err("invalid session JSON")
  }
}

///|
pub fn decode_sessions(json : Json) -> Result[Array[Session], String] {
  match json {
    Array(items) => {
      let results : Array[Session] = []
      for item in items {
        match decode_session(item) {
          Ok(s) => results.push(s)
          Err(e) => return Err(e)
        }
      }
      Ok(results)
    }
    _ => Err("invalid sessions JSON")
  }
}

// --- Agent ---

///|
fn decode_agent_mode(json : Json) -> AgentMode {
  match json {
    String("primary") => Primary
    String("subagent") => Subagent
    _ => All
  }
}

///|
pub fn decode_agent(json : Json) -> Result[Agent, String] {
  match json {
    ({
      "name": String(name),
      "description": String(_),
      "mode": mode_json,
      "color": String(color),
      "model_id": String(model_id),
      ..
    } : Json) => {
      let mode = decode_agent_mode(mode_json)
      let c = if color != "" { color } else { "#e94560" }
      Ok({ name, description: "", mode, color: c, model_id, tools: {} })
    }
    _ => Err("invalid agent JSON")
  }
}

///|
pub fn decode_agents(json : Json) -> Result[Array[Agent], String] {
  match json {
    Array(items) => {
      let results : Array[Agent] = []
      for item in items {
        match decode_agent(item) {
          Ok(a) => results.push(a)
          Err(e) => return Err(e)
        }
      }
      Ok(results)
    }
    _ => Err("invalid agents JSON")
  }
}

// --- Project ---

///|
pub fn decode_project(json : Json) -> Result[Project, String] {
  match json {
    ({ "id": String(id), "name": String(name), "directory": String(dir), .. } : Json) =>
      Ok({ id, name, directory: dir })
    _ => Err("invalid project JSON")
  }
}

///|
pub fn decode_projects(json : Json) -> Result[Array[Project], String] {
  match json {
    Array(items) => {
      let results : Array[Project] = []
      for item in items {
        match decode_project(item) {
          Ok(p) => results.push(p)
          Err(e) => return Err(e)
        }
      }
      Ok(results)
    }
    _ => Err("invalid projects JSON")
  }
}

// --- Message ---
// Real API format:
// {"info":{"role":"user","time":{"created":ms},"id":"msg_...","sessionID":"ses_...","agent":"...","model":{...}},"parts":[...]}
// parts: [{"type":"text","text":"..."}, {"type":"step-start","snapshot":"..."}, {"type":"step-finish","reason":"..."}, {"type":"reasoning","text":"..."}, {"type":"tool-call",...}]

///|
fn decode_message_part(json : Json) -> Result[MessagePart, String] {
  match json {
    ({ "type": String("text"), "text": String(str), .. } : Json) =>
      Ok(Text(str))
    ({
      "type": String("tool_call"),
      "tool_name": String(name),
      "input": String(input),
      ..
    } : Json) => Ok(ToolCall({ tool_name: name, input, status: Completed }))
    ({
      "type": String("tool-call"),
      "name": String(name),
      "input": String(input),
      ..
    } : Json) => Ok(ToolCall({ tool_name: name, input, status: Completed }))
    ({ "type": String("step-start"), .. } : Json) => Ok(StepStart("step"))
    ({ "type": String("step-finish"), .. } : Json) => Ok(StepFinish("step"))
    ({ "type": String("reasoning"), .. } : Json) =>
      Ok(Text("💭 reasoning..."))
    // Real API: type "tool" with nested state object
    ({ "type": String("tool"), "tool": String(name), .. } : Json) =>
      Ok(ToolCall({ tool_name: name, input: "(tool call)", status: Completed }))
    // Real API: type "patch" (file changes)
    ({ "type": String("patch"), .. } : Json) => Ok(Text(""))
    // Skip unknown types
    _ => Ok(Text(""))
  }
}

///|
pub fn decode_message(json : Json) -> Result[ChatMessage, String] {
  match json {
    // Real OpenCode Serve format: info + parts at top level
    ({
      "info": ({
        "role": String(role_str),
        "time": time_json,
        "id": String(mid),
        "sessionID": String(sid),
        ..
      } : Json),
      "parts": Array(parts_json),
      ..
    } : Json) => {
      let role = match role_str {
        "user" => User
        "assistant" => Assistant
        _ => User
      }
      let created_at = extract_time_created(time_json)
      let parts : Array[MessagePart] = []
      for p in parts_json {
        match decode_message_part(p) {
          Ok(part) => parts.push(part)
          Err(_) => () // skip invalid parts
        }
      }
      Ok({ id: mid, session_id: sid, role, parts, created_at, model_id: "" })
    }
    // Fallback: flat format
    ({
      "id": String(id),
      "role": String(role_str),
      "parts": Array(parts_json),
      ..
    } : Json) => {
      let role = match role_str {
        "user" => User
        "assistant" => Assistant
        _ => User
      }
      let parts : Array[MessagePart] = []
      for p in parts_json {
        match decode_message_part(p) {
          Ok(part) => parts.push(part)
          Err(_) => ()
        }
      }
      Ok({ id, session_id: "", role, parts, created_at: 0, model_id: "" })
    }
    _ => Err("invalid message JSON")
  }
}

///|
pub fn decode_messages(json : Json) -> Result[Array[ChatMessage], String] {
  match json {
    Array(items) => {
      let results : Array[ChatMessage] = []
      for item in items {
        match decode_message(item) {
          Ok(m) => results.push(m)
          Err(_) => () // Skip individual failures, keep good messages
        }
      }
      Ok(results)
    }
    _ => Err("invalid messages JSON")
  }
}
