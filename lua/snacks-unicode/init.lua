local M = {}

local function register(opts)
  local source = require("snacks.picker.source.unicode")
  local ok, sources = pcall(require, "snacks.picker.config.sources")
  if not ok or not sources then
    return false
  end

  sources.unicode = vim.tbl_deep_extend(
    "force",
    source.config,
    opts
  )

  return type(Snacks.picker.unicode) == "function"
end

function M.setup(opts)
  opts = opts or {}

  vim.api.nvim_create_user_command("SnacksUnicodeUpdate", function()
    local ok, err = pcall(function()
      return require("snacks-unicode.generator").run({
        async = false,
        notify = true,
      })
    end)
    if not ok then
      vim.notify("snacks-unicode: generation failed: " .. tostring(err), vim.log.levels.ERROR)
    end
  end, { desc = "Regenerate snacks-unicode data" })

  if register(opts) then
    return
  end

  vim.api.nvim_create_autocmd("VimEnter", {
    group = vim.api.nvim_create_augroup("snacks_unicode_defer", { clear = true }),
    once = true,
    callback = function()
      if not register(opts) then
        vim.notify(
          "snacks-unicode: Snacks.picker config not ready, source not registered",
          vim.log.levels.WARN
        )
      end
    end,
  })
end

return M
