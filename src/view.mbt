///|
using @html {
  aside,
  div,
  h2,
  h3,
  h4,
  span,
  button,
  input,
  textarea,
  text,
  nothing,
  section,
  header,
  footer,
  details,
  summary,
  p,
  pre,
  select,
  option,
  fragment,
}

///|
pub fn view(dispatch : @cmd.Dispatch[Msg], model : Model) -> @html.Html {
  div(class="app", [
    view_sidebar(dispatch, model),
    view_chat(dispatch, model),
    view_detail(dispatch, model),
    // Status bar
    footer(class="statusbar", [span([text(status_label(model))])]),
  ])
}
