# Unicode Character Database (UCD) Data Format

## UnicodeData.txt Format

Source: `https://www.unicode.org/Public/UCD/latest/ucd/UnicodeData.txt`

Each line is semicolon-delimited with 15 fields:

```
0000..007F; Basic Latin
0080..00FF; Latin-1 Supplement
...
```

## General Categories

| Code | Name                       | Include?                                    |
| ---- | -------------------------- | ------------------------------------------- |
| Lu   | Letter, Uppercase          | No (basic Latin excluded)                   |
| Ll   | Letter, Lowercase          | No                                          |
| Lt   | Letter, Titlecase          | No                                          |
| Lm   | Letter, Modifier           | Selectively                                 |
| Lo   | Letter, Other              | Selectively (e.g. Greek, math alphanumeric) |
| Mn   | Mark, Nonspacing           | No (invisible)                              |
| Mc   | Mark, Spacing Combining    | No                                          |
| Me   | Mark, Enclosing            | No                                          |
| Nd   | Number, Decimal Digit      | No (except non-ASCII)                       |
| Nl   | Number, Letter             | Selectively                                 |
| No   | Number, Other              | Yes (fractions, Roman numerals)             |
| Pc   | Punctuation, Connector     | Yes                                         |
| Pd   | Punctuation, Dash          | Yes                                         |
| Ps   | Punctuation, Open          | Yes                                         |
| Pe   | Punctuation, Close         | Yes                                         |
| Pi   | Punctuation, Initial quote | Yes                                         |
| Pf   | Punctuation, Final quote   | Yes                                         |
| Po   | Punctuation, Other         | Yes                                         |
| Sm   | Symbol, Math               | Yes                                         |
| Sc   | Symbol, Currency           | Yes                                         |
| Sk   | Symbol, Modifier           | Yes                                         |
| So   | Symbol, Other              | Yes                                         |
| Zs   | Separator, Space           | No                                          |
| Zl   | Separator, Line            | No                                          |
| Zp   | Separator, Paragraph       | No                                          |
| Cc   | Other, Control             | No                                          |
| Cf   | Other, Format              | No                                          |
| Cs   | Other, Surrogate           | No                                          |
| Co   | Other, Private Use         | No                                          |
| Cn   | Other, Not Assigned        | No                                          |

## UnicodeData.txt Line Format

```
<code>;<name>;<category>;<combining>;<bidi>;<decomposition>;<decimal>;<digit>;<numeric>;<mirrored>;<old-name>;<comment>;<upper>;<lower>;<title>
```

Range entries (legacy format):

```
3400;<CJK Ideograph Extension A, First>;Lo;0;L;;;;;N;;;;;
4DB5;<CJK Ideograph Extension A, Last>;Lo;0;L;;;;;N;;;;;
```

## Unicode Blocks

Defined in `Blocks.txt`. We use block ranges to assign our categories.

Key blocks for symbols:

