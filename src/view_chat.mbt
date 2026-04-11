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
  let msgs = model.messages.get(session_id).unwrap_or([])
  if msgs.length() == 0 {
    div(class="messages-empty", [text("开始新对话吧 ✨")])
  } else {
    let bubbles = msgs.map(fn(m) { view_message_bubble(m) })
    fragment(bubbles)
  }
}

///|
fn view_message_bubble(msg : ChatMessage) -> @html.Html {
  let bubble_class = match msg.role {
    User => "bubble bubble-user"
    Assistant => "bubble bubble-agent"
  }
  let role_label = match msg.role {
    User => "🧑 你"
    Assistant => "🤖 Agent"
  }
  let parts_html = msg.parts.map(fn(part) { view_message_part(part) })
  div(class=bubble_class, [
    div(class="bubble-role", [text(role_label)]),
    div(class="bubble-content", parts_html),
  ])
}

///|
fn view_message_part(part : MessagePart) -> @html.Html {
  match part {
    Text(content) => p([text(content)])
    ToolCall(info) =>
      details(class="tool-call", [
        summary(class="tool-call-header", [
          span(class="tool-name", [text("🔧 \{info.tool_name}")]),
          span(class="tool-status", [text(tool_status_label(info.status))]),
        ]),
        pre(class="tool-input", [text(info.input)]),
      ])
    StepStart(label) =>
      div(class="step-indicator step-start", [text("▶ \{label}")])
    StepFinish(label) =>
      div(class="step-indicator step-finish", [text("✓ \{label}")])
  }
}

///|
fn tool_status_label(status : ToolStatus) -> String {
  match status {
    Running => "⏳ 运行中"
    Completed => "✅ 完成"
    Failed => "❌ 失败"
    PendingApproval => "⚠️ 待审批"
  }
}

///|
fn view_agent_selector(
  dispatch : @cmd.Dispatch[Msg],
  model : Model,
) -> @html.Html {
  let options = model.agents.map(fn(agent) {
    let is_selected = agent.name == model.selected_agent
    option(value=agent.name, selected=is_selected, [text(agent.name)])
  })
  select(
    class="agent-selector",
    on_change=fn(name) { dispatch(AgentSelected(name)) },
    options,
  )
}
