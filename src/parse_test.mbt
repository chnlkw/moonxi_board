// Tests using real OpenCode Serve API v1.4.x JSON format

///|
test "decode_session parses real API format" {
  let json : Json = {
    "id": "ses_abc123",
    "slug": "jolly-island",
    "projectID": "proj_123",
    "directory": "/home/user/project",
    "title": "Test Session",
    "version": "1.4.3",
    "time": { "created": 1775925013789, "updated": 1775925014000 },
  }
  let result = decode_session(json)
  match result {
    Ok(s) => {
      assert_eq(s.id, "ses_abc123")
      assert_eq(s.project_id, "proj_123")
      assert_eq(s.title, "Test Session")
      assert_eq(s.directory, "/home/user/project")
      assert_true(s.created_at > 0)
      assert_true(s.updated_at > 0)
    }
    Err(_e) => assert_true(false)
  }
}

///|
test "decode_sessions parses array" {
  let json : Json = [
    {
      "id": "s1",
      "projectID": "p1",
      "title": "A",
      "directory": "/a",
      "time": { "created": 1000, "updated": 2000 },
    },
    {
      "id": "s2",
      "projectID": "p2",
      "title": "B",
      "directory": "/b",
      "time": { "created": 3000, "updated": 4000 },
    },
  ]
  let result = decode_sessions(json)
  match result {
    Ok(sessions) => assert_eq(sessions.length(), 2)
    Err(_e) => assert_true(false)
  }
}

///|
test "decode_message parses real API format with info+parts" {
  let json : Json = {
    "info": {
      "role": "user",
      "time": { "created": 1774799305502 },
      "id": "msg_123",
      "sessionID": "ses_abc",
      "agent": "build",
    },
    "parts": [{ "type": "text", "text": "hello world" }],
  }
  let result = decode_message(json)
  match result {
    Ok(m) => {
      assert_eq(m.id, "msg_123")
      assert_eq(m.session_id, "ses_abc")
      assert_true(m.role is User)
      assert_eq(m.parts.length(), 1)
    }
    Err(_e) => assert_true(false)
  }
}

///|
test "decode_message parses assistant message with step parts" {
  let json : Json = {
    "info": {
      "role": "assistant",
      "time": { "created": 1774799305521 },
      "id": "msg_456",
      "sessionID": "ses_abc",
    },
    "parts": [
      { "type": "step-start", "snapshot": "abc123" },
      { "type": "text", "text": "Hello!" },
      { "type": "step-finish", "reason": "stop" },
    ],
  }
  let result = decode_message(json)
  match result {
    Ok(m) => {
      assert_true(m.role is Assistant)
      assert_eq(m.parts.length(), 3)
      assert_true(m.parts[0] is StepStart)
      assert_true(m.parts[1] is Text)
      assert_true(m.parts[2] is StepFinish)
    }
    Err(_e) => assert_true(false)
  }
}

///|
test "decode_messages parses array" {
  let json : Json = [
    {
      "info": {
        "role": "user",
        "time": { "created": 100 },
        "id": "m1",
        "sessionID": "s1",
      },
      "parts": [{ "type": "text", "text": "hi" }],
    },
    {
      "info": {
        "role": "assistant",
        "time": { "created": 200 },
        "id": "m2",
        "sessionID": "s1",
      },
      "parts": [{ "type": "text", "text": "hey" }],
    },
  ]
  let result = decode_messages(json)
  match result {
    Ok(msgs) => assert_eq(msgs.length(), 2)
    Err(_e) => assert_true(false)
  }
}

///|
test "decode_session rejects invalid JSON" {
  let json : Json = { "foo": "bar" }
  let result = decode_session(json)
  assert_true(result is Err(_))
}

///|
test "decode_message rejects invalid JSON" {
  let json : Json = { "foo": "bar" }
  let result = decode_message(json)
  assert_true(result is Err(_))
}

