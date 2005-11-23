" Viki.vim -- A pseudo mini-wiki minor mode for Vim
" @Author:      Thomas Link (samul AT web.de)
" @License:     GPL (see http://www.gnu.org/licenses/gpl.txt)
" @Created:     08-Dec-2003.
" @Last Change: 20-Nov-2005.
" @Revision: 1.8.437
"
" vimscript #861
"
" Short Description:
" This plugin adds wiki-like hypertext capabilities to any document. Just type 
" :VikiMinorMode and all wiki names will be highlighted. If you press <c-cr> 
" when the cursor is over a wiki name, you jump to (or create) the referred 
" page. When invoked as :VikiMode or via :set ft=viki additional highlighting 
" is provided.
"
" Requirements:
" - multvals.vim (vimscript #171, >= 3.6.2, 13-Sep-2004)
" 
" Optional Enhancements:
" - genutils.vim (vimscript #197 for saving back references)
" - imaps.vim (vimscript #244 or #475 for |:VimQuote|)
" - kpsewhich (not a vim plugin :-) for vikiLaTeX
"
" TODO:
" - PIM or planner mode features (or rather make it an extra plugin)
"   - Special plan:// or rather pim:// urls
" - VikiRename: rename links/files
" - don't know how to deal with viki names that span several lines (e.g. 
"   in LaTeX mode)
"   
" Change Log: (See bottom of file)
" 

if &cp || exists("loaded_viki") "{{{2
    finish
endif
if !exists('loaded_multvals')
    runtime plugin/multvals.vim
endif
if !exists("loaded_multvals") || loaded_multvals < 308
    echoerr "Viki.vim requires multvals.vim >= 308"
    finish
endif
let loaded_viki = 108

let g:vikiDefNil  = ''
let g:vikiDefSep  = "\n"

let s:vikiSelfEsc = '\'
let g:vikiSelfRef = '.'

let g:vikiEnabled = 1

if !exists("tlist_viki_settings") "{{{2
    let tlist_viki_settings="deplate;s:structure"
endif

if !exists("g:vikiLowerCharacters") "{{{2
    let g:vikiLowerCharacters = "a-z"
endif

if !exists("g:vikiUpperCharacters") "{{{2
    let g:vikiUpperCharacters = "A-Z"
endif

if !exists("g:vikiSpecialProtocols") "{{{2
    let g:vikiSpecialProtocols = 'https\?\|ftps\?\|nntp\|mailto\|mailbox\|file'
endif

if !exists("g:vikiSpecialProtocolsExceptions") "{{{2
    let g:vikiSpecialProtocolsExceptions = ""
endif

if !exists("g:vikiSpecialFiles") "{{{2
    " try to put image suffixes first
    let g:vikiSpecialFiles = 'jpg\|gif\|bmp\|eps\|png\|jpeg\|wmf\|pdf\|ps\|dvi\|doc\|xls\|html'
endif

if !exists("g:vikiSpecialFilesExceptions") "{{{2
    let g:vikiSpecialFilesExceptions = ""
endif

if !exists("g:vikiHyperLinkColor")
    if &background == "light"
        let g:vikiHyperLinkColor = "DarkBlue"
    else
        let g:vikiHyperLinkColor = "LightBlue"
    endif
endif

if !exists("g:vikiInexistentColor")
    if &background == "light"
        let g:vikiInexistentColor = "DarkRed"
    else
        let g:vikiInexistentColor = "Red"
    endif
endif

if !exists("g:vikiMapMouse")         | let g:vikiMapMouse = 1           | endif "{{{2
if !exists("g:vikiUseParentSuffix")  | let g:vikiUseParentSuffix = 0    | endif "{{{2
if !exists("g:vikiNameSuffix")       | let g:vikiNameSuffix = ""        | endif "{{{2
if !exists("g:vikiAnchorMarker")     | let g:vikiAnchorMarker = "#"     | endif "{{{2
if !exists("g:vikiFreeMarker")       | let g:vikiFreeMarker = 0         | endif "{{{2
if !exists("g:vikiNameTypes")        | let g:vikiNameTypes = "csSeuix"  | endif "{{{2
if !exists("g:vikiSaveHistory")      | let g:vikiSaveHistory = 0        | endif "{{{2
if !exists("g:vikiExplorer")         | let g:vikiExplorer = "Sexplore"  | endif "{{{2
if !exists("g:vikiMarkInexistent")   | let g:vikiMarkInexistent = 1     | endif "{{{2
if !exists("g:vikiMapInexistent")    | let g:vikiMapInexistent = 1      | endif "{{{2
if !exists("g:vikiMapKeys")          | let g:vikiMapKeys = ").,;:!?\"'" | endif "{{{2
if !exists("g:vikiFamily")           | let g:vikiFamily = ""            | endif "{{{2
if !exists("g:vikiDirSeparator")     | let g:vikiDirSeparator = "/"     | endif "{{{2
if !exists("g:vikiTextstylesVer")    | let g:vikiTextstylesVer = 2      | endif "{{{2
if !exists("g:vikiBasicSyntax")      | let g:vikiBasicSyntax = 0        | endif "{{{2
if !exists("g:vikiFancyHeadings")    | let g:vikiFancyHeadings = 0      | endif "{{{2
if !exists("g:vikiHomePage")         | let g:vikiHomePage = ''          | endif "{{{2
if !exists("g:vikiHide")             | let g:vikiHide = ''              | endif "{{{2
if !exists("g:vikiFolds")            | let g:vikiFolds = 'hl'           | endif "{{{2

if !exists("g:vikiMapFunctionality") "{{{2
    " f ... follow link
    " i ... check for inexistant
    " q ... quote
    " b ... go back
    " e ... edit
    let g:vikiMapFunctionality = "fiqbFe"
endif

if !exists("g:vikiOpenFileWith_ANY") "{{{2
    if has("win32")
        let g:vikiOpenFileWith_ANY = "exec 'silent !cmd /c start '. escape('%{FILE}', ' &!%')"
    elseif $GNOME_DESKTOP_SESSION_ID != ""
        let g:vikiOpenFileWith_ANY = "exec 'silent !gnome-open '. escape('%{FILE}', ' &!%')"
    elseif $KDEDIR != ""
        let g:vikiOpenFileWith_ANY = "exec 'silent !kfmclient exec '. escape('%{FILE}', ' &!%')"
    endif
endif

if !exists("*VikiOpenSpecialFile") "{{{2
    fun! VikiOpenSpecialFile(file) "{{{3
        let proto = tolower(matchstr(a:file, '\c\.\zs[a-z]\+$'))
        if exists("g:vikiOpenFileWith_". proto)
            let prot = g:vikiOpenFileWith_{proto}
        elseif exists('g:vikiOpenFileWith_ANY')
            let prot = g:vikiOpenFileWith_ANY
        else
            let prot = ''
        endif
        if prot != ''
            let openFile = VikiSubstituteArgs(prot, "FILE", a:file)
            exec openFile
        else
            throw "Viki: Please define g:vikiOpenFileWith_". proto ." or g:vikiOpenFileWith_ANY!"
        endif
    endf
endif

if !exists("g:vikiOpenUrlWith_mailbox") "{{{2
    let g:vikiOpenUrlWith_mailbox="call VikiOpenMailbox('%{URL}')"
    fun! VikiOpenMailbox(url) "{{{3
        exec VikiDecomposeUrl(strpart(a:url, 10))
        let idx = matchstr(args, 'number=\zs\d\+$')
        if filereadable(filename)
            call VikiOpenLink(filename, "", 0, "go ".idx)
        else
            throw "Viki: Can't find mailbox url: ".filename
        endif
    endf
endif

" Possible values: special*, query, normal
if !exists("g:vikiUrlFileAs") | let g:vikiUrlFileAs = 'special' | endif "{{{2

if !exists("g:vikiOpenUrlWith_file") "{{{2
    let g:vikiOpenUrlWith_file="call VikiOpenFileUrl('%{URL}')"
    fun! VikiOpenFileUrl(url) "{{{3
        if VikiIsSpecialFile(a:url)
            if g:vikiUrlFileAs == 'special'
                let as_special = 1
            elseif g:vikiUrlFileAs == 'query'
                echo a:url
                let as_special = input('Treat URL as special file? (Y/n) ')
                let as_special = (as_special[0] !=? 'n')
            else
                let as_special = 0
            endif
            if as_special
                call VikiOpenSpecialFile(a:url)
                return
            endif
        endif
        exec VikiDecomposeUrl(strpart(a:url, 7))
        if filereadable(filename)
            call VikiOpenLink(filename, anchor)
        else
            throw "Viki: Can't find file url: ".filename
        endif
    endf
endif

if !exists("g:vikiOpenUrlWith_ANY") "{{{2
    if has("win32")
        let g:vikiOpenUrlWith_ANY = "exec 'silent !rundll32 url.dll,FileProtocolHandler '. escape('%{URL}', ' !&%')"
    elseif $GNOME_DESKTOP_SESSION_ID != ""
        let g:vikiOpenUrlWith_ANY = "exec 'silent !gnome-open '. escape('%{URL}', ' !&%')"
    elseif $KDEDIR != ""
        let g:vikiOpenUrlWith_ANY = "exec 'silent !kfmclient exec '. escape('%{URL}', ' !&%')"
    endif
endif

