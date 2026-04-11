# Moonxi Board - 多 Agent 看板应用设计文档

> POC 版本 v2 (Rabbita 架构) | 2026-04-10

---

## 1. 项目概述

**Moonxi Board** 是一个多 Agent 看板应用，界面风格类似微信聊天，用于管理多个 AI Agent、多个 Project 的会话交互。

**核心定位**: 游戏化的 Agent 管理看板 —— 把多 Agent 协作当成「组队打副本」来设计。

### 1.1 技术栈

| 层 | 技术 | 说明 |
|---|---|---|
| UI 框架 | **Rabbita** (moonbit-community/rabbita) | TEA 架构，声明式 HTML EDSL，~15KB gzip |
| 语言 | **MoonBit** (JS Backend) | 编译为 JS，类型安全，模式匹配 |
| 后端 API | **OpenCode Serve** | `opencode serve` 本地 HTTP API |
| 实时通信 | SSE (Server-Sent Events) | 封装为 Rabbita custom subscription |
| 构建 | moon build + 静态服务器 | 无需 Vite/Webpack |

### 1.2 为什么选 Rabbita

| 理由 | 说明 |
|---|---|
| 全 MoonBit | 砍掉 JS Bridge 层，UI + 逻辑全在 MoonBit 中，类型安全 |
| TEA 架构 | Model/View/Update 单向数据流，状态可预测 |
| 内置 HTTP | `@http.get/post` 直接调用 OpenCode API |
| 内置 Subscriptions | 定时器、键盘、鼠标、resize 等 UI 事件开箱即用 |
| Cell 模块化 | Sidebar/Chat/Detail 各自独立 Cell，互不干扰 |
| 极轻量 | ~15KB min+gzip，含 VDOM + 标准库 |
| 生产验证 | mooncakes.io 已用 Rabbita 重写 |

### 1.3 POC 范围

1. 连接 `opencode serve` API（健康检查、会话列表、发送消息）
2. 微信风格聊天界面（消息气泡、会话列表）
3. 多 Agent 切换对话
4. 多 Project 管理
5. SSE 实时消息流（custom subscription）
6. Rabbita Cell 架构验证

---

## 2. 系统架构

### 2.1 TEA 架构全景

```
┌──────────────────────────────────────────────────────────────────┐
│                         Browser                                  │
│                                                                  │
│   ┌──────────┐    Msg     ┌───────────┐   (model, cmd)          │
│   │   View   │ ──────────>│  Update   │ ──────────┐              │
│   │ (Html[]) │            │ (纯函数)  │            │              │
│   └────┬─────┘            └───────────┘            ▼              │
│        │                                        ┌────────┐       │
│   VDOM diff/patch                              │  Model  │       │
│        │                                        └───┬────┘       │
│        ▼                                            │            │
│   ┌─────────┐            ┌───────────┐              │            │
│   │  DOM    │ <──────────│ Rabbita   │◄─────────────┘            │
│   │ (渲染)  │   patch    │ Runtime   │                            │
│   └─────────┘            └─────┬─────┘                            │
│                                │ 执行 Cmd                         │
│                    ┌───────────┼───────────┐                      │
│                    ▼           ▼           ▼                      │
│              ┌─────────┐ ┌─────────┐ ┌──────────┐                │
│              │ @http   │ │  SSE    │ │ @sub.*   │                │
│              │ (fetch) │ │ (custom)│ │ (内置订阅)│                │
│              └────┬────┘ └────┬────┘ └────┬─────┘                │
│                   │           │           │  触发 Msg              │
│                   └───────────┴───────────┘                      │
└──────────────────────────────┬───────────────────────────────────┘
                               │ HTTP + SSE
┌──────────────────────────────▼───────────────────────────────────┐
│                   OpenCode Serve (localhost:4096)                  │
│                                                                    │
│   GET/POST /session             → 会话管理                        │
│   GET/POST /session/:id/message → 消息收发                        │
│   GET     /global/event         → SSE 实时事件流                  │
│   GET     /agent                → Agent 列表                      │
│   GET     /project              → Project 列表                    │
│   GET     /global/health        → 健康检查                        │
└────────────────────────────────────────────────────────────────────┘
```

### 2.2 Cell 模块划分

```
                    ┌─────────────────────┐
                    │     App (root)      │
                    │  Model: AppState    │
                    └─────────┬───────────┘
                              │
            ┌─────────────────┼──────────────────┐
            ▼                 ▼                  ▼
   ┌──────────────┐  ┌──────────────┐  ┌──────────────┐
   │  SidebarCell │  │   ChatCell   │  │ DetailCell   │
   │              │  │              │  │              │
   │ Model:       │  │ Model:       │  │ Model:       │
   │  sessions[]  │  │  messages[]  │  │  agent?      │
   │  projects[]  │  │  input_text  │  │  stats       │
   │  search      │  │  streaming   │  │  permissions │
   │              │  │              │  │              │
   │ Msg:         │  │ Msg:         │  │ Msg:         │
   │  SelectSes   │  │  SendMsg     │  │  TogglePanel │
   │  SearchSes   │  │  InputChange │  │  ExpandTool  │
   │  NewSession  │  │  ScrollMsgs  │  │              │
   │  StarSession │  │  GotMessages │  │              │
   └──────────────┘  └──────────────┘  └──────────────┘
```

