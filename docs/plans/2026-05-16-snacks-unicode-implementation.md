---
status: in-progress
phase: 1
updated: 2026-05-16
---

# Implementation Plan: snacks-unicode

## Goal

Create a standalone Neovim plugin that registers a `Snacks.picker.unicode()` source for fuzzy-searching comprehensive Unicode symbols (including emoji) across 16 semantic categories, with data generated on install/update into `stdpath("state")`.

## Context & Decisions

| Decision                                                                  | Rationale                                                                                                                                                              | Source                                                                                |
| ------------------------------------------------------------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------- |
| Standalone plugin vs extending built-in icons picker                      | Dedicated source gives full control over finder, format, preview, and category layout vs cramming into the existing icons system                                       | `ref:../research/snacks-picker-source-architecture.md`                                |
| Use `#` component naming convention (`unicode#find`)                      | Follows the pattern used by built-in LSP config sources; resolves via `M.field()` to module exports                                                                    | `ref:../research/snacks-picker-source-architecture.md`                                |
| Module at `lua/snacks/picker/source/unicode/`                             | Snacks' `M.field()` uses `require("snacks.picker.source.<path>")` which finds modules on Neovim's runtimepath; matches third-party pattern used by snacks-luasnip.nvim | `ref:../research/snacks-picker-source-architecture.md`                                |
| Register source via setup() injecting into `Snacks.picker.config.sources` | Triggers `__newindex` metatable which auto-creates `Snacks.picker.unicode()` wrapper; no user boilerplate                                                              | `ref:../research/snacks-picker-source-architecture.md`                                |
| 16 categories mapped from Unicode blocks                                  | Block mapping gives clean semantic categories (arrows, math, greek) instead of raw Unicode General Categories (Sm, So, Sc) which are too granular                      | `ref:../research/unicode-data-format.md`                                              |
| Generate data on install/update into `stdpath("state")`                   | Users get fresh Unicode data without waiting for a plugin release, and mutable generated files live in the correct per-user writable state directory                   | `ref:https://lazy.folke.io/developers`, `ref:http://neovim.io/doc/user/starting.html` |
| Emoji from muan/unicode-emoji-json as primary emoji dataset               | Captures human-readable names and multi-codepoint emoji sequences that are not representable as single `UnicodeData.txt` rows                                          | `ref:../research/unicode-data-format.md`                                              |
| Own each Unicode block in exactly one category                            | Prevents duplicate entries and keeps generation rules deterministic                                                                                                    | `ref:../research/unicode-data-format.md`                                              |
| Confirm action = `"put"`                                                  | Same as the built-in icons picker; inserts the selected Unicode character at cursor                                                                                    | `ref:../research/snacks-picker-source-architecture.md`                                |
| Reuse built-in `SnacksPickerIcon` highlight groups                        | Visual consistency with the rest of Snacks picker; no custom highlight definitions needed                                                                              | `ref:../research/snacks-picker-source-architecture.md`                                |
| Refresh only on install/update and manual command                         | Matches the desired UX and avoids hidden background network work during normal editor usage                                                                            | User requirement                                                                      |

## Phase 1: Research & Data Generation [IN PROGRESS]

- [x] 1.1 Research Snacks.picker source architecture → `ref:../research/snacks-picker-source-architecture.md`
- [x] 1.2 Research Unicode data sources and format → `ref:../research/unicode-data-format.md`
- [ ] **1.3 Write `scripts/generate.lua`** ← CURRENT
- [ ] 1.4 Write `build.lua` so `lazy.nvim` runs generation on install/update
- [ ] 1.5 Run generation to produce state data under `stdpath("state")/snacks-unicode/`
- [ ] 1.6 Verify data completeness and correctness

## Phase 2: Picker Source Module [PENDING]

- [ ] 2.1 Create `lua/snacks/picker/source/unicode/init.lua` — source entry point, config, and helper functions
- [ ] 2.2 Implement `M.find(opts)` — the finder function that loads and returns items from generated state data
- [ ] 2.3 Implement `M.format(item, picker)` — the formatter showing icon + name + category + codepoint
- [ ] 2.4 Implement `M.preview(ctx)` — preview showing the symbol at large size with codepoint hex
- [ ] 2.5 Define `M.config` — default source config table

## Phase 3: Plugin Entry & Integration [PENDING]

