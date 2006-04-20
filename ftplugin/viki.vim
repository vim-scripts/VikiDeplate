" viki.vim -- the viki ftplugin
" @Author:      Thomas Link (samul AT web.de)
" @License:     GPL (see http://www.gnu.org/licenses/gpl.txt)
" @Created:     12-Jän-2004.
" @Last Change: 29-Mär-2006.
" @Revision: 146

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

let b:vikiEnabled = 2

let &include='\(^\s*#INC.\{-}\(\sfile=\|:\)\)'
" let &include='\(^\s*#INC.\{-}\(\sfile=\|:\)\|\[\[\)'
" set includeexpr=substitute(v:fname,'\].*$','','')

let &define='^\s*\(#Def.\{-}id=\|#\(Fn\|Footnote\).\{-}\(:\|id=\)\|#VAR.\{-}\s\)'

let b:vikiHeadingMaxLevel = 0

" if !exists('b:vikiHideBody') | let b:vikiHideBody = 0 | endif

" if !hasmapto(":VikiFind")
"     nnoremap <buffer> <c-tab>   :VikiFindNext<cr>
"     nnoremap <buffer> <LocalLeader>vn :VikiFindNext<cr>
"     nnoremap <buffer> <c-s-tab> :VikiFindPrev<cr>
"     nnoremap <buffer> <LocalLeader>vN :VikiFindPrev<cr>
" endif

" compiler deplate


if exists('*VikiFoldLevel')
    finish
endif

fun! VikiFoldLevel(lnum)
    let vikiFolds = exists('b:vikiFolds') ? b:vikiFolds : g:vikiFolds
    if stridx(vikiFolds, 'h') >= 0
        if vikiFolds =~? 'h'
            let fl = <SID>ScanHeading(a:lnum, a:lnum, vikiFolds)
            if fl != ''
                return fl
            endif
        endif
        if vikiFolds =~# 'l' 
            let list = <SID>MatchList(a:lnum)
            if list > 0
                " return '>'. (b:vikiHeadingMaxLevel + (list / &sw))
                return (b:vikiHeadingMaxLevel + (list / &sw))
            elseif getline(a:lnum) !~ '^[[:blank:]]' && <SID>MatchList(a:lnum - 1) > 0
                let fl = <SID>ScanHeading(a:lnum - 1, 1, vikiFolds)
                if fl != ''
                    if fl[0] == '>'
                        let fl = strpart(fl, 1)
                    endif
                    return '<'. (fl + 1)
                endif
            endif
        endif
        if vikiFolds =~# 's'
            if exists('b:vikiFoldDef')
                exec b:vikiFoldDef
                if vikiFoldLine == a:lnum
                    return vikiFoldLevel
                endif
            endif
            let i = 1
            while i > a:lnum
                let vfl = VikiFoldLevel(a:lnum - i)
                if vfl[0] == '>'
                    let b:vikiFoldDef = 'let vikiFoldLine='. a:lnum 
                                \ .'|let vikiFoldLevel="'. vfl .'"'
                    return vfl
                elseif vfl == '='
                    let i = i + 1
                endif
            endwh
        endif
        if b:vikiHeadingMaxLevel == 0
            return 0
        elseif vikiFolds =~# 'b'
            return b:vikiHeadingMaxLevel + 1
        else
            return "="
        endif
    endif
    return 0
endfun

fun! <SID>ScanHeading(lnum, top, vikiFolds)
    let lnum = a:lnum
    while lnum >= a:top
        let head = <SID>MatchHead(lnum)
        if head > 0
            if head > b:vikiHeadingMaxLevel
                let b:vikiHeadingMaxLevel = head
            endif
            if b:vikiInverseFold || a:vikiFolds =~# 'H'
                if b:vikiMaxFoldLevel > head
                    return ">". (b:vikiMaxFoldLevel - head)
                else
                    return ">0"
                end
            else
                return ">". head
            endif
        endif
        let lnum = lnum - 1
    endwh
    return ''
endf

fun! <SID>MatchHead(lnum)
    " let head = matchend(getline(a:lnum), '\V\^'. escape(b:vikiHeadingStart, '\') .'\ze\s\+')
    return matchend(getline(a:lnum), '\V\^'. b:vikiHeadingStart .'\+\ze\s\+')
endf

fun! <SID>MatchList(lnum)
    let rx = '^[[:blank:]]\+\ze\(#[A-F]\d\?\|#\d[A-F]\?\|[-+*#?@]\|[0-9#]\+\.\|[a-zA-Z?]\.\|.\{-1,}[[:blank:]]::\)[[:blank:]]'
    return matchend(getline(a:lnum), rx)
endf

