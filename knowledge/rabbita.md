# Rabbita 框架知识

> moonbit-community/rabbita | TEA 架构 | v0.11.5

## 基本信息

- **GitHub**: https://github.com/moonbit-community/rabbita
- **包名**: `moonbit-community/rabbita`
- **许可证**: Apache-2.0
- **原名**: Rabbit-TEA
- **生产案例**: [mooncakes.io](https://mooncakes.io)
- **Bundle**: ~15KB min+gzip

## 核心概念

### TEA 架构

```
View (Html) → Msg → Update (Model) → (Cmd, Model) → View
```

- **Model**: 不可变状态 struct
- **Msg**: 枚举所有事件（用户操作 + API 响应 + SSE）
- **update**: 纯函数 `(Dispatch[Msg], Msg, Model) → (Cmd, Model)`
- **view**: 纯函数 `(Dispatch[Msg], Model) → Html`
- **subscriptions**: 可选，`(Dispatch[Msg], Model) → Sub`

### Cell (模块化)

```moonbit
@rabbita.cell(
  model~,
  update~,
  view~,
  subscriptions?,
)
```

### simple_cell (无 Cmd)

```moonbit
@rabbita.simple_cell(
  model~,
  update=(msg, model) => new_model,
  view~,
)
```

## 子包 Import

```moonbit
import {
  "moonbit-community/rabbita" @rabbita
  "moonbit-community/rabbita/http" @http
  "moonbit-community/rabbita/sub" @sub
  "moonbit-community/rabbita/html" @html
  "moonbit-community/rabbita/websocket" @websocket
}
```

## HTML EDSL

```moonbit
using @html {div, h1, button, input, textarea, p, span, a, ul, li,
             section, header, footer, aside, main, nav, details, summary,
             pre, img, canvas}

// 基本用法
div([class="container", id="main"], [
  h1([], [text("Hello")]),
  button(on_click=dispatch(Msg::Click), [text("Click me")]),
])

// Input 事件
input([
  value=model.text,
  on_input=dispatch.map(txt => InputChanged(txt)),
])

// 条件渲染
if model.show {
  div([], [text("visible")])
} else {
  div([], [])
}

// 列表渲染
ul([], model.items.map(fn(item) {
  li([], [text(item.name)])
}))
```

## HTTP (@http)

```moonbit
// GET
@http.get("/api/data", expect=@http.Text(fn(result) {
  match result {
    Ok(text) => dispatch(GotData(Ok(text)))
    Err(msg) => dispatch(GotData(Err(msg)))
  }
}))

// GET JSON
@http.get("/api/data", expect=@http.Json(fn(result) { ... }))

// POST
@http.post("/api/data", body=@http.Json(body_data), expect=...)

// 完整 request
@http.request("/api/data", "DELETE", expect=..., body=@http.Empty)
```

## Subscriptions (@sub)

```moonbit
// 内置订阅
@sub.every(1000, dispatch(Tick))            // 定时器
@sub.on_resize(v => dispatch(Resized(v)))   // 窗口 resize
@sub.on_scroll(s => dispatch(Scrolled(s)))  // 滚动
@sub.on_key_down(k => dispatch(KeyDown(k))) // 键盘按下
@sub.on_key_up(k => dispatch(KeyUp(k)))     // 键盘抬起
@sub.on_mouse_move(m => dispatch(Mouse(m))) // 鼠标移动
@sub.on_visibility_change(h => dispatch(Visibility(h))) // 页面可见性
@sub.on_animation_frame(t => dispatch(Frame(t)))        // 动画帧

// 批量订阅
@sub.batch([sub1, sub2, sub3])

// 无订阅
@sub.none
```

## Custom Subscription

```moonbit
@sub.custom_sub(
  key,       // String, 唯一标识
  scope,     // @sub.Local 或 @sub.Global
  payload,   // Error 类型 (传给 loader)
  SubLoader(fn(payload, scheduler) {
    // 启动外部资源
    // 通过 scheduler.add_cmd(cmd) 发送消息
    Some({
      unload: fn(scheduler) { /* 清理 */ },
      update_tagger: fn(new_tagger) { /* 更新 */ },
    })
  }),
)
```

## WebSocket (@websocket)

```moonbit
// 连接
@websocket.connect(
  id="my-ws",
  url="ws://localhost:8080",
  on_event=dispatch.map(event => match event {
    Opened => WsOpened
    Message(text) => WsMessage(text)
    Closed(info) => WsClosed
    Errored => WsError
  }),
)

// 监听 (subscription 方式)
@websocket.listen(
  url,
  open=dispatch(WsOpened),
  message=dispatch.map(text => WsMessage(text)),
  close=dispatch.map(info => WsClosed(info)),
  error=dispatch(WsError),
)

// 发送
@websocket.send(id="my-ws", payload=@websocket.Text("hello"))

// 关闭
@websocket.close(id="my-ws")
```

## Cmd

```moonbit
// 无 Cmd
none()

// 批量 Cmd
@cmd.batch([cmd1, cmd2])

// 自定义 Cmd
@cmd.custom_cmd(kind=Immediately, fn(scheduler) {
  // 执行副作用
  // scheduler.add_cmd(dispatch(Msg))
})
```

## 注意事项

1. **必须 `#cfg(target="js")`** — Rabbita 只支持 JS Backend
2. **没有内置 SSE** — 需用 custom subscription + `extern "js"` 封装
3. **HTML 属性不全** — 复杂属性用 `style=["..."]` 内联
4. **view 必须用 `using @html`** — 声明用到的 HTML 标签
5. **Cell 可嵌套** — 子 Cell 通过 dispatch 转换 Msg 与父 Cell 通信

## 参考资料

- [Rabbit-TEA 博客](https://www.moonbitlang.cn/blog/rabbit-tea)
- [mooncakes.io 源码](https://github.com/moonbitlang/mooncakes.io) — 生产级 Rabbita 应用
- [Rabbita examples](https://github.com/moonbit-community/rabbita/tree/main/examples) — 官方示例
