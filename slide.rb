# slide.rb - slide content + layout knobs
#
# This is the file you usually edit. Build with `./build.sh`.
# Available font constants are defined in fonts/*.rb (loaded earlier in
# the build):
#
#   ASCII (terminus)    : FONT_6x12 / FONT_8x16 / FONT_12x24 / FONT_16x32
#   Japanese (shinonome): SHINONOME_K12 / SHINONOME_K16
#   Sprites (hasumikin) : SPRITE_RAPIKO / SPRITE_CAMERLENGO

# ---------- layout ----------
SCREEN_COLS     = 480  # assumed terminal width in cells (Rapicco-scale, 1 cell = 1 px)
SCREEN_ROWS     = 110  # assumed terminal height in cells
SPRITE_BASELINE = SCREEN_ROWS # rapiko / camerlengo の足元 y。下端固定なら SCREEN_ROWS
DURATION_SEC    = 30   # total presentation time the camerlengo bar fills
SPRITE_HEIGHT   = 11   # rows occupied by rapiko / camerlengo

# ---------- font choices ----------
TITLE_FONT   = FONT_8x16 # JP_FONT / JP_SCALE follow this in facet.rb
BODY_EN_FONT = FONT_6x12
BODY_JP_FONT = SHINONOME_K12

# ---------- slides ----------
PAGES = [
  { title: "facet",
    body: ["",
           "  a minimal bitmap slide tool on mruby",
           "",
           "  width ruler (75 ascii chars = 450 cells, margin on the right):",
           "  ----+----1----+----2----+----3----+----4----+----5----+----6----+----7----+",
           "",
           "  l + Enter to go forward"] },

  { title: "design",
    body: ["- mruby subset only",
           "- no filesystem, no signals",
           "- pages embedded as ruby literals",
           "- stdin and stdout only"] },

  { title: "keys",
    body: ["- h + Enter  : previous page",
           "- l + Enter  : next page",
           "- q + Enter  : quit",
           "",
           "  line-buffered. no stty needed"] },

  { title: "ascii font",
    body: ["- terminus 4.49.1, 4 sizes bundled",
           "    6x12 / 8x16 / 12x24 / 16x32",
           "- 1 pixel = 1 terminal cell",
           "- glyphs packed as string literals in fonts/"] },

  { title: "decoration",
    body: ["- bullet lines get a red sprite dot",
           "- non-bullet lines stay plain",
           "- title is yellow, body is white",
           "- rabbit = page progress, turtle = time"] },

  { title: "東雲フォント",
    body: ["- shinonome 0.9.11 を取り込み",
           "- ひらがな ・ カタカナ ・ 第1水準漢字",
           "- 12x12 と 16x16 を内蔵",
           "- 24x24 と 32x32 は整数倍スケールで描画"] },

  { title: "漢字混在",
    body: ["- タイトルも本文もすべて bitmap で描画される",
           "- ASCII は terminus、JP は shinonome を 1 文字単位で切替",
           "- 端末のフォントには依存しない"] },

  { title: "rows",
    body: ["  line 1 - body top, just below the title",
           "  line 2 - ruler ----+----1----+----2----+----3----+----4----+----5----+----6",
           "  line 3 - ascii lower: abcdefghijklmnopqrstuvwxyz 0123456789",
           "  line 4 - 日本語: あいうえお かきくけこ さしすせそ たちつてと なにぬねの",
           "  line 5 - 混在:   ABCDE 漢字 日本語 東雲 第一水準 0123456789",
           "  line 6 - last visible row, the next one bleeds into the sprite area"] },

  { title: "build",
    body: ["- `./build.sh` で facet.mrb を生成",
           "- fonts/*.rb を先に並べて 1 ファイルに mrbc",
           "- 東雲のデータは chunk に分けて起動時に unpack する"] },

  { title: "facet",
    body: ["",
           "  end of demo",
           "",
           "  q + Enter to quit"] },
]
