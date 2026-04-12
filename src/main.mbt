///|
fn main {
  let config = @types.make_server_config(base_url(), "opencode", "")
  let model = init_model(config)
  let app = @rabbita.cell(model~, update~, view~)
  @rabbita.new(app).mount("app")
}
