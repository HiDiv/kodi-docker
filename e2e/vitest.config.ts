import { defineConfig } from "vitest/config";

export default defineConfig({
  test: {
    globals: true,
    testTimeout: 30_000,
    hookTimeout: 30_000,
    include: ["**/*.test.ts"],
  },
  resolve: {
    alias: {
      "kodi-e2e": "/opt/kodi-e2e/src",
    },
  },
});
