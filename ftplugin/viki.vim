" viki.vim -- the viki ftplugin
" @Author:      Thomas Link (samul AT web.de)
" @License:     GPL (see http://www.gnu.org/licenses/gpl.txt)
" @Created:     12-Jän-2004.
" @Last Change: 17-Mai-2004.
" @Revision: 13

if exists("b:did_ftplugin")
  finish
endif
let b:did_ftplugin = 1

let b:vikiCommentStart = "%"
let b:vikiCommentEnd   = ""

exe "setlocal commentstring=". b:vikiCommentStart ."%s". b:vikiCommentEnd
exe "setlocal comments=:". b:vikiCommentStart

setlocal foldmethod=expr
setlocal foldexpr=VikiFoldLevel(v:lnum)

fun! VikiFoldLevel(lnum)
    " let head = matchend(getline(a:lnum), '\V\^'. escape(b:vikiHeadingStart, '\') .'\ze\s\+')
    let head = matchend(getline(a:lnum), '\V\^'. b:vikiHeadingStart .'\+\ze\s\+')
    if head > 0
        return ">". head
    else
        " return foldlevel(a:lnum - 1)
        return "="
    endif
endfun

if !hasmapto(":VikiFind")
    nnoremap <buffer> <c-tab>   :VikiFindNext<cr>
    nnoremap <buffer> <c-s-tab> :VikiFindPrev<cr>
endif

" compiler viki

let b:vikiEnabled = 2

" vim: ff=unix
