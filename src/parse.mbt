// === JSON Decoders ===

// --- Session ---

///|
pub fn decode_session(json : Json) -> Result[Session, String] {
  match json {
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
      "tools": tools_json,
      ..
    } : Json) => {
      let mode = decode_agent_mode(mode_json)
      let color = if color != "" { color } else { "#e94560" }
      let tools : Map[String, Bool] = {}
      Ok({ name, description: "", mode, color, model_id, tools })
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

///|
fn decode_message_part(json : Json) -> Result[MessagePart, String] {
  match json {
    ({ "type": String("text"), "text": String(str), .. } : Json) =>
      Ok(Text(str))
    ({
      "type": String("tool_call"),
      "tool_name": String(name),
      "input": String(input),
      "status": status_json,
      ..
    } : Json) => {
      let status = match status_json {
        String("running") => Running
        String("completed") => Completed
        String("failed") => Failed
        String("pending_approval") => PendingApproval
        _ => PendingApproval
      }
      Ok(ToolCall({ tool_name: name, input, status }))
    }
    ({ "type": String("step-start"), "step": String(step), .. } : Json) =>
      Ok(StepStart(step))
    ({ "type": String("step-finish"), "step": String(step), .. } : Json) =>
      Ok(StepFinish(step))
    _ => Ok(Text("unknown"))
  }
}

///|
pub fn decode_message(json : Json) -> Result[ChatMessage, String] {
  match json {
    ({
      "id": String(id),
      "session_id": String(sid),
      "role": String(role_str),
      "parts": Array(parts_json),
      "created_at": Number(ca),
      "model_id": String(model_id),
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
          Err(e) => return Err(e)
        }
      }
      Ok({ id, session_id: sid, role, parts, created_at: ca.to_int(), model_id })
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
          Err(e) => return Err(e)
        }
      }
      Ok(results)
    }
    _ => Err("invalid messages JSON")
  }
}
