-- scripts/generate.lua
-- Regenerate snacks-unicode data from Unicode sources.
-- Run: nvim --headless -u NONE -c "luafile scripts/generate.lua" -c "qa"

local plugin_root = vim.fn.expand("<sfile>:p:h:h")
vim.opt.rtp:prepend(plugin_root)

require("snacks-unicode.generator").run({ async = false, notify = true })
