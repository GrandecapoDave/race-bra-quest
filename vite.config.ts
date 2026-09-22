import { defineConfig } from "@lovable.dev/vite-tanstack-config";

export default defineConfig({
  vite: {
    preview: {
      allowedHosts: true,
      host: true,
    },
    server: {
      allowedHosts: true,
      host: true,
    },
  },
  tanstackStart: {
    server: { entry: "server" },
  },
});
