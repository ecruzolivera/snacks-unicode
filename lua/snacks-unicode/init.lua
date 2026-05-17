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
    local source = require("snacks.picker.source.unicode")
    Snacks.picker.config.sources.unicode = vim.tbl_deep_extend(
      "force",
      source.config,
      opts
    )
  end

  if Snacks and Snacks.picker then
    register()
  else
    vim.api.nvim_create_autocmd("VimEnter", {
      group = vim.api.nvim_create_augroup("snacks_unicode_defer", { clear = true }),
      once = true,
      callback = function()
        if Snacks and Snacks.picker then
          register()
        else
          vim.notify(
            "snacks-unicode: Snacks.picker not available, source not registered",
            vim.log.levels.WARN
          )
        end
      end,
    })
  end
end

return M
