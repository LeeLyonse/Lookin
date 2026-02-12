# Lookin MCP Server

MCP (Model Context Protocol) server for [Lookin](https://lookin.work), enabling AI agents to inspect iOS app UI hierarchies in real-time.

## Architecture

```
AI Agent <--MCP(stdio)--> LookinMCP (Node.js) <--HTTP--> Lookin Client (macOS) <--Peertalk--> iOS App
```

## Prerequisites

- Lookin Client (macOS app) running with the embedded HTTP server (port 56780)
- An iOS app connected to Lookin with LookinServer SDK integrated

## Install

```bash
npm install -g lookin-mcp
```

Or use directly with npx (no install needed).

## MCP Configuration

Add to your MCP config (e.g. `~/.claude/mcp.json`):

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

## Available Tools

| Tool | Description |
|------|-------------|
| `lookin_get_status` | Check if Lookin is running and an iOS app is connected |
| `lookin_list_apps` | List connected iOS apps |
| `lookin_reload_hierarchy` | Reload UI tree from iOS device (call before get_ui_tree for fresh data) |
| `lookin_get_ui_tree` | Get full UI hierarchy (text or JSON format) |
| `lookin_get_selected_view` | Get details of the currently selected view |
| `lookin_get_view_detail` | Get detailed attributes of a view by oid |
| `lookin_search_views` | Search views by class name, text, or address |

## Text Tree Format

The default `text` format for `lookin_get_ui_tree` is optimized for token efficiency:

```
UIWindow 0x7f8 oid=123 {0,0,390,844}
  UIView 0x7f9 oid=124 (MainVC.view) {0,0,390,844}
    UILabel 0x7fa oid=125 {145,100,100,20}
    UIButton 0x7fb oid=126 {155,400,80,44} [hidden]
```

Each line: `{indent}{className} {address} oid={id} ({subtitle}) {x,y,w,h} [flags]`

Use `format: "json"` when you need structured data for programmatic processing.

## Development

```bash
cd LookinMCP
npm install
npm run build
```

## License

GPL-3.0
