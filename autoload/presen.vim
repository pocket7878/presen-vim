"Vital
let s:V = vital#of('presen_vim')

function! s:ReadVp(vpfilepath)"{{{
        if a:vpfilepath ==# '%'
                for i in range(1, line('$'))
                        let l:line = getline(i)
                        let l:line = substitute(l:line,"^\\s\\+\\|\\s\\+$","","g")
                        ";以降の行は無視する"
                        if l:line !~ "^;"
                                call add(l:buf, l:line)
                        endif
                endfor
        else
                let l:buf = []
                for line in readfile(a:vpfilepath)        
                        let line = substitute(line,"^\\s\\+\\|\\s\\+$","","g")
                        ";以降の行は無視する"
                        if line !~ "^;"
                                call add(l:buf, line)
                        endif
                endfor
        endif
        return join(l:buf, ' ')
endfunction"}}}

function! s:CreateToken(vpfilepath)"{{{
        let l:line = s:ReadVp(a:vpfilepath)
        let l:buf = []
        let l:reg = ''
        let l:inString = 0
        let l:nextEscape = 0
        for i in split(l:line, '\zs')
                if l:nextEscape
                        "エスケープされている状態ならば全ての文字はなんの効果ももたない
                        let l:reg = l:reg.i
                        "エスケープ状態を解除する
                        let l:nextEscape = 0
                elseif i == '('
                        if l:inString
                                let l:reg = l:reg.i
                        else
                                "そこまでの文字をバッファに追加して
                                if l:reg != ''
                                        call add(l:buf, l:reg)
                                endif
                                "レジスターを初期化する
                                let l:reg = ''
                                "エスケープされていない状態でカッコに遭遇したらそれは切りだす
                                call add(l:buf, i)
                        endif
                elseif i == ' '
                        "スペースに遭遇した
                        "もし文字列中ならば無視してレジスターに追加する
                        if l:inString
                                let l:reg = l:reg.i
                        else
                                "文字列中でないならそこまでの文字をバッファに追加する
                                if l:reg != ''
                                        call add(l:buf, l:reg)
                                endif
                                "レジスターを初期化する
                                let l:reg = ''
                        endif
                elseif i == '"'
                        "ダブルクオートに遭遇した
                        "この段階でもしもエスケープされたダブルクオートはスキップされている筈
                        "よって文字列の開始か終了だと判断できる
                        if l:inString 
                                let l:inString = 0
                                call add(l:buf, l:reg)
                                "レジスターを初期化する
                                let l:reg = ''
                        else
                                let l:inString = 1
                        endif
                elseif i == '\'
                        let l:nextEscape = 1
                        "結果の中にもエスケープ文字は残っている必要が有るので
                        let l:reg = l:reg.i
                elseif i == ')'
                        if l:inString
                                let l:reg = l:reg.i
                        else
                                "エスケープされていないコッカに遭遇した
                                "そこまでの文字をバッファに追加して
                                if l:reg != ''
                                        call add(l:buf, l:reg)
                                endif
                                "レジスターを初期化する
                                let l:reg = ''
                                call add(l:buf, i)
                        endif
                elseif i == '{' || i == '}'
                        if l:inString
                                let l:reg = l:reg.i
                        else
                                "そこまでの文字をバッファに追加して
                                if l:reg != ''
                                        call add(l:buf, l:reg)
                                endif
                                "レジスターを初期化する
                                let l:reg = ''
                                call add(l:buf, i)
                        endif
                else 
                        "それ以外の文字たちはすべてレジスタに連結する
                        let l:reg = l:reg.i
                endif
        endfor
        return l:buf
endfunction"}}}

function! s:ListTokenLength(lst)"{{{
        let l:leng = 0
        if type(a:lst) != type([])
                return 1
        else
                for item in a:lst
                        if type(item) ==# type("")
                                "もしアイテムがただの文字列ならば長さに1ついか
                                let l:leng += 1
                        else
                                "アイテムが配列なので再帰てきに計測したながさを追加する
                                let l:leng += s:ListTokenLength(item)
                        endif
                        unlet item
                endfor
        "はさんでいる括弧の分の個数を追加して返却
        return l:leng+2
        endif
