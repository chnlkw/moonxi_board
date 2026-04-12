// game.mbt
// Game logic: agent icons, achievements, combo mechanics.

///|
pub fn agent_icon(agent_name : String) -> String {
  match agent_name {
    "build" | "sisyphus" => "🏗️"
    "oracle" => "🔮"
    "explore" => "🔍"
    "librarian" => "📚"
    "metis" => "🦉"
    "momus" => "🎭"
    _ => "🤖"
  }
}

///|
pub fn check_achievement(stats : @types.GameStats) -> String? {
  if stats.total_messages == 10 {
    Some("🎯 初次对话: 完成10条消息")
  } else if stats.total_messages == 50 {
    Some("💬 对话达人: 完成50条消息")
  } else if stats.combo_streak == 5 {
    Some("🔥 五连击: 连续5条消息")
  } else if stats.combo_streak == 10 {
    Some("⚡ 十连击: 连续10条消息")
  } else {
    None
  }
}

///|
pub fn increment_combo(stats : @types.GameStats) -> @types.GameStats {
  @types.make_game_stats(stats.total_messages, stats.combo_streak + 1)
}

///|
pub fn reset_combo(stats : @types.GameStats) -> @types.GameStats {
  @types.make_game_stats(stats.total_messages, 0)
}

///|
pub fn increment_messages(stats : @types.GameStats) -> @types.GameStats {
  @types.make_game_stats(stats.total_messages + 1, stats.combo_streak + 1)
}
