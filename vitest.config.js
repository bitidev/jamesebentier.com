import { defineConfig } from "vitest/config"

// Unit tests for the pure ES-module helpers under app/javascript/keyboard_nav/
// (resolveNavTarget, commands, hints, search_index, theme_cycle -- see
// docs/specs/1187-modal-vim-keyboard-navigation.md, Testing Strategy). These
// modules take/return plain data with zero DOM access, so no jsdom environment
// is required for the majority of cases.
export default defineConfig({
  test: {
    include: ["app/javascript/**/*.test.js"],
    environment: "node"
  }
})
