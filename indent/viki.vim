" viki.vim -- viki indentation
" @Author:      Thomas Link (samul AT web.de)
" @Website:     http://members.a1.net/t.link/
" @License:     GPL (see http://www.gnu.org/licenses/gpl.txt)
" @Created:     16-Jän-2004.
" @Last Change: 19-Aug-2004.
" @Revision: 0.84

if exists("b:did_indent") || exists("g:vikiNoIndent")
    finish
endif
let b:did_indent = 1

setlocal indentexpr=VikiGetIndent()
setlocal indentkeys&
" setlocal indentkeys+=

" Only define the function once.
if exists("*VikiGetIndent")
    finish
endif

fun! VikiGetIndent()
    " Find a non-blank line above the current line.
    let lnum = prevnonblank(v:lnum - 1)

    " At the start of the file use zero indent.
    if lnum == 0
        return 0
    endif

    let ind  = indent(lnum)
    let line = getline(lnum)      " last line
    
    " Do not change indentation of commented lines.
    if line =~ '^\s*%'
        return ind
    endif

    let cnum  = v:lnum
    let cline = getline(cnum) " current line
    let cind  = indent(cnum)

    let indRx  = '^\s\+'
    let clInd  = matchend(cline, indRx)

    if clInd >= 0
        let listRx = '^\s\+\([-+*#?]\|[0-9#]\+\.\|[a-zA-Z?]\.\)\s'
        let descRx = '^\s\+.\{-1,}\s::\s'
        
        let clList = matchend(cline, listRx)
        let clDesc = matchend(cline, descRx)

        if clList < 0 && clDesc < 0
            let pnum   = v:lnum - 1
            let pline  = getline(pnum) " last line
            let pind   = indent(pnum)
            let plInd  = matchend(pline, indRx)
            let plList = matchend(pline, listRx)
            let plDesc = matchend(pline, descRx)

            if plList >= 0
                return plList
            endif

            if plDesc >= 0
                return pind + &sw
            endif

            return plInd
        endif
    endif
    
    return cind
endfun