| Block                                | Range       | Our Category         |
| ------------------------------------ | ----------- | -------------------- |
| Latin-1 Supplement                   | 0080-00FF   | punctuation (subset) |
| Latin Extended-A                     | 0100-017F   | punctuation (subset) |
| Latin Extended-B                     | 0180-024F   | punctuation (subset) |
| Modifier Tone Letters                | A700-A71F   | no                   |
| Spacing Modifier Letters             | 02B0-02FF   | no                   |
| Greek and Coptic                     | 0370-03FF   | greek                |
| General Punctuation                  | 2000-206F   | punctuation          |
| Superscripts and Subscripts          | 2070-209F   | sub-super            |
| Currency Symbols                     | 20A0-20CF   | currency             |
| Letterlike Symbols                   | 2100-214F   | letterlike           |
| Number Forms                         | 2150-218F   | number-forms         |
| Arrows                               | 2190-21FF   | arrows               |
| Mathematical Operators               | 2200-22FF   | math                 |
| Miscellaneous Technical              | 2300-23FF   | technical            |
| Control Pictures                     | 2400-243F   | technical            |
| Enclosed Alphanumerics               | 2460-24FF   | misc                 |
| Box Drawing                          | 2500-257F   | box-drawing          |
| Block Elements                       | 2580-259F   | blocks               |
| Geometric Shapes                     | 25A0-25FF   | geometric            |
| Miscellaneous Symbols                | 2600-26FF   | misc-symbols         |
| Dingbats                             | 2700-27BF   | dingbats             |
| Misc Math Symbols-A                  | 27C0-27EF   | math                 |
| Supplemental Arrows-A                | 27F0-27FF   | arrows               |
| Braille Patterns                     | 2800-28FF   | braille              |
| Supplemental Arrows-B                | 2900-297F   | arrows               |
| Misc Math Symbols-B                  | 2980-29FF   | math                 |
| Supplemental Math Operators          | 2A00-2AFF   | math                 |
| Misc Symbols and Arrows              | 2B00-2BFF   | arrows               |
| CJK Symbols and Punctuation          | 3000-303F   | cjk                  |
| Enclosed CJK                         | 3200-32FF   | cjk                  |
| CJK Compatibility                    | 3300-33FF   | cjk                  |
| Enclosed Alphanumeric Supplement     | 1F100-1F1FF | emoji                |
| Enclosed Ideographic Supplement      | 1F200-1F2FF | emoji                |
| Misc Symbols and Pictographs         | 1F300-1F5FF | emoji                |
| Emoticons                            | 1F600-1F64F | emoji                |
| Ornamental Dingbats                  | 1F650-1F67F | emoji                |
| Transport and Map Symbols            | 1F680-1F6FF | emoji                |
| Alchemical Symbols                   | 1F700-1F77F | misc                 |
| Geometric Shapes Extended            | 1F780-1F7FF | geometric            |
| Supplemental Arrows-C                | 1F800-1F8FF | arrows               |
| Supplemental Symbols and Pictographs | 1F900-1F9FF | emoji                |
| Chess Symbols                        | 1FA00-1FA6F | misc                 |
| Symbols and Pictographs Extended-A   | 1FA70-1FAFF | emoji                |
| Symbols for Legacy Computing         | 1FB00-1FBFF | misc                 |
| Math Alphanumeric Symbols            | 1D400-1D7FF | math                 |
| Letterlike Symbols                   | 2100-214F   | letterlike           |

## Emoji Data

Better human-readable names available from:
`https://raw.githubusercontent.com/muan/unicode-emoji-json/refs/heads/main/data-by-emoji.json`

Format:

```json
{
  "😀": { "name": "grinning face", "slug": "grinning_face", "group": "smileys and people" },
  "🔥": { "name": "fire", "slug": "fire", "group": "travel and places" },
  ...
}
```

This is the same source used by Snacks' built-in emoji picker.

## Block Range Approach for Category Mapping

Instead of filtering by General Category (too fine-grained for our use case),
map Unicode blocks to our 15 semantic categories.

Strategy:

1. Parse Blocks.txt to get block ranges and names
2. Map each block to one of our categories
3. Within included ranges, also filter out:
   - ASCII (U+0000-U+007F)
   - CJK Unified Ideographs (U+4E00-U+9FFF, U+3400-U+4DBF)
   - Hangul Syllables (U+AC00-U+D7AF)
   - Private Use Areas
   - Surrogates
   - Non-characters

## References

- `ref:https://www.unicode.org/reports/tr44/` (UAX #44)
- `ref:https://www.unicode.org/Public/UCD/latest/ucd/UnicodeData.txt`
- `ref:https://www.unicode.org/Public/UCD/latest/ucd/Blocks.txt`
- `ref:https://raw.githubusercontent.com/muan/unicode-emoji-json/refs/heads/main/data-by-emoji.json`
