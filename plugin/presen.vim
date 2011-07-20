"Define presentation command
command! -nargs=? -complete=file Presen  call presen#presentation(<q-args>)

au BufNewFile,BufRead *.vp      setf vimpresen
