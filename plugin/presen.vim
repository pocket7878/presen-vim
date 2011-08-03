"Define presentation command
command! -nargs=? -complete=file Presen  call presen#presentation(<q-args>)

"Set filetype
au BufNewFile,BufRead *.vp      setf vimpresen

