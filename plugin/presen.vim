"Define presentation command
command! -nargs=? -complete=file Presen  call presen#presentation(<q-args>)
command! -nargs=? -complete=file Vp2html  call presen#vp2html(<q-args>)

"Set filetype
au BufNewFile,BufRead *.vp      setf vimpresen

