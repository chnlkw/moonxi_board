///|
fn main {
  let config = @types.make_server_config(@board.base_url(), "opencode", "")
  let model = @board.init_model(config)
  let app = @rabbita.cell(model~, update=@board.update, view=@board.view)
  @rabbita.new(app).mount("app")
}
