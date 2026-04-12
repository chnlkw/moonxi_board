// subscriptions.mbt
// SSE subscription using extern "js" FFI + Rabbita's built-in subscriptions.
// Since Rabbita 0.11.8's custom_subscription is package-private,
// we start SSE as a side-effect and use @sub.every for heartbeat,
// plus @sub.on_key_down for keyboard events.

// === SSE FFI (JavaScript) ===

///|
extern "js" fn start_sse(
  url : String,
  on_event : (String, String) -> Unit,
) -> Unit =
  #|(url, on_event) => {
  #|  try {
  #|    globalThis.__moonxi_sse = new EventSource(url);
  #|    globalThis.__moonxi_sse.onmessage = (e) => {
  #|      try {
  #|        const data = JSON.parse(e.data);
  #|        on_event(data.type || "message", e.data);
  #|      } catch(ex) {
  #|        on_event("error", "");
  #|      }
  #|    };
  #|    globalThis.__moonxi_sse.onerror = () => {
  #|      on_event("error", "");
  #|    };
  #|  } catch(ex) {
  #|    on_event("error", "");
  #|  }
  #|}

///|
extern "js" fn stop_sse() -> Unit =
  #|() => {
  #|  if (globalThis.__moonxi_sse) {
  #|    globalThis.__moonxi_sse.close();
  #|    globalThis.__moonxi_sse = null;
  #|  }
  #|}

// === SSE Event Parsing ===

///|
/// Parse SSE event into Msg
fn parse_sse_event(event_type : String, data : String) -> Msg? {
  match event_type {
    "session.created" => Some(SSEConnected)
    "session.updated" => Some(SSEConnected)
    "session.deleted" => Some(SSESessionDeleted(data))
    "session.status" => Some(SSEConnected)
    "server.heartbeat" => Some(SSEConnected)
    "error" => Some(SSEDisconnected)
    _ => None
  }
}

// === Subscription Wiring ===

///|
/// SSE subscription — starts EventSource and uses periodic heartbeat.
/// The SSE callback dispatches messages directly via the cell's inbox.
fn sse_subscribe(
  dispatch : @cmd.Dispatch[Msg],
  config : @types.ServerConfig,
) -> @sub.Sub {
  let url = "\{config.base_url}/global/event"
  start_sse(url, fn(event_type, data) {
    let msg = parse_sse_event(event_type, data)
    match msg {
      Some(m) => {
        let _ = dispatch(m)
        ()
      }
      None => ()
    }
  })
  @sub.every(5000, dispatch(SSEConnected))
}

///|
/// Main subscriptions function — SSE + keyboard.
/// Wire into cell via: @rabbita.cell(model~, update~, view~, subscriptions~)
fn subscriptions(dispatch : @cmd.Dispatch[Msg], model : Model) -> @sub.Sub {
  @sub.batch([
    sse_subscribe(dispatch, model.config),
    @sub.on_key_down(fn(k) {
      match k.key() {
        "Enter" => dispatch(SendClicked)
        _ => @cmd.none
      }
    }),
  ])
}
