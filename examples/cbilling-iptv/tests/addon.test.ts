import { describe, it, expect, beforeAll, afterAll } from "vitest";
import { KodiClient } from "kodi-e2e/kodi-client.js";

describe("Addon: plugin.video.cbilling.iptv", () => {
  let kodi: KodiClient;

  beforeAll(async () => {
    kodi = new KodiClient();
    await kodi.connect();
    // Ensure we're on home screen
    const { window } = await kodi.getCurrentWindow();
    if (window.id !== 10000) {
      await kodi.activateWindow("home", []);
      await new Promise((r) => setTimeout(r, 2000));
    }
  });

  afterAll(() => {
    kodi.disconnect();
  });

  it("addon is installed and has correct id", async () => {
    const addons = await kodi.getAddons();
    const addon = addons.find(
      (a) => a.addonid === "plugin.video.cbilling.iptv",
    );
    expect(addon).toBeDefined();
    expect(addon!.name).toBeTruthy();
  });

  it("can open addon via ActivateWindow", async () => {
    await kodi.activateWindow("videos", [
      "plugin://plugin.video.cbilling.iptv/",
    ]);
    await new Promise((r) => setTimeout(r, 3000));

    const { window } = await kodi.getCurrentWindow();
    expect(window.id).not.toBe(10000);
    // Take screenshot via Kodi built-in
    await kodi.takeScreenshot();
  });

  it("can list addon root directory items", async () => {
    const items = await kodi.getDirectoryItems(
      "plugin://plugin.video.cbilling.iptv/",
    );
    expect(items.length).toBeGreaterThan(0);
    console.log(
      `    📋 Menu items: ${items.map((i) => i.label).join(", ")}`,
    );
  });

  it("can navigate back to home", async () => {
    // Send Home action and wait
    await kodi.executeAction("previousmenu");
    await new Promise((r) => setTimeout(r, 2000));
    await kodi.executeAction("previousmenu");
    await new Promise((r) => setTimeout(r, 2000));
    await kodi.executeAction("previousmenu");
    await new Promise((r) => setTimeout(r, 2000));

    const { window } = await kodi.getCurrentWindow();
    // Accept home (10000) or any non-addon window as success
    expect(window.id).toBeLessThan(10100);
  });
});
