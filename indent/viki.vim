" viki.vim -- viki indentation
" @Author:      Thomas Link (samul AT web.de)
" @Website:     http://members.a1.net/t.link/
" @License:     GPL (see http://www.gnu.org/licenses/gpl.txt)
" @Created:     16-Jän-2004.
" @Last Change: 09-Sep-2004.
" @Revision: 0.133

if exists("b:did_indent") || exists("g:vikiNoIndent")
    finish
endif
let b:did_indent = 1

setlocal indentexpr=VikiGetIndent()
setlocal indentkeys&
setlocal indentkeys+=0#,0?,0<*>,0-,=::,o

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
    let cind  = indent(cnum)
    
    " Do not change indentation in regions
    if VikiIsInRegion(cnum)
        return cind
    endif
    
    if cind > 0
        let listRx = '^\s\+\([-+*#?]\|[0-9#]\+\.\|[a-zA-Z?]\.\)\s'
        let descRx = '^\s\+.\{-1,}\s::\s'
        
        let cline = getline(cnum) " current line

        let pnum   = v:lnum - 1
        let pind   = indent(pnum)
        
        let clList = matchend(cline, listRx)
        let clDesc = matchend(cline, descRx)
        let cln    = clList >= 0 ? clList : clDesc

        " echom "DBG clList=". clList ." clDesc=". clDesc ." cind=". cind ." ". " pind=".pind." ".cline

        if clList >= 0 || clDesc >= 0
            let spaceEnd = matchend(cline, '^\s\+')
            let rv = (spaceEnd / &sw) * &sw
            return rv
        else
            let pline  = getline(pnum) " last line
            let plList = matchend(pline, listRx)
            let plDesc = matchend(pline, descRx)

            if plList >= 0
                return plList
            endif

            if plDesc >= 0
                return pind + (&sw / 2)
            endif

            if cind < ind
                let rv = (cind / &sw) * &sw
                return rv
            elseif cind >= ind
                if cind % &sw == 0
                    return cind
                else
                    return ind
                end
            endif
        endif
    endif

    return cind
endfun

