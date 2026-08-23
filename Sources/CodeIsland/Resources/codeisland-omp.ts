// CodeIsland OMP extension
// version: v4

import { execFileSync } from "node:child_process";
import { connect } from "node:net";
import { getuid } from "node:process";
import type { ExtensionAPI } from "@oh-my-pi/pi-coding-agent/extensibility/extensions/types";

const userId = getuid?.() ?? 0;
const SOCKET_PATH = `/tmp/codeisland-${userId}.sock`;

const ENV_KEYS = [
  "TERM_PROGRAM",
  "ITERM_SESSION_ID",
  "TERM_SESSION_ID",
  "TMUX",
  "TMUX_PANE",
  "KITTY_WINDOW_ID",
  "CMUX_SURFACE_ID",
  "CMUX_WORKSPACE_ID",
  "ZELLIJ_PANE_ID",
  "ZELLIJ_SESSION_NAME",
  "WEZTERM_PANE",
  "__CFBundleIdentifier",
] as const;

function collectEnv(): Record<string, string> {
  const env: Record<string, string> = {};
  for (const key of ENV_KEYS) {
    if (process.env[key]) env[key] = process.env[key]!;
  }
  return env;
}

function detectTty(): string | null {
  try {
    let pid = process.pid;
    for (let i = 0; i < 8; i++) {
      const out = execFileSync("ps", ["-o", "tty=,ppid=", "-p", String(pid)], {
        timeout: 1_000,
      })
        .toString()
        .trim();
      const [tty, ppidStr] = out.split(/\s+/);
      if (tty && tty !== "??" && tty !== "?") {
        return tty.startsWith("/dev/") ? tty : `/dev/${tty}`;
      }
      const ppid = parseInt(ppidStr ?? "0", 10);
      if (!ppid || ppid <= 1) break;
      pid = ppid;
    }
  } catch {}
  return null;
}

function sendToSocket(payload: object): Promise<void> {
  const { promise, resolve } = Promise.withResolvers<void>();
  let finished = false;
  const finish = () => {
    if (finished) return;
    finished = true;
    resolve();
  };
  let serialized: string;
  try {
    serialized = JSON.stringify(payload);
  } catch {
    finish();
    return promise;
  }

  try {
    const sock = connect({ path: SOCKET_PATH }, () => {
      sock.end(serialized, finish);
    });
    sock.once("error", finish);
    sock.setTimeout(3_000, () => {
      sock.destroy();
      finish();
    });
  } catch {
    finish();
  }
  return promise;
}

function base(
  sessionId: string,
  cwd: string,
  extra: Record<string, unknown>,
  tty: string | null,
  transcriptPath: string | null,
) {
  return {
    session_id: `omp-${sessionId}`,
    _source: "omp",
    _ppid: process.pid,
    _env: collectEnv(),
    _tty: tty,
    cwd,
    // Lets HookServer fold subagent transcripts (nested under
    // `<parent>.jsonl/<child>.jsonl`) onto the parent session card.
    ...(transcriptPath ? { transcript_path: transcriptPath } : {}),
    ...extra,
  };
}

function sessionFile(ctx: { sessionManager: { getSessionFile?: () => unknown } }): string | null {
  try {
    const file = ctx.sessionManager?.getSessionFile?.();
    return typeof file === "string" && file ? file : null;
  } catch {
    return null;
  }
}

function extractLastAssistantText(messages: readonly unknown[]): string {
  const assistants = messages.filter(
    (message): message is { role: "assistant"; content: unknown } =>
      !!message &&
      typeof message === "object" &&
      "role" in message &&
      message.role === "assistant" &&
      "content" in message,
  );
  const last = assistants.at(-1);
  if (!last || !Array.isArray(last.content)) return "";
  return last.content
    .filter((content): content is { type: "text"; text: string } =>
      !!content &&
      typeof content === "object" &&
      "type" in content &&
      content.type === "text" &&
      "text" in content &&
      typeof content.text === "string",
    )
    .map((content) => content.text)
    .join("")
    .trim();
}