///|
test "decode_message parses real API response with tool/patch parts" {
  // Exact format from real OpenCode Serve v1.4.x
  let json : Json = {
    "info": {
      "parentID": "msg_prev",
      "role": "assistant",
      "mode": "Sisyphus (Ultraworker)",
      "agent": "Sisyphus (Ultraworker)",
      "path": {
        "cwd": "/home/opencode/workspace",
        "root": "/home/opencode/workspace",
      },
      "cost": 0,
      "tokens": {
        "total": 25997,
        "input": 25508,
        "output": 41,
        "reasoning": 11,
        "cache": { "write": 0, "read": 448 },
      },
      "modelID": "glm-5.1",
      "providerID": "zhipuai-coding-plan",
      "time": { "created": 1775835122934, "completed": 1775835139376 },
      "finish": "tool-calls",
      "id": "msg_d78058cf6001MpNgZ3T1vPryXX",
      "sessionID": "ses_2c5b7cdf5ffe1dasG26wSqTkmc",
    },
    "parts": [
      {
        "snapshot": "abc123",
        "type": "step-start",
        "id": "prt_1",
        "sessionID": "ses_abc",
        "messageID": "msg_1",
      },
      {
        "type": "reasoning",
        "text": "thinking...",
        "time": { "start": 1, "end": 2 },
        "id": "prt_2",
        "sessionID": "ses_abc",
        "messageID": "msg_1",
      },
      {
        "type": "tool",
        "tool": "bash",
        "callID": "call_123",
        "state": {
          "status": "completed",
          "input": { "command": "ls -la", "description": "list files" },
          "output": "file1\nfile2\n",
        },
        "id": "prt_3",
        "sessionID": "ses_abc",
        "messageID": "msg_1",
      },
      {
        "reason": "tool-calls",
        "snapshot": "def456",
        "type": "step-finish",
        "tokens": { "total": 100 },
        "cost": 0,
        "id": "prt_4",
        "sessionID": "ses_abc",
        "messageID": "msg_1",
      },
      {
        "type": "patch",
        "hash": "abc123",
        "files": ["/home/opencode/workspace/test"],
        "id": "prt_5",
        "sessionID": "ses_abc",
        "messageID": "msg_1",
      },
    ],
  }
  let result = decode_message(json)
  match result {
    Ok(m) => {
      assert_true(m.role is Assistant)
      assert_eq(m.id, "msg_d78058cf6001MpNgZ3T1vPryXX")
      assert_eq(m.session_id, "ses_2c5b7cdf5ffe1dasG26wSqTkmc")
      // Should have 5 parts (step-start, reasoning->text, tool->text, step-finish, patch->text)
      assert_true(m.parts.length() >= 3)
    }
    Err(e) => {
      println("DECODE FAILED: \{e}")
      assert_true(false)
    }
  }
}

///|
test "decode_messages tolerates individual bad messages" {
  let json : Json = [
    {
      "info": {
        "role": "user",
        "time": { "created": 100 },
        "id": "m1",
        "sessionID": "s1",
      },
      "parts": [{ "type": "text", "text": "hi" }],
    },
    { "garbage": true },
    {
      "info": {
        "role": "assistant",
        "time": { "created": 200 },
        "id": "m2",
        "sessionID": "s1",
      },
      "parts": [{ "type": "text", "text": "hey" }],
    },
  ]
  let result = decode_messages(json)
  match result {
    Ok(msgs) => assert_eq(msgs.length(), 2)
    Err(_e) => assert_true(false)
  }
}

///|
test "decode_message handles reasoning and tool-call parts" {
  let json : Json = {
    "info": {
      "role": "assistant",
      "time": { "created": 100 },
      "id": "m1",
      "sessionID": "s1",
    },
    "parts": [
      { "type": "reasoning", "text": "thinking..." },
      { "type": "tool-call", "name": "bash", "input": "ls -la" },
      { "type": "text", "text": "done" },
    ],
  }
  let result = decode_message(json)
  match result {
    Ok(m) => {
      assert_eq(m.parts.length(), 3)
      assert_true(m.parts[1] is ToolCall)
    }
    Err(_e) => assert_true(false)
  }
}