---

## 3. 界面设计

### 3.1 整体布局（微信风格三栏）

```
┌─────────────────────────────────────────────────────────────────┐
│  🔴 🟡 🟢   Moonxi Board                    ─ □ ✕            │
├────────┬───────────────────────────────────┬───────────────────┤
│        │                                   │                   │
│ 🔍搜索 │  🤖 Sisyphus (build)             │  Agent 详情       │
│────────│────────────────────────────────── │───────────────────│
│ ⭐ 收藏 │                                   │  名称: Sisyphus   │
│        │  ┌──────────────────────┐         │  模式: primary    │
│ 💬 会话 │  │ 🧑 你:              │         │  模型: claude-3.5 │
│ ├ Proj1 │  │ 帮我实现JWT认证     │         │                   │
│ │ ├ Ses1│  └──────────────────────┘         │  权限:           │
│ │ ├ Ses2│                                   │  ✏️ 编辑: ask     │
│ │ └ Ses3│  ┌──────────────────────┐         │  💻 Bash: allow  │
│ ├ Proj2 │  │ 🤖 Sisyphus:        │         │                   │
│ │ └ Ses4│  │ 好的，我来实现JWT   │         │  工具:           │
│        │  │ 认证中间件...        │         │  ✅ filesystem    │
│ 🤖 Agent│  │ ▓▓▓▓▓░░░░ 60%      │         │  ✅ bash         │
│        │  └──────────────────────┘         │  ✅ webfetch     │
│ ⚙️ 设置 │                                   │                   │
│        │  ┌──────────────────────┐         │  ── 会话统计 ──  │
│        │  │ 🔧 Tool: edit_file  │         │  Token: 2.4k     │
│        │  │ 编辑 src/auth.mbt   │         │  消息: 12        │
│        │  │ +15 -3              │         │  耗时: 45s       │
│        │  └──────────────────────┘         │                   │
│        │                                   │                   │
│        │────────────────────────────────── │                   │
│        │ [🤖选择Agent] [📎] 输入消息... [➤]│                   │
├────────┴───────────────────────────────────┴───────────────────┤
│  ● Connected | Sessions: 5 | Agents: 4 | Project: moonxi_board│
└─────────────────────────────────────────────────────────────────┘
```

### 3.2 核心交互

#### 会话列表 (SidebarCell)
- 按 Project 分组显示会话
- 每个会话项显示: Agent 头像、会话标题、最后消息摘要、时间
- 未读消息红点
- 会话状态指示器: 🟢空闲 🟡思考中 🔴执行中
- 支持搜索、收藏、新建会话

#### 聊天面板 (ChatCell)
- 消息气泡: 用户消息右侧蓝色、Agent 消息左侧灰色
- Tool 调用折叠显示（可展开查看详情）
- 流式输出（SSE 驱动，逐字显示）
- 消息操作: 复制、重试、fork、revert

#### 输入区域
- Agent 选择器（下拉选择当前对话 Agent）
- 文本输入框（支持多行）
- 发送按钮
- 斜杠命令支持（/command）

### 3.3 游戏化元素

| 元素 | 设计 | 说明 |
|---|---|---|
| Agent 角色 | 每个 Agent 一个头像+职业标签 | Sisyphus=⚔️战士, Oracle=🔮法师, Explore=🗡️盗贼, Librarian=📚学者 |
| 会话 = 任务 | 会话标题前加 ⚔️📋🔧 等任务图标 | 不同类型任务不同图标 |
| 进度条 | Agent 执行时显示进度 | 基于 tool 调用步骤估算 |
| 成就系统 | 记录里程碑 | 首次成功部署=🏆, 0错误通过=⭐ |
| 连击计数 | 连续成功执行不中断 | 显示 🔥 combo streak |

---

## 4. 数据模型 (MoonBit)

### 4.1 核心类型

```moonbit
// === 连接配置 ===
struct ServerConfig {
  base_url : String      // "http://localhost:4096"
  username : String      // "opencode"
  password : String
} derive(Show, Eq)

// === 会话 ===
struct Session {
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

enum SessionStatus {
  Idle
  Busy
  Compacting
  Error
} derive(Show, Eq)

// === 消息 ===
struct ChatMessage {
  id : String
  session_id : String
  role : MessageRole
  parts : Array[MessagePart]
  created_at : Int
  model_id : String
} derive(Show, Eq)

enum MessageRole {
  User
  Assistant
} derive(Show, Eq)

// === 消息部件 ===
enum MessagePart {
  Text(String)
  ToolCall(ToolCallInfo)
  ToolResult(ToolResultInfo)
  StepStart(String)
  StepFinish(String)
  Reasoning(String)
  FileDiff(FileDiffInfo)
  Subtask(SubtaskInfo)
} derive(Show, Eq)

struct ToolCallInfo {
  tool_name : String
  input : String
  status : ToolStatus
} derive(Show, Eq)

enum ToolStatus {
  Running
  Completed
  Failed
  PendingApproval
} derive(Show, Eq)

struct ToolResultInfo {
  tool_name : String
  output : String
  success : Bool
} derive(Show, Eq)

struct FileDiffInfo {
  file_path : String
  additions : Int
  deletions : Int
  content : String
} derive(Show, Eq)

struct SubtaskInfo {
  agent : String
  description : String
  prompt : String
} derive(Show, Eq)

// === Agent ===
struct Agent {
  name : String
  description : String
  mode : AgentMode
  color : String
  model_id : String
  tools : Map[String, Bool]
} derive(Show, Eq)

enum AgentMode {
  Primary
  Subagent
  All
} derive(Show, Eq)

// === Project ===
struct Project {
  id : String
  name : String
  directory : String
} derive(Show, Eq)
```

