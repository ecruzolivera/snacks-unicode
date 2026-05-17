---
status: in-progress
phase: 1
updated: 2026-05-16
---

# Implementation Plan: snacks-unicode

## Goal

Create a standalone Neovim plugin that registers a `Snacks.picker.unicode()` source for fuzzy-searching comprehensive Unicode symbols (including emoji) across 15 semantic categories.

## Context & Decisions

| Decision                                                                  | Rationale                                                                                                                                                              | Source                                                |
| ------------------------------------------------------------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ----------------------------------------------------- |
| Standalone plugin vs extending built-in icons picker                      | Dedicated source gives full control over finder, format, preview, and category layout vs cramming into the existing icons system                                       | `ref:./research/snacks-picker-source-architecture.md` |
| Use `#` component naming convention (`unicode#find`)                      | Follows the pattern used by built-in LSP config sources; resolves via `M.field()` to module exports                                                                    | `ref:./research/snacks-picker-source-architecture.md` |
| Module at `lua/snacks/picker/source/unicode/`                             | Snacks' `M.field()` uses `require("snacks.picker.source.<path>")` which finds modules on Neovim's runtimepath; matches third-party pattern used by snacks-luasnip.nvim | `ref:./research/snacks-picker-source-architecture.md` |
| Register source via setup() injecting into `Snacks.picker.config.sources` | Triggers `__newindex` metatable which auto-creates `Snacks.picker.unicode()` wrapper; no user boilerplate                                                              | `ref:./research/snacks-picker-source-architecture.md` |
| 15 categories mapped from Unicode blocks                                  | Block mapping gives clean semantic categories (arrows, math, greek) instead of raw Unicode General Categories (Sm, So, Sc) which are too granular                      | `ref:./research/unicode-data-format.md`               |
| Pre-generate JSON data files (committed to repo)                          | Users don't need internet or generation script; data works offline; generation script available for regeneration                                                       | `ref:./research/unicode-data-format.md`               |
| Emoji from muan/unicode-emoji-json                                        | Same source as Snacks built-in emoji picker; has human-readable names ("grinning face") vs official "GRINNING FACE"                                                    | `ref:./research/unicode-data-format.md`               |
| Fallback char check with `vim.fn.char2nr`                                 | Some Unicode chars may not render in the user's font; can silently skip empty/invisible glyphs at load time                                                            | `ref:./research/unicode-data-format.md`               |
| Confirm action = `"put"`                                                  | Same as the built-in icons picker; inserts the selected Unicode character at cursor                                                                                    | `ref:./research/snacks-picker-source-architecture.md` |
| Reuse built-in `SnacksPickerIcon` highlight groups                        | Visual consistency with the rest of Snacks picker; no custom highlight definitions needed                                                                              | `ref:./research/snacks-picker-source-architecture.md` |

## Phase 1: Research & Data Generation [IN PROGRESS]

- [x] 1.1 Research Snacks.picker source architecture → `ref:./research/snacks-picker-source-architecture.md`
- [x] 1.2 Research Unicode data sources and format → `ref:./research/unicode-data-format.md`
- [ ] **1.3 Write `scripts/generate.lua`** ← CURRENT
- [ ] 1.4 Run generation script to produce JSON data files under `lua/snacks/picker/source/unicode/data/`
- [ ] 1.5 Verify data completeness and correctness

## Phase 2: Picker Source Module [PENDING]

- [ ] 2.1 Create `lua/snacks/picker/source/unicode/init.lua` — source entry point, config, and helper functions
- [ ] 2.2 Implement `M.find(opts)` — the finder function that loads and returns items from JSON data
- [ ] 2.3 Implement `M.format(item, picker)` — the formatter showing icon + name + category + codepoint
- [ ] 2.4 Implement `M.preview(ctx)` — preview showing the symbol at large size with codepoint hex
- [ ] 2.5 Define `M.config` — default source config table

## Phase 3: Plugin Entry & Integration [PENDING]

- [ ] 3.1 Create `lua/snacks-unicode/init.lua` — plugin entry point with `setup(opts)` function
- [ ] 3.2 Ensure `setup()` registers the source into `Snacks.picker.config.sources`
- [ ] 3.3 Handle Edge Case: Snacks not yet loaded when setup runs (defer with autocmd or vim.schedule)
- [ ] 3.4 Clean up stale cache files if the plugin is updated

## Phase 4: Verification [PENDING]

- [ ] 4.1 Load plugin in Neovim and verify `Snacks.picker.unicode()` opens without errors
- [ ] 4.2 Fuzzy search across categories (e.g., type "arrow", "fire", "alpha", "euro")
- [ ] 4.3 Verify confirm inserts the correct Unicode character into the buffer
- [ ] 4.4 Verify preview shows correct codepoint information
- [ ] 4.5 Test with `{ categories = { "arrows", "math" } }` filter
- [ ] 4.6 Test with no items (empty category list): picker should show empty list, not crash

## Notes

- 2026-05-16: Snacks.picker does not validate the existence of a custom source's finder module until the picker is actually opened. The `__newindex` metatable always wraps, even for modules that will fail at require time. Deferred error handling is fine. `ref:./research/snacks-picker-source-architecture.md`

- 2026-05-16: UnicodeData.txt contains ~155K characters. After filtering out CJK, Hangul, ASCII, controls, and private use, we expect ~12K-18K symbols across all categories. The emoji JSON from muan adds ~1,800 entries with human-readable names. `ref:./research/unicode-data-format.md`

## Implementation Details

### Data Generation (`scripts/generate.lua`)

Strategy:

1. Fetch `Blocks.txt` to get block boundaries
2. Map each block to one of 15 categories
3. Fetch `UnicodeData.txt` and parse each line
4. For each character, check if its block is in our included set
5. Skip excluded ranges (CJK, Hangul, ASCII, controls, Private Use)
6. Build item with: `{ icon: "<char>", name: "<UCD_NAME>", category: "<our_category>", codepoint: "<U+XXXX>" }`
7. For emoji category: override from muan JSON for human-readable names
8. Write one JSON file per category to `lua/snacks/picker/source/unicode/data/`

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
| misc-symbols | Miscellaneous Symbols, Alchemical Symbols, Chess Symbols, Legacy Computing, Misc Technical (non-emojis)                                                       | ~800       |
| number-forms | Number Forms, Enclosed Alphanumerics                                                                                                                          | ~100       |
| punctuation  | General Punctuation (non-ASCII), Latin-1 Supplement (non-ASCII punctuation subset)                                                                            | ~150       |
| sub-super    | Superscripts and Subscripts                                                                                                                                   | ~50        |
| technical    | Miscellaneous Technical (subset), Control Pictures                                                                                                            | ~350       |

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
function M.find(opts)
  local categories = opts.categories or vim.tbl_keys(M.data)
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
```

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
2. **Missing data file**: If a category JSON is missing, skip it with `Snacks.notify.warn()`. Don't error.
3. **Snacks not loaded**: `setup()` checks if `Snacks.picker` exists; if not, defer via `vim.schedule` loop or `User` autocmd.
4. **Unrenderable chars**: Characters that require specific fonts will display as boxes. This is expected and standard across all Unicode tools.
5. **Large data volume**: ~10K items is well within Snacks' async matching pipeline. The finder returns all items synchronously (from JSON), and the matcher handles filtering async.
6. **Data freshness**: User can re-run `generate.lua` to update data for newer Unicode versions. The generation script is documented and included in the repo.
