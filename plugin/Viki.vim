" Viki.vim -- A pseude mini-wiki minor mode for Vim
" @Author:      Thomas Link (samul AT web.de)
" @License:     GPL (see http://www.gnu.org/licenses/gpl.txt)
" @Created:     08-Dec-2003.
" @Last Change: 19-Dez-2003.
" @Revision: 380
" 
" Description:
" This plugin adds wiki-like hypertext capabilities to any document. Just type 
" :VikiMinorMode and all wiki names will be highlighted. If you press <c-cr> 
" when the cursor is over a wiki name, you jump to (or create) the referred page.
"
" If the variables b:getWikiLink or b:getExtWikiLink exist, their values are 
" used as function names for returning the current wiki name's definition 
" (="name|destination|anchor").
"
" If the variables b:editWikiPage or b:createWikiPage exist, their values are
" interpreted as _command_ names for editing readable or creating new wiki 
" pages.
"
" Wiki Names:
" A wiki name is either:
" 1. a word in CamelCase
" 2. an extended wiki name of the form: [[destination]], 
"    [[destination][name]], or [[destination][name#anchor]]
" 3. an URL (see g:WikiUrlRx): http, ftp, mailto
" 4. a reference to an anchor in the current file: :#anchor
"
" If the variable b:wikiNameSuffix is defined, it will be added to simple wiki 
" names so that the simple wiki name "OtherFile" refers to "OtherFile.suffix" 
" -- e.g. for interlinking LaTeX-files.
"
" Opening extended wiki names referring to files with suffixes matching one of 
" g:WikiSpecialFiles (e.g. "[[test.jpg]]") can be delegated to the operating 
" system -- see VikiOpenSpecialFile(filename).
"
" In extended wiki names, destination path is relative to the document's 
" current directory if it doesn't match "^\([a-z]:\|[a-z]\+://\)". I.e.  
" [[../test]] refers to the directory parent to the document's directory.
"
" Adding #[a-z0-9]\+ to the wiki name denotes a reference to a specific anchor.  
" Examples for wiki names referring to an anchor:
"
" 	ThatPage#there
" 	[[anyplace/filename.txt][#there]]
" 	[[anyplace/filename.txt][Filename#there]]
"
" A anchor is marked as "^".b:commentStart."#[a-z0-9]\+" in the destination 
" file. Examples ('|' = beginning of the line):
"
" - LaTeX file, b:commentStart is set to "%"
"   |%#anchor
" - Text file, no b:commentStart is defined
"   |#anchor
" 
" Default Key Binding:
" <c-cr>   ... VikiMaybeFollowWikiLink: Usually only works when the cursor is 
" over a wiki syntax group -- if the second argument is 1 it tries to 
" interpret the text under the cursor as a wiki name anyway.
" 
" Prerequirements:
" - multvals.vim (vimscript #171)
" 
" Commands:
" - VikiMinorMode
" - VikiMinorModeMaybe (don't complain when Viki is already enabled)
" 
" Functions:
" - VikiMinorMode(state)
" - VikiMaybeFollowWikiLink()
" - VikiFindAnchor(anchor)
" - VikiOpenSpecialFile(filename)
" - VikiOpenSpecialProtocol(url)
"
" Variables:
" - g:WikiLowerCharacters
" - g:WikiAnchorMarker
" - g:WikiSimpleNameRx
" - g:WikiSimpleNameNameIdx
" - g:WikiSimpleNameDestIdx
" - g:WikiSimpleNameAnchorIdx
" - g:WikiExtendedNameRx
" - g:WikiExtendedNameNameIdx
" - g:WikiExtendedNameDestIdx
" - g:WikiExtendedNameAnchorIdx
" - g:WikiSpecialFiles, b:WikiSpecialFiles
" - g:WikiSpecialProtocols, b:WikiSpecialProtocols
"
" TODO:
" - Recheck the key binding
" - Different highlighting for existing and non-existing wiki pages
" - Check for protocols/remote pages etc.
" - History (integrate with tags stack?)
" - A real wiki mode with more highlighting -- although this plugin should be 
"   more of an add-on to other modes (e.g. LaTeX) and not a self-contained 
"   full-fledged wiki mode with html rendering etc.
" - Handlers for wiki names refering to images, sound files and the like.
" - Soft/pseudo anchors (e.g. \label{anchor} in LaTeX mode)
" - Soft/pseudo wiki names (e.g. \include{destination} in LaTeX mode)
" - ...
" 

let s:wikiDefNil  = "*"
let s:wikiDefSep  = "|"
let s:wikiSelfEsc = ""
let s:wikiSelfRef = ":"

if !exists("g:WikiLowerCharacters")
    let g:WikiLowerCharacters = "a-zäöüßáàéèíìóòçñ"
endif

if !exists("g:WikiSimpleNameRx")
    let g:WikiSimpleNameRx = "\\C\\(\\<[A-ZÄÖÜ][".g:WikiLowerCharacters."]\\+\\([A-ZÄÖÜ][".g:WikiLowerCharacters."0-9]\\+\\)\\+\\|".s:wikiSelfEsc.s:wikiSelfRef."\\)\\(#\\([".g:WikiLowerCharacters."0-9]\\+\\)\\)\\?\\>"
    let g:WikiSimpleNameNameIdx   = 1
    let g:WikiSimpleNameDestIdx   = 0
    let g:WikiSimpleNameAnchorIdx = 4
endif

if !exists("g:WikiUrlRx")
    let g:WikiUrlRx = "\\(\\<\\(https\\?\\|ftps\\?\\):\\/\\/[A-Za-z0-9.:/%?=&_~-]\\+\\|mailto:[a-bA-Z.@%0-9]\\+\\)\\(#\\([A-Za-z0-9]\\+\\)\\>\\)\\?"
    let g:WikiUrlNameIdx   = 0
    let g:WikiUrlDestIdx   = 1
    let g:WikiUrlAnchorIdx = 4
endif

if !exists("g:WikiExtendedNameRx")
    let g:WikiExtendedNameRx="\\[\\[\\([^]]\\+\\)\\]\\(\\[\\([^]#]\\+\\)\\?\\(#\\([".g:WikiLowerCharacters."0-9]\\+\\)\\)\\?\\]\\)\\?\\]"
    let g:WikiExtendedNameNameIdx   = 3
    let g:WikiExtendedNameDestIdx   = 1
    let g:WikiExtendedNameAnchorIdx = 5
endif

if !exists("g:WikiAnchorMarker")
    let g:WikiAnchorMarker = "#"
endif

if !exists("g:WikiSpecialFiles")
    let g:WikiSpecialFiles = "jpg\\|gif\\|bmp\\|pdf\\|dvi\\|ps"
endif

if !exists("*VikiOpenSpecialFile")
    if has("win32")
        fun! VikiOpenSpecialFile(filename)
            "             if &shell =~? "\\<cmd\\.exe"
            "                 exe ":!start ".a:filename
            "             else
            exe ":!cmd /c start ".a:filename
            "             endif
        endfun
    else
        fun! VikiOpenSpecialFile(filename)
            throw "Viki: Please redefine VikiOpenSpecialFile(filename) first!"
        endfun
    endif
endif

if !exists("g:WikiSpecialProtocols")
    let g:WikiSpecialProtocols = "https\\?\\|ftps\\?"
endif

if !exists("*VikiOpenSpecialProtocol")
    if has("win32")
        fun! VikiOpenSpecialProtocol(url)
            "             if &shell =~? "\\<cmd\\.exe"
            "                 exe ":!start ".a:url
            "             else
            exe ":!cmd /c start ".a:url
            "             endif
        endfun
    else
        fun! VikiOpenSpecialProtocol(url)
            throw "Viki: Please redefine VikiOpenSpecialFile(filename) first!"
        endfun
    endif
endif

fun! VikiMinorMode(state)
    if exists("b:VikiEnabled")
        if a:state == 1
            throw "Viki is already enabled."
        elseif a:state == 0
            throw "Viki can't be disabled (not yet)."
        elseif a:state == -1
        else
            throw "VikiMinorMode(): state should be one of: -1, 1, 0"
        endif
    elseif a:state
        if version < 508
            command! -nargs=+ WikiHiLink hi link <args>
        else
            command! -nargs=+ WikiHiLink hi def link <args>
        endif

        "TODO: I guess this should be done only once
        exe "syn match wikiLink /" . g:WikiSimpleNameRx . "/"
        exe "syn match wikiURL /" . g:WikiUrlRx . "/"
        exe "syn match wikiExtendedLink /" . g:WikiExtendedNameRx . "/"
        hi wikiHyperLink guibg=orange guifg=black
        WikiHiLink wikiLink wikiHyperLink
        WikiHiLink wikiURL wikiHyperLink
        WikiHiLink wikiExtendedLink wikiHyperLink

        "if exists("b:WikiIncludesRx")
        "    exe "syn match wikiIncludes /" . b:WikiIncludesRx . "/"
        "    WikiHiLink wikiIncludes wikiHyperLink
        "endif
        
        delcommand WikiHiLink
        
        "nnoremap <buffer> <c-cr> "=VikiMaybeFollowWikiLink("",1)<cr>p
        "inoremap <buffer> <c-cr> <c-r>=VikiMaybeFollowWikiLink("",1)<cr>
        "nmap <buffer> <c-cr> "=VikiMaybeFollowWikiLink(1,1)<cr>p
        "imap <buffer> <c-cr> <c-r>=VikiMaybeFollowWikiLink(1,1)<cr>
        "exe "nnoremap <buffer> <c-cr> \"=VikiMaybeFollowWikiLink(\"".maparg("<c-cr>")."\",1)<cr>p"
        "exe "inoremap <buffer> <c-cr> <c-r>=VikiMaybeFollowWikiLink(\"".maparg("<c-cr>", "i")."\",1)<cr>"
        "nnoremap <buffer> <c-cr> "=VikiMaybeFollowWikiLink(0)<cr>p
        "inoremap <buffer> <c-cr> <c-r>=VikiMaybeFollowWikiLink(0)<cr>
        nnoremap <buffer> <c-cr> :call VikiMaybeFollowWikiLink(0,1)<cr>
        inoremap <buffer> <c-cr> <c-o><c-cr>
        "nnoremap <buffer> <s-c-cr> :call VikiMaybeFollowWikiLink(0,1)<cr>
        "inoremap <buffer> <s-c-cr> <c-o><c-cr>
        
        let b:VikiEnabled = 1
    else
        throw "Viki is already disabled."
    endif
endfun

command! VikiMinorMode call VikiMinorMode(1)
command! VikiMinorModeMaybe call VikiMinorMode(-1)

" find a:anchor in the current file
fun! VikiFindAnchor(anchor)
    if a:anchor != s:wikiDefNil
        if exists("b:commentStart")
            let prefix = b:commentStart . g:WikiAnchorMarker
        else
            let prefix = g:WikiAnchorMarker
        endif
        exe "0/^" . prefix . a:anchor
    endif
endfun

fun! <SID>DoOpenWikiLink(filename, anchor)
    exe "e " . a:filename
    VikiMinorMode
    call VikiFindAnchor(a:anchor)
endfun

fun! <SID>DoFollowWikiLink(def)
    let name   = MvElementAt(a:def, s:wikiDefSep, 0)
    let dest   = MvElementAt(a:def, s:wikiDefSep, 1)
    let anchor = MvElementAt(a:def, s:wikiDefSep, 2)
	if dest == s:wikiDefNil
		throw "No target? ".a:def
    elseif name == s:wikiSelfRef              "reference to self
        call VikiFindAnchor(anchor)
    else
        if filereadable(dest)                 "reference to a local, already existing file
            let buf = bufnr(simplify(dest))
            if buf >= 0
                exe "buffer ".buf
                VikiMinorModeMaybe
                call VikiFindAnchor(anchor)
            elseif exists("b:editWikiPage")
                exe b:editWikiPage . " " . dest
            else
                call <SID>DoOpenWikiLink(dest, anchor)
            endif
        else                                  "reference to a remote or yet inexistent page
            if exists("b:WikiSpecialProtocols")
                let wikiSpecialProtocols = b:WikiSpecialProtocols."\\|".g:WikiSpecialProtocols
            else
                let wikiSpecialProtocols = g:WikiSpecialProtocols
            endif
            if dest =~ "^\\(".wikiSpecialProtocols."\\):"
                call VikiOpenSpecialProtocol(dest)
            else
                if exists("b:WikiSpecialFiles")
                    let wikiSpecialFiles = b:WikiSpecialFiles."\\|".g:WikiSpecialFiles
                else
                    let wikiSpecialFiles = g:WikiSpecialFiles
                endif
                if dest =~ "\\.\\(".wikiSpecialFiles."\\)$"
                    call VikiOpenSpecialFile(dest)
                elseif exists("b:createWikiPage")
                    exe b:createWikiPage . " " . dest
                elseif input("File doesn't exists. Create '".dest."'? (Y/n) ") != "n"
                    call <SID>DoOpenWikiLink(dest, anchor)
                endif
            endif
        endif
    endif
    return ""
endfun

fun! <SID>MakeWikiDefPart(txt)
    if a:txt == ""
        return s:wikiDefNil
    else
        return a:txt
    endif
endfun

fun! <SID>MakeWikiDef(name, dest, anchor)
    if a:name == s:wikiDefSep || a:dest == s:wikiDefSep || a:anchor == s:wikiDefSep
        throw "Viki: A wiki definition must not include ".s:wikiDefSep
    else
        let arr = MvAddElement("",  s:wikiDefSep, <SID>MakeWikiDefPart(a:name))
        let arr = MvAddElement(arr, s:wikiDefSep, <SID>MakeWikiDefPart(a:dest))
        let arr = MvAddElement(arr, s:wikiDefSep, <SID>MakeWikiDefPart(a:anchor))
        return arr
    endif
endfun

fun! <SID>GetWikiNamePart(txt, erx, idx, errorMsg)
    if a:idx
        let rv = substitute(a:txt, "^".a:erx."$", "\\".a:idx, "")
        if rv == ""
            return s:wikiDefNil
        else
            return rv
        endif
    else
        return s:wikiDefNil
    endif
endfun

fun! <SID>GetWikiLink(erx, nameIdx, destIdx, anchorIdx)
" fun! GetWikiLink(erx, nameIdx, destIdx, anchorIdx)
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
        let name   = <SID>GetWikiNamePart(part, a:erx, a:nameIdx, "no name")
        let dest   = <SID>GetWikiNamePart(part, a:erx, a:destIdx, "no destination")
        let anchor = <SID>GetWikiNamePart(part, a:erx, a:anchorIdx, "no anchor")
        return <SID>MakeWikiDef(name, dest, anchor)
    else
        throw "Viki: Malformed wiki name: " . txt . " (".a:erx.")"
    endif
endfun

fun! <SID>CompleteSimpleWikiNameDef(def)
    let name   = MvElementAt(a:def, s:wikiDefSep, 0)
    let dest   = MvElementAt(a:def, s:wikiDefSep, 1)
    let anchor = MvElementAt(a:def, s:wikiDefSep, 2)
    if name == s:wikiDefNil
        throw "Viki: Malformed simple wiki name (no name): ".a:def
    endif
    if dest == s:wikiDefNil
        if exists("b:wikiNameSuffix")
            let dest=expand("%:p:h")."/".name.b:wikiNameSuffix
        else
            let dest=expand("%:p:h")."/".name
        endif
    else
        throw "Viki: Malformed simple wiki name (destination): ".a:def
    endif
    return <SID>MakeWikiDef(name, dest, anchor)
endfun

fun! <SID>CompleteExtendedWikiNameDef(def)
    let name   = MvElementAt(a:def, s:wikiDefSep, 0)
    let dest   = MvElementAt(a:def, s:wikiDefSep, 1)
    let anchor = MvElementAt(a:def, s:wikiDefSep, 2)
    if dest == s:wikiDefNil
        throw "Viki: Malformed extended wiki name (no destination): ".a:def
    elseif dest =~? "^[a-z]:"
        " an absolute dos path
    elseif dest =~? "^[a-z]\\+://"
        " some protocol, yet unhandled
    elseif dest =~ "^\\~"
        let dest = $HOME . strpart(dest, 1)
    else
        " a relative path
        let dest = expand("%:p:h")."/".dest
    endif
    if name == s:wikiDefNil
        let name = dest
    endif
    return <SID>MakeWikiDef(name, dest, anchor)
endfun

fun! <SID>WikiLinkNotFoundEtc(oldmap, ignoreSyntax)
    if a:oldmap == ""
        throw "Viki: Show me the way to the next wiki name or I have to ... ".a:ignoreSyntax.":".getline(".")
    elseif a:oldmap == 1
        return "\<c-cr>"
    else
        return a:oldmap
    endif
endfun

" oldmap: If there isn't a wiki link under the cursor:
" 	""       ... throw error 
" 	1        ... return \<c-cr>
" 	whatever ... return whatever
" ignoreSyntax: If there isn't a wiki syntax group under the cursor:
"   0 ... no wiki name found
"   1 ... try to find a wiki name matching a the viki regexp
fun! VikiMaybeFollowWikiLink(oldmap, ignoreSyntax)
    try
        let synName = synIDattr(synID(line('.'),col('.'),0),"name")
        if synName =~# "^wiki"
            let ignoreSyntax = 0
        else
            let ignoreSyntax = a:ignoreSyntax
        endif
        if synName ==# "wikiLink" || a:ignoreSyntax == 1
            if exists("b:getWikiLink")
                exe "let def = " . b:getWikiLink."()"
            else
                let def=<SID>GetWikiLink(g:WikiSimpleNameRx, g:WikiSimpleNameNameIdx, 
                            \ g:WikiSimpleNameDestIdx, g:WikiSimpleNameAnchorIdx)
            endif
            return <SID>DoFollowWikiLink( <SID>CompleteSimpleWikiNameDef(def) )
        elseif synName ==# "wikiExtendedLink" || a:ignoreSyntax == 2
            if exists("b:getExtWikiLink")
                exe "let def = " . b:getExtWikiLink."()"
            else
                let def=<SID>GetWikiLink(g:WikiExtendedNameRx, g:WikiExtendedNameNameIdx, 
                            \ g:WikiExtendedNameDestIdx, g:WikiExtendedNameAnchorIdx)
            endif
            return <SID>DoFollowWikiLink( <SID>CompleteExtendedWikiNameDef(def) )
        elseif synName ==# "wikiURL" || a:ignoreSyntax == 3
            echo "DBG: URL"
            if exists("b:getURLWiki")
                exe "let def = " . b:getURLWiki . "()"
            else
                let def=<SID>GetWikiLink(g:WikiUrlRx, g:WikiUrlNameIdx, 
                            \ g:WikiUrlDestIdx, g:WikiUrlAnchorIdx)
            endif
            return <SID>DoFollowWikiLink( <SID>CompleteExtendedWikiNameDef(def) )
        else
            call <SID>WikiLinkNotFoundEtc(a:oldmap, a:ignoreSyntax)
        endif
    catch /^Viki:/
        if a:ignoreSyntax == 1 || a:ignoreSyntax == 2
            return VikiMaybeFollowWikiLink(a:oldmap, a:ignoreSyntax + 1)
        else
            call <SID>WikiLinkNotFoundEtc(a:oldmap, a:ignoreSyntax)
        endif
    endtry
endfun

