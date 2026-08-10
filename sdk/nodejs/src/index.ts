import { spawn } from "node:child_process";
import { dirname, join } from "node:path";
import { fileURLToPath } from "node:url";
import { arch, platform } from "node:os";
import { createInterface } from "node:readline";
import { Notification } from "./events";

function getSystem(): string {
  const platformName = platform().toLowerCase();
  const archName = arch().toLowerCase();
  return `${platformName}-${archName}`;
}

export class Maria {
  async *start(prompt: string): AsyncGenerator<Notification, void, unknown> {
    const system = getSystem();

    // Get the path to the bin directory relative to this file
    const __dirname = dirname(fileURLToPath(import.meta.url));
    const executablePath = join(__dirname, "..", "bin", `${system}.exe`);

    const process = spawn(executablePath, ["exec", prompt], {
      stdio: ["ignore", "pipe", "inherit"],
    });

    if (!process.stdout) {
      throw new Error("Failed to spawn Maria process: stdout is null");
    }

    const rl = createInterface({
      input: process.stdout,
      crlfDelay: Infinity,
    });

    for await (const line of rl) {
      if (line.trim()) {
        try {
          const notification: Notification = JSON.parse(line);
          yield notification;
        } catch (error) {
          throw new Error(`Failed to parse notification: ${line}`);
        }
      }
    }

    const exitCode = await new Promise<number | null>((resolve) => {
      process.on("close", resolve);
    });

    if (exitCode !== 0) {
      throw new Error(`Maria process failed with exit code: ${exitCode}`);
    }
  }
}

export interface SessionInfo {
  id: string;
  agent_id: string;
  busy: boolean;
  created_at: number;
  last_active: number;
}

export interface CreateSessionResult {
  session_id: string;
  agent_id: string;
}

export interface SendMessageResult {
  success: boolean;
}

export type ServerStreamEvent =
  | { type: "MariaQueuedMessagesSynchronized"; queued_messages: unknown[] }
  | { type: "Maria"; event: unknown };

export class HTTPResponseError extends Error {
  constructor(public statusCode: number, public body: string) {
    super(`HTTP ${statusCode}: ${body}`);
    this.name = "HTTPResponseError";
  }
}

export class MariaClient {
  constructor(private baseUrl: string) {}

  private async request(
    method: string,
    path: string,
    body?: object,
  ): Promise<any> {
    const url = `${this.baseUrl}${path}`;
    const response = await fetch(url, {
      method,
      headers: body ? { "Content-Type": "application/json" } : undefined,
      body: body ? JSON.stringify(body) : undefined,
    });
    const text = await response.text();
    if (!response.ok) {
      throw new HTTPResponseError(response.status, text);
    }
    return JSON.parse(text);
  }

  async createSession(opts: {
    name?: string;
    resume_id?: string;
    web_search?: boolean;
  }): Promise<CreateSessionResult> {
    return this.request("POST", "/v1/sessions", opts);
  }

  async listSessions(): Promise<SessionInfo[]> {
    return this.request("GET", "/v1/sessions");
  }

  async getSession(sessionId: string): Promise<SessionInfo | null> {
    try {
      return await this.request("GET", `/v1/sessions/${sessionId}`);
    } catch (e) {
      if (e instanceof HTTPResponseError && e.statusCode === 404) return null;
      throw e;
    }
  }

  async closeSession(sessionId: string): Promise<boolean> {
    try {
      await this.request("DELETE", `/v1/sessions/${sessionId}`);
      return true;
    } catch (e) {
      if (e instanceof HTTPResponseError && e.statusCode === 404) return false;
      throw e;
    }
  }

  async sendMessage(
    sessionId: string,
    message: object,
    webSearch?: boolean,
  ): Promise<SendMessageResult> {
    const body: any = { message };
    if (webSearch !== undefined) body.web_search = webSearch;
    return this.request("POST", `/v1/sessions/${sessionId}/message`, body);
  }

  async *streamEvents(
    sessionId: string,
  ): AsyncGenerator<ServerStreamEvent, void, unknown> {
    const url = `${this.baseUrl}/v1/sessions/${sessionId}/events`;
    const response = await fetch(url);
    if (!response.ok) {
      throw new HTTPResponseError(response.status, await response.text());
    }
    if (!response.body) throw new Error("No response body for SSE stream");
    const reader = response.body.getReader();
    const decoder = new TextDecoder();
    let buffer = "";
    while (true) {
      const { done, value } = await reader.read();
      if (done) break;
      buffer += decoder.decode(value, { stream: true });
      while (buffer.includes("\n\n")) {
        const idx = buffer.indexOf("\n\n");
        const eventBlock = buffer.slice(0, idx);
        buffer = buffer.slice(idx + 2);
        let eventData = "";
        for (const line of eventBlock.split("\n")) {
          if (line.startsWith("data:")) {
            eventData += line.slice(5).trim();
          }
        }
        if (eventData) {
          const parsed = JSON.parse(eventData);
          if (Array.isArray(parsed)) {
            yield { type: "MariaQueuedMessagesSynchronized", queued_messages: parsed };
          } else {
            yield { type: "Maria", event: parsed };
          }
        }
      }
    }
  }
}

export * from "./events";
