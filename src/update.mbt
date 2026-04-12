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
      ])
      (cmd, { ..model, connection: Connecting })
    }
    GotHealth(Ok(_)) => (@cmd.none, { ..model, connection: Connected })
    GotHealth(Err(_)) =>
      (@cmd.none, { ..model, connection: Error("health check failed") })
    GotSessions(Ok(sessions)) =>
      (@cmd.none, { ..model, sessions: Success(sessions) })
    GotSessions(Err(msg)) => {
      println(msg)
      (@cmd.none, { ..model, sessions: Failed(msg) })
    }
    GotAgents(Ok(agents)) => (@cmd.none, { ..model, agents: Success(agents) })
    GotAgents(Err(msg)) => (@cmd.none, { ..model, agents: Failed(msg) })
    GotProjects(Ok(projects)) =>
      (@cmd.none, { ..model, projects: Success(projects) })
    GotProjects(Err(msg)) => (@cmd.none, { ..model, projects: Failed(msg) })
    SelectSession(id) => {
      let _ = model.messages.set(id, Loading)
      let cmd = api_load_messages(dispatch, model.config, id)
      (cmd, { ..model, active_session_id: id, messages: model.messages })
    }
    GotMessages(sid, Ok(messages)) => {
      let _ = model.messages.set(sid, Success(messages))
      (@cmd.none, { ..model, messages: model.messages })
    }
    GotMessages(sid, Err(msg)) => {
      let _ = model.messages.set(sid, Failed(msg))
      (@cmd.none, { ..model, messages: model.messages })
    }
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
    MessageSent(Ok(messages)) => {
      let sid = model.active_session_id
      match model.messages.get(sid) {
        Some(Success(existing)) => {
          let _ = model.messages.set(sid, Success(existing + messages))
          (@cmd.none, { ..model, messages: model.messages })
        }
        _ => {
          let _ = model.messages.set(sid, Success(messages))
          (@cmd.none, { ..model, messages: model.messages })
        }
      }
    }
    MessageSent(Err(_)) => (@cmd.none, model)
    AgentSelected(name) => (@cmd.none, { ..model, selected_agent: name })
    ProjectSelected(id) => (@cmd.none, { ..model, active_project_id: id })
    SearchInputChanged(query) => (@cmd.none, { ..model, search_query: query })
    StarSession(id) =>
      match model.sessions {
        Success(sessions) =>
          (@cmd.none, { ..model, sessions: Success(toggle_star(sessions, id)) })
        _ => (@cmd.none, model)
      }
    DeleteSession(id) => {
      let cmd = api_delete_session(dispatch, model.config, id)
      (cmd, model)
    }
    ToggleSidebar => (@cmd.none, { ..model, sidebar_open: !model.sidebar_open })
    ToggleDetail => (@cmd.none, { ..model, detail_open: !model.detail_open })
    SSEConnected => (@cmd.none, { ..model, sse_connected: true })
    SSEDisconnected => (@cmd.none, { ..model, sse_connected: false })
    SSESessionCreated(s) =>
      match model.sessions {
        Success(sessions) =>
          (@cmd.none, { ..model, sessions: Success(sessions + [s]) })
        Loading | Failed(_) => (@cmd.none, { ..model, sessions: Success([s]) })
      }
    SSESessionUpdated(s) =>
      match model.sessions {
        Success(sessions) =>
          (
            @cmd.none,
            { ..model, sessions: Success(update_session(sessions, s)) },
          )
        _ => (@cmd.none, model)
      }
    SSESessionDeleted(id) =>
      match model.sessions {
        Success(sessions) =>
          (
            @cmd.none,
            {
              ..model,
              sessions: Success(sessions.filter(fn(s) { s.id != id })),
            },
          )
        _ => (@cmd.none, model)
      }
    SSEMessageUpdated(sid, msg) => (@cmd.none, append_message(model, sid, msg))
    KeyPressed(_key) => (@cmd.none, model)
    BaseUrlChanged(text) => (@cmd.none, { ..model, base_url_input: text })
    BaseUrlSubmitted => {
      let url = model.base_url_input
      save_base_url(url)
      let new_config = { ..model.config, base_url: url }
      let cmd = @cmd.batch([
        api_health_check(dispatch, new_config),
        api_load_sessions(dispatch, new_config),
      ])
      (cmd, { ..model, config: new_config, connection: Connecting })
    }
  }
}
