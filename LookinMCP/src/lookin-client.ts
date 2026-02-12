const LOOKIN_BASE_URL = "http://127.0.0.1:56780";
const TIMEOUT_MS = 10000;

interface LookinResponse {
  error?: string;
  [key: string]: unknown;
}

async function fetchJSON(
  path: string,
  method: "GET" | "POST" = "GET"
): Promise<LookinResponse> {
  const url = `${LOOKIN_BASE_URL}${path}`;
  const controller = new AbortController();
  const timeout = setTimeout(() => controller.abort(), TIMEOUT_MS);

  try {
    const response = await fetch(url, { method, signal: controller.signal });
    const data = (await response.json()) as LookinResponse;
    return data;
  } catch (err: unknown) {
    if (err instanceof Error && err.name === "AbortError") {
      return { error: "Request to Lookin Client timed out. Is Lookin running?" };
    }
    return {
      error: `Cannot connect to Lookin Client at ${LOOKIN_BASE_URL}. Make sure Lookin is running.`,
    };
  } finally {
    clearTimeout(timeout);
  }
}

export async function getStatus(): Promise<LookinResponse> {
  return fetchJSON("/api/status");
}

export async function listApps(): Promise<LookinResponse> {
  return fetchJSON("/api/apps");
}

export async function getHierarchy(
  format: "text" | "json" = "text"
): Promise<LookinResponse> {
  return fetchJSON(`/api/hierarchy?format=${format}`);
}

export async function getSelectedView(): Promise<LookinResponse> {
  return fetchJSON("/api/selected");
}

export async function getViewDetail(oid: string): Promise<LookinResponse> {
  return fetchJSON(`/api/view?oid=${encodeURIComponent(oid)}`);
}

export async function searchViews(keyword: string): Promise<LookinResponse> {
  return fetchJSON(`/api/search?keyword=${encodeURIComponent(keyword)}`);
}

export async function reloadHierarchy(): Promise<LookinResponse> {
  return fetchJSON("/api/reload", "POST");
}
