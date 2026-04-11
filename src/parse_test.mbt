// === Parse Tests ===

///|
test "decode_session parses valid JSON" {
  let json : Json = {
    "id": "ses_1",
    "project_id": "/proj",
    "title": "Test",
    "directory": "/proj",
    "created_at": 123,
    "updated_at": 456,
  }
  let result = decode_session(json)
  assert_true(result is Ok(_))
  match result {
    Ok(s) => {
      assert_eq(s.id, "ses_1")
      assert_eq(s.project_id, "/proj")
      assert_eq(s.title, "Test")
      assert_eq(s.directory, "/proj")
      assert_eq(s.created_at, 123)
      assert_eq(s.updated_at, 456)
    }
    _ => ()
  }
}

///|
test "decode_session rejects invalid JSON" {
  let json : Json = { "id": "ses_1" }
  let result = decode_session(json)
  assert_true(result is Err(_))
}

///|
test "decode_sessions parses array" {
  let json : Json = [
    {
      "id": "ses_1",
      "project_id": "/p",
      "title": "S1",
      "directory": "/p",
      "created_at": 1,
      "updated_at": 1,
    },
    {
      "id": "ses_2",
      "project_id": "/p",
      "title": "S2",
      "directory": "/p",
      "created_at": 2,
      "updated_at": 2,
    },
  ]
  let result = decode_sessions(json)
  assert_true(result is Ok(_))
  match result {
    Ok(arr) => assert_eq(arr.length(), 2)
    _ => ()
  }
}

///|
test "decode_agent parses valid JSON" {
  let json : Json = {
    "name": "Sisyphus",
    "description": "Main agent",
    "mode": "primary",
    "color": "#ff0000",
    "model_id": "gpt-4",
    "tools": {},
  }
  let result = decode_agent(json)
  assert_true(result is Ok(_))
  match result {
    Ok(a) => {
      assert_eq(a.name, "Sisyphus")
      // description is ignored in decoder
      assert_eq(a.description, "")
      assert_true(a.mode is Primary)
      assert_eq(a.color, "#ff0000")
    }
    _ => ()
  }
}

///|
test "decode_agent defaults color and mode" {
  let json : Json = {
    "name": "Test",
    "description": "Test agent",
    "mode": "unknown",
    "color": "",
    "model_id": "model",
    "tools": {},
  }
  let result = decode_agent(json)
  assert_true(result is Ok(_))
  match result {
    Ok(a) => {
      assert_eq(a.color, "#e94560")
      assert_true(a.mode is All)
    }
    _ => ()
  }
}

///|
test "decode_agents parses array" {
  let json : Json = [
    {
      "name": "A1",
      "description": "",
      "mode": "primary",
      "color": "",
      "model_id": "",
      "tools": {},
    },
    {
      "name": "A2",
      "description": "",
      "mode": "subagent",
      "color": "",
      "model_id": "",
      "tools": {},
    },
  ]
  let result = decode_agents(json)
  assert_true(result is Ok(_))
  match result {
    Ok(arr) => assert_eq(arr.length(), 2)
    _ => ()
  }
}

///|
test "decode_project parses valid JSON" {
  let json : Json = {
    "id": "/proj",
    "name": "My Project",
    "directory": "/home/proj",
  }
  let result = decode_project(json)
  assert_true(result is Ok(_))
  match result {
    Ok(p) => {
      assert_eq(p.id, "/proj")
      assert_eq(p.name, "My Project")
      assert_eq(p.directory, "/home/proj")
    }
    _ => ()
  }
}

///|
test "decode_project rejects invalid JSON" {
  let json : Json = { "name": "No ID" }
  let result = decode_project(json)
  assert_true(result is Err(_))
}

///|
test "decode_message parses with parts" {
  let json : Json = {
    "id": "msg_1",
    "session_id": "ses_1",
    "role": "user",
    "parts": [
      { "type": "text", "text": "Hello" },
      { "type": "step-start", "step": "start" },
      { "type": "step-finish", "step": "finish" },
    ],
    "created_at": 100,
    "model_id": "gpt-4",
  }
  let result = decode_message(json)
  assert_true(result is Ok(_))
  match result {
    Ok(m) => {
      assert_eq(m.id, "msg_1")
      assert_true(m.role is User)
      assert_eq(m.parts.length(), 3)
    }
    _ => ()
  }
}

///|
test "decode_message parses tool_call part" {
  let json : Json = {
    "id": "msg_1",
    "session_id": "ses_1",
    "role": "assistant",
    "parts": [
      {
        "type": "tool_call",
        "tool_name": "bash",
        "input": "ls",
        "status": "completed",
      },
    ],
    "created_at": 100,
    "model_id": "gpt-4",
  }
  let result = decode_message(json)
  assert_true(result is Ok(_))
  match result {
    Ok(m) =>
      match m.parts[0] {
        ToolCall(info) => {
          assert_eq(info.tool_name, "bash")
          assert_eq(info.input, "ls")
          assert_true(info.status is Completed)
        }
        Text(_) => ()
        StepStart(_) => ()
        StepFinish(_) => ()
      }
    _ => ()
  }
}
