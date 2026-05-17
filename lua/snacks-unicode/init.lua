local M = {}

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

  local function register()
    if not Snacks or not Snacks.picker then
      vim.schedule(register)
      return
    end
    local source = require("snacks.picker.source.unicode")
    Snacks.picker.config.sources.unicode = vim.tbl_deep_extend(
      "force",
      source.config,
      opts
    )
  end

  register()
end

return M