if !exists("*VikiOpenSpecialProtocol") "{{{2
    fun! VikiOpenSpecialProtocol(url) "{{{3
        let proto = tolower(matchstr(a:url, '\c^[a-z]\{-}\ze:'))
        let prot  = "g:vikiOpenUrlWith_". proto
        let protp = exists(prot)
        if !protp
            let prot  = "g:vikiOpenUrlWith_ANY"
            let protp = exists(prot)
        endif
        if protp
            exec "let openURL = ". prot
            let openURL = VikiSubstituteArgs(openURL, "URL", a:url)
            exec openURL
        else
            throw "Viki: Please define g:vikiOpenUrlWith_". proto ." or g:vikiOpenUrlWith_ANY!"
        endif
    endf
endif

let s:InterVikiRx = '^\(['. g:vikiUpperCharacters .']\+\)::\(.\+\)$'
let s:InterVikis  = ''

" VikiDefine(name, prefix, ?suffix=g:vikiNameSuffix)
fun! VikiDefine(name, prefix, ...)
    let s:InterVikis = s:InterVikis . a:name ."::\n"
    let g:vikiInter{a:name}          = a:prefix
    let g:vikiInter{a:name}_suffix   = a:0 >= 1 ? a:1 : g:vikiNameSuffix
endf

command! -nargs=+ VikiDefine call VikiDefine(<f-args>)

fun! <SID>AddToRegexp(regexp, pattern) "{{{3
    if a:pattern == ""
        return a:regexp
    elseif a:regexp == ""
        return a:pattern
    else
        return a:regexp .'\|'. a:pattern
    endif
endf

fun! <SID>CanonicFilename(fname)
    return substitute(a:fname, '[\/]\+', '/', 'g')
endf

fun! <SID>VikiFindRx() "{{{3
    let rx = <SID>AddToRegexp("", b:vikiSimpleNameSimpleRx)
    let rx = <SID>AddToRegexp(rx, b:vikiExtendedNameSimpleRx)
    let rx = <SID>AddToRegexp(rx, b:vikiUrlSimpleRx)
    return rx
endf

fun! <SID>EditWrapper(cmd, fname) "{{{3
    if g:vikiHide == 'hide'
        exec 'hide '. a:cmd .' '. a:fname
    elseif g:vikiHide == 'update'
        update
        exec a:cmd .' '. a:fname
    else
        try
            exec a:cmd .' '. a:fname
        catch /^Vim\%((\a\+)\)\=:E37/
            echoerr 'Vim raised E37: You tried to abondon a dirty buffer (see :h E37)'
            echoerr 'Viki: You may want to reconsider your g:vikiHide or 'hidden' settings'
        endtry
    endif
endf

fun! VikiFind(flag) "{{{3
    let rx = <SID>VikiFindRx()
    if rx != ""
        call search(rx, a:flag)
    endif
endf

command! VikiFindNext call VikiDispatchOnFamily('VikiFind', '')
command! VikiFindPrev call VikiDispatchOnFamily('VikiFind', 'b')

" <SID>IsSupportedType(type, ?types=b:vikiNameTypes)
fun! <SID>IsSupportedType(type, ...)
    let types = a:0 >= 1 ? a:1 : b:vikiNameTypes
    if types == ''
        return 1
    else
        " return stridx(b:vikiNameTypes, a:type) >= 0
        return b:vikiNameTypes =~# '['. a:type .']'
    endif
endf

fun! <SID>VikiRxFromCollection(coll)
    " let rx = strpart(a:coll, 0, strlen(a:coll) - 1)
    " let rx = substitute(rx, "\n", '\\|', "g")
    let rx = substitute(a:coll, '\\|$', '', '')
    if rx == ''
        return ''
    else
        return '\V\('. rx .'\)'
    endif
endf

" VikiMarkInexistent(line1, line2, maxcol, quick)
" maxcol ... check only up to maxcol
" quick  ... check only if the cursor is located after a link
fun! <SID>VikiMarkInexistent(line1, line2, ...)
    if !b:vikiMarkInexistent
        return
    endif
    let li0 = line('.')
    let co0 = virtcol('.')
    let li  = li0
    let co  = col('.')
    if a:0 >= 2 && a:2 && !(synIDattr(synID(li, co - 1, 1), 'name') =~ '^viki.*Link$')
        return
    endif

    let maxcol = a:0 >= 1 ? (a:1 == -1 ? 9999999 : a:1) : 9999999
    
    if a:line1 > 0
        exe 'norm! '. a:line1 .'G'
        let min = a:line1
    else
        go
        let min = 1
    endif
    let max = a:line2 > 0 ? a:line2 : line('$')

    if line('.') == 1 && line('$') == max
        let b:vikiNamesNull = ''
        let b:vikiNamesOk   = ''
    else
        if !exists('b:vikiNamesNull') | let b:vikiNamesNull = '' | endif
        if !exists('b:vikiNamesOk')   | let b:vikiNamesOk   = '' | endif
    endif

    try
        let feedback = (max - min) > 5
        if feedback
            let sl  = &statusline
            let rng = min .'-'. max
            let &statusline='Viki: checking line '. rng
            let rng = ' ('. min .'-'. max .')'
            redrawstatus
        endif

        if line('.') == 1
            norm! G$
        else
            norm! k$
        endif

        let rx = <SID>VikiFindRx()
        let pp = 0
        let ll = 0
        let li  = search(rx, 'w')
        while ll != li && li >= min && li <= max && col('.') < maxcol
            if feedback
                " if li % 10 == 0 && li != ll
                if li % 10 == 0
                    let &statusline='Viki: checking line '. line('.') . rng
                    redrawstatus
                    " let ll = li
                endif
            endif
            let ll  = li
            let def = VikiGetLink('-', 1)
            if def == '-'
                echom 'Internal error: VikiMarkInexistent: '. def
            else
                let dest = MvElementAt(def, g:vikiDefSep, 1)
                let part = MvElementAt(def, g:vikiDefSep, 3)
                if part =~ '^'. b:vikiSimpleNameSimpleRx .'$'
                    let check = 1
                    if part =~ '^\[-.\{}-\]$'
                        let partx = escape(part, "'\"\\/")
                    else
                        let partx = '\<'. escape(part, "'\"\\/") .'\>'
                    endif
                elseif dest =~ '^'. b:vikiUrlSimpleRx .'$'
                    let check = 0
                    let partx = escape(part, "'\"\\/")
                    let b:vikiNamesNull = MvRemoveElementAll(b:vikiNamesNull, '\\|', partx, '\|')
                    let b:vikiNamesOk   = MvPushToFront(b:vikiNamesOk, '\\|', partx, '\|')
                elseif part =~ b:vikiExtendedNameSimpleRx
                    let check = 1
                    let partx = escape(part, "'\"\\/")
                    " elseif part =~ b:vikiCmdSimpleRx
                    " <+TBD+>
                else
                    let check = 0
                endif
                if check && dest != "" && dest != g:vikiSelfRef && !isdirectory(dest)
                    if filereadable(dest)
                        " let b:vikiNamesNull = MvRemoveElementAll(b:vikiNamesNull, "\n", partx)
                        " let b:vikiNamesOk   = MvPushToFront(b:vikiNamesOk, "\n", partx)
                        let b:vikiNamesNull = MvRemoveElementAll(b:vikiNamesNull, '\\|', partx, '\|')
                        let b:vikiNamesOk   = MvPushToFront(b:vikiNamesOk, '\\|', partx, '\|')
                    else
                        " let b:vikiNamesNull = MvPushToFront(b:vikiNamesNull, "\n", partx)
                        " let b:vikiNamesOk   = MvRemoveElementAll(b:vikiNamesOk, "\n", partx)
                        let b:vikiNamesNull = MvPushToFront(b:vikiNamesNull, '\\|', partx, '\|')
                        let b:vikiNamesOk   = MvRemoveElementAll(b:vikiNamesOk, '\\|', partx, '\|')
                    endif
                endif
            endif
            let li = search(rx, 'W')
        endwh
        if b:vikiMarkInexistent == 1
            exe 'syntax clear '. b:vikiInexistentHighlight
            let rx = <SID>VikiRxFromCollection(b:vikiNamesNull)
            if rx != ''
                exe 'syntax match '. b:vikiInexistentHighlight .' /'. rx .'/'
            endif
        elseif  b:vikiMarkInexistent == 2
            syntax clear vikiOkLink
            syntax clear vikiExtendedOkLink
            let rx = <SID>VikiRxFromCollection(b:vikiNamesOk)
            if rx != ''
                exe 'syntax match vikiOkLink /'. rx .'/'
            endif
        endif
    finally
        if feedback
            let &statusline=sl
        endif
    endtry
    exe 'norm! '. li0 .'G'. co0 .'|'
    let b:vikiCheckInexistent = 0
endf

command! -nargs=* -range=% VikiMarkInexistent call <SID>VikiMarkInexistent(<line1>, <line2>, <f-args>)
command! VikiMarkInexistentInParagraph '{,'}VikiMarkInexistent
command! VikiMarkInexistentInParagraphQuick exec "'{,'}VikiMarkInexistent -1 1"
command! VikiMarkInexistentInLine .,.VikiMarkInexistent
command! VikiMarkInexistentInLineQuick exec ".,.VikiMarkInexistent ". col("$") ." 1"
" command! VikiMarkInexistentInLineQuicker if &modified | exec ".,.VikiMarkInexistent ". col(".") ." 1" | endif