endfunction"}}}

function! s:GetSexp(vpBuf)"{{{
        let l:buf = []
        let l:level = 0
        let l:idx = 0
        let l:finish = 0
        while l:finish != 1 
                if l:idx >= len(a:vpBuf)
                        let l:finish = 1
                else
                        if a:vpBuf[l:idx] == '('
                                "ネストレベルを一段深くする
                                let l:level += 1
                                "カッコがはじまったらのこりをパースしてそれをバッファーについかする
                                let l:returnVal = s:GetSexp(a:vpBuf[l:idx + 1 : ])
                                call add(l:buf, l:returnVal)
                                let l:idx += s:ListTokenLength(l:returnVal)
                        elseif a:vpBuf[l:idx] == ')'
                                "ネストレベルを一段浅くする
                                let l:level -= 1
                                "ネストレベルが0になったらバッファをかえす
                                if l:level <= 0
                                        let l:finish = 1
                                endif
                        else
                                call add(l:buf, a:vpBuf[l:idx])
                                let l:idx += 1
                        endif
                endif
        endwhile
        return l:buf
endfunction"}}}

function! s:ContextArrToContextDict(context)"{{{
        let l:dict = {}
        for idx in range(0, len(a:context)-1)
                if a:context[idx][0] ==# 'width'
                        let l:dict['width'] = a:context[idx][1]
                elseif a:context[idx][0] ==# 'height'
                        let l:dict['height'] = a:context[idx][1]
                elseif a:context[idx][0] ==# 'font'
                        let l:dict['font'] = a:context[idx][1]
                endif
        endfor
        return l:dict
endfunction"}}}

function! s:PageArrToPageDict(page)"{{{
        let l:dict = {}
        for idx in range(0, len(a:page)-1)
                if a:page[idx][0] ==# 'title'
                        let l:dict['title'] = a:page[idx][1]
                elseif a:page[idx][0] ==# 'contents'
                        let l:dict['contents'] = a:page[idx][1 :]
                endif
        endfor
        return l:dict
endfunction"}}}

function! s:CreatePresenScript(vpfilepath)"{{{
        let l:tokens = s:CreateToken(a:vpfilepath)
        let l:pages = []
        let l:context = {}
        let l:idx = 0
        let l:finish = 0
        while l:finish != 1
                if len(l:tokens) == 0
                        let l:finish = 1
                else
                        "Get One sexp
                        let l:Page = s:GetSexp(l:tokens)
                        "Check sexp type (defslide or defcontext)
                        if l:Page[0][0] ==# "defcontext"
                                "つまり最後に定義されたコンテキストが有効になる
                                let l:context = s:ContextArrToContextDict(l:Page[0][1 :])
                        elseif l:Page[0][0] ==# "defslide"
                                for pageArry in l:Page[0][1 : ]
                                        "Add Page
                                        call add(l:pages, s:PageArrToPageDict(pageArry))
                                endfor
                        endif
                        "Forword idx
                        let l:tokens = l:tokens[s:ListTokenLength(l:Page[0]) : ]
                endif
        endwhile
        return [l:context, l:pages]
endfunction"}}}

