if exists('g:loaded_presen_vim')
  finish
endif
let g:loaded_presen_vim = 1

let s:save_cpo = &cpo
set cpo&vim

"Define presentation command
command! -nargs=? -complete=file Presen  call presen#presentation(<q-args>)
command! -nargs=? -complete=file Vp2html  call presen#vp2html(<q-args>)

let &cpo = s:save_cpo
unlet s:save_cpo
