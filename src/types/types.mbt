// === Server Config ===

///|
pub(all) struct ServerConfig {
  base_url : String
  username : String
  password : String
} derive(Show, Eq)

///|
pub fn make_server_config(
  base_url : String,
  username : String,
  password : String,
) -> ServerConfig {
  { base_url, username, password }
}

// === Connection ===

///|
pub(all) enum ConnectionStatus {
  Disconnected
  Connecting
  Connected
  Error(String)
} derive(Show, Eq)

// === Session ===

///|
pub(all) enum SessionStatus {
  Idle
  Busy
  Compacting
  Error
} derive(Show, Eq)

///|
pub(all) struct Session {
  id : String
  project_id : String
  title : String
  directory : String
  status : SessionStatus
  created_at : Int
  updated_at : Int
  agent_name : String
  is_starred : Bool
  unread_count : Int
} derive(Show, Eq)

///|
pub fn make_session(
  id : String,
  project_id : String,
  title : String,
  directory : String,
  status : SessionStatus,
  created_at : Int,
  updated_at : Int,
  agent_name : String,
  is_starred : Bool,
  unread_count : Int,
) -> Session {
  {
    id,
    project_id,
    title,
    directory,
    status,
    created_at,
    updated_at,
    agent_name,
    is_starred,
    unread_count,
  }
}

// === Message ===

///|
pub(all) enum MessageRole {
  User
  Assistant
} derive(Show, Eq)

///|
pub(all) enum ToolStatus {
  Running
  Completed
  Failed
  PendingApproval
} derive(Show, Eq)

///|
pub(all) struct ToolCallInfo {
  tool_name : String
  input : String
  status : ToolStatus
} derive(Show, Eq)

///|
pub fn make_tool_call_info(
  tool_name : String,
  input : String,
  status : ToolStatus,
) -> ToolCallInfo {
  { tool_name, input, status }
}

///|
pub(all) enum MessagePart {
  Text(String)
  ToolCall(ToolCallInfo)
  StepStart(String)
  StepFinish(String)
} derive(Show, Eq)

///|
pub(all) struct ChatMessage {
  id : String
  session_id : String
  role : MessageRole
  parts : Array[MessagePart]
  created_at : Int
  model_id : String
} derive(Show, Eq)

///|
pub fn make_chat_message(
  id : String,
  session_id : String,
  role : MessageRole,
  parts : Array[MessagePart],
  created_at : Int,
  model_id : String,
) -> ChatMessage {
  { id, session_id, role, parts, created_at, model_id }
}

// === Agent ===

///|
pub(all) enum AgentMode {
  Primary
  Subagent
  All
} derive(Show, Eq)

///|
pub(all) struct Agent {
  name : String
  description : String
  mode : AgentMode
  color : String
  model_id : String
  tools : Array[(String, Bool)]
} derive(Show, Eq)

///|
pub fn make_agent(
  name : String,
  description : String,
  mode : AgentMode,
  color : String,
  model_id : String,
  tools : Array[(String, Bool)],
) -> Agent {
  { name, description, mode, color, model_id, tools }
}

// === Project ===

///|
pub(all) struct Project {
  id : String
  name : String
  directory : String
} derive(Show, Eq)

///|
pub fn make_project(id : String, name : String, directory : String) -> Project {
  { id, name, directory }
}

// === Game Stats ===

///|
pub(all) struct GameStats {
  total_messages : Int
  combo_streak : Int
} derive(Show, Eq)

///|
pub fn make_game_stats(total_messages : Int, combo_streak : Int) -> GameStats {
  { total_messages, combo_streak }
}
