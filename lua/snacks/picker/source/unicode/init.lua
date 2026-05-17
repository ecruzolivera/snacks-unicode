local M = {}

M.categories = {
  "arrows",
  "blocks",
  "box-drawing",
  "braille",
  "currency",
  "dingbats",
  "emoji",
  "geometric",
  "greek",
  "letterlike",
  "math",
  "misc-symbols",
  "number-forms",
  "punctuation",
  "sub-super",
  "technical",
}

M.config = {
  finder = "unicode#find",
  format = "unicode#format",
  preview = "unicode#preview",
  layout = { preset = "vscode" },
  main = { current = true },
  confirm = "put",
  categories = nil,
}

local function state_dir()
  return vim.fn.stdpath("state") .. "/snacks-unicode"
end

local function load_category(category)
  local path = state_dir() .. "/" .. category .. ".json"
  local ok, raw = pcall(vim.fn.readfile, path)
  if not ok then
    Snacks.notify.warn(
      "snacks-unicode: missing generated data for category '" .. category .. "'"
    )
    return {}
  end
  return vim.json.decode(table.concat(raw, "\n")) or {}
end

function M.find(opts)
  local categories = opts.categories or M.categories
  local ret = {}
  for _, cat in ipairs(categories) do
    local items = load_category(cat)
    for _, entry in ipairs(items) do
      table.insert(ret, {
        icon = entry.icon,
        name = entry.name,
        category = entry.category,
        codepoint = entry.codepoint,
        text = entry.category .. " " .. entry.name .. " " .. entry.icon,
        data = entry.icon,
      })
    end
  end
  return ret
end

function M.format(item, picker)
  local a = Snacks.picker.util.align
  local ret = {}
  local icon_width = vim.api.nvim_strwidth(item.icon)
  ret[#ret + 1] = { a(item.icon, math.max(icon_width, 3)), "SnacksPickerIcon" }
  ret[#ret + 1] = { " " }
  ret[#ret + 1] = { a(item.name or "", 42), "SnacksPickerIconName" }
  ret[#ret + 1] = { " " }
  ret[#ret + 1] = { a(item.codepoint, 8), "SnacksPickerComment" }
  ret[#ret + 1] = { " " }
  ret[#ret + 1] = { item.category, "SnacksPickerIconCategory" }
  return ret
end

function M.preview(ctx)
  local item = ctx.item
  local lines = {
    "",
    "  " .. item.icon .. "   (codepoint " .. item.codepoint .. ")",
    "",
    "  Name: " .. item.name,
    "  Category: " .. item.category,
  }
  vim.api.nvim_buf_set_lines(ctx.buf, 0, -1, false, lines)
  vim.bo[ctx.buf].filetype = "snacks_picker_preview"
end

return M
