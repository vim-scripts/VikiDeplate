" vikiLatex.vim -- viki add-on for LaTeX
" @Author:      Thomas Link (samul AT web.de)
" @License:     GPL (see http://www.gnu.org/licenses/gpl.txt)
" @Created:     28-Jän-2004.
" @Last Change: 02-Mai-2004.
" @Revision:    0.124

if &cp || exists("s:loaded_vikiLatex")
    finish
endif
let s:loaded_vikiLatex = 1

fun! VikiSetupBufferLaTeX(state)
    let noMatch = ""
    call VikiSetupBuffer(a:state, "sSic")
    let b:vikiAnchorRx = '\\label{%{ANCHOR}}'
    let b:vikiNameTypes = substitute(b:vikiNameTypes, '\C[Sic]', "", "g")
    let b:vikiLaTeXCommands = 'viki\|include\|input\|usepackage\|psfig\|includegraphics\|bibliography\|ref'
    if exists("g:vikiLaTeXUserCommands")
        let b:vikiLaTeXCommands = b:vikiLaTeXCommands .'\|'. g:vikiLaTeXUserCommands
    endif
    if b:vikiNameTypes =~# "s"
        " let b:vikiSimpleNameRx         = '\(\\\('. b:vikiLaTeXCommands .'\)\(\[\(\_.\{-}\)\]\)\?{\(.\{-}\)}\)'
        " let b:vikiSimpleNameSimpleRx   = '\\\('. b:vikiLaTeXCommands .'\)\(\[\_.\{-}\]\)\?{.\{-}}'
        let b:vikiSimpleNameRx         = '\(\\\('. b:vikiLaTeXCommands .'\)\(\[\(.\{-}\)\]\)\?{\(.\{-}\)}\)'
        let b:vikiSimpleNameSimpleRx   = '\\\('. b:vikiLaTeXCommands .'\)\(\[.\{-}\]\)\?{.\{-}}'
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

fun! VikiLatexCheckFilename(filename, ...)
    if a:filename != ""
        """ search in the current directory
        let i = 1
        while i <= a:0
            exe "let fn = '".a:filename."'.a:". i
            if filereadable(fn)
                return fn
            endif
            let i = i + 1
        endwh

        """ use kpsewhich
        let i = 1
        while i <= a:0
            exe "let fn = '".a:filename."'.a:". i
            exe "let rv = system('kpsewhich ". fn ."')"
            if rv != ""
                return substitute(rv, "\n", "", "g")
            endif
            let i = i + 1
        endwh
    endif
    return ""
endfun

fun! VikiCompleteSimpleNameDefLaTeX(def)
    let name   = MvElementAt(a:def, g:vikiDefSep, 0)
    if name == g:vikiDefNil
        throw "Viki: Malformed simple viki name (no name): ".a:def
    endif

    let cmd  = substitute(name, b:vikiSimpleNameRx, '\'. b:vikiSimpleNameCommandIdx, "g")

    let file = substitute(name, b:vikiSimpleNameRx, '\'. b:vikiSimpleNameFileIdx,    "g")
    " let file   = MvElementAt(a:def, g:vikiDefSep, 1)
    " if !(file == g:vikiDefNil)
        " throw "Viki: Malformed simple viki name (destination): ".a:def
    " endif
    
    let opts = MvElementAt(a:def, g:vikiDefSep, 2)

    let anchor    = g:vikiDefNil
    let useSuffix = g:vikiDefSep
    
    if cmd == "input"
        let dest = VikiLatexCheckFilename(file, "", ".tex", ".sty")
    elseif cmd == "usepackage"
        let dest = VikiLatexCheckFilename(file, ".sty")
    elseif cmd == "include"
        let dest = VikiLatexCheckFilename(file, ".tex")
    elseif cmd == "viki"
        let dest = VikiLatexCheckFilename(file, ".tex")
        let anchor = opts
    elseif cmd == "psfig"
        let f == matchstr(file, "figure=\zs.\{-}\ze[,}]")
        let dest = VikiLatexCheckFilename(file, "")
    elseif cmd == "includegraphics"
        let dest = VikiLatexCheckFilename(file, "", 
                    \ ".eps", ".ps", ".pdf", ".png", ".jpeg", ".jpg", ".gif", ".wmf")
    elseif cmd == "bibliography"
        let n = VikiSelect(file, ",", "Select Bibliography")
        if n >= 0
            let f    = MvElementAt(file, ",", n)
            let dest = VikiLatexCheckFilename(f, ".bib")
        else
            let dest = ""
        endif
    elseif cmd == "ref"
        let anchor = file
        let dest   = g:vikiSelfRef
    elseif exists("*VikiLaTeX_".cmd)
        exe VikiLaTeX_{cmd}(file, opts)
    else
        throw "Viki LaTeX: unsupported command: ". cmd
    endif
    
    if dest == ""
        throw "Viki LaTeX: can't find: ". name
    else
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

" vim: ff=unix