### 4.2 App Model (Rabbita State)

```moonbit
// App 全局状态
struct Model {
  // 连接
  config : ServerConfig
  connection : ConnectionStatus

  // 数据
  projects : Array[Project]
  sessions : Array[Session]
  agents : Array[Agent]
  messages : Map[String, Array[ChatMessage]]  // sessionId → messages

  // UI 状态
  active_session_id : String
  active_project_id : String
  selected_agent : String
  sidebar_open : Bool
  detail_open : Bool
  input_text : String
  search_query : String

  // SSE
  sse_connected : Bool

  // 游戏化
  stats : GameStats
} derive(Show)

enum ConnectionStatus {
  Disconnected
  Connecting
  Connected
  Error(String)
} derive(Show, Eq)

struct GameStats {
  total_messages : Int
  combo_streak : Int
  achievements : Array[Achievement]
} derive(Show, Eq)

struct Achievement {
  id : String
  title : String
  icon : String
  unlocked_at : Int
} derive(Show, Eq)
```

### 4.3 Msg 枚举 (所有事件)

```moonbit
enum Msg {
  // ====== 初始化 ======
  AppStarted
  GotHealth(Result[String, String])
  GotSessions(Result[Array[Session], String])
  GotAgents(Result[Array[Agent], String])
  GotProjects(Result[Array[Project], String])

  // ====== 会话操作 ======
  SelectSession(String)                       // session_id
  GotMessages(String, Result[Array[ChatMessage], String])  // session_id, result
  NewSessionClicked
  SessionCreated(Result[Session, String])
  DeleteSession(String)                       // session_id
  SessionDeleted(Result[String, String])
  StarSession(String)                         // session_id
  SearchInputChanged(String)

  // ====== 聊天操作 ======
  InputChanged(String)
  SendClicked
  MessageSent(Result[Array[ChatMessage], String])
  AgentSelected(String)                       // agent_name
  CommandEntered(String)                      // /command text

  // ====== Project 操作 ======
  ProjectSelected(String)                     // project_id
  FilterByProject(String)                     // project_id or ""

  // ====== SSE 实时事件 ======
  SSEConnected
  SSEDisconnected
  SSESessionCreated(Session)
  SSESessionUpdated(Session)
  SSESessionDeleted(String)
  SSESessionStatusChanged(String, SessionStatus)
  SSEMessageUpdated(String, ChatMessage)      // session_id, message
  SSEMessagePartUpdated(String, MessagePart)  // session_id, part

  // ====== UI 操作 ======
  ToggleSidebar
  ToggleDetail
  ToggleSettings
  KeyPressed(String)                          // keyboard shortcut

  // ====== 游戏化 ======
  AchievementUnlocked(Achievement)
  ComboIncremented
  ComboReset
}
```

---

## 5. Rabbita 实现

### 5.1 App 入口

```moonbit
// main.mbt

///|
fn main {
  let config = {
    base_url: "http://localhost:4096",
    username: "opencode",
    password: "",
  }
  let model = init_model(config)
  let app = @rabbita.cell(
    model~,
    update~,
    view~,
    subscriptions~,
  )
  @rabbita.new(app).mount("app")
}

///|
fn init_model(config : ServerConfig) -> Model {
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
    stats: { total_messages: 0, combo_streak: 0, achievements: [] },
  }
}
```

### 5.2 Update (核心逻辑)