function! s:parseContents(linum,centerp, contents)"{{{
        let l:linum = a:linum
        for item in a:contents
                if type(item) ==# type([])
                        if item[0] ==# "center"
                                "Get next linum
                                let l:linum = s:parseContents(l:linum,1, item[1 : ])
                        elseif item[0] ==# "p"
                                let l:linum += 1
                                let l:linum = s:parseContents(l:linum,1, item[1 : ])
                                let l:linum += 1
                        elseif item[0] ==# "hl"
                                call curses#display#mvprinthl(l:linum)
                                let l:linum += 1
                        elseif item[0] ==# "vimlogo"
                                if a:centerp
                                        call s:cprintVimLogo(l:linum)
                                else
                                        call s:printVimLogo(l:linum,1)
                                endif
                                let l:linum += 15
                        elseif item[0] ==# "t"
                                call curses#display#mvcprintw(curses#info#rows()/2, item[1])
                                break
                        ""PrintList
                        "Item list
                        elseif item[0] ==# 'ul'
                                if a:centerp
                                        call curses#display#mvcprintList(l:linum, "* ",item[1 : ])
                                else
                                        call curses#display#mvprintList(l:linum, 1, "* ",item[1 : ])
                                endif
                                let l:linum += len(item[1 : ])
                        "Numberd list
                        elseif item[0] ==# 'ol'
                                if a:centerp
                                        call curses#display#mvcnprintList(l:linum, item[1 : ])
                                else
                                        call curses#display#mvnprintList(l:linum, 1, item[1 : ])
                                endif
                                let l:linum += len(item[1 : ])
                        elseif item[0] ==# 'lines'
                                if a:centerp
                                        call curses#display#mvcprintList(l:linum, "",item[1 : ])
                                else
                                        call curses#display#mvprintList(l:linum, 1, "",item[1 : ])
                                endif
                                let l:linum += len(item[1 : ])
                        endif
                else
                        if a:centerp
                                call curses#display#mvcprintw(l:linum, item)
                        else
                                call curses#mvprintw(l:linum, 1, item)
                        endif
                        let l:linum += 1
                endif
                unlet item
        endfor
        return l:linum
endfunction"}}}

function! s:ParsePage(pageDict)"{{{
        "タイトルが設定されていたらそれを表示する
        if has_key(a:pageDict, 'title')
                call curses#display#mvcprintw(1, a:pageDict['title'])
        endif
        let l:center_mode = 0
        let l:linum = 3
        "コンテンツを表示する
        call s:parseContents(3,0,a:pageDict['contents'])
endfunction"}}}

function! s:openPresenWindow()"{{{
        if !exists('s:bufnr')
                let s:bufnr = -1 " A number that doesn't exist.
        endif
        if !bufexists(s:bufnr)
                let s:prevBufNr = bufnr('%')
                edit `='[Presentation]'`
                let s:bufnr = bufnr('%')
                setlocal bufhidden=hide buftype=nofile noswapfile nobuflisted
                setlocal filetype=presen
        elseif bufwinnr(s:bufnr) != -1
                let s:prevBufNr = bufnr('%')
                execute bufwinnr(s:bufnr) 'wincmd w'
        else
                let s:prevBufNr = bufnr('%')
                execute 'buffer' s:bufnr
        endif
endfunction"}}}

function! s:getCurrentContext()"{{{
        let l:context = {}
        let l:context['width'] = &columns
        let l:context['height'] = &lines
        if has('gui_running')
                let l:context['font'] = &guifont
        endif
        return l:context
endfunction"}}}

function! s:applyContext(context)"{{{
        if has_key(a:context, 'width')
                execute 'set columns='.str2nr(a:context['width'])
        endif
        if has_key(a:context, 'height')
                execute 'set lines='.str2nr(a:context['height'])
        endif
        if has('gui_running')
                if has_key(a:context, 'font')
                        execute 'set guifont='.escape(a:context['font'],' ')
                endif
        endif
endfunction"}}}

"ページ遷移のための関数群
"指定番号のページを表示する
function! s:show_page(page)"{{{
        let b:page = a:page
        "画面を消去
        call curses#erase() 
        "現在のページを表示する
        call s:ParsePage(b:PresenScript[1][a:page - 1])
        setlocal statusline=[%{b:page}/%{b:pages}]
        redraw
endfunction"}}}

"次のページがあればそれを表示する
function! presen#nextPage()"{{{
        if b:page != b:pages
                let b:page += 1
        endif
        call s:show_page(b:page)
endfunction"}}}

"前のページがあればそれを表示する
function! presen#prevPage()"{{{
        if b:page != 1
                let b:page -= 1
        endif
        call s:show_page(b:page)
endfunction"}}}

"最初のページに遷移する
function! presen#firstPage()"{{{
        let b:page = 1
        call s:show_page(b:page)
endfunction"}}}

