" vikiLatex.vim -- viki add-on for LaTeX
" @Author:      Thomas Link (samul AT web.de)
" @License:     GPL (see http://www.gnu.org/licenses/gpl.txt)
" @Created:     28-Jän-2004.
" @Last Change: 30-Jän-2004.
" @Revision:    0.83
" 
" Description:
" Use LaTeX commands as simple viki names. Currently supported:
"   - \viki[anchor]{name]
" 	- \input
" 	- \include
" 	- \usepackage
" 	- \psfig
" 	- \includegraphics

fun! VikiSetupBufferLaTeX(state)
    let noMatch = ""
    call VikiSetupBuffer(a:state, "sSic")
    let b:vikiNameTypes = substitute(b:vikiNameTypes, '\C[Sic]', "", "g")
    let b:vikiLatexCommands = 'viki\|include\|input\|usepackage\|psfig\|includegraphics'
    if b:vikiNameTypes =~# "s"
        let b:vikiSimpleNameRx         = '\(\\\('. b:vikiLatexCommands .'\)\(\[\(.\{-}\)\]\)\?{\(.\{-}\)}\)'
        let b:vikiSimpleNameSimpleRx   = '\\\('. b:vikiLatexCommands .'\)\(\[.\{-}\]\)\?{.\{-}}'
        let b:vikiSimpleNameNameIdx    = 1
        let b:vikiSimpleNameCommandIdx = 2
        let b:vikiSimpleNameFileIdx    = 5
        let b:vikiSimpleNameDestIdx    = 0
        let b:vikiSimpleNameAnchorIdx  = 4
    else
        let b:vikiSimpleNameRx        = noMatch
        let b:vikiSimpleNameSimpleRx  = noMatch
        let b:vikiSimpleNameNameIdx   = 0
        let b:vikiSimpleNameDestIdx   = 0
        let b:vikiSimpleNameAnchorIdx = 0
    endif
endfun

fun! <SID>VikiLatexCheckFilename(filename, ...)
    let i = 1
    while i <= a:0
        exe "let fn = '".a:filename."'.a:". i
        if filereadable(fn)
            return fn
        else
            exe "let rv = system('kpsewhich ". fn ."')"
            if rv != ""
                return substitute(rv, "\n", "", "g")
            endif
            let i = i + 1
        endif
    endwh
    return ""
endfun

fun! VikiCompleteSimpleNameDefLaTeX(def)
    let name   = MvElementAt(a:def, g:vikiDefSep, 0)
    if name == g:vikiDefNil
        throw "Viki: Malformed simple viki name (no name): ".a:def
    endif

    let dest   = MvElementAt(a:def, g:vikiDefSep, 1)
    if !(dest == g:vikiDefNil)
        throw "Viki: Malformed simple viki name (destination): ".a:def
    endif
    
    let useSuffix = "*|*"

    let cmd  = substitute(name, b:vikiSimpleNameRx, '\'. b:vikiSimpleNameCommandIdx, "g")
    let file = substitute(name, b:vikiSimpleNameRx, '\'. b:vikiSimpleNameFileIdx,    "g")
    if cmd == "input"
        let dest = <SID>VikiLatexCheckFilename(file, "", ".tex", ".sty")
    elseif cmd == "usepackage"
        let dest = <SID>VikiLatexCheckFilename(file, ".sty")
    elseif cmd == "include" || cmd == "viki"
        let dest = <SID>VikiLatexCheckFilename(file, ".tex")
    elseif cmd == "psfig"
        let f == matchstr(file, "figure=\zs.\{-}\ze[,}]")
        let dest = <SID>VikiLatexCheckFilename(file, "")
    elseif cmd == "includegraphics"
        let dest = <SID>VikiLatexCheckFilename(file, "", 
                    \ ".eps", ".ps", ".pdf", ".png", ".jpeg", ".jpg", ".gif", ".wmf")
    else
        throw "Viki LaTeX: unsupported command: ". cmd
    endif
    
    if dest == ""
        throw "Viki LaTeX: can't find: ". name
    else
        if cmd == "viki"
            let anchor = MvElementAt(a:def, g:vikiDefSep, 2)
        else
            let name   = g:vikiDefNil
            let anchor = g:vikiDefNil
        endif
        return VikiMakeDef(name, dest, anchor)
    endif
endfun

fun! VikiMinorModeLaTeX (state)
    let b:vikiFamily = "LaTeX"
    call VikiMinorMode(a:state)
endfun

command! VikiMinorModeLaTeX call VikiMinorModeLaTeX(1)
command! VikiMinorModeMaybeLaTeX call VikiMinorModeLaTeX(-1)
" au FileType tex let b:vikiFamily="LaTeX"

