local M = {}

local URLS = {
  blocks = "https://www.unicode.org/Public/UCD/latest/ucd/Blocks.txt",
  unicode_data = "https://www.unicode.org/Public/UCD/latest/ucd/UnicodeData.txt",
  emoji = "https://raw.githubusercontent.com/muan/unicode-emoji-json/refs/heads/main/data-by-emoji.json",
}

local BLOCK_CATEGORY = {
  ["Arrows"] = "arrows",
  ["Supplemental Arrows-A"] = "arrows",
  ["Supplemental Arrows-B"] = "arrows",
  ["Supplemental Arrows-C"] = "arrows",
  ["Miscellaneous Symbols and Arrows"] = "arrows",
  ["Block Elements"] = "blocks",
  ["Box Drawing"] = "box-drawing",
  ["Braille Patterns"] = "braille",
  ["Currency Symbols"] = "currency",
  ["Dingbats"] = "dingbats",
  ["Ornamental Dingbats"] = "dingbats",
  ["Geometric Shapes"] = "geometric",
  ["Geometric Shapes Extended"] = "geometric",
  ["Greek and Coptic"] = "greek",
  ["Greek Extended"] = "greek",
  ["Letterlike Symbols"] = "letterlike",
  ["Mathematical Operators"] = "math",
  ["Miscellaneous Mathematical Symbols-A"] = "math",
  ["Miscellaneous Mathematical Symbols-B"] = "math",
  ["Supplemental Mathematical Operators"] = "math",
  ["Mathematical Alphanumeric Symbols"] = "math",
  ["Miscellaneous Symbols"] = "misc-symbols",
  ["Alchemical Symbols"] = "misc-symbols",
  ["Chess Symbols"] = "misc-symbols",
  ["Symbols for Legacy Computing"] = "misc-symbols",
  ["Number Forms"] = "number-forms",
  ["Enclosed Alphanumerics"] = "number-forms",
  ["General Punctuation"] = "punctuation",
  ["Latin-1 Supplement"] = "punctuation",
  ["Latin Extended-A"] = "punctuation",
  ["Latin Extended-B"] = "punctuation",
  ["Superscripts and Subscripts"] = "sub-super",
  ["Miscellaneous Technical"] = "technical",
  ["Control Pictures"] = "technical",
}

local EMOJI_BLOCKS = {
  ["Miscellaneous Symbols and Pictographs"] = true,
  ["Emoticons"] = true,
  ["Transport and Map Symbols"] = true,
  ["Supplemental Symbols and Pictographs"] = true,
  ["Enclosed Alphanumeric Supplement"] = true,
  ["Enclosed Ideographic Supplement"] = true,
  ["Symbols and Pictographs Extended-A"] = true,
}

local EXCLUDED_CATEGORIES = {
  Mn = true, Mc = true, Me = true,
  Cc = true, Cf = true, Cs = true, Co = true, Cn = true,
  Zs = true, Zl = true, Zp = true,
}

local RESTRICTED_BLOCKS = {
  ["Latin-1 Supplement"] = true,
  ["Latin Extended-A"] = true,
  ["Latin Extended-B"] = true,
}

local EXCLUDED_LETTER_CATEGORIES = {
  Lu = true, Ll = true, Lt = true, Lm = true, Lo = true,
  Nd = true, Nl = true,
}

local function notify(msg, level)
  if vim then
    vim.notify(msg, level or vim.log.levels.INFO)
  end
end

local function fetch(url)
  local stdout = vim.fn.system({ "curl", "-fsSL", "--max-time", "30", url })
  if vim.v.shell_error ~= 0 then
    error("Failed to fetch " .. url)
  end
  return stdout
end

local function parse_blocks(txt)
  local ranges = {}
  for line in txt:gmatch("[^\n]+") do
    line = line:gsub("#.*$", ""):match("^%s*(.-)%s*$")
    if line ~= "" then
      local start_hex, end_hex, name = line:match("^(%x+)%.%.(%x+);%s*(.+)$")
      if start_hex then
        table.insert(ranges, {
          start_cp = tonumber(start_hex, 16),
          end_cp = tonumber(end_hex, 16),
          name = name,
        })
      end
    end
  end
  return ranges
end

local function codepoint_to_char(cp)
  return vim.fn.nr2char(cp)
end

local function codepoint_str_from_char(char)
  local parts = {}
  for _, cp in utf8.codes(char) do
    table.insert(parts, string.format("U+%X", cp))
  end
  return table.concat(parts, " ")
end

local function build_block_map(ranges)
  local map = {}
  for _, r in ipairs(ranges) do
    local cat = BLOCK_CATEGORY[r.name]
    if cat then
      map[r.name] = { start_cp = r.start_cp, end_cp = r.end_cp, category = cat }
    end
  end
  return map
end

local function find_block_for_codepoint(cp, ranges)
  for _, r in ipairs(ranges) do
    if cp >= r.start_cp and cp <= r.end_cp then
      return r.name
    end
  end
  return nil
end

