let s:save_cpo = &cpo
set cpo&vim

let s:unite_source = {
      \ 'name': 'presen',
      \ 'hooks': {},
      \ 'action_table': {'*': {}},
      \ }

function! s:unite_source.hooks.on_init(args, context)
        "DO NOTHING
endfunction

function! s:unite_source.hooks.on_close(args, context)
        "DO NOTHING
endfunction

let s:unite_source.action_table['*'].preview = {
      \ 'description' : 'show this page.',
      \ 'is_quit' : 0,
      \ }

function! s:unite_source.action_table['*'].preview.func(candidate)
  execute a:candidate.action__command
endfunction

function! s:showPageCommand(pageNum)
        return printf("call presen#showPage(%s)", a:pageNum)
endfunction

function! s:unite_source.gather_candidates(args, context)
  let titleList = presen#presenInfo()
  return map(titleList, '{
        \ "word": v:val[0][2 : ],
        \ "abbr": v:val[0],
        \ "source": "presen",
        \ "kind": "command",
        \ "action__command": s:showPageCommand(v:val[1]),
        \ }')
endfunction

function! unite#sources#presen#define()
  return s:unite_source
endfunction


"unlet s:unite_source

let &cpo = s:save_cpo
unlet s:save_cpo