```moonbit
// update.mbt

///|
fn update(dispatch : Dispatch[Msg], msg : Msg, model : Model) -> (Cmd, Model) {
  match msg {
    // ====== 初始化 ======
    AppStarted => (
      @cmd.batch([
        api_health_check(dispatch),
        api_load_sessions(dispatch),
        api_load_agents(dispatch),
        api_load_projects(dispatch),
      ]),
      { model with connection: Connecting },
    )
    GotHealth(Ok(version)) => (none(), { model with connection: Connected })
    GotHealth(Err(_)) => (none(), { model with connection: Error("unreachable") })
    GotSessions(Ok(sessions)) => (
      none(),
      { model with sessions },
    )
    GotSessions(Err(msg)) => (none(), model) // TODO: error toast
    GotAgents(Ok(agents)) => (
      none(),
      { model with agents, selected_agent: first_agent_name(agents) },
    )
    GotAgents(Err(_)) => (none(), model)
    GotProjects(Ok(projects)) => (
      none(),
      { model with projects, active_project_id: first_project_id(projects) },
    )
    GotProjects(Err(_)) => (none(), model)

    // ====== 会话操作 ======
    SelectSession(id) => (
      api_load_messages(dispatch, id),
      { model with active_session_id: id },
    )
    GotMessages(session_id, Ok(messages)) => (
      none(),
      { model with messages: model.messages.set(session_id, messages) },
    )
    GotMessages(_, Err(_)) => (none(), model)
    NewSessionClicked => (api_create_session(dispatch, model), model)
    SessionCreated(Ok(session)) => (
      api_load_sessions(dispatch),
      { model with active_session_id: session.id },
    )
    SessionCreated(Err(_)) => (none(), model)
    DeleteSession(id) => (api_delete_session(dispatch, id), model)
    SessionDeleted(Ok(_)) => (api_load_sessions(dispatch), model)
    SessionDeleted(Err(_)) => (none(), model)
    StarSession(id) => (none(), toggle_star(model, id))
    SearchInputChanged(query) => (none(), { model with search_query: query })

    // ====== 聊天操作 ======
    InputChanged(text) => (none(), { model with input_text: text })
    SendClicked => {
      if model.input_text == "" || model.active_session_id == "" {
        (none(), model)
      } else {
        (
          api_send_message(
            dispatch, model.active_session_id,
            model.input_text, model.selected_agent,
          ),
          { model with input_text: "" },
        )
      }
    }
    MessageSent(Ok(messages)) => (
      none(),
      {
        model with
          messages: model.messages.set(model.active_session_id, messages),
          stats: {
            model.stats with
            total_messages: model.stats.total_messages + 1,
            combo_streak: model.stats.combo_streak + 1,
          },
      },
    )
    MessageSent(Err(_)) => (
      none(),
      { model with stats: { model.stats with combo_streak: 0 } },
    )
    AgentSelected(name) => (none(), { model with selected_agent: name })
    CommandEntered(cmd) => (api_run_command(dispatch, model.active_session_id, cmd), model)

    // ====== Project 操作 ======
    ProjectSelected(id) => (none(), { model with active_project_id: id })
    FilterByProject(id) => (none(), { model with active_project_id: id })

    // ====== SSE ======
    SSEConnected => (none(), { model with sse_connected: true })
    SSEDisconnected => (none(), { model with sse_connected: false })
    SSESessionCreated(session) => (
      none(),
      { model with sessions: model.sessions.append(session) },
    )
    SSESessionUpdated(session) => (
      none(),
      { model with sessions: update_session(model.sessions, session) },
    )
    SSESessionDeleted(id) => (
      none(),
      { model with sessions: model.sessions.filter(fn(s) { s.id != id }) },
    )
    SSESessionStatusChanged(id, status) => (
      none(),
      { model with sessions: update_session_status(model.sessions, id, status) },
    )
    SSEMessageUpdated(session_id, message) => (
      none(),
      append_message(model, session_id, message),
    )
    SSEMessagePartUpdated(session_id, part) => (
      none(),
      append_message_part(model, session_id, part),
    )

    // ====== UI ======
    ToggleSidebar => (none(), { model with sidebar_open: !model.sidebar_open })
    ToggleDetail => (none(), { model with detail_open: !model.detail_open })
    ToggleSettings => (none(), model)
    KeyPressed(key) => handle_key(dispatch, model, key)

    // ====== 游戏化 ======
    AchievementUnlocked(a) => (
      none(),
      { model with stats: {
        model.stats with achievements: model.stats.achievements.append(a)
      }},
    )
    ComboIncremented => (
      none(),
      { model with stats: { model.stats with combo_streak: model.stats.combo_streak + 1 }},
    )
    ComboReset => (
      none(),
      { model with stats: { model.stats with combo_streak: 0 }},
    )
  }
}
```

### 5.3 View (声明式 UI)

