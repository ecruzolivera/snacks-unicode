# snacks-unicode

A [snacks.nvim](https://github.com/folke/snacks.nvim) picker source for fuzzy-searching Unicode symbols and emoji across 16 semantic categories.

![picker preview](https://img.shields.io/badge/status-beta-yellow)

## Features

- 7000+ Unicode symbols across 16 categories (arrows, math, greek, emoji, etc.)
- Emoji with human-readable names (from [muan/unicode-emoji-json](https://github.com/muan/unicode-emoji-json))
- Multi-codepoint emoji sequences preserved (flags, ZWJ sequences, skin tones)
- Data generated lazily on install/update via `lazy.nvim` build hook
- No data files committed to the repo — always fresh from Unicode sources
- `:SnacksUnicodeUpdate` command for manual regeneration

## Requirements

- Neovim >= 0.8.0
- [folke/snacks.nvim](https://github.com/folke/snacks.nvim)
- `curl` (for data generation on install)

## Installation

```lua
local Snacks = require("snacks")
return {
  "ecruzolivera/snacks-unicode",
  dependencies = { "folke/snacks.nvim" },
  config = function(_, opts)
    require("snacks-unicode").setup(opts)
  end,
  event = "VeryLazy",
  keys = {
    {
      "<leader>fu",
      function()
        Snacks.picker.pick("unicode")
      end,
      desc = "Unicode Symbols",
    },
    {
      "<leader>fU",
      function()
        Snacks.picker.pick("unicode", { categories = { "emoji" } })
      end,
      desc = "Emoji",
    },
  },
}
```

On install/update, `lazy.nvim` runs the generation script automatically. Generated data is stored in `stdpath("state")/snacks-unicode/`.

## Usage

Open the picker:

```vim
:lua Snacks.picker.unicode()
```

Filter by category:

```vim
:lua Snacks.picker.unicode({ categories = { "arrows", "math" } })
:lua Snacks.picker.unicode({ categories = { "emoji" } })
```

Regenerate data:

```vim
:SnacksUnicodeUpdate
```

## Display format

```
  →   RIGHTWARDS ARROW         U+2192     Arrows
 icon   name                    codepoint  category
```

Preview shows the symbol at large size with its codepoint, name, and category.

## Categories

| Category     | Includes                                                                                  | Count |
| ------------ | ----------------------------------------------------------------------------------------- | ----- |
| arrows       | Arrows, Supplemental Arrows-A/B/C, Misc Symbols and Arrows                                | ~700  |
| blocks       | Block Elements                                                                            | ~32   |
| box-drawing  | Box Drawing                                                                               | ~128  |
| braille      | Braille Patterns                                                                          | ~256  |
| currency     | Currency Symbols                                                                          | ~35   |
| dingbats     | Dingbats, Ornamental Dingbats                                                             | ~240  |
| emoji        | Misc Symbols and Pictographs, Emoticons, Transport, Supplemental, Enclosed Supplement     | ~1900 |
| geometric    | Geometric Shapes, Geometric Shapes Extended                                               | ~200  |
| greek        | Greek and Coptic, Greek Extended                                                          | ~370  |
| letterlike   | Letterlike Symbols                                                                        | ~80   |
| math         | Mathematical Operators, Misc Math Symbols-A/B, Supplemental Math Operators, Math Alphanum | ~1700 |
| misc-symbols | Miscellaneous Symbols, Alchemical Symbols, Chess Symbols, Legacy Computing                | ~740  |
| number-forms | Number Forms, Enclosed Alphanumerics                                                      | ~220  |
| punctuation  | General Punctuation, Latin-1 Supplement, Latin Extended-A/B (punctuation/symbols only)    | ~100  |
| sub-super    | Superscripts and Subscripts                                                               | ~42   |
| technical    | Miscellaneous Technical, Control Pictures                                                 | ~300  |

## How it works

1. `build.lua` runs during `lazy.nvim` install/update
2. The generator fetches `Blocks.txt`, `UnicodeData.txt` from unicode.org, and the emoji JSON dataset
3. Data is written as JSON files to `stdpath("state")/snacks-unicode/`
4. At runtime, the picker source loads those files and presents them to `<leader>su`

Generation only happens during install/update or when `:SnacksUnicodeUpdate` is issued — never in the background.

## Regenerating data

If Unicode publishes a new version, regenerate at any time:

```vim
:SnacksUnicodeUpdate
```

Or from the command line:

```bash
nvim --headless -u NONE -c "luafile scripts/generate.lua" -c "qa"
```

## Edge cases

- **Empty categories filter** → picker shows empty list, does not crash
- **Missing data** → missing category files are skipped with a warning
- **Snacks not loaded** → source registration is deferred until `VimEnter`
- **Offline install** → generation fails gracefully, plugin still loads (data will be missing until `:SnacksUnicodeUpdate`)
- **Snacks missing entirely** → warning is shown once, no infinite retry

## License

MIT