local function generate_non_emoji(unicode_data_txt, block_ranges, block_map)
  local categories = {}
  for _, r in ipairs(block_ranges) do
    local info = block_map[r.name]
    if info then
      categories[info.category] = categories[info.category] or {}
    end
  end

  local skipped = 0

  -- Pre-build sorted block boundaries for binary search
  local sorted_ranges = {}
  for _, r in ipairs(block_ranges) do
    table.insert(sorted_ranges, r)
  end
  table.sort(sorted_ranges, function(a, b) return a.start_cp < b.start_cp end)

  for line in unicode_data_txt:gmatch("[^\n]+") do
    line = line:gsub("#.*$", ""):match("^%s*(.-)%s*$")
    if line ~= "" then
      local fields = vim.split(line, ";")
      if #fields >= 2 then
        local cp = tonumber(fields[1], 16)
        local name = fields[2]
        local gen_cat = fields[3]

        -- Global exclusion by General Category
        if EXCLUDED_CATEGORIES[gen_cat] then
          skipped = skipped + 1
          goto continue
        end

        -- Find block
        local block_name = find_block_for_codepoint(cp, sorted_ranges)
        if not block_name then
          skipped = skipped + 1
          goto continue
        end

        -- Skip emoji blocks (handled separately)
        if EMOJI_BLOCKS[block_name] then
          skipped = skipped + 1
          goto continue
        end

        local info = block_map[block_name]
        if not info then
          skipped = skipped + 1
          goto continue
        end

        -- For restricted blocks (Latin supplements), filter out letters and digits
        if RESTRICTED_BLOCKS[block_name] and EXCLUDED_LETTER_CATEGORIES[gen_cat] then
          skipped = skipped + 1
          goto continue
        end

        local char = codepoint_to_char(cp)
        if char == "" then
          skipped = skipped + 1
          goto continue
        end

        local item = {
          icon = char,
          name = name,
          category = info.category,
          codepoint = string.format("U+%04X", cp),
        }

        local cat_items = categories[info.category]
        if cat_items then
          table.insert(cat_items, item)
        end

        ::continue::
      end
    end
  end

  return categories, skipped
end

local function generate_emoji(emoji_json_txt)
  local ok, data = pcall(vim.json.decode, emoji_json_txt)
  if not ok then
    error("Failed to parse emoji JSON")
  end

  local items = {}
  for emoji_char, info in pairs(data) do
    table.insert(items, {
      icon = emoji_char,
      name = info.name,
      category = "emoji",
      codepoint = codepoint_str_from_char(emoji_char),
    })
  end

  table.sort(items, function(a, b) return a.codepoint < b.codepoint end)
  return items
end

local function write_json(path, data)
  local tmp = path .. ".tmp"
  local f = io.open(tmp, "w")
  if not f then
    error("Failed to open " .. tmp .. " for writing")
  end
  f:write(vim.json.encode(data))
  f:close()
  os.rename(tmp, path)
end

local function ensure_dir(path)
  vim.fn.mkdir(path, "p")
end

function M.run(opts)
  opts = opts or {}
  opts.notify = opts.notify ~= false

  local state_dir = vim.fn.stdpath("state") .. "/snacks-unicode"
  ensure_dir(state_dir)

  if opts.notify then
    notify("snacks-unicode: fetching Unicode data...")
  end

  local blocks_txt = fetch(URLS.blocks)
  local unicode_data_txt = fetch(URLS.unicode_data)
  local emoji_json_txt = fetch(URLS.emoji)

  if opts.notify then
    notify("snacks-unicode: parsing blocks...")
  end
  local block_ranges = parse_blocks(blocks_txt)
  local block_map = build_block_map(block_ranges)

  if opts.notify then
    notify("snacks-unicode: generating non-emoji categories...")
  end
  local categories, skipped = generate_non_emoji(unicode_data_txt, block_ranges, block_map)

  if opts.notify then
    notify("snacks-unicode: generating emoji category...")
  end
  local emoji_items = generate_emoji(emoji_json_txt)
  categories["emoji"] = emoji_items

  if opts.notify then
    notify("snacks-unicode: writing data files...")
  end

  local total = 0
  for cat, items in pairs(categories) do
    table.sort(items, function(a, b) return a.codepoint < b.codepoint end)
    write_json(state_dir .. "/" .. cat .. ".json", items)
    total = total + #items
  end

  local meta = {
    unicode_version = "latest",
    generated_at = os.date("!%Y-%m-%dT%H:%M:%SZ"),
    total_items = total,
    categories = {},
  }
  for cat, items in pairs(categories) do
    table.insert(meta.categories, { name = cat, count = #items })
  end
  table.sort(meta.categories, function(a, b) return a.name < b.name end)
  write_json(state_dir .. "/metadata.json", meta)

  if opts.notify then
    notify(
      string.format("snacks-unicode: generated %d items across %d categories (%d excluded)",
        total, #vim.tbl_keys(categories), skipped),
      vim.log.levels.INFO
    )
  end

  return total
end

return M
