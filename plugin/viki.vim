" Viki.vim -- A pseude mini-wiki minor mode for Vim
" @Author:      Thomas Link (samul AT web.de)
" @License:     GPL (see http://www.gnu.org/licenses/gpl.txt)
" @Created:     08-Dec-2003.
" @Last Change: 01-Feb-2004.
" @Revision: 1.0.0
" 
" Short Description:
" This plugin adds wiki-like hypertext capabilities to any document. Just type 
" :VikiMinorMode and all wiki names will be highlighted. If you press <c-cr> 
" when the cursor is over a wiki name, you jump to (or create) the referred 
" page.
"
" Requirements:
" - multvals.vim (vimscript #171)
" 
" TODO:
" - Recheck the key binding
" - Soft/pseudo anchors (e.g. \label{anchor} in LaTeX mode)
" - Different highlighting for existing and non-existing wiki pages
" - define a syntax for "embedded" commands (for citations, references, 
"   user-defined commands etc.)
" - write a latex/html/tbook/docbook/whatever exporter
" - A variable with file patterns (directories) for which viki is turned on by 
"   default (or use something like localvimrc instead).
" - ...
" 
" Change Log:
" 1.0
" - Extended names: For compatibility reasons with other wikis, the anchor is 
"   now in the reference part.
" - For compatibility reasons with other wikis, prepending an anchor with 
"   b:commentStart is optional.
" - g:vikiUseParentSuffix
" - Renamed variables & functions (basically s/Wiki/Viki/g)
" - added a ftplugin stub, moved the description to a help file
" - "[--]" is reference to current file
" - Folding support (at section level)
" - Intervikis
" - More highlighting
" - g:vikiFamily, b:vikiFamily
" - VikiGoBack() (persistent history data)
" - rudimentary LaTeX support ("soft" viki names)

if &cp || exists("s:loaded_viki")
    finish
endif
let s:loaded_viki = 1

let g:vikiDefNil  = '*'
let g:vikiDefSep  = '|'

let s:vikiSelfEsc = '\'
let s:vikiSelfRef = '.'

if !exists("g:vikiLowerCharacters")
    let g:vikiLowerCharacters = "a-zäöüßáàéèíìóòçñ"
endif

if !exists("g:vikiUpperCharacters")
    let g:vikiUpperCharacters = "A-ZÄÖÜ"
endif

if !exists("g:vikiSpecialProtocols")
    let g:vikiSpecialProtocols = "https\\?\\|ftps\\?"
endif

if !exists("g:vikiSpecialProtocolsExceptions")
    let g:vikiSpecialProtocolsExceptions = ""
endif

if !exists("g:vikiSpecialFiles")
    let g:vikiSpecialFiles = 'jpg\|gif\|bmp\|pdf\|dvi\|ps\|eps\|png\|jpeg\|wmf'
endif

if !exists("g:vikiSpecialFilesExceptions")
    let g:vikiSpecialFilesExceptions = ""
endif

if !exists("g:vikiMapMouse")              | let g:vikiMapMouse = 1              | endif
if !exists("g:vikiUseParentSuffix")       | let g:vikiUseParentSuffix = 0       | endif
if !exists("g:vikiAnchorMarker")          | let g:vikiAnchorMarker = "#"        | endif
if !exists("g:vikiMarkupEndsWithNewline") | let g:vikiMarkupEndsWithNewline = 1 | endif
if !exists("g:vikiNameTypes")             | let g:vikiNameTypes = "csSeui"      | endif
if !exists("g:vikiSaveHistory")           | let g:vikiSaveHistory = 0           | endif

if !exists("*VikiOpenSpecialFile")
    if has("win32")
        fun! VikiOpenSpecialFile(filename)
            exe ":!cmd /C start ".a:filename
        endfun
    else
        fun! VikiOpenSpecialFile(filename)
            throw "Viki: Please redefine VikiOpenSpecialFile(filename) first!"
        endfun
    endif
endif

if !exists("*VikiOpenSpecialProtocol")
    if has("win32")
        fun! VikiOpenSpecialProtocol(url)
            exe ":!cmd /C start ".a:url
        endfun
    else
        fun! VikiOpenSpecialProtocol(url)
            throw "Viki: Please redefine VikiOpenSpecialFile(filename) first!"
        endfun
    endif
endif