```moonbit
// view.mbt
using @html {
  div, h1, h2, h3, p, span, button, input, textarea,
  ul, li, a, img, section, header, footer, nav, aside, main
}

///|
fn view(dispatch : Dispatch[Msg], model : Model) -> Html {
  div([class="app", id="app"], [
    // 侧边栏
    view_sidebar(dispatch, model),
    // 聊天主区域
    view_chat(dispatch, model),
    // 详情面板
    if model.detail_open {
      view_detail(dispatch, model)
    } else {
      div([], [])
    },
    // 底部状态栏
    view_statusbar(dispatch, model),
  ])
}

///|
fn view_sidebar(dispatch : Dispatch[Msg], model : Model) -> Html {
  let class_name = if model.sidebar_open { "sidebar open" } else { "sidebar closed" }
  aside([class=class_name], [
    // 搜索框
    div([class="sidebar-search"], [
      input([
        class="search-input",
        placeholder="搜索会话...",
        value=model.search_query,
        on_input=dispatch.map(query => SearchInputChanged(query)),
      ]),
    ]),

    // 会话列表 (按 Project 分组)
    view_session_groups(dispatch, model),

    // 新建会话按钮
    button(
      class="btn-new-session",
      on_click=dispatch(NewSessionClicked),
      [text("+ 新会话")],
    ),
  ])
}

///|
fn view_chat(dispatch : Dispatch[Msg], model : Model) -> Html {
  main([class="chat-panel"], [
    // 聊天头部
    header([class="chat-header"], [
      h2([class="chat-title"], [
        text(active_session_title(model)),
      ]),
      button(
        class="btn-toggle-detail",
        on_click=dispatch(ToggleDetail),
        [text("📋")],
      ),
    ]),

    // 消息列表
    section([class="chat-messages"], [
      view_messages(dispatch, model),
    ]),

    // 输入区域
    footer([class="chat-input"], [
      // Agent 选择器
      view_agent_selector(dispatch, model),
      // 文本输入
      textarea([
        class="input-text",
        placeholder="输入消息...",
        value=model.input_text,
        on_input=dispatch.map(text => InputChanged(text)),
      ]),
      // 发送按钮
      button(
        class="btn-send",
        on_click=dispatch(SendClicked),
        [text("➤")],
      ),
    ]),
  ])
}

///|
fn view_messages(dispatch : Dispatch[Msg], model : Model) -> Html {
  let messages = model.messages.get(model.active_session_id).unwrap_or([])
  div([class="messages-container"],
    messages.map(fn(msg) {
      view_message_bubble(dispatch, model, msg)
    })
  )
}

///|
fn view_message_bubble(
  dispatch : Dispatch[Msg],
  model : Model,
  msg : ChatMessage,
) -> Html {
  let is_user = msg.role is User
  let bubble_class = if is_user { "bubble bubble-user" } else { "bubble bubble-agent" }
  let agent = find_agent(model.agents, msg.model_id)

  div([class=bubble_class], [
    // 头像 + 名称
    if !is_user {
      div([class="bubble-header"], [
        span([class="agent-avatar"], [text(agent_icon(agent))]),
        span([class="agent-name"], [text(agent.name)]),
      ])
    } else {
      div([], [])
    },
    // 消息内容
    div([class="bubble-content"],
      msg.parts.map(fn(part) { view_message_part(dispatch, part) })
    ),
    // 时间戳
    span([class="bubble-time"], [text(format_time(msg.created_at))]),
  ])
}

///|
fn view_message_part(dispatch : Dispatch[Msg], part : MessagePart) -> Html {
  match part {
    Text(content) => p([class="part-text"], [text(content)])
    ToolCall(info) => details([class="part-tool"], [
      summary([class="tool-summary"], [
        span([class="tool-icon"], [text("🔧")]),
        span([class="tool-name"], [text(info.tool_name)]),
        span([class="tool-status"], [text(tool_status_icon(info.status))]),
      ]),
      pre([class="tool-input"], [text(info.input)]),
    ])
    ToolResult(info) => div([class="part-tool-result"], [
      if info.success {
        pre([class="tool-output"], [text(info.output)])
      } else {
        pre([class="tool-error"], [text(info.output)])
      }
    ])
    FileDiff(info) => details([class="part-diff"], [
      summary([], [
        text("\{info.file_path} (+\{info.additions} -\{info.deletions})"),
      ]),
      pre([class="diff-content"], [text(info.content)]),
    ])
    StepStart(name) => div([class="part-step"], [text("▶ \{name}")])
    StepFinish(name) => div([class="part-step done"], [text("✓ \{name}")])
    Reasoning(content) => details([class="part-reasoning"], [
      summary([], [text("💭 思考过程")]),
      p([], [text(content)]),
    ])
    Subtask(info) => div([class="part-subtask"], [
      span([class="subtask-agent"], [text("🤖 \{info.agent}")]),
      span([class="subtask-desc"], [text(info.description)]),
    ])
  }
}

///|
fn view_agent_selector(dispatch : Dispatch[Msg], model : Model) -> Html {
  // 使用 div + button 列表模拟下拉选择
  div([class="agent-selector"], [
    button([class="agent-selector-btn"], [
      text("🤖 \{model.selected_agent}"),
    ]),
    // TODO: 下拉列表
  ])
}

///|
fn view_detail(dispatch : Dispatch[Msg], model : Model) -> Html {
  aside([class="detail-panel"], [
    h3([], [text("Agent 详情")]),
    // 显示当前 Agent 信息
    let agent = find_agent_by_name(model.agents, model.selected_agent)
    match agent {
      Some(a) => div([class="agent-detail"], [
        p([], [text("名称: \{a.name}")]),
        p([], [text("模式: \{agent_mode_label(a.mode)}")]),
        p([], [text("模型: \{a.model_id}")]),
        h4([], [text("工具")]),
        ul([], a.tools.entries().map(fn(entry) {
          let (name, enabled) = entry
          li([], [text("\{if enabled { "✅" } else { "❌" }} \{name}")])
        }).toArray()),
      ])
      None => p([], [text("未选择 Agent")])
    },
    // 游戏化统计
    h3([], [text("🔥 连击: \{model.stats.combo_streak}")]),
  ])
}

///|
fn view_statusbar(dispatch : Dispatch[Msg], model : Model) -> Html {
  let status_icon = if model.sse_connected { "●" } else { "○" }
  footer([class="statusbar"], [
    span([], [text("\{status_icon} \{connection_label(model.connection)}")]),
    span([], [text("Sessions: \{model.sessions.length()}")]),
    span([], [text("Agents: \{model.agents.length()}")]),
  ])
}
```

