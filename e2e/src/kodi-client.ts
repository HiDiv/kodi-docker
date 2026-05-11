import WebSocket from "ws";

export interface KodiWindow {
  id: number;
  label: string;
}

export interface PlayerProperties {
  speed: number;
  time: { hours: number; minutes: number; seconds: number };
  totaltime: { hours: number; minutes: number; seconds: number };
}

export class KodiClient {
  private ws: WebSocket | null = null;
  private requestId = 0;
  private pending = new Map<number, { resolve: Function; reject: Function }>();
  private host: string;
  private httpPort: number;
  private wsPort: number;

  constructor(
    host = process.env.KODI_HOST || "localhost",
    httpPort = Number(process.env.KODI_HTTP_PORT || 18080),
    wsPort = Number(process.env.KODI_WS_PORT || 19090),
  ) {
    this.host = host;
    this.httpPort = httpPort;
    this.wsPort = wsPort;
  }

  async connect(timeoutMs = 10_000): Promise<void> {
    return new Promise((resolve, reject) => {
      const timer = setTimeout(
        () => reject(new Error("WebSocket connect timeout")),
        timeoutMs,
      );
      this.ws = new WebSocket(`ws://${this.host}:${this.wsPort}/jsonrpc`);
      this.ws.on("open", () => {
        clearTimeout(timer);
        resolve();
      });
      this.ws.on("error", (err) => {
        clearTimeout(timer);
        reject(err);
      });
      this.ws.on("message", (data) => {
        const msg = JSON.parse(data.toString());
        if (msg.id && this.pending.has(msg.id)) {
          const { resolve } = this.pending.get(msg.id)!;
          this.pending.delete(msg.id);
          resolve(msg.result ?? msg.error);
        }
      });
    });
  }

  disconnect(): void {
    this.ws?.close();
    this.ws = null;
  }

  private call(method: string, params?: object): Promise<any> {
    return new Promise((resolve, reject) => {
      if (!this.ws || this.ws.readyState !== WebSocket.OPEN) {
        return reject(new Error("Not connected"));
      }
      const id = ++this.requestId;
      this.pending.set(id, { resolve, reject });
      this.ws.send(JSON.stringify({ jsonrpc: "2.0", method, params, id }));
      setTimeout(() => {
        if (this.pending.has(id)) {
          this.pending.delete(id);
          reject(new Error(`Timeout: ${method}`));
        }
      }, 15_000);
    });
  }

  // --- Basic ---
  ping(): Promise<string> {
    return this.call("JSONRPC.Ping");
  }

  async getVersion(): Promise<{ major: number; minor: number }> {
    const r = await this.call("Application.GetProperties", {
      properties: ["version"],
    });
    return r.version;
  }

  // --- Navigation ---
  navigate(direction: "up" | "down" | "left" | "right"): Promise<string> {
    const methods: Record<string, string> = {
      up: "Input.Up",
      down: "Input.Down",
      left: "Input.Left",
      right: "Input.Right",
    };
    return this.call(methods[direction]);
  }

  select(): Promise<string> {
    return this.call("Input.Select");
  }

  back(): Promise<string> {
    return this.call("Input.Back");
  }

  // --- GUI ---
  async getCurrentWindow(): Promise<{
    window: KodiWindow;
    control: string;
  }> {
    const r = await this.call("GUI.GetProperties", {
      properties: ["currentwindow", "currentcontrol"],
    });
    return { window: r.currentwindow, control: r.currentcontrol?.label };
  }

  activateWindow(window: string, params?: string[]): Promise<string> {
    return this.call("GUI.ActivateWindow", {
      window,
      parameters: params,
    });
  }

  // --- Files ---
  async getDirectoryItems(
    directory: string,
  ): Promise<{ label: string; file: string }[]> {
    const r = await this.call("Files.GetDirectory", {
      directory,
      media: "video",
    });
    return r.files || [];
  }

  // --- Addons ---
  async getAddons(): Promise<{ addonid: string; name: string }[]> {
    const r = await this.call("Addons.GetAddons", {
      type: "xbmc.python.pluginsource",
      properties: ["name"],
    });
    return r.addons || [];
  }

  executeAddon(addonId: string): Promise<string> {
    return this.call("Addons.ExecuteAddon", { addonid: addonId });
  }

  // --- Player ---
  async getActivePlayers(): Promise<{ playerid: number; type: string }[]> {
    return this.call("Player.GetActivePlayers");
  }

  async getPlayerProperties(playerId: number): Promise<PlayerProperties> {
    return this.call("Player.GetProperties", {
      playerid: playerId,
      properties: ["speed", "time", "totaltime"],
    });
  }

  playerPlayPause(playerId: number): Promise<any> {
    return this.call("Player.PlayPause", { playerid: playerId });
  }

  playerStop(playerId: number): Promise<string> {
    return this.call("Player.Stop", { playerid: playerId });
  }

  playerSeek(
    playerId: number,
    value: { seconds: number },
  ): Promise<any> {
    return this.call("Player.Seek", { playerid: playerId, value });
  }

  // --- Actions ---
  executeAction(action: string): Promise<string> {
    return this.call("Input.ExecuteAction", { action });
  }

  takeScreenshot(): Promise<string> {
    return this.call("Input.ExecuteAction", { action: "screenshot" });
  }

  // --- Utility ---
  async waitForPlayback(timeoutMs = 15_000): Promise<PlayerProperties> {
    const start = Date.now();
    while (Date.now() - start < timeoutMs) {
      const players = await this.getActivePlayers();
      if (players.length > 0) {
        const props = await this.getPlayerProperties(players[0].playerid);
        if (props.speed > 0) return props;
      }
      await new Promise((r) => setTimeout(r, 1000));
    }
    throw new Error("Playback did not start within timeout");
  }

  async waitForWindow(
    windowId: number,
    timeoutMs = 10_000,
  ): Promise<void> {
    const start = Date.now();
    while (Date.now() - start < timeoutMs) {
      const { window } = await this.getCurrentWindow();
      if (window.id === windowId) return;
      await new Promise((r) => setTimeout(r, 500));
    }
    throw new Error(`Window ${windowId} did not appear within timeout`);
  }
}