- [ ] 3.1 Create `lua/snacks-unicode/init.lua` — plugin entry point with `setup(opts)` function
- [ ] 3.2 Ensure `setup()` registers the source into `Snacks.picker.config.sources`
- [ ] 3.3 Handle Edge Case: Snacks not yet loaded when setup runs (defer with autocmd or vim.schedule)
- [ ] 3.4 Add `:SnacksUnicodeUpdate` command to regenerate data on demand

## Phase 4: Verification [PENDING]

- [ ] 4.1 Load plugin in Neovim and verify `Snacks.picker.unicode()` opens without errors
- [ ] 4.2 Fuzzy search across categories (e.g., type "arrow", "fire", "alpha", "euro")
- [ ] 4.3 Verify confirm inserts the correct Unicode character into the buffer
- [ ] 4.4 Verify preview shows correct codepoint information
- [ ] 4.5 Test with `{ categories = { "arrows", "math" } }` filter
- [ ] 4.6 Test with no items (empty category list): picker should show empty list, not crash
- [ ] 4.7 Verify `:SnacksUnicodeUpdate` regenerates state data successfully

## Notes

- 2026-05-16: Snacks.picker does not validate the existence of a custom source's finder module until the picker is actually opened. The `__newindex` metatable always wraps, even for modules that will fail at require time. Deferred error handling is fine. `ref:../research/snacks-picker-source-architecture.md`
- 2026-05-16: UnicodeData.txt contains ~155K characters. After filtering out CJK, Hangul, ASCII, controls, and private use, we expect ~12K-18K symbols across all non-emoji categories. The emoji JSON from muan adds ~1,800+ entries, including multi-codepoint sequences with human-readable names. `ref:../research/unicode-data-format.md`
- 2026-05-17: `lazy.nvim` runs plugin `build` hooks on install and update, and those build steps can run asynchronously. `stdpath("state")` is Neovim's writable state directory, typically `~/.local/state/nvim` on Linux. `ref:https://lazy.folke.io/developers`, `ref:http://neovim.io/doc/user/starting.html`

## Implementation Details

### Data Generation (`scripts/generate.lua`)

Strategy:

1. Fetch `Blocks.txt` to get block boundaries
2. Map each included block to exactly one of 16 categories
3. Fetch `UnicodeData.txt` and parse each line
4. For each non-emoji codepoint, check whether its block is in our included set
5. Skip excluded ranges (ASCII, CJK, Hangul, controls, surrogates, private use, non-characters, invisible combining marks)
6. Build item with: `{ icon = "<char>", name = "<UCD_NAME>", category = "<our_category>", codepoint = "<U+XXXX>" }`
7. Fetch `muan/unicode-emoji-json` and build the entire `emoji` category directly from that dataset so multi-codepoint emoji sequences are preserved
8. Write one JSON file per category under `stdpath("state")/snacks-unicode/` using temp files plus atomic rename
9. Write metadata file with Unicode version and generation timestamp

### Category Mapping

| Category     | Block names                                                                                                                                                   | Est. Count |
| ------------ | ------------------------------------------------------------------------------------------------------------------------------------------------------------- | ---------- |
| arrows       | Arrows, Supplemental Arrows-A/B/C, Misc Symbols and Arrows                                                                                                    | ~700       |
| blocks       | Block Elements                                                                                                                                                | ~32        |
| box-drawing  | Box Drawing                                                                                                                                                   | ~128       |
| braille      | Braille Patterns                                                                                                                                              | ~256       |
| currency     | Currency Symbols                                                                                                                                              | ~50        |
| dingbats     | Dingbats, Ornamental Dingbats                                                                                                                                 | ~260       |
| emoji        | Misc Symbols and Pictographs, Emoticons, Transport, Supplemental, Enclosed Alphanumeric Suppl, Enclosed Ideographic Suppl, Symbols and Pictographs Extended-A | ~2,200     |
| geometric    | Geometric Shapes, Geometric Shapes Extended                                                                                                                   | ~200       |
| greek        | Greek and Coptic, Greek Extended                                                                                                                              | ~550       |
| letterlike   | Letterlike Symbols                                                                                                                                            | ~100       |
| math         | Mathematical Operators, Misc Math Symbols-A/B, Supplemental Math Operators, Math Alphanumeric Symbols                                                         | ~4,000     |
| misc-symbols | Miscellaneous Symbols, Alchemical Symbols, Chess Symbols, Legacy Computing                                                                                    | ~800       |
| number-forms | Number Forms, Enclosed Alphanumerics                                                                                                                          | ~100       |
| punctuation  | General Punctuation (non-ASCII), Latin-1 Supplement (non-ASCII punctuation subset)                                                                            | ~150       |
| sub-super    | Superscripts and Subscripts                                                                                                                                   | ~50        |
| technical    | Miscellaneous Technical, Control Pictures                                                                                                                     | ~350       |