fun! VikiCheckInexistent()
    if g:vikiEnabled && &ft == "viki" && g:vikiMarkInexistent && exists("b:vikiCheckInexistent") && b:vikiCheckInexistent > 0
        " call inputdialog('b:vikiCheckInexistent: '. b:vikiCheckInexistent)
        call <SID>VikiMarkInexistent(b:vikiCheckInexistent, b:vikiCheckInexistent)
        " VikiMarkInexistent
        " VikiMarkInexistentInParagraph
    endif
endf

" autocmd VimLeavePre * let g:vikiMarkInexistent = 0
autocmd BufEnter * call VikiMinorModeReset()
autocmd VimLeavePre * let g:vikiEnabled = 0
autocmd BufWinEnter * call VikiCheckInexistent()
autocmd Filetype viki if g:vikiMarkInexistent | let b:vikiCheckInexistent = 1 | endif
" autocmd CursorHold * if &ft == 'viki' && g:vikiMarkInexistent | VikiMarkInexistentInLineQuicker | endif

fun! VikiSetBufferVar(name, ...) "{{{3
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
endf

fun! <SID>VikiLetVar(name, var) "{{{3
    if exists("b:".a:var)
        return "let ".a:name." = b:".a:var
    elseif exists("g:".a:var)
        return "let ".a:name." = g:".a:var
    else
        return ""
    endif
endf

fun! VikiDispatchOnFamily(fn, ...) "{{{3
    let fam = exists("b:vikiFamily") ? b:vikiFamily : g:vikiFamily
    if fam == "" || !exists("*".a:fn.fam)
        let cmd = a:fn
    else
        let cmd = a:fn.fam
    endif
    
    let i = 1
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
endf

