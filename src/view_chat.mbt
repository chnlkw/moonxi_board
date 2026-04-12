///|
pub fn view_chat(dispatch : @cmd.Dispatch[Msg], model : Model) -> @html.Html {
  section(class="chat-panel", [
    // Chat header
    header(class="chat-header", [
      button(class="btn-toggle-sidebar", on_click=dispatch(ToggleSidebar), [
        text("☰"),
      ]),
      h2(class="chat-title", [text(active_session_title(model))]),
      button(class="btn-toggle-detail", on_click=dispatch(ToggleDetail), [
        text("📋"),
      ]),
    ]),
    // Connection settings bar
    div(class="connection-bar", [
      span(class="connection-dot", [text(connection_label(model.connection))]),
      input(
        class="base-url-input",
        placeholder="OpenCode Serve URL (e.g. http://host:4096)",
        value=model.base_url_input,
        on_input=fn(t) { dispatch(BaseUrlChanged(t)) },
        [nothing],
      ),
      button(class="btn-connect", on_click=dispatch(BaseUrlSubmitted), [
        text("连接"),
      ]),
    ]),
    // Messages
    div(class="messages-container", [view_messages(model)]),
    // Input area
    footer(class="chat-input", [
      view_agent_selector(dispatch, model),
      textarea(
        class="input-text",
        placeholder="输入消息... (Enter 发送)",
        value=model.input_text,
        on_input=fn(t) { dispatch(InputChanged(t)) },
        [nothing],
      ),
      button(class="btn-send", on_click=dispatch(SendClicked), [text("➤")]),
    ]),
  ])
}

///|
fn view_messages(model : Model) -> @html.Html {
  let session_id = model.active_session_id
  match model.messages.get(session_id) {
    Some(Success(msgs)) =>
      if msgs.length() == 0 {
        div(class="messages-empty", [text("开始新对话吧 ✨")])
      } else {
        let bubbles = msgs.map(fn(m) { view_message_bubble(m) })
        fragment(bubbles)
      }
    Some(Loading) => skeleton_messages(3)
    Some(Failed(msg)) => load_failed("messages", msg)
    None => div(class="messages-empty", [text("开始新对话吧 ✨")])
  }
}

///|
fn view_message_bubble(msg : @types.ChatMessage) -> @html.Html {
  let bubble_class = match msg.role {
    @types.User => "bubble bubble-user"
    @types.Assistant => "bubble bubble-agent"
  }
  let role_label = match msg.role {
    @types.User => "🧑 你"
    @types.Assistant => "🤖 Agent"
  }
  let parts_html = msg.parts.map(fn(part) { view_message_part(part) })
  div(class=bubble_class, [
    div(class="bubble-role", [text(role_label)]),
    div(class="bubble-content", parts_html),
  ])
}

///|
fn view_message_part(part : @types.MessagePart) -> @html.Html {
  match part {
    @types.Text(content) => p([text(content)])
    @types.ToolCall(info) =>
      details(class="tool-call", [
        summary(class="tool-call-header", [
          span(class="tool-name", [text("🔧 \{info.tool_name}")]),
          span(class="tool-status", [text(tool_status_label(info.status))]),
        ]),
        pre(class="tool-input", [text(info.input)]),
      ])
    @types.StepStart(label) =>
      div(class="step-indicator step-start", [text("▶ \{label}")])
    @types.StepFinish(label) =>
      div(class="step-indicator step-finish", [text("✓ \{label}")])
  }
}

///|
fn tool_status_label(status : @types.ToolStatus) -> String {
  match status {
    @types.Running => "⏳ 运行中"
    @types.Completed => "✅ 完成"
    @types.Failed => "❌ 失败"
    @types.PendingApproval => "⚠️ 待审批"
  }
}

///|
fn view_agent_selector(
  dispatch : @cmd.Dispatch[Msg],
  model : Model,
) -> @html.Html {
  match model.agents {
    Success(agents) => {
      let options = agents.map(fn(agent) {
        let is_selected = agent.name == model.selected_agent
        option(value=agent.name, selected=is_selected, [text(agent.name)])
      })
      select(
        class="agent-selector",
        on_change=fn(name) { dispatch(AgentSelected(name)) },
        options,
      )
    }
    Loading => skeleton_agents()
    Failed(msg) => load_failed("agents", msg)
  }
}