### 5.4 Subscriptions (SSE + 键盘)

```moonbit
// subscriptions.mbt

///|
fn subscriptions(dispatch : Dispatch[Msg], model : Model) -> @sub.Sub {
  @sub.batch([
    // SSE 实时事件流 (custom subscription)
    sse_subscribe(dispatch, model.config),

    // 键盘快捷键
    @sub.on_key_down(fn(k) {
      match k.key {
        "Enter" => dispatch(SendClicked)
        _ => @cmd.none
      }
    }),
  ])
}

///|
/// SSE 封装为 Rabbita custom subscription
fn sse_subscribe(dispatch : Dispatch[Msg], config : ServerConfig) -> @sub.Sub {
  @sub.custom_sub(
    "opencode-sse",
    @sub.Local,
    config.base_url,
    SubLoader(fn(payload, scheduler) {
      let url = "\{payload}/global/event"
      start_sse(url, fn(event_type, data) {
        let msg = parse_sse_event(event_type, data)
        match msg {
          Some(m) => scheduler.add_cmd(dispatch(m))
          None => ()
        }
      })
      Some({
        unload: fn(_) { stop_sse() },
        update_tagger: fn(_) { () },
      })
    }),
  )
}

// === SSE FFI ===

///|
extern "js" fn start_sse(
  url : String,
  on_event : (String, String) -> Unit,
) -> Unit = #|(url, on_event) => {
  globalThis.__moonxi_sse = new EventSource(url);
  globalThis.__moonxi_sse.onmessage = (e) => {
    const data = JSON.parse(e.data);
    on_event(data.type, e.data);
  };
  globalThis.__moonxi_sse.onerror = () => {
    on_event("error", "");
  };
}

///|
extern "js" fn stop_sse() -> Unit = #|() => {
  if (globalThis.__moonxi_sse) {
    globalThis.__moonxi_sse.close();
    globalThis.__moonxi_sse = null;
  }
}

///|
/// 解析 SSE 事件为 Msg
fn parse_sse_event(event_type : String, data : String) -> Option[Msg] {
  match event_type {
    "session.created" => {
      let session = parse_session(data)
      Some(SSESessionCreated(session))
    }
    "session.updated" => {
      let session = parse_session(data)
      Some(SSESessionUpdated(session))
    }
    "session.deleted" => {
      let id = parse_id(data)
      Some(SSESessionDeleted(id))
    }
    "session.status" => Some(SSEConnected)
    "server.heartbeat" => Some(SSEConnected)
    "error" => Some(SSEDisconnected)
    _ => None
  }
}
```

### 5.5 API Cmd (HTTP)

```moonbit
// api.mbt

///|
fn api_health_check(dispatch : Dispatch[Msg]) -> Cmd {
  @http.get("/global/health", expect=@http.Text(fn(result) {
    match result {
      Ok(version) => dispatch(GotHealth(Ok(version)))
      Err(msg) => dispatch(GotHealth(Err(msg)))
    }
  }))
}

///|
fn api_load_sessions(dispatch : Dispatch[Msg]) -> Cmd {
  @http.get("/session", expect=@http.Json(fn(result) {
    match result {
      Ok(data) => {
        let sessions = parse_sessions(data)
        dispatch(GotSessions(Ok(sessions)))
      }
      Err(msg) => dispatch(GotSessions(Err(msg)))
    }
  }))
}

///|
fn api_load_messages(dispatch : Dispatch[Msg], session_id : String) -> Cmd {
  @http.get(
    "/session/\{session_id}/message",
    expect=@http.Json(fn(result) {
      match result {
        Ok(data) => {
          let messages = parse_messages(data)
          dispatch(GotMessages(session_id, Ok(messages)))
        }
        Err(msg) => dispatch(GotMessages(session_id, Err(msg)))
      }
    }),
  )
}

///|
fn api_send_message(
  dispatch : Dispatch[Msg],
  session_id : String,
  text : String,
  agent : String,
) -> Cmd {
  let body = @http.json({
    "parts": [{ "type": "text", "text": text }],
    "agent": agent,
  })
  @http.post(
    "/session/\{session_id}/message",
    body~,
    expect=@http.Json(fn(result) {
      match result {
        Ok(data) => {
          let messages = parse_messages(data)
          dispatch(MessageSent(Ok(messages)))
        }
        Err(msg) => dispatch(MessageSent(Err(msg)))
      }
    }),
  )
}

///|
fn api_create_session(dispatch : Dispatch[Msg], model : Model) -> Cmd {
  let body = @http.json({ "title": "新会话" })
  @http.post(
    "/session",
    body~,
    expect=@http.Json(fn(result) {
      match result {
        Ok(data) => {
          let session = parse_session(data)
          dispatch(SessionCreated(Ok(session)))
        }
        Err(msg) => dispatch(SessionCreated(Err(msg)))
      }
    }),
  )
}

///|
fn api_delete_session(dispatch : Dispatch[Msg], session_id : String) -> Cmd {
  @http.request(
    "/session/\{session_id}",
    "DELETE",
    expect=@http.Text(fn(result) {
      match result {
        Ok(_) => dispatch(SessionDeleted(Ok(session_id)))
        Err(msg) => dispatch(SessionDeleted(Err(msg)))
      }
    }),
    body=@http.Empty,
  )
}

///|
fn api_load_agents(dispatch : Dispatch[Msg]) -> Cmd {
  @http.get("/agent", expect=@http.Json(fn(result) {
    match result {
      Ok(data) => dispatch(GotAgents(Ok(parse_agents(data))))
      Err(msg) => dispatch(GotAgents(Err(msg)))
    }
  }))
}

///|
fn api_load_projects(dispatch : Dispatch[Msg]) -> Cmd {
  @http.get("/project", expect=@http.Json(fn(result) {
    match result {
      Ok(data) => dispatch(GotProjects(Ok(parse_projects(data))))
      Err(msg) => dispatch(GotProjects(Err(msg)))
    }
  }))
}

///|
fn api_run_command(dispatch : Dispatch[Msg], session_id : String, cmd : String) -> Cmd {
  let body = @http.json({ "command": cmd })
  @http.post(
    "/session/\{session_id}/command",
    body~,
    expect=@http.Json(fn(result) {
      match result {
        Ok(data) => {
          let messages = parse_messages(data)
          dispatch(MessageSent(Ok(messages)))
        }
        Err(msg) => dispatch(MessageSent(Err(msg)))
      }
    }),
  )
}
```