fun! <SID>AddToRegexp(regexp, pattern)
    if a:pattern == ""
        return a:regexp
    elseif a:regexp == ""
        return a:pattern
    else
        return a:regexp .'\|'. a:pattern
    endif
endfun

fun! <SID>VikiFind(flag)
    let rx = <SID>AddToRegexp("", b:vikiSimpleNameSimpleRx)
    let rx = <SID>AddToRegexp(rx, b:vikiExtendedNameSimpleRx)
    let rx = <SID>AddToRegexp(rx, b:vikiUrlSimpleRx)
    if rx != ""
        call search(rx, a:flag)
    endif
endfun

command! VikiFindNext call <SID>VikiFind("")
command! VikiFindPrev call <SID>VikiFind("b")

fun! VikiSetBufferVar(name, ...)
    if !exists("b:".a:name)
        if a:0 > 0
            let i = 1
            while i <= a:0
                exe "let altVar = a:". i
                if altVar[0] == "*"
                    exe "let b:".a:name." = ". strpart(altVar, 1)
                    return
                elseif exists(altVar)
                    exe "let b:".a:name." = ". altVar
                    return
                endif
                let i = i + 1
            endwh
            throw "VikiSetBuffer: Couldn't set ". a:name
        else
            exe "let b:".a:name." = g:".a:name
        endif
    endif
endfun

fun! VikiDispatchOnFamily(fn, ...)
    let i = 1
    if exists("b:vikiFamily")
        let fam = b:vikiFamily
    elseif exists("g:vikiFamily")
        let fam = g:vikiFamily
    else
        let fam = ""
    endif
    if fam == "" || !exists("*".a:fn.fam)
        let cmd = a:fn
    else
        let cmd = a:fn.fam
    endif
    
    let args = ""
    while i <= a:0
        exe "let val = 'a:".i."'"
        if i == 1
            let args = args . val
        else
            let args = args . ", " val
        endif
        let i = i + 1
    endwh
    exe "return ". cmd . "(" . args . ")"
endfun

