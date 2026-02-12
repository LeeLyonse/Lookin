import { McpServer } from "@modelcontextprotocol/sdk/server/mcp.js";
import { z } from "zod";
import {
  getStatus,
  listApps,
  getHierarchy,
  getSelectedView,
  getViewDetail,
  searchViews,
  reloadHierarchy,
} from "./lookin-client.js";

export function registerTools(server: McpServer): void {
  server.tool(
    "lookin_get_status",
    "Check Lookin connection status. Returns whether Lookin Client is running and if an iOS app is connected.",
    {},
    async () => {
      const result = await getStatus();
      return {
        content: [{ type: "text", text: JSON.stringify(result, null, 2) }],
        isError: !!result.error,
      };
    }
  );

  server.tool(
    "lookin_list_apps",
    "List all connected iOS apps in Lookin.",
    {},
    async () => {
      const result = await listApps();
      return {
        content: [{ type: "text", text: JSON.stringify(result, null, 2) }],
        isError: !!result.error,
      };
    }
  );

  server.tool(
    "lookin_get_ui_tree",
    "Get the full UI view hierarchy tree of the current iOS app. Default format is 'text' (indented text tree, token-efficient). Use 'json' for structured data. Each text line shows: className address oid (subtitle) {x,y,w,h} [flags]",
    {
      format: z
        .enum(["text", "json"])
        .default("text")
        .describe(
          "Output format. 'text' is compact and token-efficient (recommended). 'json' gives structured data."
        ),
    },
    async ({ format }) => {
      const result = await getHierarchy(format);
      if (result.error) {
        return {
          content: [{ type: "text", text: JSON.stringify(result, null, 2) }],
          isError: true,
        };
      }
      // For text format, return the tree string directly to save tokens
      if (format === "text" && typeof result.tree === "string") {
        return {
          content: [{ type: "text", text: result.tree }],
        };
      }
      return {
        content: [{ type: "text", text: JSON.stringify(result, null, 2) }],
      };
    }
  );

  server.tool(
    "lookin_get_selected_view",
    "Get detailed info about the currently selected view in Lookin. Returns className, address, oid, frame, bounds, alpha, hidden state, viewController, and more.",
    {},
    async () => {
      const result = await getSelectedView();
      return {
        content: [{ type: "text", text: JSON.stringify(result, null, 2) }],
        isError: !!result.error,
      };
    }
  );

  server.tool(
    "lookin_get_view_detail",
    "Get detailed attributes of a specific view by its oid (object ID). Use this after getting the UI tree to inspect a particular view.",
    {
      oid: z
        .string()
        .describe("The oid of the view to inspect (from UI tree output)."),
    },
    async ({ oid }) => {
      const result = await getViewDetail(oid);
      return {
        content: [{ type: "text", text: JSON.stringify(result, null, 2) }],
        isError: !!result.error,
      };
    }
  );

  server.tool(
    "lookin_search_views",
    "Search views by class name, text content, ivar name, or memory address.",
    {
      keyword: z.string().describe("Search keyword (class name, text, address, etc.)"),
    },
    async ({ keyword }) => {
      const result = await searchViews(keyword);
      return {
        content: [{ type: "text", text: JSON.stringify(result, null, 2) }],
        isError: !!result.error,
      };
    }
  );

  server.tool(
    "lookin_reload_hierarchy",
    "Reload the UI hierarchy from the iOS device. Call this before getting the UI tree to ensure you have the latest data, especially if the user may have navigated to a different screen.",
    {},
    async () => {
      const result = await reloadHierarchy();
      return {
        content: [{ type: "text", text: JSON.stringify(result, null, 2) }],
        isError: !!result.error,
      };
    }
  );
}
