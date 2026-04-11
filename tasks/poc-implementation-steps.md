# Moonxi Board POC 实现步骤

> 基于 Rabbita TEA 架构 | 2026-04-10

## 当前状态

- 项目: 空模板 + 设计文档已完成
- 设计文档: `docs/design.md`
- 框架知识: `knowledge/rabbita.md`
- 工具链: moon 0.1.20260330, `--target js`

---

## Step 0: 项目基础设施

```
0.1  添加 rabbita 依赖到 moon.mod.json
     moon add moonbit-community/rabbita

0.2  创建 src/ 目录结构
     src/moon.pkg — 配置 rabbita import, is-main: true
     src/main.mbt — Rabbita app 入口 (mount "app")

0.3  创建 web/index.html
     最小骨架: <div id="app"></div> + CSS 变量主题 + 内联样式
     引用编译后的 JS: <script src="../target/js/release/build/..."></script>
```

验证: `moon check --target js` ✅

---

## Step 1: 数据骨架 (纯类型，可测试)

```
1.1  src/model.mbt
     - Model struct (连接/数据/UI/游戏化)
     - Msg enum (所有事件)
     - 数据类型: Session, ChatMessage, Agent, Project, MessagePart...
     - 辅助类型: SessionStatus, ConnectionStatus, GameStats...
     - init_model() 工厂函数

1.2  src/model_test.mbt
     - init_model 默认值测试
     - Msg 模式匹配覆盖测试
```

验证: `moon check --target js` + `moon test --target js` ✅

---

## Step 2: 最小 View (Hello World 验证)

```
2.1  src/view.mbt
     - 最小 view: div 里渲染 model.connection 状态
     - 一个按钮: ToggleSidebar

2.2  src/main.mbt
     - @rabbita.cell(model~, update~, view~)
     - @rabbita.new(app).mount("app")

2.3  web/index.html
     - 暗色主题 CSS
     - 加载编译产物
```

验证: `moon build --target js` → 浏览器打开 → 看到界面

---

## Step 3: API Cmd 层 (HTTP 连通)

```
3.1  src/api.mbt
     - api_health_check: GET /global/health
     - api_load_sessions: GET /session
     - api_load_agents: GET /agent
     - api_load_projects: GET /project
     - api_load_messages: GET /session/:id/message
     - api_send_message: POST /session/:id/message
     - api_create_session: POST /session

3.2  src/parse.mbt
     - parse_session: JSON → Session
     - parse_sessions, parse_agents, parse_projects, parse_messages
     - 基于 @json 解析

3.3  src/parse_test.mbt
     - 各 parse 函数单元测试 (用 mock JSON 字符串)
```

验证: `moon test --target js` 解析测试通过 ✅

---

## Step 4: Update 逻辑 (纯函数，可测试)

```
4.1  src/update.mbt
     - update() 完整实现
     - AppStarted → 批量加载 Cmd
     - GotSessions/GotAgents/GotProjects → 更新 model
     - SelectSession → 加载消息
     - SendClicked → 发送消息
     - 所有 Msg 分支

4.2  src/helpers.mbt
     - toggle_star, update_session, update_session_status
     - append_message, append_message_part
     - active_session_title, agent_icon, format_time
     - first_agent_name, first_project_id
     - connection_label, agent_mode_label

4.3  src/update_test.mbt
     - update(AppStarted, ...) → connection: Connecting
     - update(GotSessions(Ok([...])), ...) → sessions 更新
     - update(SendClicked, ...) → input_text 清空
     - update(SelectSession(id), ...) → active_session_id 更新
```

验证: `moon test --target js` — update 纯函数测试全过 ✅

---

## Step 5: 完整 View (微信风格 UI)

```
5.1  src/view.mbt — 主 view 框架
     - 三栏布局: sidebar + chat + detail
     - view() 调度子视图

5.2  src/view_sidebar.mbt
     - 搜索框 (input + on_input)
     - 按 Project 分组的会话列表
     - 新建会话按钮
     - 会话状态指示器

5.3  src/view_chat.mbt
     - 聊天头部 (会话标题 + 详情切换)
     - 消息气泡列表 (用户蓝/Agent灰)
     - Tool 调用折叠 (details/summary)
     - 输入区 (textarea + 发送按钮)
     - Agent 选择器

5.4  src/view_detail.mbt
     - Agent 信息面板
     - 工具列表
     - 游戏化统计 (🔥连击)

5.5  web/index.html — CSS 完善
     - 三栏 flex 布局
     - 消息气泡样式
     - 侧边栏滚动
     - 暗色主题所有细节
     - 响应式基础
```

验证: `moon build --target js` → 连 opencode serve → 完整交互

---

## Step 6: SSE 实时流

```
6.1  src/subscriptions.mbt
     - sse_subscribe: @sub.custom_sub 封装
     - extern "js" FFI: start_sse / stop_sse
     - parse_sse_event: SSE event_type → Msg
     - subscriptions(): SSE + @sub.on_key_down

6.2  src/subscriptions_test.mbt
     - parse_sse_event 各事件类型测试
```

验证: 连接 opencode serve → TUI 发消息 → Web 实时收到

---

## Step 7: 游戏化 + 打磨

```
7.1  src/game.mbt
     - combo_streak 逻辑
     - achievement 解锁条件
     - agent_icon / agent_mode_label 角色

7.2  web/index.html — CSS 动画
     - 消息进入动画
     - 状态变化过渡
     - 连击数字特效
```

验证: 动画+游戏化生效

---

## 依赖关系图

```
Step 0: moon.mod.json → src/moon.pkg → web/index.html
         (基础设施)
              ↓
Step 1: model.mbt → model_test.mbt
         (纯类型，零依赖)
              ↓
Step 2: main.mbt + view.mbt (最小版)
         (Hello World 跑通)
              ↓
Step 3: parse.mbt → parse_test.mbt → api.mbt
         (API 连通)
              ↓
Step 4: helpers.mbt → update.mbt → update_test.mbt
         (完整状态转换)
              ↓
Step 5: view_*.mbt + CSS
         (完整 UI)
              ↓
Step 6: subscriptions.mbt
         (实时流)
              ↓
Step 7: game.mbt + CSS 打磨
         (游戏化)
```

## 每步验证

| Step | 验证方式 |
|------|---------|
| 0 | `moon check --target js` |
| 1 | `moon test --target js` |
| 2 | 浏览器打开看到界面 |
| 3 | `moon test --target js` |
| 4 | `moon test --target js` |
| 5 | 连 opencode serve 完整交互 |
| 6 | TUI 发消息 Web 实时收到 |
| 7 | 动画+游戏化生效 |