---

## 6. API 集成

### 6.1 OpenCode Serve 端点映射

| 功能 | HTTP 方法 | 端点 | Rabbita Cmd | POC 优先级 |
|---|---|---|---|---|
| 健康检查 | GET | `/global/health` | `@http.get` | P0 |
| 会话列表 | GET | `/session` | `@http.get` | P0 |
| 创建会话 | POST | `/session` | `@http.post` | P0 |
| 消息列表 | GET | `/session/:id/message` | `@http.get` | P0 |
| 发送消息 | POST | `/session/:id/message` | `@http.post` | P0 |
| SSE 事件流 | GET | `/global/event` | custom sub | P0 |
| Agent 列表 | GET | `/agent` | `@http.get` | P1 |
| Project 列表 | GET | `/project` | `@http.get` | P1 |
| 删除会话 | DELETE | `/session/:id` | `@http.request` | P1 |
| 斜杠命令 | POST | `/session/:id/command` | `@http.post` | P2 |
| 会话 Fork | POST | `/session/:id/fork` | `@http.post` | P2 |
| 消息 Revert | POST | `/session/:id/revert` | `@http.post` | P2 |

### 6.2 认证

```
HTTP Basic Auth (在 @http 请求头中注入):
  Authorization: Basic base64(username:password)
```

---

## 7. 项目结构

```
moonxi_board/
├── moon.mod.json              # 依赖: moonbit-community/rabbita
├── moon.pkg                   # 根包
├── docs/
│   └── design.md              # 本设计文档
├── memory/                    # 记忆目录
├── knowledge/                 # 知识目录
│   └── rabbita.md             # Rabbita 框架知识
├── tasks/                     # 任务目录
│
├── web/                       # 前端资源
│   └── index.html             # 入口 HTML (含 CSS)
│
├── src/                       # MoonBit 源码 (Rabbita app)
│   ├── moon.pkg               # 依赖 rabbita
│   ├── main.mbt               # 入口: mount app
│   ├── model.mbt              # Model + Msg + 数据类型
│   ├── update.mbt             # update 函数 (纯函数状态转换)
│   ├── view.mbt               # view 函数 (声明式 HTML EDSL)
│   ├── view_sidebar.mbt       # Sidebar 视图
│   ├── view_chat.mbt          # Chat 视图
│   ├── view_detail.mbt        # Detail 视图
│   ├── subscriptions.mbt      # SSE custom subscription + 键盘
│   ├── api.mbt                # OpenCode API Cmd 封装
│   ├── parse.mbt              # JSON 解析 (OpenCode 响应 → Model 类型)
│   ├── helpers.mbt            # 辅助函数 (时间格式化、搜索过滤等)
│   └── game.mbt               # 游戏化逻辑
│
├── src_test/                  # 测试
│   ├── moon.pkg
│   ├── update_test.mbt        # update 函数单元测试
│   └── parse_test.mbt         # JSON 解析测试
│
└── cmd/
    └── main/                  # CLI 入口 (可选)
        ├── moon.pkg
        └── main.mbt
```

### 7.1 moon.mod.json

```json
{
  "name": "chnlkw/moonxi_board",
  "version": "0.1.0",
  "deps": {
    "moonbit-community/rabbita": "0.11.5"
  }
}
```

### 7.2 src/moon.pkg

```
import {
  "moonbit-community/rabbita" @rabbita
  "moonbit-community/rabbita/http" @http
  "moonbit-community/rabbita/sub" @sub
  "moonbit-community/rabbita/html" @html
}
options("is-main": true)
```

---

## 8. POC 实施计划

### Phase 1: 骨架 + 连通 (第 1-2 天)

**目标**: Rabbita app 跑起来 + 连通 OpenCode Serve