fun! VikiSetupBuffer(state, ...)
    " let noMatch = '\%0l' "match nothing
    let noMatch = ""
    let dontSetup = a:0 > 0 ? a:1 : ""
    
    call VikiSetBufferVar("vikiAnchorMarker")
    call VikiSetBufferVar("vikiMarkupEndsWithNewline")
    if a:state =~ '1$'
        call VikiSetBufferVar("vikiCommentStart", 
                    \ "b:commentStart", "b:ECcommentOpen", "b:EnhCommentifyCommentOpen",
                    \ "*matchstr(&commentstring, '^\\zs.*\\ze%s')")
        call VikiSetBufferVar("vikiCommentEnd",
                    \ "b:commentEnd", "b:ECcommentClose", "b:EnhCommentifyCommentClose", 
                    \ "*matchstr(&commentstring, '%s\\zs.*\\ze$')")
    endif
    
    let vikiSimpleNameQuoteChars = "[^][:*/&?<>|\\\"]"
    
    let b:vikiSimpleNameQuoteBeg   = "\\[-"
    let b:vikiSimpleNameQuoteEnd   = "-\\]"
    
    if b:vikiNameTypes =~# "s" && !(dontSetup =~# "s")
        let b:vikiSimpleNameRx = "\\C\\(\\(\\<[".g:vikiUpperCharacters."]\\+::\\)\\?\\(". 
                    \ b:vikiSimpleNameQuoteBeg . vikiSimpleNameQuoteChars 
                    \ ."\\{-}". b:vikiSimpleNameQuoteEnd 
                    \ ."\\|\\<[". g:vikiUpperCharacters ."][". g:vikiLowerCharacters ."]\\+\\([".
                    \ g:vikiUpperCharacters."][".g:vikiLowerCharacters."0-9]\\+\\)\\+\\>\\)\\)\\(#\\([".
                    \ g:vikiLowerCharacters."0-9]\\+\\)\\>\\)\\?"
        let b:vikiSimpleNameSimpleRx = "\\C\\(\\(\\<[".g:vikiUpperCharacters."]\\+::\\)\\?". 
                    \ b:vikiSimpleNameQuoteBeg . vikiSimpleNameQuoteChars 
                    \ ."\\{-}". b:vikiSimpleNameQuoteEnd 
                    \ ."\\|\\<[".g:vikiUpperCharacters."][".g:vikiLowerCharacters."]\\+\\([".
                    \ g:vikiUpperCharacters."][".g:vikiLowerCharacters."0-9]\\+\\)\\+\\>\\)\\(#[".
                    \ g:vikiLowerCharacters."_0-9]\\+\\>\\)\\?"
        let b:vikiSimpleNameNameIdx   = 1
        let b:vikiSimpleNameDestIdx   = 0
        let b:vikiSimpleNameAnchorIdx = 6
    else
        let b:vikiSimpleNameRx        = noMatch
        let b:vikiSimpleNameSimpleRx  = noMatch
        let b:vikiSimpleNameNameIdx   = 0
        let b:vikiSimpleNameDestIdx   = 0
        let b:vikiSimpleNameAnchorIdx = 0
    endif
   
    if b:vikiNameTypes =~# "u" && !(dontSetup =~# "u")
        let b:vikiUrlRx = "\\(\\<\\(".g:vikiSpecialProtocols."\\):\\/\\/[A-Za-z0-9.:/%?=&_~-]\\+".
                    \ "\\|mailto:[a-bA-Z.@%0-9]\\+\\)\\(#\\([A-Za-z0-9]\\+\\)\\>\\)\\?"
        let b:vikiUrlSimpleRx = "\\(\\<".g:vikiSpecialProtocols.":\\/\\/[A-Za-z0-9.:/%?=&_~-]\\+".
                    \ "\\|mailto:[a-bA-Z.@%0-9]\\+\\)\\(#[A-Za-z0-9]\\+\\>\\)\\?"
        let b:vikiUrlNameIdx   = 0
        let b:vikiUrlDestIdx   = 1
        let b:vikiUrlAnchorIdx = 4
    else
        let b:vikiUrlRx        = noMatch
        let b:vikiUrlSimpleRx  = noMatch
        let b:vikiUrlNameIdx   = 0
        let b:vikiUrlDestIdx   = 0
        let b:vikiUrlAnchorIdx = 0
    endif
    
    if b:vikiNameTypes =~# "e" && !(dontSetup =~# "e")
        let b:vikiExtendedNameRx = "\\[\\[\\(\\(".g:vikiSpecialProtocols."\\)://[^]]\\+\\|".
                    \ "[^]#]\\+\\)\\(#\\([".g:vikiLowerCharacters."0-9]\\+\\)\\)\\?\\]".
                    \ "\\(\\[\\([^]#]\\+\\)\\]\\)\\?\\]"
        let b:vikiExtendedNameSimpleRx = "\\[\\[\\(".g:vikiSpecialProtocols."://[^]]\\+\\|[^]#]\\+\\)".
                    \ "\\(#[".g:vikiLowerCharacters."0-9]\\+\\)\\?\\]\\(\\[[^]#]\\+\\]\\)\\?\\]"
        let b:vikiExtendedNameNameIdx   = 6
        let b:vikiExtendedNameDestIdx   = 1
        let b:vikiExtendedNameAnchorIdx = 4
    else
        let b:vikiExtendedNameRx        = noMatch
        let b:vikiExtendedNameSimpleRx  = noMatch
        let b:vikiExtendedNameNameIdx   = 0
        let b:vikiExtendedNameDestIdx   = 0
        let b:vikiExtendedNameAnchorIdx = 0
    endif
endfun

fun! VikiDefineMarkup(state)
    if b:vikiNameTypes =~# "s" && b:vikiSimpleNameRx != ""
        exe "syn match vikiLink /" . b:vikiSimpleNameRx . "/"
    endif
    if b:vikiNameTypes =~# "e" && b:vikiExtendedNameRx != ""
        exe "syn match vikiExtendedLink '" . b:vikiExtendedNameRx . "'"
    endif
    if b:vikiNameTypes =~# "u" && b:vikiUrlRx != ""
        exe "syn match vikiURL /" . b:vikiUrlRx . "/"
    endif
endfun