### Source Config Defaults

```lua
M.config = {
  finder = "unicode#find",
  format = "unicode#format",
  preview = "unicode#preview",
  layout = { preset = "vscode" },
  main = { current = true },
  confirm = "put",
  categories = nil,  -- nil = all; can be set to a subset list
}
```

### Finder Logic

```lua
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

local function load_category(category)
  local path = state_dir() .. "/" .. category .. ".json"
  local ok, lines = pcall(vim.fn.readfile, path)
  if not ok then
    Snacks.notify.warn("snacks-unicode: missing generated data for category '" .. category .. "'")
    return {}
  end
  return vim.json.decode(table.concat(lines, "\n")) or {}
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

return M
```

`state_dir()` should return `vim.fn.stdpath("state") .. "/snacks-unicode"`.

### Formatter Display

```
  →   RIGHTWARDS ARROW         U+2192     Arrows
  ──   ─────────────────────── ─────────── ──────
  icon (padded)   name         codepoint   category
```

Implementation:

```lua
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
```

### Preview Display

```lua
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
  -- TODO: add extmarks for larger display size
end
```

### Plugin Entry (`lua/snacks-unicode/init.lua`)

```lua
local M = {}

function M.setup(opts)
  opts = opts or {}
  local source = require("snacks.picker.source.unicode")
  local config = vim.tbl_deep_extend("force", source.config, opts)
  Snacks.picker.config.sources.unicode = config
  vim.api.nvim_create_user_command("SnacksUnicodeUpdate", function()
    require("snacks-unicode.generator").run({ async = true, notify = true })
  end, { desc = "Regenerate snacks-unicode data" })
end

return M
```

### User Configuration

```lua
-- lazy.nvim
{
  "ernesto/snacks-unicode",
  dependencies = { "folke/snacks.nvim" },
  config = function(_, opts)
    require("snacks-unicode").setup(opts)
  end,
  keys = {
    { "<leader>su", function() Snacks.picker.unicode() end, desc = "Unicode Symbols" },
    { '<leader>sU', function() Snacks.picker.unicode({ categories = { "emoji" } }) end, desc = "Emoji" },
  },
}
```

### Edge Cases

1. **Empty categories**: If `categories = {}`, return empty array. Picker shows empty list, not crash.
2. **Missing generated data**: If a category JSON file is missing, skip it with `Snacks.notify.warn()`. Don't error.
3. **Snacks not loaded**: `setup()` checks if `Snacks.picker` exists; if not, defer via `vim.schedule` loop or `User` autocmd.
4. **Emoji sequences**: Some emoji are multi-codepoint strings. Treat `icon` and `data` as Lua strings, not single codepoints, and derive `codepoint` as a joined string such as `U+1F469 U+200D U+1F4BB`.
5. **Unrenderable chars**: Characters that require specific fonts will display as boxes. This is expected and standard across all Unicode tools.
6. **Large data volume**: ~10K-20K items is well within Snacks' async matching pipeline. The finder returns all items synchronously (from generated state files), and the matcher handles filtering async.
7. **Offline install/update**: If generation fails during `lazy` build because the network is unavailable, keep the plugin loadable but surface a warning that data was not generated.
8. **Manual refresh**: `:SnacksUnicodeUpdate` reruns generation on demand; no automatic background refresh outside install/update.
9. **Concurrent writes**: Generator should write to temp files and rename them into place atomically.

### Runtime Data Loading

```lua
-- ~/.local/state/nvim/snacks-unicode/emoji.json
[
  {
    "icon": "😀",
    "name": "grinning face",
    "category": "emoji",
    "codepoint": "U+1F600"
  }
]
```

Generated files live under `vim.fn.stdpath("state") .. "/snacks-unicode/"`, keeping mutable data out of the plugin install directory.

### Lazy Build Hook

```lua
-- build.lua
coroutine.yield("Generating snacks-unicode data")
require("snacks-unicode.generator").run({ async = false, notify = false })
```

`lazy.nvim` should execute `build.lua` automatically on install/update.
