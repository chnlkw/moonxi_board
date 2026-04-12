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
pub fn decode_session(json : Json) -> Result[@types.Session, String] {
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
      Ok(
        @types.make_session(
          id,
          pid,
          title,
          dir,
          @types.Idle,
          created_at,
          updated_at,
          "",
          false,
          0,
        ),
      )
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
      Ok(
        @types.make_session(
          id,
          pid,
          title,
          dir,
          @types.Idle,
          ca.to_int(),
          ua.to_int(),
          "",
          false,
          0,
        ),
      )
    _ => Err("invalid session JSON")
  }
}

///|
pub fn decode_sessions(json : Json) -> Result[Array[@types.Session], String] {
  match json {
    Array(items) => {
      let results : Array[@types.Session] = []
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
fn decode_agent_mode(json : Json) -> @types.AgentMode {
  match json {
    String("primary") => @types.Primary
    String("subagent") => @types.Subagent
    _ => @types.All
  }
}

///|
pub fn decode_agent(json : Json) -> Result[@types.Agent, String] {
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
      Ok(@types.make_agent(name, "", mode, c, model_id, []))
    }
    _ => Err("invalid agent JSON")
  }
}

///|
pub fn decode_agents(json : Json) -> Result[Array[@types.Agent], String] {
  match json {
    Array(items) => {
      let results : Array[@types.Agent] = []
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
pub fn decode_project(json : Json) -> Result[@types.Project, String] {
  match json {
    ({ "id": String(id), "name": String(name), "directory": String(dir), .. } : Json) =>
      Ok(@types.make_project(id, name, dir))
    _ => Err("invalid project JSON")
  }
}

///|
pub fn decode_projects(json : Json) -> Result[Array[@types.Project], String] {
  match json {
    Array(items) => {
      let results : Array[@types.Project] = []
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
fn decode_message_part(json : Json) -> Result[@types.MessagePart, String] {
  match json {
    ({ "type": String("text"), "text": String(str), .. } : Json) =>
      Ok(@types.Text(str))
    ({
      "type": String("tool_call"),
      "tool_name": String(name),
      "input": String(input),
      ..
    } : Json) =>
      Ok(
        @types.ToolCall(
          @types.make_tool_call_info(name, input, @types.Completed),
        ),
      )
    ({
      "type": String("tool-call"),
      "name": String(name),
      "input": String(input),
      ..
    } : Json) =>
      Ok(
        @types.ToolCall(
          @types.make_tool_call_info(name, input, @types.Completed),
        ),
      )
    ({ "type": String("step-start"), .. } : Json) =>
      Ok(@types.StepStart("step"))
    ({ "type": String("step-finish"), .. } : Json) =>
      Ok(@types.StepFinish("step"))
    ({ "type": String("reasoning"), .. } : Json) =>
      Ok(@types.Text("💭 reasoning..."))
    // Real API: type "tool" with nested state object
    ({ "type": String("tool"), "tool": String(name), .. } : Json) =>
      Ok(
        @types.ToolCall(
          @types.make_tool_call_info(name, "(tool call)", @types.Completed),
        ),
      )
    // Real API: type "patch" (file changes)
    ({ "type": String("patch"), .. } : Json) => Ok(@types.Text(""))
    // Skip unknown types
    _ => Ok(@types.Text(""))
  }
}

///|
pub fn decode_message(json : Json) -> Result[@types.ChatMessage, String] {
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
        "user" => @types.User
        "assistant" => @types.Assistant
        _ => @types.User
      }
      let created_at = extract_time_created(time_json)
      let parts : Array[@types.MessagePart] = []
      for p in parts_json {
        match decode_message_part(p) {
          Ok(part) => parts.push(part)
          Err(_) => () // skip invalid parts
        }
      }
      Ok(@types.make_chat_message(mid, sid, role, parts, created_at, ""))
    }
    // Fallback: flat format
    ({
      "id": String(id),
      "role": String(role_str),
      "parts": Array(parts_json),
      ..
    } : Json) => {
      let role = match role_str {
        "user" => @types.User
        "assistant" => @types.Assistant
        _ => @types.User
      }
      let parts : Array[@types.MessagePart] = []
      for p in parts_json {
        match decode_message_part(p) {
          Ok(part) => parts.push(part)
          Err(_) => ()
        }
      }
      Ok(@types.make_chat_message(id, "", role, parts, 0, ""))
    }
    _ => Err("invalid message JSON")
  }
}

///|
pub fn decode_messages(
  json : Json,
) -> Result[Array[@types.ChatMessage], String] {
  match json {
    Array(items) => {
      let results : Array[@types.ChatMessage] = []
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
