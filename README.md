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
# 1. 安装依赖
moon install

# 2. 构建
moon build --target js
cp _build/js/debug/build/src/src.js web/src.js

# 3. 启动 OpenCode Serve
opencode serve

# 4. 启动静态文件服务
cd web && python3 -m http.server 8080
```

访问 `http://localhost:8080`，页面顶部输入框填入 OpenCode Serve 地址，点「连接」。

### Docker

```bash
docker run -d \
  -p 8080:80 \
  ghcr.io/chnlkw/moonxi-board:latest
```

### K8s

```bash
bash deploy/deploy.sh
```

同域部署时，用 Nginx 反向代理将 Board 静态文件和 OpenCode Serve API 路由到同一域名下。

## 连接 OpenCode Serve

页面顶部有连接配置栏：

1. **输入框**: 填写 OpenCode Serve 的完整地址（如 `http://192.168.1.100:4096`）
2. **点击「连接」**: 保存到浏览器 localStorage，刷新后不会丢失
3. 同域部署时无需手动填写，自动使用当前域名

### OpenCode Serve CORS 配置

如果 Board 和 OpenCode Serve 不同域，需要开启 CORS：

```bash
opencode serve --cors "https://your-board-domain.com"
```

### 同域 Nginx 配置（推荐）

```nginx
server {
    listen 443 ssl;
    server_name your-domain.com;

    root /usr/share/nginx/html;
    index index.html;

    location / {
        try_files $uri $uri/ /index.html;
    }

    # 代理 OpenCode Serve API
    location ~ ^/(session|global|event|auth) {
        proxy_pass http://opencode:4096;
        proxy_http_version 1.1;
        # SSE 支持
        proxy_set_header Connection '';
        proxy_buffering off;
        proxy_cache off;
        chunked_transfer_encoding off;
    }
}
```

## API 端点

Board 使用以下 OpenCode Serve 端点：

| 方法 | 路径 | 说明 |
|------|------|------|
| GET | `/global/health` | 健康检查 |
| GET | `/session` | 获取会话列表 |
| POST | `/session` | 创建新会话 |
| DELETE | `/session/:id` | 删除会话 |
| GET | `/session/:id/message` | 获取消息列表 |
| POST | `/session/:id/message` | 发送消息 |
| GET | `/global/event` | SSE 全局事件流 |

### 发送消息格式

```json
POST /session/:id/message
{
  "parts": [{ "type": "text", "text": "你好" }],
  "agent": "build"
}
```

## 开发

```bash
moon check --target js   # 类型检查
moon test --target js    # 运行测试
moon fmt                 # 格式化
moon build --target js   # 构建
```

## 项目结构

```
moonxi_board/
├── deploy/                  # K8s 部署脚本和配置
│   ├── deploy.sh            # 一键部署脚本
│   └── k8s.yaml             # K8s 资源定义
├── docs/
│   └── design.md            # 设计文档
├── knowledge/               # 知识
│   └── rabbita.md           # Rabbita 框架知识
├── memory/                  # 记忆
├── tasks/                   # 任务
├── web/
│   └── index.html           # 入口 HTML (含 CSS)
├── src/                     # MoonBit 源码 (Rabbita app)
│   ├── main.mbt             # 入口: mount app
│   ├── model.mbt            # Model + Msg + 数据类型
│   ├── update.mbt           # update (纯函数状态转换)
│   ├── view.mbt             # view (声明式 HTML EDSL)
│   ├── view_sidebar.mbt     # Sidebar 视图
│   ├── view_chat.mbt        # Chat 视图
│   ├── view_detail.mbt      # Detail 视图
│   ├── subscriptions.mbt    # SSE + 键盘订阅
│   ├── api.mbt              # OpenCode API Cmd
│   ├── parse.mbt            # JSON 解析
│   ├── helpers.mbt          # 工具函数 + localStorage
│   ├── game.mbt             # 游戏化逻辑
│   └── *_test.mbt           # 测试
└── cmd/main/                # CLI 入口
```

## 配置

`localStorage` key `moonxi_base_url` — 保存 OpenCode Serve 地址，刷新后保留。在页面连接栏中修改即可。

## License

MIT
