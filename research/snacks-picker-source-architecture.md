# Snacks.picker Source Architecture

## Source Registration

Sources are registered in `Snacks.picker.config.sources`. A `__newindex` metatable
on the sources module auto-wraps new sources, creating `Snacks.picker.<source>()`.

```lua
setmetatable(require("snacks.picker.config.sources"), {
  __newindex = function(t, k, v)
    rawset(t, k, v)
    M.wrap(k)  -- creates Snacks.picker[k] = function(opts) return Snacks.picker.pick(k, opts) end
  end,
})
```

## Component Resolution via `M.field(spec)`

The `config.init.M.field` function resolves string references to functions:

```lua
function M.field(spec)
  local parts = vim.split(spec, ".", { plain = true })
  local name, field = parts[#parts]:match("^(.-)[_#](.+)$")
  if name and field then
    parts[#parts] = name
  else
    field = parts[#parts]
  end
  local ok, ret = pcall(function()
    return require("snacks.picker.source." .. table.concat(parts, "."))[field]
  end)
  return ok and ret or nil
end
```

The `#` separator splits into module name and field:

- `"unicode#find"` → `require("snacks.picker.source.unicode")["find"]`
- `"unicode#format"` → `require("snacks.picker.source.unicode")["format"]`

The module path is relative to Neovim's runtimepath. Files at `lua/snacks/picker/source/unicode/init.lua`
are found by `require("snacks.picker.source.unicode")`.

Components are resolved per-function via `M.finder()`, `M.format()`, `M.preview()`:

```lua
function M.finder(finder)
  if not finder or type(finder) == "function" then return finder end
  if type(finder) == "table" then ... end
  return M.field(finder) or nop
end

function M.format(opts)
  local ret = type(opts.format) == "string"
    and (Snacks.picker.format[opts.format] or M.field(opts.format))
    or opts.format
    or Snacks.picker.format.file
end
```

## Config Merging Order

1. Defaults (from `config.defaults`)
2. Global user config (from `Snacks.config.picker`)
3. Source-specific config (from `config.sources[source]`)
4. Call-time opts

Each level can override any field.

## Finder Pattern

Finders return an array of items. Each item must have at least a `text` field for
fuzzy matching. Built-in finder like `M.icons` returns items with `text`, `data`,
and custom fields like `icon`, `name`, `source`, `category`.

The `M.icons` finder sets:

```lua
icon.text = Snacks.picker.util.text(icon, { "source", "category", "name" })
icon.data = icon.icon
```

## Icons Source Format (built-in)

The built-in icons picker uses `M.format.icon` from `format.lua`:

```lua
function M.icon(item, picker)
  local a = Snacks.picker.util.align
  local icon_width = vim.api.nvim_strwidth(item.icon)
  ret[#ret + 1] = { a(item.icon, icon_width > 3 and 15 or 3), "SnacksPickerIcon" }
  ret[#ret + 1] = { " " }
  ret[#ret + 1] = { a(item.source, 10), "SnacksPickerIconSource" }
  ret[#ret + 1] = { " " }
  ret[#ret + 1] = { a(item.name, 30), "SnacksPickerIconName" }
  ret[#ret + 1] = { " " }
  ret[#ret + 1] = { a(item.category, 8), "SnacksPickerIconCategory" }
  return ret
end
```

## External Plugin Pattern

Plugins like `snacks-luasnip.nvim` put Lua files at paths that Snacks can resolve:

- `lua/snacks/picker/source/luasnip.lua` → `require("snacks.picker.source.luasnip")`

## References

- `ref:https://github.com/folke/snacks.nvim/blob/main/lua/snacks/picker/config/init.lua`
- `ref:https://github.com/folke/snacks.nvim/blob/main/lua/snacks/picker/source/icons.lua`
- `ref:https://github.com/folke/snacks.nvim/blob/main/lua/snacks/picker/format.lua`
- `ref:https://github.com/folke/snacks.nvim/blob/main/lua/snacks/picker/config/sources.lua`
- `ref:https://deepwiki.com/folke/snacks.nvim/2.8-creating-custom-pickers`
