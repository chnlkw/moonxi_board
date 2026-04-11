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
pub fn check_achievement(stats : GameStats) -> String? {
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
pub fn increment_combo(stats : GameStats) -> GameStats {
  { ..stats, combo_streak: stats.combo_streak + 1 }
}

///|
pub fn reset_combo(stats : GameStats) -> GameStats {
  { ..stats, combo_streak: 0 }
}

///|
pub fn increment_messages(stats : GameStats) -> GameStats {
  {
    total_messages: stats.total_messages + 1,
    combo_streak: stats.combo_streak + 1,
  }
}