"最後のページに遷移する
function! presen#lastPage()"{{{
        let b:page = b:pages
        call s:show_page(b:page)
endfunction"}}}

"プレゼンを終了する
function! presen#quit()"{{{
        "画面を復帰
        call curses#endWin()
        "コンテキストも復帰する
        call s:applyContext(s:context)
        "そして元のバッファーへ復帰するのさ
        execute 'buffer' s:prevBufNr
endfunction"}}}

function! presen#presentation(vpfilepath)"{{{
        if !a:vpfilepath ==# '%' 
                "Check Error
                if isdirectory(a:vpfilepath)
                        call s:V.print_error(a:vpfilepath.'is not a file.')
                        return
                endif
                if glob(a:vpfilepath) ==# ''
                        call s:V.print_error(a:vpfilepath." does not exist.")
                        return
                endif
                if !filereadable(expand(a:vpfilepath))
                        call s:V.print_error("Can't read ".a:vpfilepath.'.')
                        return
                endif
        endif
        "プレゼンスクリプトをファイルから作成する
        let l:PresenScript = s:CreatePresenScript(a:vpfilepath)
        "コンテキストを取得
        let l:context = l:PresenScript[0]
        "総ページ数を取得
        let l:pages = len(l:PresenScript[1])
        "最初は1ページから
        let l:page = 1
        "ユーザーの入力を保存する変数
        let l:ch = ''
        "プレゼンようのウィンドウとバッファーをオープンする
        call s:openPresenWindow()
        "現在のコンテキストを保存する
        let s:context = s:getCurrentContext()
        "コンテキストを反映する(なければ何も発生しないので得にexistsのチェックはしない）
        call s:applyContext(l:context)
        "外部の関数からも利用するために、バッファローカル変数にPresenScriptを保存する
        let b:PresenScript = l:PresenScript
        "そのバッファを初期化
        call curses#initScr()
        "nextPage()やprevPage()から表示するために、pagesをバッファローカルな変数に保存
        let b:pages = l:pages
        "1ページを表示
        call s:show_page(1)
endfunction"}}}

"いくつか、おもしろとしてつくっておく関数たち
function! s:printVimLogo(y,x)"{{{
        call curses#display#mvprintList(a:y, a:x, "",[
\"        ________ ++     ________",
\"       /VVVVVVVV\++++  /VVVVVVVV\\",
\"       \VVVVVVVV/++++++\VVVVVVVV/",
\"        |VVVVVV|++++++++/VVVVV/'",
\"        |VVVVVV|++++++/VVVVV/'",
\"       +|VVVVVV|++++/VVVVV/'+",
\"     +++|VVVVVV|++/VVVVV/'+++++",
\"   +++++|VVVVVV|/VVVVV/'+++++++++",
\"     +++|VVVVVVVVVVV/'+++++++++",
\"       +|VVVVVVVVV/'+++++++++",
\"        |VVVVVVV/'+++++++++",
\"        |VVVVV/'+++++++++",
\"        |VVV/'+++++++++",
\"        'V/'   ++++++",
\"                 ++"])
endfunction"}}}

function! s:cprintVimLogo(y)"{{{
        call curses#display#mvcprintList(a:y, "",[
\"        ________ ++     ________",
\"       /VVVVVVVV\++++  /VVVVVVVV\\",
\"       \VVVVVVVV/++++++\VVVVVVVV/",
\"        |VVVVVV|++++++++/VVVVV/'",
\"        |VVVVVV|++++++/VVVVV/'",
\"       +|VVVVVV|++++/VVVVV/'+",
\"     +++|VVVVVV|++/VVVVV/'+++++",
\"   +++++|VVVVVV|/VVVVV/'+++++++++",
\"     +++|VVVVVVVVVVV/'+++++++++",
\"       +|VVVVVVVVV/'+++++++++",
\"        |VVVVVVV/'+++++++++",
\"        |VVVVV/'+++++++++",
\"        |VVV/'+++++++++",
\"        'V/'   ++++++",
\"                 ++"])
endfunction"}}}

