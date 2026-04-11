///|
pub fn update(
  dispatch : @cmd.Dispatch[Msg],
  msg : Msg,
  model : Model,
) -> (@cmd.Cmd, Model) {
  match msg {
    AppStarted => {
      let cmd = @cmd.batch([
        api_health_check(dispatch, model.config),
        api_load_sessions(dispatch, model.config),
        api_load_agents(dispatch, model.config),
        api_load_projects(dispatch, model.config),
      ])
      (cmd, { ..model, connection: Connecting })
    }
    GotHealth(Ok(_)) => (@cmd.none, { ..model, connection: Connected })
    GotHealth(Err(_)) =>
      (@cmd.none, { ..model, connection: Error("health check failed") })
    GotSessions(Ok(sessions)) => (@cmd.none, { ..model, sessions, })
    GotSessions(Err(_)) => (@cmd.none, model)
    GotAgents(Ok(agents)) => (@cmd.none, { ..model, agents, })
    GotAgents(Err(_)) => (@cmd.none, model)
    GotProjects(Ok(projects)) => (@cmd.none, { ..model, projects, })
    GotProjects(Err(_)) => (@cmd.none, model)
    SelectSession(id) => {
      let cmd = api_load_messages(dispatch, model.config, id)
      (cmd, { ..model, active_session_id: id })
    }
    GotMessages(_sid, Ok(_messages)) => (@cmd.none, model)
    GotMessages(_, Err(_)) => (@cmd.none, model)
    NewSessionClicked => {
      let cmd = api_create_session(dispatch, model.config)
      (cmd, model)
    }
    InputChanged(text) => (@cmd.none, { ..model, input_text: text })
    SendClicked =>
      if model.input_text == "" || model.active_session_id == "" {
        (@cmd.none, model)
      } else {
        let cmd = api_send_message(
          dispatch,
          model.config,
          model.active_session_id,
          model.input_text,
          model.selected_agent,
        )
        (cmd, { ..model, input_text: "" })
      }
    MessageSent(Ok(_messages)) => (@cmd.none, model)
    MessageSent(Err(_)) => (@cmd.none, model)
    AgentSelected(name) => (@cmd.none, { ..model, selected_agent: name })
    ProjectSelected(id) => (@cmd.none, { ..model, active_project_id: id })
    SearchInputChanged(query) => (@cmd.none, { ..model, search_query: query })
    StarSession(id) =>
      (@cmd.none, { ..model, sessions: toggle_star(model.sessions, id) })
    DeleteSession(id) => {
      let cmd = api_delete_session(dispatch, model.config, id)
      (cmd, model)
    }
    ToggleSidebar => (@cmd.none, { ..model, sidebar_open: !model.sidebar_open })
    ToggleDetail => (@cmd.none, { ..model, detail_open: !model.detail_open })
    SSEConnected => (@cmd.none, { ..model, sse_connected: true })
    SSEDisconnected => (@cmd.none, { ..model, sse_connected: false })
    SSESessionCreated(s) =>
      (@cmd.none, { ..model, sessions: model.sessions + [s] })
    SSESessionUpdated(s) =>
      (@cmd.none, { ..model, sessions: update_session(model.sessions, s) })
    SSESessionDeleted(id) =>
      (
        @cmd.none,
        { ..model, sessions: model.sessions.filter(fn(s) { s.id != id }) },
      )
    SSEMessageUpdated(sid, msg) => (@cmd.none, append_message(model, sid, msg))
    KeyPressed(_key) => (@cmd.none, model)
  }
}
