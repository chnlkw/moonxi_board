///|
pub fn view_sidebar(dispatch : @cmd.Dispatch[Msg], model : Model) -> @html.Html {
  let class_name = if model.sidebar_open {
    "sidebar open"
  } else {
    "sidebar closed"
  }
  aside(class=class_name, [
    // Header
    div(class="sidebar-header", [
      h2([text("🌙 Moonxi Board")]),
      span(class="connection-status", [text(connection_label(model.connection))]),
    ]),
    // Search
    div(class="sidebar-search", [
      input(
        class="search-input",
        placeholder="搜索会话...",
        value=model.search_query,
        on_input=fn(q) { dispatch(SearchInputChanged(q)) },
        [nothing],
      ),
    ]),
    // Session list grouped by project
    div(class="session-list", [view_session_groups(dispatch, model)]),
    // New session button
    div(class="sidebar-footer", [
      button(class="btn-new-session", on_click=dispatch(NewSessionClicked), [
        text("+ 新会话"),
      ]),
    ]),
  ])
}

///|
fn view_session_groups(
  dispatch : @cmd.Dispatch[Msg],
  model : Model,
) -> @html.Html {
  match model.sessions {
    @util.Success(sessions) => {
      let filtered = filter_sessions(sessions, model.search_query)
      let project_ids = unique_project_ids(filtered)
      let groups = project_ids.map(fn(pid) {
        let project_name = match model.projects {
          @util.Success(projects) => find_project_name(projects, pid)
          _ => pid
        }
        let group_sessions = filtered.filter(fn(s) { s.project_id == pid })
        let items = group_sessions.map(fn(s) {
          view_session_item(dispatch, model, s)
        })
        div(class="session-group", [
          div(class="session-group-header", [text("📂 \{project_name}")]),
          div(class="session-group-items", items),
        ])
      })
      fragment(groups)
    }
    @util.Loading => skeleton_session_list(5)
    @util.Failed(msg) => load_failed("sessions", msg)
  }
}

///|
fn view_session_item(
  dispatch : @cmd.Dispatch[Msg],
  model : Model,
  s : @types.Session,
) -> @html.Html {
  let active = s.id == model.active_session_id
  let item_class = if active { "session-item active" } else { "session-item" }
  let status_icon = session_status_icon(s.status)
  div(class=item_class, on_click=dispatch(SelectSession(s.id)), [
    div(class="session-title-row", [
      span(class="session-status-icon", [text(status_icon)]),
      span(class="session-title", [text(s.title)]),
      if s.is_starred {
        span(class="session-star", [text("⭐")])
      } else {
        nothing
      },
    ]),
    div(class="session-preview", [
      span(class="session-agent", [text("🤖 \{s.agent_name}")]),
      if s.unread_count > 0 {
        span(class="unread-badge", [text("\{s.unread_count}")])
      } else {
        nothing
      },
    ]),
  ])
}

///|
fn filter_sessions(
  sessions : Array[@types.Session],
  query : String,
) -> Array[@types.Session] {
  if query.length() == 0 {
    sessions
  } else {
    sessions.filter(fn(s) {
      s.title.contains(query) || s.agent_name.contains(query)
    })
  }
}

///|
fn unique_project_ids(sessions : Array[@types.Session]) -> Array[String] {
  let ids : Array[String] = []
  sessions.each(fn(s) {
    if !ids.contains(s.project_id) {
      ids.push(s.project_id)
    }
  })
  ids
}

///|
fn find_project_name(projects : Array[@types.Project], pid : String) -> String {
  let found = projects.filter(fn(p) { p.id == pid })
  if found.length() > 0 {
    found[0].name
  } else {
    pid
  }
}

///|
fn session_status_icon(status : @types.SessionStatus) -> String {
  match status {
    @types.Idle => "🟢"
    @types.Busy => "🟡"
    @types.Compacting => "🔵"
    @types.Error => "🔴"
  }
}
