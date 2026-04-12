// === Server Config ===

///|
pub struct ServerConfig {
  base_url : String
  username : String
  password : String
} derive(Show)

// === Connection ===

///|
pub enum ConnectionStatus {
  Disconnected
  Connecting
  Connected
  Error(String)
} derive(Show)

// === Session ===

///|
pub enum SessionStatus {
  Idle
  Busy
  Compacting
  Error
} derive(Show)

///|
pub struct Session {
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
} derive(Show)

// === Message ===

///|
pub enum MessageRole {
  User
  Assistant
} derive(Show)

///|
pub enum ToolStatus {
  Running
  Completed
  Failed
  PendingApproval
} derive(Show)

///|
pub struct ToolCallInfo {
  tool_name : String
  input : String
  status : ToolStatus
} derive(Show)

///|
pub enum MessagePart {
  Text(String)
  ToolCall(ToolCallInfo)
  StepStart(String)
  StepFinish(String)
} derive(Show)

///|
pub struct ChatMessage {
  id : String
  session_id : String
  role : MessageRole
  parts : Array[MessagePart]
  created_at : Int
  model_id : String
} derive(Show)

// === Agent ===

///|
pub enum AgentMode {
  Primary
  Subagent
  All
} derive(Show)

///|
pub struct Agent {
  name : String
  description : String
  mode : AgentMode
  color : String
  model_id : String
  tools : Map[String, Bool]
} derive(Show)

// === Project ===

///|
pub struct Project {
  id : String
  name : String
  directory : String
} derive(Show)

// === Game Stats ===

///|
pub struct GameStats {
  total_messages : Int
  combo_streak : Int
} derive(Show)

// === Main Model ===

///|
pub struct Model {
  config : ServerConfig
  connection : ConnectionStatus
  projects : Array[Project]
  sessions : Array[Session]
  agents : Array[Agent]
  messages : Map[String, Array[ChatMessage]]
  active_session_id : String
  active_project_id : String
  selected_agent : String
  sidebar_open : Bool
  detail_open : Bool
  input_text : String
  search_query : String
  sse_connected : Bool
  stats : GameStats
  base_url_input : String
} derive(Show)

// === Msg ===

///|
pub enum Msg {
  AppStarted
  GotHealth(Result[String, String])
  GotSessions(Result[Array[Session], String])
  GotAgents(Result[Array[Agent], String])
  GotProjects(Result[Array[Project], String])
  SelectSession(String)
  GotMessages(String, Result[Array[ChatMessage], String])
  NewSessionClicked
  InputChanged(String)
  SendClicked
  MessageSent(Result[Array[ChatMessage], String])
  AgentSelected(String)
  ProjectSelected(String)
  SearchInputChanged(String)
  StarSession(String)
  DeleteSession(String)
  ToggleSidebar
  ToggleDetail
  SSEConnected
  SSEDisconnected
  SSEMessageUpdated(String, ChatMessage)
  SSESessionCreated(Session)
  SSESessionUpdated(Session)
  SSESessionDeleted(String)
  KeyPressed(String)
  BaseUrlChanged(String)
  BaseUrlSubmitted
}

// === Init ===

///|
pub fn init_model(config : ServerConfig) -> Model {
  {
    config,
    connection: Disconnected,
    projects: [],
    sessions: [],
    agents: [],
    messages: {},
    active_session_id: "",
    active_project_id: "",
    selected_agent: "",
    sidebar_open: true,
    detail_open: false,
    input_text: "",
    search_query: "",
    sse_connected: false,
    stats: { total_messages: 0, combo_streak: 0 },
    base_url_input: config.base_url,
  }
}
