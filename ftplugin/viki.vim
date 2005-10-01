" viki.vim -- the viki ftplugin
" @Author:      Thomas Link (samul AT web.de)
" @License:     GPL (see http://www.gnu.org/licenses/gpl.txt)
" @Created:     12-Jän-2004.
" @Last Change: 01-Okt-2005.
" @Revision: 89

if !g:vikiEnabled
    finish
endif

if exists("b:did_ftplugin")
  finish
endif
let b:did_ftplugin = 1

let b:vikiCommentStart = "%"
let b:vikiCommentEnd   = ""
if !exists("b:vikiMaxFoldLevel")
    let b:vikiMaxFoldLevel = 5
endif
if !exists("b:vikiInverseFold")
    let b:vikiInverseFold  = 0
endif

exe "setlocal commentstring=". substitute(b:vikiCommentStart, "%", "%%", "g") 
            \ ."%s". substitute(b:vikiCommentEnd, "%", "%%", "g")
exe "setlocal comments=:". b:vikiCommentStart

setlocal foldmethod=expr
setlocal foldexpr=VikiFoldLevel(v:lnum)
setlocal expandtab
setlocal iskeyword+=#

let &include='\(^\s*#INC.\{-}\(\sfile=\|:\)\)'
" let &include='\(^\s*#INC.\{-}\(\sfile=\|:\)\|\[\[\)'
" set includeexpr=substitute(v:fname,'\].*$','','')

let &define='^\s*\(#Def.\{-}id=\|#\(Fn\|Footnote\).\{-}\(:\|id=\)\|#VAR.\{-}\s\)'

fun! VikiFoldLevel(lnum)
    if stridx(g:vikiFolds, 'h') >= 0
        let head = <SID>MatchHead(a:lnum)
        if head > 0
            if b:vikiInverseFold
                if b:vikiMaxFoldLevel > head
                    return ">". (b:vikiMaxFoldLevel - head)
                else
                    return ">0"
                end
            else
                return ">". head
            endif
        endif
        return "="
    endif
    return 0
endfun

fun! <SID>MatchHead(lnum)
    " let head = matchend(getline(a:lnum), '\V\^'. escape(b:vikiHeadingStart, '\') .'\ze\s\+')
    return matchend(getline(a:lnum), '\V\^'. b:vikiHeadingStart .'\+\ze\s\+')
endf

" if !hasmapto(":VikiFind")
"     nnoremap <buffer> <c-tab>   :VikiFindNext<cr>
"     nnoremap <buffer> <LocalLeader>vn :VikiFindNext<cr>
"     nnoremap <buffer> <c-s-tab> :VikiFindPrev<cr>
"     nnoremap <buffer> <LocalLeader>vN :VikiFindPrev<cr>
" endif

" compiler deplate

let b:vikiEnabled = 2