```
P1-1. 项目初始化
      - moon.mod.json 添加 rabbita 依赖
      - src/moon.pkg 配置 import
      - web/index.html 最小骨架 (<div id="app">)

P1-2. Model + Msg 定义
      - model.mbt: 完整 Model struct + Msg enum
      - 基础 parse.mbt: JSON 解析骨架

P1-3. 最小 View
      - view.mbt: 三栏骨架 (sidebar + chat + detail)
      - 硬编码 mock 数据渲染

P1-4. API 连通
      - api.mbt: health_check + load_sessions
      - @http.get 调用 OpenCode Serve
      - 结果渲染到界面
```

### Phase 2: 聊天核心 (第 3-4 天)

**目标**: 完整的聊天交互链路

```
P2-1. 会话列表
      - 按 Project 分组渲染
      - 点击切换活跃会话
      - 新建/删除会话

P2-2. 消息渲染
      - 用户/Agent 气泡
      - Tool 调用折叠
      - 消息时间戳

P2-3. 消息发送
      - 输入框 + Agent 选择
      - POST /session/:id/message
      - 发送后追加到消息列表

P2-4. SSE 实时流
      - custom subscription 封装
      - 事件解析 → Msg
      - 自动重连
```

### Phase 3: 多 Agent / 多 Project (第 5 天)

**目标**: 完整的多实体管理

```
P3-1. Agent 管理
      - Agent 列表 & 详情面板
      - 切换 Agent 对话

P3-2. Project 管理
      - Project 列表
      - 会话按 Project 过滤

P3-3. 会话管理
      - 搜索会话
      - 收藏会话
```

### Phase 4: 游戏化 & 打磨 (第 6-7 天)

**目标**: 游戏化元素 + UI 打磨

```
P4-1. 游戏化元素
      - Agent 角色化 (图标/标签)
      - 连击计数 🔥
      - 任务图标

P4-2. CSS 打磨
      - 暗色主题
      - 消息气泡动画
      - 响应式布局

P4-3. 测试
      - update 函数纯函数测试
      - JSON 解析测试
      - 集成测试
```

---

## 9. 技术决策

### 9.1 Rabbita (TEA 架构) vs Vanilla JS

**选择**: Rabbita

**理由**:
- 全 MoonBit，无需 JS Bridge，类型安全贯穿全栈
- Model/Update/View 纯函数，状态可预测，易测试
- 内置 `@http` 直接调用 OpenCode API
- 内置 `@sub` 覆盖键盘/鼠标/resize 等事件
- `~15KB` gzip 极轻量
- mooncakes.io 生产验证

### 9.2 MoonBit JS Backend

**选择**: JS Backend (非 WASM-GC)

**理由**:
- Rabbita 依赖浏览器 DOM API，JS Backend 直接运行
- `@http`/`@sub` 等内置 Cmd 底层调用浏览器 fetch/DOM
- 调试方便，浏览器 DevTools 直接看源码
- 后续 Rabbita 支持 WASM-GC 后可无缝切换

### 9.3 SSE → Custom Subscription

**选择**: 封装 SSE 为 `@sub.custom_sub`

**理由**:
- Rabbita 无内置 SSE，但 custom subscription 机制完善
- SSE 生命周期（连接/消息/断开）自然映射到 SubLoader/RunningSub
- 与 Elm 的 `Subscription` 模式一致
- 约 30 行 FFI 代码即可完成

### 9.4 CSS 架构

```css
:root {
  --bg-primary: #1a1a2e;
  --bg-secondary: #16213e;
  --bg-chat: #0f3460;
  --text-primary: #e6e6e6;
  --text-secondary: #a0a0a0;
  --accent: #e94560;
  --user-bubble: #0d7377;
  --agent-bubble: #2d2d44;
  --border: #2d2d44;

  --sidebar-width: 280px;
  --detail-width: 300px;
  --transition-fast: 150ms ease;
  --transition-normal: 300ms ease;
}
```

CSS 写在 `web/index.html` 的 `<style>` 中，Rabbita view 通过 `class` 引用。

---

## 10. 风险与缓解

| 风险 | 影响 | 缓解措施 |
|---|---|---|
| Rabbita HTML EDSL 属性不全 | 部分 CSS/事件无法声明式使用 | 用 `style=[]` 内联或 `extern "js"` 补齐 |
| SSE custom subscription 稳定性 | 实时消息丢失 | 添加轮询降级 + 重连指数退避 |
| Rabbita 版本迭代 API 变化 | 编译失败 | 锁定版本 0.11.5，跟进 changelog |
| OpenCode API 响应格式变化 | 解析失败 | parse 层做好容错，unknown 字段忽略 |
| 大量消息渲染性能 | 界面卡顿 | 虚拟滚动（限制渲染数量）+ 分页加载 |

---

## 11. 验收标准 (POC)

- [ ] Rabbita app 成功 mount 到浏览器
- [ ] 能连接本地 `opencode serve` 实例 (`GotHealth`)
- [ ] 显示会话列表，按 Project 分组
- [ ] 点击会话查看消息历史
- [ ] 能发送消息并看到回复
- [ ] SSE 实时推送新消息（无需刷新）
- [ ] 能切换不同 Agent 对话
- [ ] 能切换不同 Project
- [ ] update 函数有单元测试
- [ ] Bundle < 100KB (含 CSS)
- [ ] 界面基本类似微信聊天风格
