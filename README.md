![Preview](https://cdn.lookin.work/public/style/images/independent/homepage/preview_en_1x.jpg "Preview")

# MCP Server (AI Agent Integration)

Lookin includes an MCP (Model Context Protocol) server that allows AI agents (like Claude) to inspect iOS app UI hierarchies.

### Setup
```json
{
  "mcpServers": {
    "lookin": {
      "command": "npx",
      "args": ["-y", "lookin-mcp"]
    }
  }
}
```

See [LookinMCP/README.md](LookinMCP/README.md) for details.

# Introduction
You can inspect and modify views in iOS app via Lookin, just like UI Inspector in Xcode, or another app called Reveal.

Official Website：https://lookin.work/

# Integration Guide
To use Lookin macOS app, you need to integrate LookinServer (iOS Framework of Lookin) into your iOS project.

> **Warning**
Never integrate LookinServer in Release building configuration.

## via CocoaPods:
### Swift Project
`pod 'LookinServer', :subspecs => ['Swift'], :configurations => ['Debug']`
### Objective-C Project
`pod 'LookinServer', :configurations => ['Debug']`

### Optional Debug Helper Pods
This fork keeps the iOS-side debug helpers split by purpose, so each app can
integrate only what it needs:

| Pod | Purpose |
|-----|---------|
| `LookinExtras` | Adds automatic UI attributes through LookinServer's `lookin_customDebugInfos`, such as `layer.maskedCorners` and common UIKit attributed string values. |
| `LookinDump` | Adds the `lkdump__...` Lookin Console property-chain dumper for Swift stored properties and Objective-C no-argument getters. |
| `LookinTouch` | Adds debug-only touch, swipe, and keyboard commands callable from Lookin Console or MCP. |

Add any of them to the same Debug app target that already integrates
`LookinServer`:

```ruby
pod 'LookinExtras',
    :git => 'https://github.com/LeeLyonse/Lookin.git',
    :tag => 'extras-v0.2.0',
    :configurations => ['Debug']

pod 'LookinDump',
    :git => 'https://github.com/LeeLyonse/Lookin.git',
    :tag => 'dump-v0.1.0',
    :configurations => ['Debug']

pod 'LookinTouch',
    :git => 'https://github.com/LeeLyonse/Lookin.git',
    :tag => 'touch-v0.0.1',
    :configurations => ['Debug']
```

`LookinDump` adds selectors such as `lkdump__nextResponder__viewModel__currentOptionsForMap` and `lkdump__frame`. It supports Swift stored-property reflection and Objective-C no-argument getter reading, including common scalar return types. Each `lkdump__` path component is invoked as a zero-argument method, so avoid naming value-returning methods with side effects (e.g. `becomeFirstResponder`); Swift computed properties not exposed to Objective-C resolve to `<nil>`.

`LookinTouch` adds selectors such as `lktouch__tapVisibleCenter`, `lktouch__swipeUp`, `lktype_hex__E4BDA0E5A5BD`, `lkdelete__3`, and `lkreturn`. They are intended for local Debug automation only and use private UIKit/IOKit APIs, so never include this pod in Release builds.

This fork also expands `attributeGroups` in the macOS client's JSON detail output, so MCP agents can read the extra attributes exposed by `LookinExtras`. The MCP server also exposes `lookin_invoke_method`, which can call the same no-argument selectors used by Lookin Console, including `LookinDump` and `LookinTouch` commands when the debug app integrates those pods.

## via Swift Package Manager:
`https://github.com/QMUI/LookinServer/`

# Repository
LookinServer: https://github.com/QMUI/LookinServer

macOS app: https://github.com/hughkli/Lookin/

# Tips
- How to display custom information in Lookin: https://bytedance.larkoffice.com/docx/TRridRXeUoErMTxs94bcnGchnlb
- How to display more member variables in Lookin: https://bytedance.larkoffice.com/docx/CKRndHqdeoub11xSqUZcMlFhnWe
- How to turn on Swift optimization for Lookin: https://bytedance.larkoffice.com/docx/GFRLdzpeKoakeyxvwgCcZ5XdnTb
- Documentation Collection: https://bytedance.larkoffice.com/docx/Yvv1d57XQoe5l0xZ0ZRc0ILfnWb

# Acknowledgements
https://qxh1ndiez2w.feishu.cn/docx/YIFjdE4gIolp3hxn1tGckiBxnWf

---
# MCP 服务（AI Agent 集成）

Lookin 内置了 MCP (Model Context Protocol) 服务，允许 AI Agent（如 Claude）实时查询 iOS 应用的 UI 视图层级。

### 配置
```json
{
  "mcpServers": {
    "lookin": {
      "command": "npx",
      "args": ["-y", "lookin-mcp"]
    }
  }
}
```

详见 [LookinMCP/README.md](LookinMCP/README.md)。

# 简介
Lookin 可以查看与修改 iOS App 里的 UI 对象，类似于 Xcode 自带的 UI Inspector 工具，或另一款叫做 Reveal 的软件。

官网：https://lookin.work/

# 安装 LookinServer Framework
如果这是你的 iOS 项目第一次使用 Lookin，则需要先把 LookinServer 这款 iOS Framework 集成到你的 iOS 项目中。

> **Warning**
记得不要在 AppStore 模式下集成 LookinServer。

## 通过 CocoaPods：

### Swift 项目
`pod 'LookinServer', :subspecs => ['Swift'], :configurations => ['Debug']`
### Objective-C 项目
`pod 'LookinServer', :configurations => ['Debug']`

### 可选 Debug 辅助 Pod
这个 fork 把 iOS 侧调试能力按用途拆开了，项目可以只集成自己需要的部分：

| Pod | 用途 |
|-----|------|
| `LookinExtras` | 通过 LookinServer 的 `lookin_customDebugInfos` 扩展点补充自动 UI 属性，例如 `layer.maskedCorners` 和常见 UIKit 富文本属性。 |
| `LookinDump` | 增加 `lkdump__...` Lookin Console 属性链打印能力，用于读取 Swift stored property 和 Objective-C 无参 getter。 |
| `LookinTouch` | 增加 Debug-only 点击、滑动、键盘输入命令，可以通过 Lookin Console 或 MCP 调用。 |

把需要的 pod 加到已经集成 `LookinServer` 的同一个 Debug App target：

```ruby
pod 'LookinExtras',
    :git => 'https://github.com/LeeLyonse/Lookin.git',
    :tag => 'extras-v0.2.0',
    :configurations => ['Debug']

pod 'LookinDump',
    :git => 'https://github.com/LeeLyonse/Lookin.git',
    :tag => 'dump-v0.1.0',
    :configurations => ['Debug']

pod 'LookinTouch',
    :git => 'https://github.com/LeeLyonse/Lookin.git',
    :tag => 'touch-v0.0.1',
    :configurations => ['Debug']
```

`LookinDump` 提供 `lkdump__nextResponder__viewModel__currentOptionsForMap`、`lkdump__frame` 这类命令。它支持读取 Swift stored property，以及 Objective-C 无参 getter，包括常见标量返回值。`lkdump__` 路径每一段都会作为无参方法被调用，因此不要使用有副作用的取值方法（例如 `becomeFirstResponder`）；未暴露给 Objective-C 的 Swift computed property 会解析为 `<nil>`。

`LookinTouch` 提供 `lktouch__tapVisibleCenter`、`lktouch__swipeUp`、`lktype_hex__E4BDA0E5A5BD`、`lkdelete__3`、`lkreturn` 这类命令。它只用于本地 Debug 自动化，并使用了私有 UIKit/IOKit API，绝对不要集成到 Release 构建里。

这个 fork 的 macOS Client 也展开了 `attributeGroups` 的 JSON detail 输出，所以 MCP Agent 可以读取 `LookinExtras` 暴露出来的额外属性。MCP server 也提供 `lookin_invoke_method`，可以调用和 Lookin Console 相同的无参 selector；只要 Debug app 集成了对应 pod，就能调用 `LookinDump` 和 `LookinTouch` 的命令。

## 通过 Swift Package Manager:
`https://github.com/QMUI/LookinServer/`

# 源代码仓库

iOS 端 LookinServer：https://github.com/QMUI/LookinServer

macOS 端软件：https://github.com/hughkli/Lookin/

# 技巧
- 如何在 Lookin 中展示自定义信息: https://bytedance.larkoffice.com/docx/TRridRXeUoErMTxs94bcnGchnlb
- 如何在 Lookin 中展示更多成员变量: https://bytedance.larkoffice.com/docx/CKRndHqdeoub11xSqUZcMlFhnWe
- 如何为 Lookin 开启 Swift 优化: https://bytedance.larkoffice.com/docx/GFRLdzpeKoakeyxvwgCcZ5XdnTb
- 文档汇总：https://bytedance.larkoffice.com/docx/Yvv1d57XQoe5l0xZ0ZRc0ILfnWb

# 鸣谢
https://qxh1ndiez2w.feishu.cn/docx/YIFjdE4gIolp3hxn1tGckiBxnWf