export default function codeislandExtension(pi: ExtensionAPI) {
  const tty = detectTty();
  const startedSessions = new Set<string>();
  const outboundTails = new Map<string, Promise<void>>();

  function enqueueEvent(sessionId: string, payload: object): void {
    const previous = outboundTails.get(sessionId)?.catch(() => {}) ?? Promise.resolve();
    const next = previous.then(() => sendToSocket(payload));
    outboundTails.set(sessionId, next);
    void next.finally(() => {
      if (outboundTails.get(sessionId) === next) {
        outboundTails.delete(sessionId);
      }
    });
  }
  function ensureSessionStarted(
    sessionId: string,
    ctx: { cwd: string; sessionManager: { getSessionFile?: () => unknown } },
  ): void {
    const sid = `omp-${sessionId}`;
    if (startedSessions.has(sid)) return;

    const sessionName = pi.getSessionName();
    enqueueEvent(sid, base(sessionId, ctx.cwd, {
      hook_event_name: "SessionStart",
      ...(sessionName ? { session_title: sessionName } : {}),
    }, tty, sessionFile(ctx)));
    startedSessions.add(sid);
  }

  pi.on("session_start", (_event, ctx) => {
    ensureSessionStarted(ctx.sessionManager.getSessionId(), ctx.cwd);
  });

  pi.on("session_shutdown", (_event, ctx) => {
    const sessionId = ctx.sessionManager.getSessionId();
    enqueueEvent(`omp-${sessionId}`, base(sessionId, ctx.cwd, { hook_event_name: "SessionEnd" }, tty, sessionFile(ctx)));
    startedSessions.delete(`omp-${sessionId}`);
  });

  pi.on("before_agent_start", (event, ctx) => {
    const sessionId = ctx.sessionManager.getSessionId();
    ensureSessionStarted(sessionId, ctx);
    enqueueEvent(`omp-${sessionId}`, base(sessionId, ctx.cwd, {
      hook_event_name: "UserPromptSubmit",
      prompt: event.prompt ?? "",
    }, tty, sessionFile(ctx)));
  });

  pi.on("agent_end", (event, ctx) => {
    const sessionId = ctx.sessionManager.getSessionId();
    ensureSessionStarted(sessionId, ctx);
    const sessionName = pi.getSessionName();
    enqueueEvent(`omp-${sessionId}`, base(sessionId, ctx.cwd, {
      hook_event_name: "Stop",
      last_assistant_message: extractLastAssistantText(event.messages) || undefined,
      ...(sessionName ? { session_title: sessionName } : {}),
    }, tty, sessionFile(ctx)));
  });

  pi.on("tool_call", (event, ctx) => {
    const sessionId = ctx.sessionManager.getSessionId();
    ensureSessionStarted(sessionId, ctx);
    const toolInput: Record<string, unknown> = { ...event.input };
    if (event.toolName === "bash" && typeof event.input.command === "string") {
      toolInput.patterns = [event.input.command];
    }
    if ((event.toolName === "edit" || event.toolName === "write") && typeof event.input.path === "string") {
      toolInput.file_path = event.input.path;
    }
    enqueueEvent(`omp-${sessionId}`, base(sessionId, ctx.cwd, {
      hook_event_name: "PreToolUse",
      tool_name: event.toolName.charAt(0).toUpperCase() + event.toolName.slice(1),
      tool_input: toolInput,
    }, tty, sessionFile(ctx)));
  });

  pi.on("tool_result", (_event, ctx) => {
    const sessionId = ctx.sessionManager.getSessionId();
    ensureSessionStarted(sessionId, ctx);
    enqueueEvent(`omp-${sessionId}`, base(sessionId, ctx.cwd, { hook_event_name: "PostToolUse" }, tty, sessionFile(ctx)));
  });

  pi.on("session_before_compact", (_event, ctx) => {
    const sessionId = ctx.sessionManager.getSessionId();
    ensureSessionStarted(sessionId, ctx);
    enqueueEvent(`omp-${sessionId}`, base(sessionId, ctx.cwd, { hook_event_name: "PreCompact" }, tty, sessionFile(ctx)));
  });

  pi.on("session_compact", (_event, ctx) => {
    const sessionId = ctx.sessionManager.getSessionId();
    ensureSessionStarted(sessionId, ctx);
    enqueueEvent(`omp-${sessionId}`, base(sessionId, ctx.cwd, { hook_event_name: "PostCompact" }, tty, sessionFile(ctx)));
  });
}