fun! VikiDefineHighlighting(state)
    if version < 508
        command! -nargs=+ VikiHiLink hi link <args>
    else
        command! -nargs=+ VikiHiLink hi def link <args>
    endif
    
    if &background == "light"
        hi vikiHyperLink term=bold,underline cterm=bold,underline gui=bold,underline 
                    \ ctermbg=DarkBlue guifg=DarkBlue
    else
        hi vikiHyperLink term=bold,underline cterm=bold,underline gui=bold,underline
                    \ ctermbg=LightBlue guifg=LightBlue
    endif
    
    if b:vikiNameTypes =~# "s"
        VikiHiLink vikiLink vikiHyperLink
    endif
    if b:vikiNameTypes =~# "e"
        VikiHiLink vikiExtendedLink vikiHyperLink
    endif
    if b:vikiNameTypes =~# "u"
        VikiHiLink vikiURL vikiHyperLink
    endif
    delcommand VikiHiLink
endfun

"state ... 0,  +/-1, +/-2
fun! VikiMinorMode(state)
    if exists("b:VikiEnabled")
        if a:state == 0
            throw "Viki can't be disabled (not yet)."
        else
            return 0
        endif
    elseif a:state
        " c ... CamelCase 
        " s ... Simple viki name 
        " S ... Simple quoted viki name
        " e ... Extended viki name
        " u ... URL
        " i ... InterViki
        " call VikiSetBufferVar("vikiNameTypes", "g:vikiNameTypes", "*'csSeui'")
        call VikiSetBufferVar("vikiNameTypes")

        call VikiDispatchOnFamily("VikiSetupBuffer", a:state)
        call VikiDispatchOnFamily("VikiDefineMarkup", a:state)
        call VikiDispatchOnFamily("VikiDefineHighlighting", a:state)
 
        if !hasmapto("VikiMaybeFollowLink")
            "nnoremap <buffer> <c-cr> "=VikiMaybeFollowLink("",1)<cr>p
            "inoremap <buffer> <c-cr> <c-r>=VikiMaybeFollowLink("",1)<cr>
            "nmap <buffer> <c-cr> "=VikiMaybeFollowLink(1,1)<cr>p
            "imap <buffer> <c-cr> <c-r>=VikiMaybeFollowLink(1,1)<cr>
            "exe "nnoremap <buffer> <c-cr> \"=VikiMaybeFollowLink(\"".maparg("<c-cr>")."\",1)<cr>p"
            "exe "inoremap <buffer> <c-cr> <c-r>=VikiMaybeFollowLink(\"".maparg("<c-cr>", "i")."\",1)<cr>"
            "nnoremap <buffer> <c-cr> "=VikiMaybeFollowLink(0)<cr>p
            "inoremap <buffer> <c-cr> <c-r>=VikiMaybeFollowLink(0)<cr>
            nnoremap <buffer> <silent> <c-cr> :call VikiMaybeFollowLink(0,1)<cr>
            inoremap <buffer> <silent> <c-cr> <c-o>:call VikiMaybeFollowLink(0,1)<cr>
            if g:vikiMapMouse
                nnoremap <buffer> <silent> <m-leftmouse> <leftmouse>:call VikiMaybeFollowLink(0,1)<cr>
                inoremap <buffer> <silent> <m-leftmouse> <leftmouse><c-o>:call VikiMaybeFollowLink(0,1)<cr>
            endif
            "nnoremap <buffer> <s-c-cr> :call VikiMaybeFollowLink(0,1)<cr>
            "inoremap <buffer> <s-c-cr> <c-o><c-cr>
        endif
       
        if !hasmapto("VikiGoBack")
            nnoremap <buffer> <silent> <LocalLeader>vb :call VikiGoBack()<cr>
            if g:vikiMapMouse
                nnoremap <buffer> <silent> <m-rightmouse> <leftmouse>:call VikiGoBack(0)<cr>
                inoremap <buffer> <silent> <m-rightmouse> <leftmouse><c-o>:call VikiGoBack(0)<cr>
            endif
        endif
 
        let b:vikiEnabled = 1
        return 1
    endif
endfun

command! VikiMinorMode call VikiMinorMode(1)
command! VikiMinorModeMaybe call VikiMinorMode(-1)

fun! VikiFoldLevel(lnum)
    let head = matchend(getline(a:lnum), b:vikiHeadingStart)
    if head > 0
        return ">". (head - 1)
    else
        " return foldlevel(a:lnum - 1)
        return "="
    endif
endfun

fun! VikiMode(state)
    if exists("b:VikiEnabled")
        if a:state == 0
            throw "Viki can't be disabled (not yet)."
        else
            return 0
        endif
    elseif a:state
        set filetype=viki
    endif
endfun

command! VikiMode call VikiMode(2)
command! VikiModeMaybe call VikiMode(-2)

fun! <SID>AddVarToMultVal(var, val)
    if exists(a:var)
        exe "let i = MvIndexOfElement(". a:var .", '". g:vikiDefSep ."', ". a:val .")"
        exe "let ". a:var ."=MvPushToFront(". a:var .", '". g:vikiDefSep ."', ". a:val .")"
        return i
    else
        exe "let ". a:var ."=MvAddElement('', '". g:vikiDefSep ."', ". a:val .")"
        return -1
    endif
endfun

fun! <SID>VikiSetBackRef(file, li, co)
    let i = <SID>AddVarToMultVal("b:VikiBackFile", "'". a:file ."'")
    if i >= 0
        let b:VikiBackLine = MvPushToFrontElementAt(b:VikiBackLine, g:vikiDefSep, i)
        let b:VikiBackCol  = MvPushToFrontElementAt(b:VikiBackCol,  g:vikiDefSep, i)
    else
        call <SID>AddVarToMultVal("b:VikiBackLine", a:li)
        call <SID>AddVarToMultVal("b:VikiBackCol",  a:co)
    endif
endfun
 
fun! <SID>VikiSelectThisBackRef(n)
    return "let vbf = '". MvElementAt(b:VikiBackFile, g:vikiDefSep, a:n) ."'".
                \ " | let vbl = ". MvElementAt(b:VikiBackLine, g:vikiDefSep, a:n) .
                \ " | let vbc = ". MvElementAt(b:VikiBackCol, g:vikiDefSep, a:n)
endfun

fun! <SID>VikiSelectBackRef(...)
    if exists("b:VikiBackFile") && exists("b:VikiBackLine") && exists("b:VikiBackCol")
        let n = MvNumberOfElements(b:VikiBackFile, g:vikiDefSep)
        if n > 0
            let s = (a:0 >= 1) ? a:1 : -1
            if s >= 0 && s < n
                return <SID>VikiSelectThisBackRef(s)
            elseif n == 1
                return <SID>VikiSelectThisBackRef(0)
            else
                let i  = 0
                let nn = 0
                while i <= n
                    let f = MvElementAt(b:VikiBackFile, g:vikiDefSep, i)
                    if f != ""
                        if i == 0
                            echomsg i ."* ". f
                        else
                            echomsg i ."  ". f
                        endif
                        let nn = i
                    endif
                    let i = i + 1
                endwh
                if nn == 0
                    let this = 0
                else
                    let this = input("Select Back Reference [0-".nn."]: ", "0")
                endif
                if  this >= 0 && this <= nn
                    return <SID>VikiSelectThisBackRef(this)
                endif
            endif
        endif
    endif
    return ""
endfun

if g:vikiSaveHistory && exists("*GetPersistentVar") && exists("*PutPersistentVar")
    fun! VikiGetSimplifiedBufferName()
        return substitute( expand("%:p"), "[^a-zA-Z0-9]", "_", "g")
    endfun
    
    fun! VikiSaveBackReferences()
        if exists("b:VikiBackFile") && b:VikiBackFile != ""
            call PutPersistentVar("VikiBackFile", VikiGetSimplifiedBufferName(), b:VikiBackFile)
            call PutPersistentVar("VikiBackLine", VikiGetSimplifiedBufferName(), b:VikiBackLine)
            call PutPersistentVar("VikiBackCol",  VikiGetSimplifiedBufferName(), b:VikiBackCol)
        endif
    endfun
    
    fun! VikiRestoreBackReferences()
        if exists("b:VikiEnabled") && !exists("b:VikiBackFile")
            let b:VikiBackFile = GetPersistentVar("VikiBackFile", VikiGetSimplifiedBufferName(), "")
            let b:VikiBackLine = GetPersistentVar("VikiBackLine", VikiGetSimplifiedBufferName(), "")
            let b:VikiBackCol  = GetPersistentVar("VikiBackCol",  VikiGetSimplifiedBufferName(), "")
        endif
    endfun

    au BufEnter * call VikiRestoreBackReferences()
    au BufLeave * call VikiSaveBackReferences()
endif

fun! VikiGoBack(...)
    let s  = (a:0 >= 1) ? a:1 : -1
    let br = <SID>VikiSelectBackRef(s)
    if br == ""
        echomsg "Viki: No back reference defined?"
    else
        exe br
        let buf = bufnr("^". vbf ."$")
        if buf >= 0
            exe "buffer ".buf
        else
            exe "edit " . vbf
        endif
        if vbf == expand("%:p")
            call cursor(vbl, vbc)
        else
            throw "Viki: Couldn't open file: ". b:VikiBackFile
        endif
    endif
endfun

fun! VikiFindAnchor(anchor)
    if a:anchor != g:vikiDefNil
        call search("\\V\\^". b:vikiCommentStart ."\\?". b:vikiAnchorMarker . a:anchor, "w")
    endif
endfun

fun! <SID>VikiOpenLink(filename, anchor, ...)
    if a:0 >= 1
        let create = a:1
    else
        let create = 0
    endif

    let li = line(".")
    let co = col(".")
    let fi = expand("%:p")
    
    " let buf = bufnr("^". simplify(a:filename) ."$")
    let buf = bufnr(a:filename)
    if buf >= 0
        exe "buffer ".buf
        call <SID>VikiSetBackRef(fi, li, co)
        call VikiDispatchOnFamily("VikiMinorMode", -1)
        call VikiDispatchOnFamily("VikiFindAnchor", a:anchor)
    elseif create && exists("b:createVikiPage")
        exe b:createVikiPage . " " . a:filename
    elseif exists("b:editVikiPage")
        exe b:editVikiPage . " " . a:filename
    else
        exe "edit " . a:filename
        call <SID>VikiSetBackRef(fi, li, co)
        call VikiDispatchOnFamily("VikiMinorMode", -1)
        call VikiDispatchOnFamily("VikiFindAnchor", a:anchor)
    endif
endfun

fun! <SID>VikiFollowLink(def)
    let name   = MvElementAt(a:def, g:vikiDefSep, 0)
    let dest   = MvElementAt(a:def, g:vikiDefSep, 1)
    let anchor = MvElementAt(a:def, g:vikiDefSep, 2)
    if name == s:vikiSelfRef              "reference to self
        call VikiDispatchOnFamily("VikiFindAnchor", anchor)
    elseif dest == g:vikiDefNil
		throw "No target? ".a:def
    else
        if exists("b:vikiSpecialProtocols")
            let vikiSpecialProtocols = b:vikiSpecialProtocols."\\|".g:vikiSpecialProtocols
        else
            let vikiSpecialProtocols = g:vikiSpecialProtocols
        endif
        if dest =~ "^\\(".vikiSpecialProtocols."\\):" &&
                    \ (g:vikiSpecialProtocolsExceptions == "" ||
                    \ !(dest =~ g:vikiSpecialProtocolsExceptions))
            call VikiOpenSpecialProtocol(dest)
        else
            if exists("b:vikiSpecialFiles")
                let vikiSpecialFiles = b:vikiSpecialFiles .'\|'. g:vikiSpecialFiles
            else
                let vikiSpecialFiles = g:vikiSpecialFiles
            endif
            if dest =~ '\.\('. vikiSpecialFiles .'\)$' &&
                        \ (g:vikiSpecialFilesExceptions == "" ||
                        \ !(dest =~ g:vikiSpecialFilesExceptions))
                call VikiOpenSpecialFile(dest)
            elseif filereadable(dest)                 "reference to a local, already existing file
                call <SID>VikiOpenLink(dest, anchor)
            elseif input("File doesn't exists. Create '".dest."'? (Y/n) ") != "n"
                call <SID>VikiOpenLink(dest, anchor, 1)
            endif
        endif
    endif
    return ""
endfun

fun! <SID>MakeVikiDefPart(txt)
    if a:txt == ""
        return g:vikiDefNil
    else
        return a:txt
    endif
endfun

fun! VikiMakeDef(name, dest, anchor)
    if a:name =~ g:vikiDefSep || a:dest =~ g:vikiDefSep || a:anchor =~ g:vikiDefSep
        throw "Viki: A viki definition must not include ".g:vikiDefSep
    else
        let arr = MvAddElement("",  g:vikiDefSep, <SID>MakeVikiDefPart(a:name))
        let arr = MvAddElement(arr, g:vikiDefSep, <SID>MakeVikiDefPart(a:dest))
        let arr = MvAddElement(arr, g:vikiDefSep, <SID>MakeVikiDefPart(a:anchor))
        return arr
    endif
endfun

fun! <SID>GetVikiNamePart(txt, erx, idx, errorMsg)
    if a:idx
        let rv = substitute(a:txt, "^\\C".a:erx."$", "\\".a:idx, "")
        if rv == ""
            return g:vikiDefNil
        else
            return rv
        endif
    else
        return g:vikiDefNil
    endif
endfun

fun! <SID>GetVikiLink(erx, nameIdx, destIdx, anchorIdx, ignoreSyntax)
    if a:erx != ""
        let ebeg = -1
        let col  = col(".") - 1
        let txt  = getline(".")
        let cont = match(txt, a:erx, 0)
        while (0 <= cont) && (cont <= col)
            let contn = matchend(txt, a:erx, cont)
            if (cont <= col) && (col < contn)
                let ebeg = match(txt, a:erx, cont)
                let elen = contn - ebeg
                break
            else
                let cont = match(txt, a:erx, contn)
            endif
        endwh
        if ebeg >= 0
            let part   = strpart(txt, ebeg, elen)
            let name   = <SID>GetVikiNamePart(part, a:erx, a:nameIdx,   "no name")
            let dest   = <SID>GetVikiNamePart(part, a:erx, a:destIdx,   "no destination")
            let anchor = <SID>GetVikiNamePart(part, a:erx, a:anchorIdx, "no anchor")
            return VikiMakeDef(name, dest, anchor)
        elseif a:ignoreSyntax
            return ""
        else
            throw "Viki: Malformed viki name: " . txt . " (". a:erx .")"
        endif
    else
        return ""
    endif
endfun

fun! VikiExpandSimpleName(dest, name, suffix)
    if exists("b:vikiNameSuffix") && a:suffix == "*|*"
        let dest = a:dest ."/". a:name.b:vikiNameSuffix
    elseif g:vikiUseParentSuffix && a:suffix == "*|*"
        let sfx = expand("%:e")
        if sfx == ""
            let dest = a:dest ."/". a:name
        else
            let dest = a:dest ."/". a:name ."." . sfx
        endif
    else
        let dest = a:dest ."/". a:name . a:suffix
    endif
    return dest
endfun

fun! VikiCompleteSimpleNameDef(def)
    let name   = MvElementAt(a:def, g:vikiDefSep, 0)
    if name == g:vikiDefNil
        throw "Viki: Malformed simple viki name (no name): ".a:def
    endif

    let dest   = MvElementAt(a:def, g:vikiDefSep, 1)
    if !(dest == g:vikiDefNil)
        throw "Viki: Malformed simple viki name (destination): ".a:def
    endif
    
    let useSuffix = "*|*"
    let otherwikiRx = "^\\([". g:vikiUpperCharacters ."]\\+\\)::\\(.\\+\\)$"
    if b:vikiNameTypes =~# "i" && name =~# otherwikiRx
        let ow = substitute(name, otherwikiRx, "\\1", "")
        if exists("g:vikiInter".ow)
            let dest      = g:vikiInter{ow}
            let name      = substitute(name, otherwikiRx, "\\2", "")
            if exists("g:vikiInter".ow."_suffix")
                let useSuffix = g:vikiInter{ow}_suffix
            endif
        else
            throw "Viki: InterViki is not defined: ".ow
        endif
    else
        let dest = expand("%:p:h")
    endif

    if b:vikiNameTypes =~# "S"
        if name =~ "^". b:vikiSimpleNameQuoteBeg . b:vikiSimpleNameQuoteEnd ."$"
            let name  = s:vikiSelfRef
        elseif name =~ "^". b:vikiSimpleNameQuoteBeg .".\\+". b:vikiSimpleNameQuoteEnd ."$"
            let name = matchstr(name, "^". b:vikiSimpleNameQuoteBeg ."\\zs.\\+\\ze". b:vikiSimpleNameQuoteEnd ."$")
        endif
    elseif !(b:vikiNameTypes =~# "c")
        throw "Viki: CamelCase names not allowed"
    endif
    
    if name != s:vikiSelfRef
        let rdest = VikiExpandSimpleName(dest, name, useSuffix)
    else
        let rdest = g:vikiDefNil
    endif
    let anchor = MvElementAt(a:def, g:vikiDefSep, 2)
    return VikiMakeDef(name, rdest, anchor)
endfun

fun! VikiCompleteExtendedNameDef(def)
    let name   = MvElementAt(a:def, g:vikiDefSep, 0)
    let dest   = MvElementAt(a:def, g:vikiDefSep, 1)
    let anchor = MvElementAt(a:def, g:vikiDefSep, 2)
    if dest == g:vikiDefNil
        throw "Viki: Malformed extended viki name (no destination): ".a:def
    elseif dest =~? "^[a-z]:"                 " an absolute dos path
    elseif dest =~? "^\/"                     " an absolute unix path
    elseif dest =~? "^[a-z]\\+://"            " some protocol
    elseif dest =~ "^\\~"                     " user home
        let dest = $HOME . strpart(dest, 1)
    else                                      " a relative path
        let dest = expand("%:p:h")."/".dest
    endif
    if name == g:vikiDefNil
        let name = dest
    endif
    return VikiMakeDef(name, dest, anchor)
endfun

fun! <SID>VikiLinkNotFoundEtc(oldmap, ignoreSyntax)
    if a:oldmap == ""
        echomsg "Viki: Show me the way to the next viki name or I have to ... ".a:ignoreSyntax.":".getline(".")
    elseif a:oldmap == 1
        return "\<c-cr>"
    else
        return a:oldmap
    endif
endfun

" oldmap: If there isn't a viki link under the cursor:
" 	""       ... throw error 
" 	1        ... return \<c-cr>
" 	whatever ... return whatever
" ignoreSyntax: If there isn't a viki syntax group under the cursor:
"   0 ... no viki name found
"   1 ... try to find a viki name matching a the viki regexp
fun! VikiMaybeFollowLink(oldmap, ignoreSyntax)
    let synName = synIDattr(synID(line('.'),col('.'),0),"name")
    if synName ==# "vikiLink"
        let vikiType = 1
        let tryNext = 0
    elseif synName ==# "vikiExtendedLink"
        let vikiType = 2
        let tryNext  = 0
    elseif synName ==# "vikiURL"
        let vikiType = 3
        let tryNext  = 0
    else
        let vikiType = a:ignoreSyntax
        let tryNext  = 1
    endif
    while vikiType <= 3
        if vikiType == 1 && b:vikiNameTypes =~? "s"
            if exists("b:getVikiLink")
                exe "let def = " . b:getVikiLink."()"
            else
                let def=<SID>GetVikiLink(b:vikiSimpleNameRx, b:vikiSimpleNameNameIdx, 
                            \ b:vikiSimpleNameDestIdx, b:vikiSimpleNameAnchorIdx, a:ignoreSyntax)
            endif
            if def != ""
                return <SID>VikiFollowLink( VikiDispatchOnFamily("VikiCompleteSimpleNameDef", def) )
            endif
        elseif vikiType == 2 && b:vikiNameTypes =~# "e"
            if exists("b:getExtVikiLink")
                exe "let def = " . b:getExtVikiLink."()"
            else
                let def=<SID>GetVikiLink(b:vikiExtendedNameRx, b:vikiExtendedNameNameIdx, 
                            \ b:vikiExtendedNameDestIdx, b:vikiExtendedNameAnchorIdx, a:ignoreSyntax)
            endif
            if def != ""
                return <SID>VikiFollowLink( VikiDispatchOnFamily("VikiCompleteExtendedNameDef", def) )
            endif
        elseif vikiType == 3 && b:vikiNameTypes =~# "u"
            if exists("b:getURLViki")
                exe "let def = " . b:getURLViki . "()"
            else
                let def=<SID>GetVikiLink(b:vikiUrlRx, b:vikiUrlNameIdx, 
                            \ b:vikiUrlDestIdx, b:vikiUrlAnchorIdx, a:ignoreSyntax)
            endif
            if def != ""
                return <SID>VikiFollowLink( VikiDispatchOnFamily("VikiCompleteExtendedNameDef", def) )
            endif
        endif
        if tryNext && vikiType > 0 && vikiType < 3
            let vikiType = vikiType + 1
        endif
    endwh
    call <SID>VikiLinkNotFoundEtc(a:oldmap, vikiType)
endfun