fun! VikiSetupBuffer(state, ...) "{{{3
    if !g:vikiEnabled
        return
    endif

    let dontSetup = a:0 > 0 ? a:1 : ""
    " let noMatch = '\%0l' "match nothing
    let noMatch = ""
   
    if exists("b:vikiNoSimpleNames") && b:vikiNoSimpleNames
        let b:vikiNameTypes = substitute(b:vikiNameTypes, '\Cs', '', 'g')
    endif
    if exists("b:vikiDisableType") && b:vikiDisableType != ""
        let b:vikiNameTypes = substitute(b:vikiNameTypes, '\C'. b:vikiDisableType, '', 'g')
    endif

    call VikiSetBufferVar("vikiAnchorMarker")
    call VikiSetBufferVar("vikiSpecialProtocols")
    call VikiSetBufferVar("vikiSpecialProtocolsExceptions")
    call VikiSetBufferVar("vikiMarkInexistent")
    call VikiSetBufferVar("vikiTextstylesVer")
    call VikiSetBufferVar("vikiTextstylesVer")
    call VikiSetBufferVar("vikiLowerCharacters")
    call VikiSetBufferVar("vikiUpperCharacters")

    if a:state =~ '1$'
        call VikiSetBufferVar("vikiCommentStart", 
                    \ "b:commentStart", "b:ECcommentOpen", "b:EnhCommentifyCommentOpen",
                    \ "*matchstr(&commentstring, '^\\zs.*\\ze%s')")
        call VikiSetBufferVar("vikiCommentEnd",
                    \ "b:commentEnd", "b:ECcommentClose", "b:EnhCommentifyCommentClose", 
                    \ "*matchstr(&commentstring, '%s\\zs.*\\ze$')")
    endif
    
    let b:vikiSimpleNameQuoteChars = '^][:*/&?<>|\"'
    
    let b:vikiSimpleNameQuoteBeg   = '\[-'
    let b:vikiSimpleNameQuoteEnd   = '-\]'
    let b:vikiQuotedSelfRef        = "^". b:vikiSimpleNameQuoteBeg . b:vikiSimpleNameQuoteEnd ."$"
    let b:vikiQuotedRef            = "^". b:vikiSimpleNameQuoteBeg .'.\+'. b:vikiSimpleNameQuoteEnd ."$"

    let b:vikiAnchorNameRx         = '['. b:vikiLowerCharacters .']['. 
                \ b:vikiLowerCharacters . b:vikiUpperCharacters .'_0-9]*'
    
    let interviki = '\<['. b:vikiUpperCharacters .']\+::'

    if <SID>IsSupportedType("sSc") && !(dontSetup =~? "s")
        if <SID>IsSupportedType("S") && !(dontSetup =~# "S")
            let quotedVikiName = b:vikiSimpleNameQuoteBeg 
                        \ .'['. b:vikiSimpleNameQuoteChars .']'
                        \ .'\{-}'. b:vikiSimpleNameQuoteEnd
        else
            let quotedVikiName = ""
        endif
        if <SID>IsSupportedType("c") && !(dontSetup =~# "c")
            let simpleWikiName = VikiGetSimpleRx4SimpleWikiName()
            if quotedVikiName != ""
                let quotedVikiName = quotedVikiName .'\|'
            endif
        else
            let simpleWikiName = ""
        endif
        let b:vikiSimpleNameRx = '\C\(\('. interviki .'\)\?'.
                    \ '\('. quotedVikiName . simpleWikiName .'\)\)'.
                    \ '\(#\('. b:vikiAnchorNameRx .'\)\>\)\?'
        let b:vikiSimpleNameSimpleRx = '\C\(\<['.b:vikiUpperCharacters.']\+::\)\?'.
                    \ '\('. quotedVikiName . simpleWikiName .'\)'.
                    \ '\(#'. b:vikiAnchorNameRx .'\>\)\?'
        let b:vikiSimpleNameNameIdx   = 1
        let b:vikiSimpleNameDestIdx   = 0
        let b:vikiSimpleNameAnchorIdx = 5
        let b:vikiSimpleNameCompound = 'let erx="'. escape(b:vikiSimpleNameRx, '\"')
                    \ .'" | let nameIdx='. b:vikiSimpleNameNameIdx
                    \ .' | let destIdx='. b:vikiSimpleNameDestIdx
                    \ .' | let anchorIdx='. b:vikiSimpleNameAnchorIdx
    else
        let b:vikiSimpleNameRx        = noMatch
        let b:vikiSimpleNameSimpleRx  = noMatch
        let b:vikiSimpleNameNameIdx   = 0
        let b:vikiSimpleNameDestIdx   = 0
        let b:vikiSimpleNameAnchorIdx = 0
    endif
   
    if <SID>IsSupportedType("u") && !(dontSetup =~# "u")
        let urlChars = 'A-Za-z0-9.,:%?=&_~@$/|+-'
        let b:vikiUrlRx = '\<\(\('.b:vikiSpecialProtocols.'\):['. urlChars .']\+\)'.
                    \ '\(#\([A-Za-z0-9]*\)\)\?'
        let b:vikiUrlSimpleRx = '\<\('. b:vikiSpecialProtocols .'\):['. urlChars .']\+'.
                    \ '\(#[A-Za-z0-9]*\)\?'
        let b:vikiUrlNameIdx   = 0
        let b:vikiUrlDestIdx   = 1
        let b:vikiUrlAnchorIdx = 4
        let b:vikiUrlCompound = 'let erx="'. escape(b:vikiUrlRx, '\"')
                    \ .'" | let nameIdx='. b:vikiUrlNameIdx
                    \ .' | let destIdx='. b:vikiUrlDestIdx
                    \ .' | let anchorIdx='. b:vikiUrlAnchorIdx
    else
        let b:vikiUrlRx        = noMatch
        let b:vikiUrlSimpleRx  = noMatch
        let b:vikiUrlNameIdx   = 0
        let b:vikiUrlDestIdx   = 0
        let b:vikiUrlAnchorIdx = 0
    endif
   
    if <SID>IsSupportedType("x") && !(dontSetup =~# "x")
        let b:vikiCmdRx        = '\({\S\+\|#['. b:vikiUpperCharacters .']\w*\)\(.\{-}\):\s*\(.\{-}\)\($\|}\)'
        let b:vikiCmdSimpleRx  = '\({\S\+\|#['. b:vikiUpperCharacters .']\w*\).\{-}\($\|}\)'
        let b:vikiCmdNameIdx   = 1
        let b:vikiCmdDestIdx   = 3
        let b:vikiCmdAnchorIdx = 2
        let b:vikiCmdCompound = 'let erx="'. escape(b:vikiCmdRx, '\"')
                    \ .'" | let nameIdx='. b:vikiCmdNameIdx
                    \ .' | let destIdx='. b:vikiCmdDestIdx
                    \ .' | let anchorIdx='. b:vikiCmdAnchorIdx
    else
        let b:vikiCmdRx        = noMatch
        let b:vikiCmdSimpleRx  = noMatch
        let b:vikiCmdNameIdx   = 0
        let b:vikiCmdDestIdx   = 0
        let b:vikiCmdAnchorIdx = 0
    endif
    
    if <SID>IsSupportedType("e") && !(dontSetup =~# "e")
        let b:vikiExtendedNameRx = 
                    \ '\[\[\(\('.b:vikiSpecialProtocols.'\)://[^]]\+\|[^]#]\+\)\?'.
                    \ '\(#\([^]]*\)\)\?\]\(\[\([^]]\+\)\]\)\?[!~*\-]*\]'
                    " \ '\(#\('. b:vikiAnchorNameRx .'\)\)\?\]\(\[\([^]]\+\)\]\)\?[!~*\-]*\]'
        let b:vikiExtendedNameSimpleRx = 
                    \ '\[\[\('. b:vikiSpecialProtocols .'://[^]]\+\|[^]#]\+\)\?'.
                    \ '\(#[^]]*\)\?\]\(\[[^]]\+\]\)\?[!~*\-]*\]'
                    " \ '\(#'. b:vikiAnchorNameRx .'\)\?\]\(\[[^]]\+\]\)\?[!~*\-]*\]'
        let b:vikiExtendedNameNameIdx   = 6
        let b:vikiExtendedNameDestIdx   = 1
        let b:vikiExtendedNameAnchorIdx = 4
        let b:vikiExtendedNameCompound = 'let erx="'. escape(b:vikiExtendedNameRx, '\"')
                    \ .'" | let nameIdx='. b:vikiExtendedNameNameIdx
                    \ .' | let destIdx='. b:vikiExtendedNameDestIdx
                    \ .' | let anchorIdx='. b:vikiExtendedNameAnchorIdx
    else
        let b:vikiExtendedNameRx        = noMatch
        let b:vikiExtendedNameSimpleRx  = noMatch
        let b:vikiExtendedNameNameIdx   = 0
        let b:vikiExtendedNameDestIdx   = 0
        let b:vikiExtendedNameAnchorIdx = 0
    endif

    let b:vikiInexistentHighlight = "vikiInexistentLink"
endf

fun! VikiDefineMarkup(state) "{{{3
    if <SID>IsSupportedType("sS") && b:vikiSimpleNameSimpleRx != ""
        exe "syntax match vikiLink /" . b:vikiSimpleNameSimpleRx . "/"
    endif
    if <SID>IsSupportedType("e") && b:vikiExtendedNameSimpleRx != ""
        exe "syntax match vikiExtendedLink '" . b:vikiExtendedNameSimpleRx . "' skipnl"
    endif
    if <SID>IsSupportedType("u") && b:vikiUrlSimpleRx != ""
        exe "syntax match vikiURL /" . b:vikiUrlSimpleRx . "/"
    endif
endf

fun! VikiGetSimpleRx4SimpleWikiName()
    let upper = <SID>UpperCharacters()
    let lower = <SID>LowerCharacters()
    let simpleWikiName = '\<['.upper.']['.lower.']\+\(['.upper.']['.lower.'0-9]\+\)\+\>'
    return simpleWikiName
endf

fun! <SID>UpperCharacters()
    return exists('b:vikiUpperCharacters') ? b:vikiUpperCharacters : g:vikiUpperCharacters
endf

fun! <SID>LowerCharacters()
    return exists('b:vikiLowerCharacters') ? b:vikiLowerCharacters : g:vikiLowerCharacters
endf

fun! VikiDefineHighlighting(state) "{{{3
    if version < 508
        command! -nargs=+ VikiHiLink hi link <args>
    else
        command! -nargs=+ VikiHiLink hi def link <args>
    endif

    exe "hi vikiInexistentLink term=bold,underline cterm=bold,underline gui=bold,underline". 
                \ " ctermfg=". g:vikiInexistentColor ." guifg=". g:vikiInexistentColor
    exe "hi vikiHyperLink term=bold,underline cterm=bold,underline gui=bold,underline". 
                \ " ctermfg=". g:vikiHyperLinkColor ." guifg=". g:vikiHyperLinkColor

    if <SID>IsSupportedType("sS")
        VikiHiLink vikiLink vikiHyperLink
        VikiHiLink vikiOkLink vikiHyperLink
        VikiHiLink vikiRevLink Normal
    endif
    if <SID>IsSupportedType("e")
        VikiHiLink vikiExtendedLink vikiHyperLink
        VikiHiLink vikiExtendedOkLink vikiHyperLink
        VikiHiLink vikiRevExtendedLink Normal
    endif
    if <SID>IsSupportedType("u")
        VikiHiLink vikiURL vikiHyperLink
    endif
    delcommand VikiHiLink
endf

fun! <SID>MapMarkInexistent(key, element, insert, before)
    let arg = maparg(a:key, "i")
    if arg == ""
        let arg = a:insert
    endif
    if a:before
        exe 'inoremap <silent> <buffer> '. a:key .' '. arg .'<c-o>:VikiMarkInexistentIn'. a:element .'<cr>'
    else
        exe 'inoremap <silent> <buffer> '. a:key .' <c-o>:VikiMarkInexistentIn'. a:element .'<cr>'. arg
    endif
endf

fun! VikiMapKeys(state)
    if exists("b:vikiMapFunctionality") && b:vikiMapFunctionality
        let mf = b:vikiMapFunctionality
    else
        let mf = g:vikiMapFunctionality
    endif
    if mf =~# 'f' && !hasmapto("VikiMaybeFollowLink")
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
        nnoremap <buffer> <silent> <LocalLeader>vf :call VikiMaybeFollowLink(0,1)<cr>
        nnoremap <buffer> <silent> <LocalLeader><c-cr> :call VikiMaybeFollowLink(0,1,-1)<cr>
        nnoremap <buffer> <silent> <LocalLeader>vs :call VikiMaybeFollowLink(0,1,-1)<cr>
        nnoremap <buffer> <silent> <LocalLeader>vv :call VikiMaybeFollowLink(0,1,-2)<cr>
        nnoremap <buffer> <silent> <LocalLeader>v1 :call VikiMaybeFollowLink(0,1,1)<cr>
        nnoremap <buffer> <silent> <LocalLeader>v2 :call VikiMaybeFollowLink(0,1,2)<cr>
        nnoremap <buffer> <silent> <LocalLeader>v3 :call VikiMaybeFollowLink(0,1,3)<cr>
        nnoremap <buffer> <silent> <LocalLeader>v4 :call VikiMaybeFollowLink(0,1,4)<cr>
        if g:vikiMapMouse
            nnoremap <buffer> <silent> <m-leftmouse> <leftmouse>:call VikiMaybeFollowLink(0,1)<cr>
            inoremap <buffer> <silent> <m-leftmouse> <leftmouse><c-o>:call VikiMaybeFollowLink(0,1)<cr>
        endif
        "nnoremap <buffer> <s-c-cr> :call VikiMaybeFollowLink(0,1)<cr>
        "inoremap <buffer> <s-c-cr> <c-o><c-cr>
    endif
    if mf =~# 'e' && !hasmapto("VikiEdit")
        noremap <buffer> <LocalLeader>ve :VikiEdit 
    endif
    if mf =~# 'i' && !hasmapto("VikiMarkInexistent")
        noremap <buffer> <silent> <LocalLeader>vd :VikiMarkInexistent<cr>
        noremap <buffer> <silent> <LocalLeader>vp :VikiMarkInexistentInParagraph<cr>
        if g:vikiMapInexistent
            let i = 0
            let m = strlen(g:vikiMapKeys)
            while i < m
                let k = g:vikiMapKeys[i]
                call <SID>MapMarkInexistent(k, "LineQuick", k, 0)
                let i = i + 1
            endwh
            call <SID>MapMarkInexistent("]", "LineQuick", "]", 1)
            call <SID>MapMarkInexistent("<space>", "LineQuick", " ", 0)
            call <SID>MapMarkInexistent("<cr>", "LineQuick", "", 0)
            " call <SID>MapMarkInexistent("<cr>", "Paragraph", "", 0)
        endif
    endif
    if mf =~# 'q' && !hasmapto("VikiQuote") && exists("*VEnclose")
        vnoremap <buffer> <silent> <LocalLeader>vq :VikiQuote<cr><esc>:VikiMarkInexistentInLineQuick<cr>
        nnoremap <buffer> <silent> <LocalLeader>vq viw:VikiQuote<cr><esc>:VikiMarkInexistentInLineQuick<cr>
        inoremap <buffer> <silent> <LocalLeader>vq <esc>viw:VikiQuote<cr><esc>:VikiMarkInexistentInLineQuick<cr>i
    endif
    if mf =~# 'b' && !hasmapto("VikiGoBack")
        nnoremap <buffer> <silent> <LocalLeader>vb :call VikiGoBack()<cr>
        if g:vikiMapMouse
            nnoremap <buffer> <silent> <m-rightmouse> <leftmouse>:call VikiGoBack(0)<cr>
            inoremap <buffer> <silent> <m-rightmouse> <leftmouse><c-o>:call VikiGoBack(0)<cr>
        endif
    endif
    if mf =~# 'F' && !hasmapto(":VikiFind")
        nnoremap <buffer> <silent> <c-tab>   :VikiFindNext<cr>
        nnoremap <buffer> <silent> <LocalLeader>vn :VikiFindNext<cr>
        nnoremap <buffer> <silent> <c-s-tab> :VikiFindPrev<cr>
        nnoremap <buffer> <silent> <LocalLeader>vN :VikiFindPrev<cr>
    endif
endf

"state ... 0,  +/-1, +/-2
fun! VikiMinorMode(state) "{{{3
    if !g:vikiEnabled
        return 0
    endif
    if a:state == 0
        return 0
    endif
    " if exists("b:vikiEnabled")
    "     if b:vikiEnabled && a:state < 0
    "         return 0
    "     endif
    "     " echom "VIKI: Viki mode already set."
    " endif
    if !exists("b:vikiEnabled") || !b:vikiEnabled
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
        call VikiDispatchOnFamily("VikiMapKeys", a:state)
        let b:vikiEnabled = 1
    endif
    call VikiDispatchOnFamily("VikiDefineMarkup", a:state)
    call VikiDispatchOnFamily("VikiDefineHighlighting", a:state)
    return 1
endf

fun! VikiMinorModeReset() "{{{3
    if exists("b:vikiEnabled") && b:vikiEnabled == 1
        call VikiMinorMode(-1)
    endif
endf

command! VikiMinorMode call VikiMinorMode(1)
command! VikiMinorModeMaybe call VikiMinorMode(-1)
" this requires imaps to be installed
command! -range VikiQuote :call VEnclose("[-", "-]", "[-", "-]")

fun! VikiMode(state) "{{{3
    if exists("b:vikiEnabled")
        if b:vikiEnabled && a:state < 0
            return 0
        endif
        echom "VIKI: Viki mode already set."
    endif
    set filetype=viki
endf

command! VikiMode call VikiMode(2)
command! VikiModeMaybe call VikiMode(-2)

fun! <SID>AddVarToMultVal(var, val) "{{{3
    if exists(a:var)
        exe "let i = MvIndexOfElement(". a:var .", '". g:vikiDefSep ."', ". a:val .")"
        exe "let ". a:var ."=MvPushToFront(". a:var .", '". g:vikiDefSep ."', ". a:val .")"
        return i
    else
        exe "let ". a:var ."=MvAddElement('', '". g:vikiDefSep ."', ". a:val .")"
        return -1
    endif
endf

fun! VikiIsInRegion(line)
    let i   = 0
    let max = col("$")
    while i < max
        if synIDattr(synID(a:line, i, 1), "name") == "vikiRegion"
            return 1
        endif
        let i = i + 1
    endw
    return 0
endf

fun! <SID>VikiSetBackRef(file, li, co) "{{{3
    let i = <SID>AddVarToMultVal("b:VikiBackFile", "'". a:file ."'")
    if i >= 0
        let b:VikiBackLine = MvPushToFrontElementAt(b:VikiBackLine, g:vikiDefSep, i)
        let b:VikiBackCol  = MvPushToFrontElementAt(b:VikiBackCol,  g:vikiDefSep, i)
    else
        call <SID>AddVarToMultVal("b:VikiBackLine", a:li)
        call <SID>AddVarToMultVal("b:VikiBackCol",  a:co)
    endif
endf

fun! VikiSelect(array, seperator, queryString) "{{{3
    let n = MvNumberOfElements(a:array, a:seperator)
    if n == 1
        return 0
    elseif n > 1
        let i  = 0
        let nn = 0
        while i <= n
            let f = MvElementAt(a:array, a:seperator, i)
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
            let this = input(a:queryString ." [0-".nn."]: ", "0")
        endif
        if  this >= 0 && this <= nn
            return this
        endif
    endif
    return -1
endf

fun! <SID>VikiSelectThisBackRef(n) "{{{3
    return "let vbf = '". MvElementAt(b:VikiBackFile, g:vikiDefSep, a:n) ."'".
                \ " | let vbl = ". MvElementAt(b:VikiBackLine, g:vikiDefSep, a:n) .
                \ " | let vbc = ". MvElementAt(b:VikiBackCol, g:vikiDefSep, a:n)
endf

fun! <SID>VikiSelectBackRef(...) "{{{3
    if exists("b:VikiBackFile") && exists("b:VikiBackLine") && exists("b:VikiBackCol")
        if a:0 >= 1 && a:1 >= 0
            let s = a:1
        else
            let s = VikiSelect(b:VikiBackFile, g:vikiDefSep, "Select Back Reference")
        endif
        if s >= 0
            return <SID>VikiSelectThisBackRef(s)
        endif
    endif
    return ""
endf

if g:vikiSaveHistory && exists("*GetPersistentVar") && exists("*PutPersistentVar") "{{{2
    fun! VikiGetSimplifiedBufferName() "{{{3
        return substitute( expand("%:p"), "[^a-zA-Z0-9]", "_", "g")
    endf
    
    fun! VikiSaveBackReferences() "{{{3
        if exists("b:VikiBackFile") && b:VikiBackFile != ""
            call PutPersistentVar("VikiBackFile", VikiGetSimplifiedBufferName(), b:VikiBackFile)
            call PutPersistentVar("VikiBackLine", VikiGetSimplifiedBufferName(), b:VikiBackLine)
            call PutPersistentVar("VikiBackCol",  VikiGetSimplifiedBufferName(), b:VikiBackCol)
        endif
    endf
    
    fun! VikiRestoreBackReferences() "{{{3
        if exists("b:vikiEnabled") && !exists("b:VikiBackFile")
            let b:VikiBackFile = GetPersistentVar("VikiBackFile", VikiGetSimplifiedBufferName(), "")
            let b:VikiBackLine = GetPersistentVar("VikiBackLine", VikiGetSimplifiedBufferName(), "")
            let b:VikiBackCol  = GetPersistentVar("VikiBackCol",  VikiGetSimplifiedBufferName(), "")
        endif
    endf

    au BufEnter * call VikiRestoreBackReferences()
    au BufLeave * call VikiSaveBackReferences()
endif

fun! VikiGoBack(...) "{{{3
    let s  = (a:0 >= 1) ? a:1 : -1
    let br = <SID>VikiSelectBackRef(s)
    if br == ""
        echomsg "Viki: No back reference defined? (". s ."/". br .")"
    else
        exe br
        let buf = bufnr("^". vbf ."$")
        if buf >= 0
            call <SID>EditWrapper('buffer', buf)
        else
            call <SID>EditWrapper('edit', vbf)
        endif
        if vbf == expand("%:p")
            call cursor(vbl, vbc)
        else
            throw "Viki: Couldn't open file: ". b:VikiBackFile
        endif
    endif
endf

command! -narg=? VikiGoBack call VikiGoBack(<f-args>)

fun! VikiSubstituteArgs(str, ...) "{{{3
    let i  = 1
    " let rv = escape(a:str, '\')
    let rv = a:str
    while a:0 >= i
        exec "let lab = a:". i
        exec "let val = a:". (i+1)
        let rv = substitute(rv, '\C\(^\|[^%]\)\zs%{'. lab .'}', escape(val, '\&'), "g")
        " let rv = escape(rv, '\')
        let i = i + 2
    endwh
    let rv = substitute(rv, '%%', "%", "g")
    return rv
endf

fun! VikiFindAnchor(anchor) "{{{3
    if a:anchor != g:vikiDefNil
        let co = virtcol(".")
        let li = line(".")
        let anchorRx = '\^\s*\('. b:vikiCommentStart .'\)\?\s*'. b:vikiAnchorMarker . a:anchor
        if exists("b:vikiAnchorRx")
            let varx = VikiSubstituteArgs(b:vikiAnchorRx, 'ANCHOR', a:anchor)
            let anchorRx = '\('.anchorRx.'\|'. varx .'\)'
        endif
        norm! $
        let found = search('\V'. anchorRx, "w")
        if !found
            exec "norm! ". li ."G". co ."|"
            if g:vikiFreeMarker
                call search('\c\V'. escape(a:anchor, '\'), "w")
            endif
        endif
    endif
endf

fun! VikiGetWinNr(...)
    let winNr = a:0 >= 1 ? a:1 : 0
    if winNr == 0
        if exists("b:vikiSplit")
            let winNr = b:vikiSplit
        elseif exists("g:vikiSplit")
            let winNr = g:vikiSplit
        else
            let winNr = 0
        endif
    endif
    return winNr
endf

fun! VikiSetWindow(winNr)
    let winNr = VikiGetWinNr(a:winNr)
    if winNr != 0
        let wm = <SID>HowManyWindows()
        if winNr == -2
            wincmd v
        elseif wm == 1 || winNr == -1
            wincmd s
        else
            exec winNr ."wincmd w"
        end
    endif
endf

" VikiOpenLink(filename, anchor, ?create=0, ?postcmd='', ?wincmd=0)
fun! VikiOpenLink(filename, anchor, ...) "{{{3
    let create  = a:0 >= 1 ? a:1 : 0
    let postcmd = a:0 >= 2 ? a:2 : ""
    let winNr   = a:0 >= 3 ? a:3 : b:vikiNextWindow
    
    let li = line(".")
    let co = col(".")
    let fi = expand("%:p")
    
    " let buf = bufnr("^". simplify(a:filename) ."$")
    let buf = bufnr("^". a:filename ."$")
    " let buf = bufnr(a:filename)
    call VikiSetWindow(winNr)
    if buf >= 0
        call <SID>EditWrapper('buffer', buf)
        call <SID>VikiSetBackRef(fi, li, co)
        call VikiDispatchOnFamily("VikiMinorMode", -1)
        call VikiDispatchOnFamily("VikiFindAnchor", a:anchor)
    elseif create && exists("b:createVikiPage")
        exe b:createVikiPage . " " . a:filename
    elseif exists("b:editVikiPage")
        exe b:editVikiPage . " " . a:filename
    else
        call <SID>EditWrapper('edit', a:filename)
        set buflisted
        call <SID>VikiSetBackRef(fi, li, co)
        call VikiDispatchOnFamily("VikiMinorMode", -1)
        call VikiDispatchOnFamily("VikiFindAnchor", a:anchor)
    endif
    if postcmd != ""
        exec postcmd
    endif
endf

fun! <SID>HowManyWindows()
    let i = 1
    while winbufnr(i) > 0
        let i = i + 1
    endwh
    return i - 1
endf

fun! VikiDecomposeUrl(dest) "{{{3
    let dest = substitute(a:dest, '^\c/*\([a-z]\)|', '\1:', "")
    let rv = ""
    let i  = 0
    while 1
        let in = match(dest, '%\d\d', i)
        if in >= 0
            let c  = "0x".strpart(dest, in + 1, 2)
            let rv = rv. strpart(dest, i, in - i) . nr2char(c)
            let i  = in + 3
        else
            break
        endif
    endwh
    let rv     = rv. strpart(dest, i)
    let uend   = match(rv, '[?#]')
    if uend >= 0
        let args   = matchstr(rv, '?\zs.\+$', uend)
        let anchor = matchstr(rv, '#\zs.\+$', uend)
        let rv     = strpart(rv, 0, uend)
    else
        let args   = ""
        let anchor = ""
        let rv     = rv
    end
    return "let filename='". rv ."'|let anchor='". anchor ."'|let args='". args ."'"
endf

fun! <SID>GetSpecialFilesSuffixes() "{{{3
    if exists("b:vikiSpecialFiles")
        return b:vikiSpecialFiles .'\|'. g:vikiSpecialFiles
    else
        return g:vikiSpecialFiles
    endif
endf

fun! VikiIsSpecialFile(dest) "{{{3
    let vikiSpecialFiles = <SID>GetSpecialFilesSuffixes()
    return (a:dest =~ '\.\('. vikiSpecialFiles .'\)$' &&
                \ (g:vikiSpecialFilesExceptions == "" ||
                \ !(a:dest =~ g:vikiSpecialFilesExceptions)))
endf

fun! <SID>VikiFollowLink(def, ...) "{{{3
    let winNr  = a:0 >= 1 ? a:1 : 0
    let name   = MvElementAt(a:def, g:vikiDefSep, 0)
    let dest   = MvElementAt(a:def, g:vikiDefSep, 1)
    let anchor = MvElementAt(a:def, g:vikiDefSep, 2)
    if name == g:vikiSelfRef || dest == g:vikiSelfRef
        call VikiDispatchOnFamily("VikiFindAnchor", anchor)
    elseif dest == g:vikiDefNil
		throw "No target? ".a:def
    else
        let b:vikiNextWindow = winNr
        try
            if dest =~ '^\('.b:vikiSpecialProtocols.'\):' &&
                        \ (b:vikiSpecialProtocolsExceptions == "" ||
                        \ !(dest =~ b:vikiSpecialProtocolsExceptions))
                call VikiOpenSpecialProtocol(dest)
            elseif VikiIsSpecialFile(dest)
                call VikiOpenSpecialFile(dest)
            elseif filereadable(dest)                 "reference to a local, already existing file
                call VikiOpenLink(dest, anchor, 0, "", winNr)
            elseif bufexists(dest)
                call <SID>EditWrapper('buffer', dest)
            elseif isdirectory(dest)
                exe g:vikiExplorer ." ". dest
            else
                let ok = input("File doesn't exists. Create '".dest."'? (Y/n) ", "y")
                if ok != "" && ok != "n"
                    let b:vikiCheckInexistent = line(".")
                    call VikiOpenLink(dest, anchor, 1, '', winNr)
                endif
            endif
        finally
            let b:vikiNextWindow = 0
        endtry
    endif
    return ""
endf

fun! <SID>MakeVikiDefPart(txt) "{{{3
    if a:txt == ""
        return g:vikiDefNil
    else
        return a:txt
    endif
endf

fun! VikiMakeDef(name, dest, anchor, part) "{{{3
    if a:name =~ g:vikiDefSep || a:dest =~ g:vikiDefSep || a:anchor =~ g:vikiDefSep 
                \ || a:part =~ g:vikiDefSep
        throw "Viki: A viki definition must not include ".g:vikiDefSep
                    \ .": ".a:name.", ".a:dest.", ".a:anchor ." (". a:part .")"
    else
        let arr = MvAddElement("",  g:vikiDefSep, <SID>MakeVikiDefPart(a:name))
        let arr = MvAddElement(arr, g:vikiDefSep, <SID>MakeVikiDefPart(a:dest))
        let arr = MvAddElement(arr, g:vikiDefSep, <SID>MakeVikiDefPart(a:anchor))
        let arr = MvAddElement(arr, g:vikiDefSep, <SID>MakeVikiDefPart(a:part))
        return arr
    endif
endf

fun! <SID>GetVikiNamePart(txt, erx, idx, errorMsg) "{{{3
    if a:idx
        let rv = substitute(a:txt, '^\C'. a:erx ."$", '\'.a:idx, "")
        if rv == ""
            return g:vikiDefNil
        else
            return rv
        endif
    else
        return g:vikiDefNil
    endif
endf

fun! VikiLinkDefinition(txt, col, compound, ignoreSyntax) "{{{3
    exe a:compound
    if erx != ""
        let ebeg = -1
        let cont = match(a:txt, erx, 0)
        while (ebeg >= 0 || (0 <= cont) && (cont <= a:col))
            let contn = matchend(a:txt, erx, cont)
            if (cont <= a:col) && (a:col < contn)
                let ebeg = match(a:txt, erx, cont)
                let elen = contn - ebeg
                break
            else
                let cont = match(a:txt, erx, contn)
            endif
        endwh
        if ebeg >= 0
            let part   = strpart(a:txt, ebeg, elen)
            let name   = <SID>GetVikiNamePart(part, erx, nameIdx,   "no name")
            let dest   = <SID>GetVikiNamePart(part, erx, destIdx,   "no destination")
            let anchor = <SID>GetVikiNamePart(part, erx, anchorIdx, "no anchor")
            return VikiMakeDef(name, dest, anchor, part)
        elseif a:ignoreSyntax
            return ""
        else
            throw "Viki: Malformed viki name: " . a:txt . " (". erx .")"
        endif
    else
        return ""
    endif
endf

fun! <SID>VikiGetSuffix() "{{{3
    if exists("b:vikiNameSuffix")
        return b:vikiNameSuffix
    endif
    if g:vikiUseParentSuffix
        let sfx = expand("%:e")
        if sfx != ""
            return ".".sfx
        endif
    endif
    return g:vikiNameSuffix
endf

fun! VikiExpandSimpleName(dest, name, suffix) "{{{3
    if a:suffix == g:vikiDefSep
        return a:dest . g:vikiDirSeparator . a:name . <SID>VikiGetSuffix()
    else
        return a:dest . g:vikiDirSeparator . a:name . (a:suffix == g:vikiDefSep? "" : a:suffix)
    endif
endf

fun! VikiCompleteSimpleNameDef(def) "{{{3
    let name   = MvElementAt(a:def, g:vikiDefSep, 0)
    if name == g:vikiDefNil
        throw "Viki: Malformed simple viki name (no name): ".a:def
    endif

    let dest   = MvElementAt(a:def, g:vikiDefSep, 1)
    if !(dest == g:vikiDefNil)
        throw "Viki: Malformed simple viki name (destination=".dest."): ". a:def
    endif
    
    let useSuffix = g:vikiDefSep
    if <SID>IsSupportedType("i") && name =~# s:InterVikiRx
        let ow = substitute(name, s:InterVikiRx, '\1', "")
        exec <SID>VikiLetVar("dest", "vikiInter".ow)
        if exists("dest")
            let dest = expand(dest)
            let name = substitute(name, s:InterVikiRx, '\2', "")
            exec <SID>VikiLetVar("useSuffix", "vikiInter".ow."_suffix")
        else
            throw "Viki: InterViki is not defined: ".ow
        endif
    else
        let dest = expand("%:p:h")
    endif

    if <SID>IsSupportedType("S")
        if name =~ b:vikiQuotedSelfRef
            let name  = g:vikiSelfRef
        elseif name =~ b:vikiQuotedRef
            let name = matchstr(name, "^". b:vikiSimpleNameQuoteBeg .'\zs.\+\ze'. b:vikiSimpleNameQuoteEnd ."$")
        endif
    elseif !<SID>IsSupportedType("c")
        throw "Viki: CamelCase names not allowed"
    endif
    
    if name != g:vikiSelfRef
        let rdest = VikiExpandSimpleName(dest, name, useSuffix)
    else
        let rdest = g:vikiDefNil
    endif
    let anchor = MvElementAt(a:def, g:vikiDefSep, 2)
    let part   = MvElementAt(a:def, g:vikiDefSep, 3)
    return VikiMakeDef(name, rdest, anchor, part)
endf

fun! VikiCompleteExtendedNameDef(def) "{{{3
    let name   = MvElementAt(a:def, g:vikiDefSep, 0)
    let dest   = MvElementAt(a:def, g:vikiDefSep, 1)
    let anchor = MvElementAt(a:def, g:vikiDefSep, 2)
    let part   = MvElementAt(a:def, g:vikiDefSep, 3)
    if dest == g:vikiDefNil
        if anchor == g:vikiDefNil
            throw "Viki: Malformed extended viki name (no destination): ".a:def
        else
            let dest = g:vikiSelfRef
        endif
    elseif <SID>IsSupportedType("i") && dest =~? '^['. <SID>UpperCharacters() .']\+::' " an Interviki name
        let ow = substitute(dest, s:InterVikiRx, '\1', "")
        exec <SID>VikiLetVar("idest", "vikiInter".ow)
        if exists("idest")
            let idest = expand(idest)
            let dest  = substitute(dest, s:InterVikiRx, '\2', "")
            exec <SID>VikiLetVar("useSuffix", "vikiInter".ow."_suffix")
            let dest = VikiExpandSimpleName(idest, dest, useSuffix)
        else
            throw "Viki: InterViki is not defined: ".ow
        endif
    elseif dest =~? '^[a-z]:'                      " an absolute dos path
    elseif dest =~? '^\/'                          " an absolute unix path
    elseif dest =~? '^'.b:vikiSpecialProtocols.':' " some protocol
    elseif dest =~ '^\~'                           " user home
        let dest = $HOME . strpart(dest, 1)
        let dest = <SID>CanonicFilename(dest)
    else                                           " a relative path
        let dest = expand("%:p:h") .g:vikiDirSeparator. dest
        let dest = <SID>CanonicFilename(dest)
    endif
    if name == g:vikiDefNil
        let name = dest
    endif
    if dest != g:vikiSelfRef && fnamemodify(dest, ":p:h") == expand("%:p:h")
        if fnamemodify(dest, ":e") == ""
            let dest = dest.<SID>VikiGetSuffix()
        endif
    endif
    return VikiMakeDef(name, dest, anchor, part)
endf
 
fun! <SID>FindFileWithSuffix(filename, suffixes) "{{{3
    if filereadable(a:filename)
        return a:filename
    else
        let suffixes = a:suffixes
        while 1
            let elt = MvElementAt(suffixes, '\\|', 0)
            if elt != ""
                let fn = a:filename .".". elt
                if filereadable(fn)
                    return fn
                else
                    let suffixes = MvRemoveElement(suffixes, '\\|', elt)
                endif
            else
                return g:vikiDefNil
            endif
        endwh
    endif
    return g:vikiDefNil
endf

fun! VikiCompleteCmdDef(def) "{{{3
    let name   = MvElementAt(a:def, g:vikiDefSep, 0)
    let dest   = MvElementAt(a:def, g:vikiDefSep, 1)
    let args   = MvElementAt(a:def, g:vikiDefSep, 2)
    let part   = MvElementAt(a:def, g:vikiDefSep, 3)
    let anchor = g:vikiDefNil
    if name ==# "#IMG" || name =~# "{img"
        let vikiSpecialFiles = <SID>GetSpecialFilesSuffixes()
        let dest = <SID>FindFileWithSuffix(dest, vikiSpecialFiles)
    elseif name ==# "#Img"
        let id = matchstr(args, '\sid=\zs\w\+')
        if id != ""
            let vikiSpecialFiles = <SID>GetSpecialFilesSuffixes()
            let dest = <SID>FindFileWithSuffix(id, vikiSpecialFiles)
        endif
    elseif name =~ "^#INC"
        " <+TBD+> Search path?
    else
        " throw "Viki: Unknown command: ". name
        let name = g:vikiDefNil
        let dest = g:vikiDefNil
        let anchor = g:vikiDefNil
    endif
    return VikiMakeDef(name, dest, anchor, part)
endf

fun! <SID>VikiLinkNotFoundEtc(oldmap, ignoreSyntax) "{{{3
    if a:oldmap == ""
        echomsg "Viki: Show me the way to the next viki name or I have to ... ".a:ignoreSyntax.":".getline(".")
    elseif a:oldmap == 1
        return "\<c-cr>"
    else
        return a:oldmap
    endif
endf

" VikiGetLink(oldmap, ignoreSyntax, ?txt, ?col=0, ?supported=b:vikiNameTypes)
fun! VikiGetLink(oldmap, ignoreSyntax, ...) "{{{3
    let col   = a:0 >= 2 ? a:2 : 0
    let types = a:0 >= 3 ? a:3 : b:vikiNameTypes
    if a:0 >= 1
        let txt      = a:1
        let vikiType = a:ignoreSyntax
        let tryAll   = 1
    else
        let synName = synIDattr(synID(line('.'),col('.'),0),"name")
        if synName ==# "vikiLink"
            let vikiType = 1
            let tryAll   = 0
        elseif synName ==# "vikiExtendedLink"
            let vikiType = 2
            let tryAll   = 0
        elseif synName ==# "vikiURL"
            let vikiType = 3
            let tryAll   = 0
        elseif synName ==# "vikiCommand" || synName ==# "vikiMacro"
            let vikiType = 4
            let tryAll   = 0
        elseif a:ignoreSyntax
            let vikiType = a:ignoreSyntax
            let tryAll   = 1
        else
            return ""
        endif
        let txt = getline(".")
        let col = col(".") - 1
    endif
    if (tryAll || vikiType == 1) && <SID>IsSupportedType("s", types)
        if exists("b:getVikiLink")
            exe "let def = " . b:getVikiLink."()"
        else
            let def = VikiLinkDefinition(txt, col, b:vikiSimpleNameCompound, a:ignoreSyntax)
        endif
        if def != ""
            return VikiDispatchOnFamily("VikiCompleteSimpleNameDef", def)
        endif
    endif
    if (tryAll || vikiType == 2) && <SID>IsSupportedType("e", types)
        if exists("b:getExtVikiLink")
            exe "let def = " . b:getExtVikiLink."()"
        else
            let def = VikiLinkDefinition(txt, col, b:vikiExtendedNameCompound, a:ignoreSyntax)
        endif
        if def != ""
            return VikiDispatchOnFamily("VikiCompleteExtendedNameDef", def)
        endif
    endif
    if (tryAll || vikiType == 3) && <SID>IsSupportedType("u", types)
        if exists("b:getURLViki")
            exe "let def = " . b:getURLViki . "()"
        else
            let def = VikiLinkDefinition(txt, col, b:vikiUrlCompound, a:ignoreSyntax)
        endif
        if def != ""
            return VikiDispatchOnFamily("VikiCompleteExtendedNameDef", def)
        endif
    endif
    if (tryAll || vikiType == 4) && <SID>IsSupportedType("x", types)
        if exists("b:getCmdViki")
            exe "let def = " . b:getCmdViki . "()"
        else
            let def = VikiLinkDefinition(txt, col, b:vikiCmdCompound, a:ignoreSyntax)
        endif
        if def != ""
            return VikiDispatchOnFamily("VikiCompleteCmdDef", def)
        endif
    endif
    return ""
endf

" VikiMaybeFollowLink(oldmap, ignoreSyntax, ?winNr=0)
fun! VikiMaybeFollowLink(oldmap, ignoreSyntax, ...) "{{{3
    let winNr = a:0 >= 1 ? a:1 : 0
    let def = VikiGetLink(a:oldmap, a:ignoreSyntax)
    if def != ""
        return <SID>VikiFollowLink(def, winNr)
    else
        return <SID>VikiLinkNotFoundEtc(a:oldmap, a:ignoreSyntax)
    endif
endf
command! VikiJump call VikiMaybeFollowLink(0,1)

" VikiEdit(name, ?bang='', ?winNr=0)
fun! VikiEdit(name, ...) "{{{3
    let bang  = a:0 >= 1 ? a:1 : ''
    let winNr = a:0 >= 2 ? a:2 : 0
    if exists('b:vikiEnabled') && bang != ''
        if g:vikiHomePage != ''
            call <SID>EditWrapper('edit', g:vikiHomePage)
        else
            call <SID>EditWrapper('buffer', 1)
        endif
    endif
    if a:name == '*'
        let name = 'file://'. g:vikiHomePage
    else
        let name = a:name
    end
    let name = substitute(name, '[\\]', '/', 'g')
    if !exists("b:vikiNameTypes")
        call VikiSetBufferVar("vikiNameTypes")
        call VikiDispatchOnFamily("VikiSetupBuffer", 0)
    endif
    let def  = VikiGetLink('', 1, name, 0, '')
    if def != ""
        return <SID>VikiFollowLink(def, winNr)
    else
        call <SID>VikiLinkNotFoundEtc('', 1)
    endif
endf

fun! <SID>VikiEditCompleteAgent(interviki, afname, fname)
    if isdirectory(a:afname)
        return ''
    else
        if exists('g:vikiInter'. a:interviki .'_suffix')
            let sfx = g:vikiInter{a:interviki}_suffix
        else
            let sfx = <SID>VikiGetSuffix()
        endif
        if sfx != '' && sfx == '.'. fnamemodify(a:fname, ':e')
            let name = fnamemodify(a:fname, ':t:r')
        else
            let name = a:fname
        endif
        if name !~ VikiGetSimpleRx4SimpleWikiName()
            let name = '[-'. a:fname .'-]'
        endif
        if a:interviki != ''
            let name = a:interviki .'::'. name
        endif
        return name
    endif
endf

fun! VikiEditComplete(ArgLead, CmdLine, CursorPos)
    let i = matchstr(a:ArgLead, '^\zs.\{-}\ze::')
    if exists('g:vikiInter'. i .'_suffix')
        let sfx = g:vikiInter{i}_suffix
    else
        let sfx = <SID>VikiGetSuffix()
    endif
    if i != '' && exists('g:vikiInter'. i)
        let d  = substitute(g:vikiInter{i}, '\', '/', 'g')
        let f  = matchstr(a:ArgLead, '::\(\[-\)\?\zs.*$')
        let rv = glob(d .'/'. f .'*'.sfx)
        let rv = substitute(rv."\n", '\V\('.escape(d, '\').'/\(\[^\n]\{-}\)\)'.sfx.'\ze\n', "\\=<SID>VikiEditCompleteAgent('".i."', submatch(1), submatch(2))", 'g')
    else
        let rv = glob('*'.sfx)
        let rv = substitute(rv."\n", '\V\n\?\zs\(\[^\n]\{-}\)\ze\n', "\\=<SID>VikiEditCompleteAgent('".i."', submatch(1), submatch(1))", 'g')
        " let rv = s:InterVikis."\n".rv
        let rv = rv."\n".s:InterVikis
    endif
    let rv = substitute(rv, '\n\n\+', '\n', 'g')
    return rv
endf


command! -nargs=1 -bang -complete=custom,VikiEditComplete VikiEdit :call VikiEdit(<q-args>, "<bang>")
command! -nargs=1 -bang -complete=custom,VikiEditComplete VikiEditInWin1 :call VikiEdit(<q-args>, "<bang>", 1)
command! -nargs=1 -bang -complete=custom,VikiEditComplete VikiEditInWin2 :call VikiEdit(<q-args>, "<bang>", 2)
command! -nargs=1 -bang -complete=custom,VikiEditComplete VikiEditInWin3 :call VikiEdit(<q-args>, "<bang>", 3)
command! -nargs=1 -bang -complete=custom,VikiEditComplete VikiEditInWin4 :call VikiEdit(<q-args>, "<bang>", 4)

command! VikiHome :call VikiEdit('*', '!')

finish "{{{1
_____________________________________________________________________________________

* Change Log
1.0
- Extended names: For compatibility reasons with other wikis, the anchor is 
now in the reference part.
- For compatibility reasons with other wikis, prepending an anchor with 
b:commentStart is optional.
- g:vikiUseParentSuffix
- Renamed variables & functions (basically s/Wiki/Viki/g)
- added a ftplugin stub, moved the description to a help file
- "[--]" is reference to current file
- Folding support (at section level)
- Intervikis
- More highlighting
- g:vikiFamily, b:vikiFamily
- VikiGoBack() (persistent history data)
- rudimentary LaTeX support ("soft" viki names)

1.1
- g:vikiExplorer (for viewing directories)
- preliminary support for "soft" anchors (b:vikiAnchorRx)
- improved VikiOpenSpecialProtocol(url); g:vikiOpenUrlWith_{PROTOCOL}, 
g:vikiOpenUrlWith_ANY
- improved VikiOpenSpecialFile(file); g:vikiOpenFileWith_{SUFFIX}, 
g:vikiOpenFileWith_ANY
- anchors may contain upper characters (but must begin with a lower char)
- some support for Mozilla ThunderBird mailbox-URLs (this requires spaces to 
be encoded as %20)
- changed g:vikiDefSep to '‡‡‡'

1.2
- syntax file: fix nested regexp problem
- deplate: conversion to html/latex; download from 
http://sourceforge.net/projects/deplate/
- made syntax a little bit more restrictive (*WORD* now matches /\*\w+\*/ 
instead of /\*\S+\*/)
- interviki definitions can now be buffer local variables, too
- fixed <SID>DecodeFileUrl(dest)
- some kind of compiler plugin (uses deplate)
- removed g/b:vikiMarkupEndsWithNewline variable
- saved all files in unix format (thanks to Grant Bowman for the hint)
- removed international characters from g:vikiLowerCharacters and 
g:vikiUpperCharacters because of difficulties with different encodings (thanks 
to Grant Bowman for pointing out this problem); non-english-speaking users have 
to set these variables in their vimrc file

1.3
- basic ctags support (see |viki-tags|)
- mini-ftplugin for bibtex files (use record labels as anchors)
- added mapping <LocalLeader><c-cr>: follow link in other window (if any)
- disabled the highlighting of italic char styles (i.e., /text/)
- the ftplugin doesn't set deplate as the compiler; renamed the compiler plugin to deplate
- syntax: sync minlines=50
- fix: VikiFoldLevel()

1.3.1
- fixed bug when VikiBack was called without a definitiv back-reference
- fixed problems with latin-1 characters

1.4
- fixed problem with table highlighting that could cause vim to hang
- it is now possible to selectivly disable simple or quoted viki names
- indent plugin

1.5
- distinguish between links to existing and non-existing files
- added key bindings <LL>vs (split) and <LL>vv (split vertically)
- added key bindings <LL>v1 through to <LL>v4: open the viki link under cursor 
in the windows 1 to 4
- handle variables g:vikiSplit, b:vikiSplit
- don't indent regions
- regions can be indented
- When a file doesn't exist, ESC or "n" aborts creation

1.5.1
- depends on multvals >= 3.8.0
- new viki family "AnyWord" (see |viki-any-word|), which turns any word into a 
potential viki link
- <LocalLeader>vq, VikiQuote: mark selected text as a quoted viki name 
(requires imaps.vim, vimscript #244 or vimscript #475)
- check for null links when pressing <space>, <cr>, ], and some other keys 
(defined in g:vikiMapKeys)
- a global suffix for viki files can be defined by g:vikiNameSuffix
- fix syntax problem when checking for links to inexistent files

1.5.2
- changed default markup of textstyles: __emphasize__, ''code''; the 
previous markup can be re-enabled by setting g:vikiTextstylesVer to 1)
- fixed problem with VikiQuote
- on follow link check for yet unsaved buffers too

1.6
- b:vikiInverseFold: Inverse folding of subsections
- support for some regions/commands/macros: #INC/#INCLUDE, #IMG, #Img 
(requires an id to be defined), {img}
- g:vikiFreeMarker: Search for the plain anchor text if no explicitly marked 
anchor could be found.
- new command: VikiEdit NAME ... allows editing of arbitrary viki names (also 
understands extended and interviki formats)
- setting the b:vikiNoSimpleNames to true prevents viki from recognizing 
simple viki names
- made some script local functions global so that it should be easier to 
integrate viki with other plugins
- fixed moving cursor on <SID>VikiMarkInexistent()
- fixed typo in b:VikiEnabled, which should be b:vikiEnabled (thanks to Ned 
Konz)

1.6.1
- removed forgotten debug message
- fixed indentation bug

1.6.2
- b:vikiDisableType
- Put AnyWord-related stuff into a file of its own.
- indentation for notices (!!!, ??? etc.)

1.6.3
- When creating a new file by following a link, the desired window number was 
ignored
- (VikiOpenSpecialFile) Escape blanks in the filename
- Set &include and &define (ftplugin)
- Set g:vikiFolds to '' to avoid using Headings for folds (which may cause a 
major slowdown on slower machines)
- renamed <SID>DecodeFileUrl(dest) to VikiDecomposeUrl()
- fixed problem with table highlighting
- file type URLs (file://) are now treated like special files
- indent: if g:vikiIndentDesc is '::', align a definition's description to the 
first non-blank position after the '::' separator

1.7
- g:vikiHomePage: If you call VikiEdit! (with "bang"), the homepage is opened 
first so that its customizations are in effect. Also, if you call :VikiHome or 
:VikiEdit *, the homepage is opened.
- basic highlighting & indentation of emacs-planner style task lists (sort of)
- command line completion for :VikiEdit
- new command/function VikiDefine for defining intervikis
- added <LocalLeader>ve map for :VikiEdit
- fixed problem in VikiEdit (when the cursor was on a valid viki link, the 
text argument was ignored)
- fixed opening special files/urls in a designated window
- fixed highlighting of comments
- vikiLowerCharacters and vikiUpperCharacters can be buffer local
- fixed problem when an url contained an ampersand
- fixed error message when the &hidden option wasn't set (see g:vikiHide)

1.8
- Fold lists too (see also g:vikiFolds)
- Allow interviki names in extended viki names (e.g., 
[[WIKI::WikiName][Display Name]])
- Renamed <SID>GetSimpleRx4SimpleWikiName() to 
VikiGetSimpleRx4SimpleWikiName() (required in some occasions; increased the 
version number so that we can check against it)
- Fix: Problem with urls/fnames containing '!' and other special characters 
(which now have to be escaped by the handler; so if you defined a custom 
handler, e.g. g:vikiOpenFileWith_ANY, please adapt its definition)
- Fix: VikiEdit! opens the homepage only when b:vikiEnabled is defined in the 
current buffer (we assume that for the homepage the global configuration is in 
effect)
- Fix: Problem when g:vikiMarkInexistent was false/0
- Fix: Removed \c from the regular expression for extended names, which caused 
FindNext to malfunction and caused a serious slowdown when matching of 
bad/unknown links
- Fix: Re-set viki minor mode after entering a buffer
- The state argument in Viki(Minor)Mode is now mostly ignored
- Fix: A simple name's anchor was ignored

" vim: ff=unix
