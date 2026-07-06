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

### Recommended Debug Extras
For richer automatic UI attributes, add `LookinExtras` to the same Debug app target:

```ruby
pod 'LookinExtras',
    :git => 'https://github.com/LeeLyonse/Lookin.git',
    :tag => 'extras-v0.2.0',
    :configurations => ['Debug']
```

`LookinExtras` runs inside the debug iOS app and provides:

- Extra automatic attributes through LookinServer's `lookin_customDebugInfos` extension point, such as `layer.maskedCorners` and common UIKit attributed string values.

If you only need console property-chain dumping, or want to use it without UI extras, add `LookinDump`:

```ruby
pod 'LookinDump',
    :git => 'https://github.com/LeeLyonse/Lookin.git',
    :tag => 'dump-v0.1.0',
    :configurations => ['Debug']
```

`LookinDump` adds selectors such as `lkdump__nextResponder__viewModel__currentOptionsForMap` and `lkdump__frame`. It supports Swift stored-property reflection and Objective-C no-argument getter reading, including common scalar return types. Each `lkdump__` path component is invoked as a zero-argument method, so avoid naming value-returning methods with side effects (e.g. `becomeFirstResponder`); Swift computed properties not exposed to Objective-C resolve to `<nil>`.

This fork also expands `attributeGroups` in the macOS client's JSON detail output, so MCP agents can read the extra attributes exposed by `LookinExtras`.

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

### 推荐的 Debug 增强
为了获得更多自动 UI 属性，建议在同一个 Debug App target 里加入 `LookinExtras`：

```ruby
pod 'LookinExtras',
    :git => 'https://github.com/LeeLyonse/Lookin.git',
    :tag => 'extras-v0.2.0',
    :configurations => ['Debug']
```

`LookinExtras` 会运行在被调试的 iOS App 进程里，提供这些增强能力：

- 通过 LookinServer 的 `lookin_customDebugInfos` 扩展点补充自动采集属性，例如 `layer.maskedCorners` 和常见 UIKit 富文本属性。

如果项目只需要 Console 属性链打印，或者不想引入 UI extras，可以单独加入 `LookinDump`：

```ruby
pod 'LookinDump',
    :git => 'https://github.com/LeeLyonse/Lookin.git',
    :tag => 'dump-v0.1.0',
    :configurations => ['Debug']
```

`LookinDump` 提供 `lkdump__nextResponder__viewModel__currentOptionsForMap`、`lkdump__frame` 这类命令。它支持读取 Swift stored property，以及 Objective-C 无参 getter，包括常见标量返回值。`lkdump__` 路径每一段都会作为无参方法被调用，因此不要使用有副作用的取值方法（例如 `becomeFirstResponder`）；未暴露给 Objective-C 的 Swift computed property 会解析为 `<nil>`。

这个 fork 的 macOS Client 也展开了 `attributeGroups` 的 JSON detail 输出，所以 MCP Agent 可以读取 `LookinExtras` 暴露出来的额外属性。

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
