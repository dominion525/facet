# Sprite data taken from picoruby-rapicco in PicoRuby ("hasumikin" set)
# Original: https://github.com/picoruby/picoruby
#           mrbgems/picoruby-rapicco/mrblib/sprite.rb
# License: MIT, Copyright © 2020 HASUMI Hitoshi
# SPRITE_CAMERLENGO drops the four blank leading rows of the original.
#
# Each row uses one character per pixel:
#   '.' = transparent (cursor advance)
#   others = palette key, rendered as a colored blank cell with
#            "\e[48;5;Nm \e[0m"

SPRITE_PALETTE = {
  "w" => 231,  # white
  "p" => 217,  # pink
  "b" => 232,  # black
  "g" => 34,   # shell green
  "y" => 178,  # dark yellow
  "d" => 22,   # dark green
  "r" => 196,  # red
}

SPRITE_RAPIKO = [
  "......www..ww",
  "......wpw..wp",
  "....wwwpwwwwpw",
  "...wwwwwwwwwwww",
  "...wwwwwbwwwwbw",
  "....wwwwwwwbwww",
  ".....wwwwwwwww",
  ".....pppppppppp",
  "....ppwwppppppww",
  "...wpppppppppp",
  ".....www....www",
]

SPRITE_CAMERLENGO = [
  ".............yyyyy",
  "............yyyddyy",
  "....ggggggggyyyyyyy",
  "...ggggggggggyyyyy",
  "..gggggggggggg",
  "yygggggggggggg",
  "...yyy......yyy",
]

SPRITE_BULLET = [
  "......rrrr",
  "....rrwwrrrr",
  "...rrrrrrrrrr...",
  ".....rrrrrr",
  ".......rr",
]
