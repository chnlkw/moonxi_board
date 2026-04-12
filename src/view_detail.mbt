///|
pub fn view_detail(dispatch : @cmd.Dispatch[Msg], model : Model) -> @html.Html {
  if !model.detail_open {
    return nothing
  }
  aside(class="detail-panel", [
    div(class="detail-header", [
      h3([text("Agent 详情")]),
      button(class="btn-close-detail", on_click=dispatch(ToggleDetail), [
        text("✕"),
      ]),
    ]),
    // Show agent info based on selected_agent
    view_agent_detail(model),
    // Game stats
    div(class="game-stats", [
      h3([text("🔥 统计")]),
      div(class="stat-row", [
        span(class="stat-label", [text("连击:")]),
        span(class="stat-value combo", [text("\{model.stats.combo_streak}")]),
      ]),
      div(class="stat-row", [
        span(class="stat-label", [text("消息:")]),
        span(class="stat-value", [text("\{model.stats.total_messages}")]),
      ]),
    ]),
  ])
}

///|
fn view_agent_detail(model : Model) -> @html.Html {
  match model.agents {
    Success(agents) =>
      match find_agent_by_name(agents, model.selected_agent) {
        Some(agent) =>
          div(class="agent-detail", [
            div(class="agent-info-section", [
              h4([text("基本信息")]),
              div(class="info-row", [
                span(class="info-label", [text("名称:")]),
                span(class="info-value", [text(agent.name)]),
              ]),
              div(class="info-row", [
                span(class="info-label", [text("模式:")]),
                span(class="info-value", [text(agent_mode_label(agent.mode))]),
              ]),
              div(class="info-row", [
                span(class="info-label", [text("模型:")]),
                span(class="info-value", [text(agent.model_id)]),
              ]),
              p(class="agent-desc", [text(agent.description)]),
            ]),
            div(class="agent-tools-section", [
              h4([text("工具权限")]),
              view_tools_list(agent.tools),
            ]),
          ])
        None =>
          div(class="agent-detail agent-detail-empty", [
            p([text("选择一个 Agent 查看详情")]),
          ])
      }
    Loading => skeleton_agents()
    Failed(msg) => load_failed("agents", msg)
  }
}

///|
fn view_tools_list(tools : Array[(String, Bool)]) -> @html.Html {
  if tools.length() == 0 {
    p(class="no-tools", [text("暂无工具信息")])
  } else {
    let items = tools.map(fn(entry) {
      let (name, enabled) = entry
      let icon = if enabled { "✅" } else { "❌" }
      div(class="tool-item", [
        span(class="tool-icon", [text(icon)]),
        span(class="tool-name", [text(name)]),
      ])
    })
    div(class="tools-list", items)
  }
}
