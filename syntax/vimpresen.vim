"小文字と大文字を区別する
syn case match

"Vim Presen Keywords
syn keyword vpKeyword   defslide
syn keyword vpKeyword   defcontext
syn keyword vpKeyword   title
syn keyword vpKeyword   contents
syn keyword vpKeyword   center
syn keyword vpKeyword   p 
syn keyword vpKeyword   lines
syn keyword vpKeyword   ul
syn keyword vpKeyword   ol
syn keyword vpKeyword   vimlogo
syn keyword vpKeyword   hl
syn keyword vpKeyword   width
syn keyword vpKeyword   height
syn keyword vpKeyword   font
syn keyword vpKeyword   fontwide
syn region  vpString	start=+"+ skip=+\\\\\|\\"+ end=+"+

"Define highlighting
hi def link vpKeyword   Statement
hi def link vpString    String
