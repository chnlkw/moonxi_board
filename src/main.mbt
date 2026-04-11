///|
fn main {
  let config = {
    base_url: "http://localhost:4096",
    username: "opencode",
    password: "",
  }
  let model = init_model(config)
  let app = @rabbita.cell(model~, update~, view~)
  @rabbita.new(app).mount("app")
}
