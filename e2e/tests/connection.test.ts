import { describe, it, expect, beforeAll, afterAll } from "vitest";
import { KodiClient } from "kodi-e2e/kodi-client.js";

describe("Kodi Connection", () => {
  let kodi: KodiClient;

  beforeAll(async () => {
    kodi = new KodiClient();
    await kodi.connect();
  });

  afterAll(() => {
    kodi.disconnect();
  });

  it("should respond to ping", async () => {
    const result = await kodi.ping();
    expect(result).toBe("pong");
  });

  it("should return Kodi version", async () => {
    const version = await kodi.getVersion();
    expect(version.major).toBeGreaterThanOrEqual(19);
    expect(version.minor).toBeGreaterThanOrEqual(0);
  });

  it("should show current window", async () => {
    const { window } = await kodi.getCurrentWindow();
    expect(window.id).toBeGreaterThan(0);
    expect(window.label).toBeTruthy();
  });

  it("should list installed addons", async () => {
    const addons = await kodi.getAddons();
    expect(addons.length).toBeGreaterThan(0);
    const cbilling = addons.find(
      (a) => a.addonid === "plugin.video.cbilling.iptv",
    );
    expect(cbilling).toBeDefined();
  });
});
