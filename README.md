# Moonxi Board

多 Agent 看板应用 — 游戏化设计，微信风格聊天界面，连接 OpenCode Serve API。

基于 [Rabbita](https://github.com/moonbit-community/rabbita) (TEA 架构) + [MoonBit](https://www.moonbitlang.cn/) 构建。

## 技术栈

- **UI 框架**: [Rabbita](https://github.com/moonbit-community/rabbita) — TEA 架构，声明式 HTML EDSL，~15KB gzip
- **语言**: MoonBit (JS Backend) — 类型安全，模式匹配，编译为 JS
- **后端 API**: [OpenCode Serve](https://opencode.ai/docs/server/) — `opencode serve` 本地 HTTP API
- **实时通信**: SSE (封装为 Rabbita custom subscription)

## 功能

- 微信风格聊天界面，多会话管理
- 多 Agent 切换对话（Sisyphus、Oracle、Explore 等）
- 多 Project 分组管理
- SSE 实时消息流
- Agent 角色化 + 任务图标 + 连击计数等游戏化元素
- 全 MoonBit — 无 JS Bridge，UI + 逻辑类型安全

## 快速开始

```bash
# 1. 启动 OpenCode Serve
opencode serve --port 4096

# 2. 构建 MoonBit
moon build --target js

# 3. 打开前端
npx serve web/
```

## 项目结构

```
moonxi_board/
├── docs/
│   └── design.md          # 设计文档
├── knowledge/             # 知识
│   └── rabbita.md         # Rabbita 框架知识
├── memory/                # 记忆
├── tasks/                 # 任务
├── web/
│   └── index.html         # 入口 HTML (含 CSS)
├── src/                   # MoonBit 源码 (Rabbita app)
│   ├── main.mbt           # 入口: mount app
│   ├── model.mbt          # Model + Msg + 数据类型
│   ├── update.mbt         # update (纯函数状态转换)
│   ├── view.mbt           # view (声明式 HTML EDSL)
│   ├── view_sidebar.mbt   # Sidebar 视图
│   ├── view_chat.mbt      # Chat 视图
│   ├── view_detail.mbt    # Detail 视图
│   ├── subscriptions.mbt  # SSE + 键盘订阅
│   ├── api.mbt            # OpenCode API Cmd
│   ├── parse.mbt          # JSON 解析
│   └── ...
└── cmd/main/              # CLI 入口
```

## 文档

- [设计文档](docs/design.md)

## License

MIT
