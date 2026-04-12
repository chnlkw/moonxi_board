// === Main Model ===

///|
pub struct Model {
  config : @types.ServerConfig
  connection : @types.ConnectionStatus
  projects : @util.Status[Array[@types.Project]]
  sessions : @util.Status[Array[@types.Session]]
  agents : @util.Status[Array[@types.Agent]]
  messages : Map[String, @util.Status[Array[@types.ChatMessage]]]
  active_session_id : String
  active_project_id : String
  selected_agent : String
  sidebar_open : Bool
  detail_open : Bool
  input_text : String
  search_query : String
  sse_connected : Bool
  stats : @types.GameStats
  base_url_input : String
} derive(Show)

// === Msg ===

///|
pub enum Msg {
  AppStarted
  GotHealth(Result[String, String])
  GotSessions(Result[Array[@types.Session], String])
  GotAgents(Result[Array[@types.Agent], String])
  GotProjects(Result[Array[@types.Project], String])
  SelectSession(String)
  GotMessages(String, Result[Array[@types.ChatMessage], String])
  NewSessionClicked
  InputChanged(String)
  SendClicked
  MessageSent(Result[Array[@types.ChatMessage], String])
  AgentSelected(String)
  ProjectSelected(String)
  SearchInputChanged(String)
  StarSession(String)
  DeleteSession(String)
  ToggleSidebar
  ToggleDetail
  SSEConnected
  SSEDisconnected
  SSEMessageUpdated(String, @types.ChatMessage)
  SSESessionCreated(@types.Session)
  SSESessionUpdated(@types.Session)
  SSESessionDeleted(String)
  KeyPressed(String)
  BaseUrlChanged(String)
  BaseUrlSubmitted
}

// === Init ===

///|
pub fn init_model(config : @types.ServerConfig) -> Model {
  {
    config,
    connection: @types.Disconnected,
    projects: @util.Success([]),
    sessions: @util.Loading,
    agents: @util.Success([]),
    messages: {},
    active_session_id: "",
    active_project_id: "",
    selected_agent: "",
    sidebar_open: true,
    detail_open: false,
    input_text: "",
    search_query: "",
    sse_connected: false,
    stats: @types.make_game_stats(0, 0),
    base_url_input: config.base_url,
  }
}
