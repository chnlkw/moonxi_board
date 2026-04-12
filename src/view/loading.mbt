///|
pub fn skeleton_session_list(count : Int) -> @html.Html {
  let items = Array::makei(count, fn(_) {
    @html.div(class="skeleton-item", [
      @html.div(class="skeleton-avatar", [@html.nothing]),
      @html.div(class="skeleton-text", [
        @html.div(class="skeleton-line-long", [@html.nothing]),
        @html.div(class="skeleton-line-short", [@html.nothing]),
      ]),
    ])
  })
  @html.div(class="skeleton-list", items)
}

///|
pub fn skeleton_messages(count : Int) -> @html.Html {
  let items = Array::makei(count, fn(i) {
    let cls = if i % 2 == 0 {
      "skeleton-msg-left"
    } else {
      "skeleton-msg-right"
    }
    @html.div(class=cls, [
      @html.div(class="skeleton-bubble", [
        @html.div(class="skeleton-line-long", [@html.nothing]),
        @html.div(class="skeleton-line-short", [@html.nothing]),
      ]),
    ])
  })
  @html.div(items)
}

///|
pub fn skeleton_agents() -> @html.Html {
  @html.div(class="skeleton-agents", [
    @html.div(class="skeleton-avatar-small", [@html.nothing]),
    @html.text("Loading agents..."),
  ])
}

///|
pub fn loading_spinner() -> @html.Html {
  @html.div(class="loading-spinner", [@html.text("Loading...")])
}

///|
pub fn load_failed(resource : String, error : String) -> @html.Html {
  @html.div(class="load-failed", [
    @html.p(class="load-failed-title", [@html.text("Failed to load {resource}")]),
    @html.p(class="load-failed-msg", [@html.text(error)]),
  ])
}

///|
pub fn empty_state(message : String) -> @html.Html {
  @html.div(class="empty-state", [@html.text(message)])
}
