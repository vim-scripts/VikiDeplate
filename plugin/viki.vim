" Viki.vim -- A pseudo mini-wiki minor mode for Vim
" @Author:      Thomas Link (samul AT web.de)
" @License:     GPL (see http://www.gnu.org/licenses/gpl.txt)
" @Created:     08-Dec-2003.
" @Last Change: 2007-05-13.
" @Revision: 2.0.2011
"
" vimscript #861
"
" Short Description:
" This plugin adds wiki-like hypertext capabilities to any document.  Just 
" type :VikiMinorMode and all wiki names will be highlighted. If you press 
" <c-cr> when the cursor is over a wiki name, you jump to (or create) the 
" referred page. When invoked as :VikiMode or via :set ft=viki additional 
" highlighting is provided.
"
" Requirements:
" - tlib.vim
" 
" Optional Enhancements:
" - imaps.vim (vimscript #244 or #475 for |:VimQuote|)
" - kpsewhich (not a vim plugin :-) for vikiLaTeX
"
" TODO:
" - cache inexistent patterns (check for file atime & size)
" - VikiEdit completion for names containing blanks
" - use netrw external file handlers instead of maintaining own handlers
" - File names containing #
" - Per Interviki simple name patterns
" - Allow Wiki links like ::Word or even ::word (not in minor mode due 
"   possible conflict with various programming languages?)
" - New region: file listing (auto-generate/update a file listing; i.e.  the 
"   region content is automatically generated when opening a file or so)
" - :VikiRename command: rename links/files (requires a cross-plattform grep 
"   or similar; maybe 7.0)
" - don't know how to deal with viki names that span several lines (e.g.  in 
"   LaTeX mode)
"   
" Change Log: (See bottom of file)

if &cp || exists("loaded_viki") "{{{2
    finish
endif
if !exists('loaded_tlib') || loaded_tlib < 4
    echoerr 'tlib >= 0.4 is required'
    finish
endif
" if !exists('loaded_multvals') "{{{2
"     runtime plugin/multvals.vim
" endif
" if !exists("loaded_multvals") || loaded_multvals < 308 "{{{2
"     echoerr "Viki.vim requires multvals.vim >= 308"
"     finish
" endif
let loaded_viki = 200

let g:vikiDefNil  = ''
let g:vikiDefSep  = "\n"

let s:vikiSelfEsc = '\'
let g:vikiSelfRef = '.'

" let s:vikiEnabledID = loaded_viki .'_'. strftime('%c')

if !exists("g:vikiEnabled") "{{{2
    let g:vikiEnabled = 1
endif

if !exists("tlist_viki_settings") "{{{2
    let tlist_viki_settings="deplate;s:structure"
endif

if !exists("g:vikiLowerCharacters") "{{{2
    let g:vikiLowerCharacters = "a-z"
endif

if !exists("g:vikiUpperCharacters") "{{{2
    let g:vikiUpperCharacters = "A-Z"
endif

if !exists("g:vikiMenuPrefix") "{{{2
    let g:vikiMenuPrefix = "Plugin.Viki."
endif

if !exists("g:vikiSpecialProtocols") "{{{2
    let g:vikiSpecialProtocols = 'https\?\|ftps\?\|nntp\|mailto\|mailbox\|file'
endif

if !exists("g:vikiSpecialProtocolsExceptions") "{{{2
    let g:vikiSpecialProtocolsExceptions = ""
endif

if !exists("g:vikiSpecialFiles") "{{{2
    let g:vikiSpecialFiles = [
                \ 'aac',
                \ 'aif',
                \ 'aiff',
                \ 'au',
                \ 'avi',
                \ 'bmp',
                \ 'doc',
                \ 'dvi',
                \ 'eps',
                \ 'eps',
                \ 'gif',
                \ 'htm',
                \ 'html',
                \ 'jpeg',
                \ 'jpg',
                \ 'm3u',
                \ 'mp1',
                \ 'mp2',
                \ 'mp3',
                \ 'mp4',
                \ 'mpeg',
                \ 'mpg',
                \ 'odg',
                \ 'ods',
                \ 'odt',
                \ 'ogg',
                \ 'pdf',
                \ 'png',
                \ 'ppt',
                \ 'ps',
                \ 'rtf',
                \ 'voc',
                \ 'wav',
                \ 'wma',
                \ 'wmf',
                \ 'wmv',
                \ 'xhtml',
                \ 'xls',
                \ ]
endif

if !exists("g:vikiSpecialFilesExceptions") "{{{2
    let g:vikiSpecialFilesExceptions = ""
endif

fun! VikiHyperLinkColor() "{{{3
    if exists("g:vikiHyperLinkColor")
        return g:vikiHyperLinkColor
    elseif &background == "light"
        return "DarkBlue"
    else
        return "LightBlue"
    endif
endf

fun! VikiInexistentColor() "{{{3
    if exists("g:vikiInexistentColor")
        return g:vikiInexistentColor
    elseif &background == "light"
        return "DarkRed"
    else
        return "Red"
    endif
endf

if !exists("g:vikiUseParentSuffix") | let g:vikiUseParentSuffix = 0      | endif "{{{2
if !exists("g:vikiNameSuffix")      | let g:vikiNameSuffix = ""          | endif "{{{2
if !exists("g:vikiAnchorMarker")    | let g:vikiAnchorMarker = "#"       | endif "{{{2
if !exists("g:vikiFreeMarker")      | let g:vikiFreeMarker = 0           | endif "{{{2
if !exists("g:vikiNameTypes")       | let g:vikiNameTypes = "csSeuixwf"  | endif "{{{2
if !exists("g:vikiExplorer")        | let g:vikiExplorer = "Sexplore"    | endif "{{{2
if !exists("g:vikiNoWrapper")       | let g:vikiNoWrapper = '\cexplore'  | endif "{{{2
if !exists("g:vikiMarkInexistent")  | let g:vikiMarkInexistent = 1       | endif "{{{2
if !exists("g:vikiMapInexistent")   | let g:vikiMapInexistent = 1        | endif "{{{2
if !exists("g:vikiMapKeys")         | let g:vikiMapKeys = "]).,;:!?\"' " | endif "{{{2
if !exists("g:vikiMapQParaKeys")    | let g:vikiMapQParaKeys = "\n"      | endif "{{{2
if !exists("g:vikiMapBeforeKeys")   | let g:vikiMapBeforeKeys = ']'      | endif "{{{2
if !exists("g:vikiFamily")          | let g:vikiFamily = ""              | endif "{{{2
if !exists("g:vikiDirSeparator")    | let g:vikiDirSeparator = "/"       | endif "{{{2
if !exists("g:vikiTextstylesVer")   | let g:vikiTextstylesVer = 2        | endif "{{{2
if !exists("g:vikiBasicSyntax")     | let g:vikiBasicSyntax = 0          | endif "{{{2
if !exists("g:vikiFancyHeadings")   | let g:vikiFancyHeadings = 0        | endif "{{{2
if !exists("g:vikiFoldBodyLevel")   | let g:vikiFoldBodyLevel = 5        | endif "{{{2
if !exists("g:vikiHomePage")        | let g:vikiHomePage = ''            | endif "{{{2
if !exists("g:vikiHide")            | let g:vikiHide = ''                | endif "{{{2
if !exists("g:vikiFolds")           | let g:vikiFolds = 'hf'             | endif "{{{2
if !exists("g:vikiIndex")           | let g:vikiIndex = 'index'          | endif "{{{2
if !exists("g:vikiFeedbackMin")     | let g:vikiFeedbackMin = &lines     | endif "{{{2
if !exists("g:vikiMapLeader")       | let g:vikiMapLeader = '<LocalLeader>v' | endif "{{{2
if !exists("g:vikiAutoMarks")       | let g:vikiAutoMarks = 1            | endif "{{{2
" if !exists("g:vikiOpenInWindow")    | let g:vikiOpenInWindow = ''        | endif "{{{2
if !exists("g:vikiHighlightMath")   | let g:vikiHighlightMath = ''       | endif "{{{2
if !exists("g:vikiSaveHistory")     | let g:vikiSaveHistory = 0          | endif "{{{2
if !exists("g:VIKIBACKREFS")        | let g:VIKIBACKREFS = {}              | endif "{{{2

if v:version >= 700 && !exists("g:vikiHyperWordsFiles") "{{{2
    let g:vikiHyperWordsFiles = [
                \ './.vikiWords',
                \ get(split(&rtp, ','), 0).'/vikiWords.txt'
                \ ]
endif

if !exists("g:vikiMapFunctionality") "{{{2
    " b     ... go back
    " c     ... follow link (c-cr)
    " e     ... edit
    " F     ... find
    " f     ... follow link (<LocalLeader>v)
    " i     ... check for inexistant destinations
    " I     ... map keys in g:vikiMapKeys and g:vikiMapQParaKeys
    " m[fb] ... map mouse (depends on f or b)
    " p     ... edit parent (or backlink)
    " q     ... quote
    " tF    ... tab as find
    " Files ... #Files related
    " let g:vikiMapFunctionality      = 'mf mb tF c q e i I Files'
    let g:vikiMapFunctionality      = 'ALL'
endif
if !exists("g:vikiMapFunctionalityMinor") "{{{2
    let g:vikiMapFunctionalityMinor = 'f b p mf mb tF c q e i'
endif

if !exists('g:vikiOpenFileWith_ws') && exists(':WsOpen') "{{{2
    fun! s:OpenAsWorkspace(file)
        exec 'WsOpen '. escape(a:file, ' &!%')
        exec 'lcd '. escape(fnamemodify(a:file, ':p:h'), ' &!%')
    endf
    let g:vikiOpenFileWith_ws = "call <SID>OpenAsWorkspace('%{FILE}')"
    call add(g:vikiSpecialFiles, 'ws')
endif
if type(g:vikiSpecialFiles) != 3
    echoerr 'Viki: g:vikiSpecialFiles must be a list'
endif
" TAssert IsList(g:vikiSpecialFiles)

if !exists("g:vikiOpenFileWith_ANY") "{{{2
    let g:vikiOpenFileWith_ANY = "exec 'silent !". g:netrw_browsex_viewer ." '. escape('%{FILE}', ' &!%')"
    " if has("win32")
    "     let g:vikiOpenFileWith_ANY = "exec 'silent !cmd /c start '. escape('%{FILE}', ' &!%')"
    " elseif $GNOME_DESKTOP_SESSION_ID != ""
    "     let g:vikiOpenFileWith_ANY = "exec 'silent !gnome-open '. escape('%{FILE}', ' &!%')"
    " elseif $KDEDIR != ""
    "     let g:vikiOpenFileWith_ANY = "exec 'silent !kfmclient exec '. escape('%{FILE}', ' &!%')"
    " endif
endif

if !exists('*VikiOpenSpecialFile') "{{{2
    fun! VikiOpenSpecialFile(file) "{{{3
        " let proto = tolower(matchstr(a:file, '\c\.\zs[a-z]\+$'))
        let proto = tolower(fnamemodify(a:file, ':e'))
        if exists('g:vikiOpenFileWith_'. proto)
            let prot = g:vikiOpenFileWith_{proto}
        elseif exists('g:vikiOpenFileWith_ANY')
            let prot = g:vikiOpenFileWith_ANY
        else
            let prot = ''
        endif
        if prot != ''
            let openFile = VikiSubstituteArgs(prot, 'FILE', a:file)
            exec openFile
        else
            throw 'Viki: Please define g:vikiOpenFileWith_'. proto .' or g:vikiOpenFileWith_ANY!'
        endif
    endf
endif

if !exists('g:vikiOpenUrlWith_mailbox') "{{{2
    let g:vikiOpenUrlWith_mailbox="call VikiOpenMailbox('%{URL}')"
    fun! VikiOpenMailbox(url) "{{{3
        exec VikiDecomposeUrl(strpart(a:url, 10))
        let idx = matchstr(args, 'number=\zs\d\+$')
        if filereadable(filename)
            call VikiOpenLink(filename, '', 0, 'go '.idx)
        else
            throw 'Viki: Can't find mailbox url: '.filename
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
            throw 'Viki: Can't find file url: '.filename
        endif
    endf
endif

if !exists("g:vikiOpenUrlWith_ANY") "{{{2
    " let g:vikiOpenUrlWith_ANY = "exec 'silent !". g:netrw_browsex_viewer ." '. escape('%{URL}', ' &!%')"
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
        let prot  = 'g:vikiOpenUrlWith_'. proto
        let protp = exists(prot)
        if !protp
            let prot  = 'g:vikiOpenUrlWith_ANY'
            let protp = exists(prot)
        endif
        if protp
            exec 'let openURL = '. prot
            let openURL = VikiSubstituteArgs(openURL, 'URL', a:url)
            TLogVAR openURL
            exec openURL
        else
            throw 'Viki: Please define g:vikiOpenUrlWith_'. proto .' or g:vikiOpenUrlWith_ANY!'
        endif
    endf
endif

fun! s:ResetSavedCursorPosition() "{{{3
    let s:cursorSet  = -1
    let s:cursorCol  = -1
    let s:cursorVCol = -1
    let s:cursorLine = -1
    let s:cursorWinTLine = -1
    let s:cursorEol  = 0
    let s:lazyredraw = &lazyredraw
endf

call s:ResetSavedCursorPosition()

fun! s:sprintf1(string, arg) "{{{3
    if exists('printf')
        return printf(string, a:arg)
    else
        let rv = substitute(a:string, '\C[^%]\zs%s', escape(a:arg, '"\'), 'g')
        let rv = substitute(rv, '%%', '%', 'g')
        return rv
    end
endf

let s:InterVikiRx = '^\(['. g:vikiUpperCharacters .']\+\)::\(.*\)$'
let s:InterVikis  = []

" VikiDefine(name, prefix, ?suffix="*", ?index="Index.${suffix}")
" suffix == "*" -> g:vikiNameSuffix
fun! VikiDefine(name, prefix, ...) "{{{3
    if a:name =~ '[^A-Z]'
        throw 'Invalid interviki name: '. a:name
    endif
    call add(s:InterVikis, a:name .'::')
    call sort(s:InterVikis)
    let g:vikiInter{a:name}          = a:prefix
    let g:vikiInter{a:name}_suffix   = a:0 >= 1 && a:1 != '*' ? a:1 : g:vikiNameSuffix
    let index = a:0 >= 2 && a:2 != '' ? a:2 : g:vikiIndex
    let findex = fnamemodify(g:vikiInter{a:name} .'/'. index . g:vikiInter{a:name}_suffix, ':p')
    if filereadable(findex)
        let vname = VikiMakeName(a:name, index, 0)
        let g:vikiInter{a:name}_index = index
    else
        " let vname = '[['. a:name .'::]]'
        let vname = a:name .'::'
    end
    let vname = escape(vname, ' \%#')
    exec 'command! '. a:name .' VikiEdit! '. vname
    if g:vikiMenuPrefix != ''
        exec 'amenu '. g:vikiMenuPrefix . a:name .' :VikiEdit! '. vname .'<cr>'
    endif
endf

command! -nargs=+ VikiDefine call VikiDefine(<f-args>)

if g:vikiMenuPrefix != '' "{{{2
    exec 'amenu '. g:vikiMenuPrefix .'Home :VikiHome<cr>'
    exec 'amenu '. g:vikiMenuPrefix .'-SepViki1- :'
endif

fun! s:AddToRegexp(regexp, pattern) "{{{3
    if a:pattern == ''
        return a:regexp
    elseif a:regexp == ''
        return a:pattern
    else
        return a:regexp .'\|'. a:pattern
    endif
endf

fun! s:CanonicFilename(fname) "{{{3
    return substitute(simplify(a:fname), '[\/]\+', '/', 'g')
endf

fun! s:VikiFindRx() "{{{3
    let rx = s:AddToRegexp('', b:vikiSimpleNameSimpleRx)
    let rx = s:AddToRegexp(rx, b:vikiExtendedNameSimpleRx)
    let rx = s:AddToRegexp(rx, b:vikiUrlSimpleRx)
    return rx
endf

fun! s:EditWrapper(cmd, fname) "{{{3
    let fname = escape(simplify(a:fname), ' %#')
    if a:cmd =~ g:vikiNoWrapper
        exec a:cmd .' '. fname
    else
        try
            if g:vikiHide == 'hide'
                exec 'hide '. a:cmd .' '. fname
            elseif g:vikiHide == 'update'
                update
                exec a:cmd .' '. fname
            else
                exec a:cmd .' '. fname
            endif
        catch /^Vim\%((\a\+)\)\=:E37/
            echoerr "Vim raised E37: You tried to abondon a dirty buffer (see :h E37)"
            echoerr "Viki: You may want to reconsider your g:vikiHide or 'hidden' settings"
        catch /^Vim\%((\a\+)\)\=:E325/
        endtry
    endif
endf

" VikiFind(flag, ?count=0, ?rx=nil)
fun! VikiFind(flag, ...) "{{{3
    let rx = (a:0 >= 2 && a:2 != '') ? a:2 : s:VikiFindRx()
    if rx != ""
        let i = a:0 >= 1 ? a:1 : 0
        while i >= 0
            call search(rx, a:flag)
            let i = i - 1
        endwh
    endif
endf

command! -count VikiFindNext call VikiDispatchOnFamily('VikiFind', '', '',  <count>)
command! -count VikiFindPrev call VikiDispatchOnFamily('VikiFind', '', 'b', <count>)

fun! VikiFindPrevHeading()
    let vikisr=@/
    let cl = getline('.')
    if cl =~ '^\*'
        let head = matchstr(cl, '^\*\+')
        let head = '*\{1,'. len(head) .'}'
    else
        let head = '*\+'
    endif
    call search('\V\^'. head .'\s', 'bW')
    let @/=vikisr
endf

fun! VikiFindNextHeading()
    let pos = getpos('.')
    let cl  = getline('.')
    " TLogDBG 'line0='. cl
    if cl =~ '^\*'
        let head = matchstr(cl, '^\*\+')
        let head = '*\{1,'. len(head) .'}'
    else
        let head = '*\+'
    endif
    " TLogDBG 'head='. head
    call setpos('.', pos)
    let vikisr = @/
    call search('\V\^'. head .'\s', 'W')
    let @/=vikisr
endf

" s:IsSupportedType(type, ?types=b:vikiNameTypes)
fun! s:IsSupportedType(type, ...) "{{{3
    if a:0 >= 1
        let types = a:1
    elseif exists('b:vikiNameTypes')
        let types = b:vikiNameTypes
    else
        let types = g:vikiNameTypes
    end
    if types == ''
        return 1
    else
        " return stridx(b:vikiNameTypes, a:type) >= 0
        return types =~# '['. a:type .']'
    endif
endf

fun! VikiRxFromCollection(coll) "{{{3
    " TAssert IsList(a:coll)
    let rx = join(a:coll, '\|')
    if rx == ''
        return ''
    else
        return '\V\('. rx .'\)'
    endif
endf

" VikiMarkInexistent(line1, line2, ?maxcol, ?quick)
" maxcol ... check only up to maxcol
" quick  ... check only if the cursor is located after a link
fun! s:VikiMarkInexistent(line1, line2, ...) "{{{3
    if !b:vikiMarkInexistent
        return
    endif
    if s:cursorCol == -1
        " let cursorRestore = 1
        let li0 = line('.')
        let co0 = col('.')
        let co1 = co0 - 1
    else
        " let cursorRestore = 0
        let li0 = s:cursorLine
        let co0 = s:cursorCol
        let co1 = co0 - 2
    end
    if a:0 >= 2 && a:2 > 0 && synIDattr(synID(li0, co1, 1), 'name') !~ '^viki.*Link$'
        return
    endif

    let lazyredraw = &lazyredraw
    set lazyredraw

    let maxcol = a:0 >= 1 ? (a:1 == -1 ? 9999999 : a:1) : 9999999

    if a:line1 > 0
        keepjumps call cursor(a:line1, 1)
        let min = a:line1
    else
        go
        let min = 1
    endif
    let max = a:line2 > 0 ? a:line2 : line('$')

    if line('.') == 1 && line('$') == max
        let b:vikiNamesNull = []
        let b:vikiNamesOk   = []
    else
        if !exists('b:vikiNamesNull') | let b:vikiNamesNull = [] | endif
        if !exists('b:vikiNamesOk')   | let b:vikiNamesOk   = [] | endif
    endif

    let feedback = (max - min) > b:vikiFeedbackMin
    try
        if feedback
            let sl  = &statusline
            let rng = min .'-'. max
            let &statusline='Viki: checking line '. rng
            let rng = ' ('. min .'-'. max .')'
            redrawstatus
        endif

        if line('.') == 1
            keepjumps norm! G$
        else
            keepjumps norm! k$
        endif

        let rx = s:VikiFindRx()
        let pp = 0
        let ll = 0
        let cc = 0
        keepjumps let li = search(rx, 'w')
        let co = col('.')
        while li != 0 && !(ll == li && cc == co) && li >= min && li <= max && co <= maxcol
            if synIDattr(synID(line('.'), col('.'), 1), "name") !~ '^vikiFiles'
                if feedback
                    " if li % 10 == 0 && li != ll
                    if li % 10 == 0
                        let &statusline='Viki: checking line '. li . rng
                        redrawstatus
                        " let ll = li
                    endif
                endif
                let ll  = li
                let co1 = co - 1
                let def = VikiGetLink(1, getline('.'), co1)
                " TAssert IsList(def)
                " TLogDBG getline('.')[co1 : -1]
                " TLogDBG string(def)
                if empty(def)
                    echom 'Internal error: VikiMarkInexistent: '. co .' '. getline('.')
                else
                    exec VikiSplitDef(def)
                    if v_part =~ '^'. b:vikiSimpleNameSimpleRx .'$'
                        if v_dest =~ g:vikiSpecialProtocols
                            let check = 0
                        elseif v:version >= 700 && has_key(b:vikiHyperWordTable, v_part)
                            let check = 0
                        else
                            let check = 1
                            let partx = escape(v_part, "'\"\\/")
                            if partx !~ '^\['
                                let partx = '\<'.partx
                            endif
                            if partx !~ '\]$'
                                let partx = partx.'\>'
                            endif
                        endif
                    elseif v_dest =~ '^'. b:vikiUrlSimpleRx .'$'
                        let check = 0
                        let partx = escape(v_part, "'\"\\/")
                        call filter(b:vikiNamesNull, 'v:val != partx')
                        call insert(b:vikiNamesOk, partx)
                    elseif v_part =~ b:vikiExtendedNameSimpleRx
                        if v_dest =~ '^'. g:vikiSpecialProtocols .':'
                            let check = 0
                        else
                            let check = 1
                            let partx = escape(v_part, "'\"\\/")
                        endif
                        " elseif v_part =~ b:vikiCmdSimpleRx
                        " <+TBD+>
                    else
                        let check = 0
                    endif
                    " TLogDBG "v_dest=".v_dest
                    " TLogDBG "check=".check
                    if check && v_dest != "" && v_dest != g:vikiSelfRef && !isdirectory(v_dest)
                        if filereadable(v_dest)
                            call filter(b:vikiNamesNull, 'v:val != partx')
                            call insert(b:vikiNamesOk, partx)
                        else
                            call insert(b:vikiNamesNull, partx)
                            call filter(b:vikiNamesOk, 'v:val != partx')
                        endif
                    endif
                endif
            endif
            keepjumps let li = search(rx, 'W')
            let co = col('.')
        endwh
        call VikiHighlightInexistent()
        let b:vikiCheckInexistent = 0
    finally
        " if cursorRestore && !s:cursorSet
        "     call VikiRestoreCursorPosition(li0, co0)
        " endif
        if feedback
            let &statusline = sl
        endif
        let &lazyredraw = lazyredraw
    endtry
endf

fun! VikiHighlightInexistent() "{{{3
    if b:vikiMarkInexistent == 1
        if exists('b:vikiNamesNull')
            exe 'syntax clear '. b:vikiInexistentHighlight
            let rx = VikiRxFromCollection(b:vikiNamesNull)
            if rx != ''
                exe 'syntax match '. b:vikiInexistentHighlight .' /'. rx .'/'
            endif
        endif
    elseif b:vikiMarkInexistent == 2
        if exists('b:vikiNamesOk')
            syntax clear vikiOkLink
            syntax clear vikiExtendedOkLink
            let rx = VikiRxFromCollection(b:vikiNamesOk)
            if rx != ''
                exe 'syntax match vikiOkLink /'. rx .'/'
            endif
        endif
    endif
endf

" command! -nargs=* -range=% VikiMarkInexistent
"             \ call VikiSaveCursorPosition()
"             \ | call <SID>VikiMarkInexistent(<line1>, <line2>, <f-args>)
"             \ | call VikiRestoreCursorPosition()
"             \ | call <SID>ResetSavedCursorPosition()

command! -nargs=* -range=% VikiMarkInexistent call <SID>VikiMarkInexistentInRange(<line1>, <line2>)

if v:version == 700 && !has('patch8')
    fun! s:SID()
        let fullname = expand("<sfile>")
        return matchstr(fullname, '<SNR>\d\+_')
    endf

    fun! VikiMarkInexistentInElement(elt) "{{{3
        let lr = &lazyredraw
        set lazyredraw
        call VikiSaveCursorPosition()
        let kpk = s:SID() . "VikiMarkInexistentIn" . a:elt
        call {kpk}()
        call VikiRestoreCursorPosition()
        call s:ResetSavedCursorPosition()
        let &lazyredraw = lr
        return ''
    endf
else
    fun! VikiMarkInexistentInElement(elt) "{{{3
        let lr = &lazyredraw
        set lazyredraw
        call VikiSaveCursorPosition()
        " lockmarks call s:VikiMarkInexistentIn{a:elt}()
        " call s:VikiMarkInexistentIn{a:elt}()
        call s:VikiMarkInexistentIn{a:elt}()
        call VikiRestoreCursorPosition()
        call s:ResetSavedCursorPosition()
        let &lazyredraw = lr
        return ''
    endf
endif

fun! s:VikiMarkInexistentInRange(line1, line2) "{{{3
    call VikiSaveCursorPosition()
    call s:VikiMarkInexistent(a:line1, a:line2)
    call VikiRestoreCursorPosition()
    call s:ResetSavedCursorPosition()
endf

fun! s:VikiMarkInexistentInParagraph() "{{{3
    if getline('.') =~ '\S'
        call s:VikiMarkInexistent(line("'{"), line("'}"))
    endif
endf

fun! s:VikiMarkInexistentInDocument() "{{{3
    call s:VikiMarkInexistent(1, line("$"))
endf

fun! s:VikiMarkInexistentInParagraphVisible() "{{{3
    let l0 = max([line("'{"), line("w0")])
    " let l1 = line("'}")
    let l1 = line(".")
    call s:VikiMarkInexistent(l0, l1)
endf

fun! s:VikiMarkInexistentInParagraphQuick() "{{{3
    let l0 = line("'{")
    let l1 = line("'}")
    call s:VikiMarkInexistent(l0, l1, -1, 1)
endf

fun! s:VikiMarkInexistentInLine() "{{{3
    call s:VikiMarkInexistent(line("."), line("."))
endf

fun! s:VikiMarkInexistentInLineQuick() "{{{3
    call s:VikiMarkInexistent(line("."), line("."), (col('.') + 1), 1)
endf

fun! VikiCheckInexistent() "{{{3
    if g:vikiEnabled && exists("b:vikiCheckInexistent") && b:vikiCheckInexistent > 0
        call s:VikiMarkInexistentInRange(b:vikiCheckInexistent, b:vikiCheckInexistent)
    endif
endf

fun! VikiSetBufferVar(name, ...) "{{{3
    if !exists('b:'.a:name)
        if a:0 > 0
            let i = 1
            while i <= a:0
                exe 'let altVar = a:'. i
                if altVar[0] == '*'
                    exe 'let b:'.a:name.' = '. strpart(altVar, 1)
                    return
                elseif exists(altVar)
                    exe 'let b:'.a:name.' = '. altVar
                    return
                endif
                let i = i + 1
            endwh
            throw 'VikiSetBuffer: Couldn't set '. a:name
        else
            exe 'let b:'.a:name.' = g:'.a:name
        endif
    endif
endf

fun! s:VikiLetVar(name, var) "{{{3
    if exists('b:'.a:var)
        return 'let '.a:name.' = b:'.a:var
    elseif exists('g:'.a:var)
        return 'let '.a:name.' = g:'.a:var
    else
        return ''
    endif
endf

" VikiDispatchOnFamily(fn, ?family='', *args)
fun! VikiDispatchOnFamily(fn, ...) "{{{3
    let fam = a:0 >= 1 && a:1 != '' ? a:1 : s:Family()
    if fam == '' || !exists('*'.a:fn.fam)
        let cmd = a:fn
    else
        let cmd = a:fn.fam
    endif
    if a:0 >= 2
        let args = join(map(range(2, a:0), 'string(a:{v:val})'), ', ')
    else
        let args = ''
    endif
    " TLogDBG args
    " TLogDBG cmd .'('. args .')'
    exe 'return '. cmd .'('. args .')'
endf

" VikiSetupBuffer(state, ?dontSetup='')
fun! VikiSetupBuffer(state, ...) "{{{3
    if !g:vikiEnabled
        return
    endif
    " echom "DBG ". expand('%') .': '. (exists('b:vikiFamily') ? b:vikiFamily : 'default')

    let dontSetup = a:0 > 0 ? a:1 : ""
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
    " call VikiSetBufferVar("vikiTextstylesVer")
    call VikiSetBufferVar("vikiLowerCharacters")
    call VikiSetBufferVar("vikiUpperCharacters")
    call VikiSetBufferVar("vikiFeedbackMin")

    if a:state == 1
        call VikiSetBufferVar("vikiCommentStart", 
                    \ "b:commentStart", "b:ECcommentOpen", "b:EnhCommentifyCommentOpen",
                    \ "*matchstr(&commentstring, '^\\zs.*\\ze%s')")
        call VikiSetBufferVar("vikiCommentEnd",
                    \ "b:commentEnd", "b:ECcommentClose", "b:EnhCommentifyCommentClose", 
                    \ "*matchstr(&commentstring, '%s\\zs.*\\ze$')")
    elseif !exists('b:vikiCommentStart')
        " This actually is an error.
        if &debug != ''
            echom "Viki: FTPlugin wasn't loaded. Viki requires :filetype plugin on"
        endif
        let b:vikiCommentStart = '%'
        let b:vikiCommentEnd   = ''
    endif
    
    let b:vikiSimpleNameQuoteChars = '^][:*/&?<>|\"'
    
    let b:vikiSimpleNameQuoteBeg   = '\[-'
    let b:vikiSimpleNameQuoteEnd   = '-\]'
    let b:vikiQuotedSelfRef        = "^". b:vikiSimpleNameQuoteBeg . b:vikiSimpleNameQuoteEnd ."$"
    let b:vikiQuotedRef            = "^". b:vikiSimpleNameQuoteBeg .'.\+'. b:vikiSimpleNameQuoteEnd ."$"

    let b:vikiAnchorNameRx         = '['. b:vikiLowerCharacters .']['. 
                \ b:vikiLowerCharacters . b:vikiUpperCharacters .'_0-9]*'
    
    let interviki = '\<['. b:vikiUpperCharacters .']\+::'

    " if s:IsSupportedType("sSc") && !(dontSetup =~? "s")
    if s:IsSupportedType("s") && !(dontSetup =~? "s")
        if s:IsSupportedType("S") && !(dontSetup =~# "S")
            let quotedVikiName = b:vikiSimpleNameQuoteBeg 
                        \ .'['. b:vikiSimpleNameQuoteChars .']'
                        \ .'\{-}'. b:vikiSimpleNameQuoteEnd
        else
            let quotedVikiName = ""
        endif
        if s:IsSupportedType("c") && !(dontSetup =~# "c")
            let simpleWikiName = VikiGetSimpleRx4SimpleWikiName()
            if quotedVikiName != ""
                let quotedVikiName = quotedVikiName .'\|'
            endif
        else
            let simpleWikiName = ""
        endif
        let simpleHyperWords = ''
        if v:version >= 700 && s:IsSupportedType('w') && !(dontSetup =~# 'w')
            let b:vikiHyperWordTable = {}
            if s:IsSupportedType('f') && !(dontSetup =~# 'f')
                let patterns = []
                if exists('b:vikiNameSuffix')
                    call add(patterns, b:vikiNameSuffix)
                endif
                if g:vikiNameSuffix != '' && index(patterns, g:vikiNameSuffix) == -1
                    call add(patterns, g:vikiNameSuffix)
                end
                let suffix = '.'. expand('%:e')
                if suffix != '.' && index(patterns, suffix) == -1
                    call add(patterns, suffix)
                end
                for p in patterns
                    let files = glob(expand('%:p:h').'/*'. p)
                    if files != ''
                        let files_l = split(files, '\n')
                        call filter(files_l, '!isdirectory(v:val) && v:val != expand("%:p")')
                        if !empty(files_l)
                            for w in files_l
                                let ww = fnamemodify(w, ":t:r")
                                if !has_key(b:vikiHyperWordTable, ww) && 
                                            \ (simpleWikiName == '' || ww !~# simpleWikiName)
                                    let b:vikiHyperWordTable[ww] = w
                                endif
                            endfor
                        endif
                    endif
                endfor
            endif
            for f in g:vikiHyperWordsFiles
                if f =~ '^\./'
                    let f = expand('%:p:h'). f[1:-1]
                endif
                if filereadable(f)
                    let hyperWords = readfile(f)
                    for wl in hyperWords
                        if wl =~ '^\s*%'
                            continue
                        endif
                        let ml = matchlist(wl, '^\(\S\+\) *\t\s*\(.\+\)$')
                        if !empty(ml)
                            let mkey = ml[1]
                            let mval = ml[2]
                            if mval == '-'
                                if has_key(b:vikiHyperWordTable, mkey)
                                    call remove(b:vikiHyperWordTable, mkey)
                                endif
                            elseif !has_key(b:vikiHyperWordTable, mkey)
                                let b:vikiHyperWordTable[mkey] = mval
                            endif
                        endif
                    endfor
                endif
            endfor
            let hyperWords = keys(b:vikiHyperWordTable)
            if !empty(hyperWords)
                let simpleHyperWords = join(map(hyperWords, '"\\<".v:val."\\>"'), '\|') .'\|'
            endif
        endif
        let b:vikiSimpleNameRx = '\C\(\('. interviki .'\)\?'.
                    \ '\('. simpleHyperWords . quotedVikiName . simpleWikiName .'\)\)'.
                    \ '\(#\('. b:vikiAnchorNameRx .'\)\>\)\?'
        let b:vikiSimpleNameSimpleRx = '\C\(\<['.b:vikiUpperCharacters.']\+::\)\?'.
                    \ '\('. simpleHyperWords . quotedVikiName . simpleWikiName .'\)'.
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
   
    if s:IsSupportedType("u") && !(dontSetup =~# "u")
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
   
    if s:IsSupportedType("x") && !(dontSetup =~# "x")
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
    
    if s:IsSupportedType("e") && !(dontSetup =~# "e")
        let b:vikiExtendedNameRx = 
                    \ '\[\[\(\('.b:vikiSpecialProtocols.'\)://[^]]\+\|[^]#]\+\)\?'.
                    \ '\(#\([^]]*\)\)\?\]\(\[\([^]]\+\)\]\)\?\([!~*\-]*\)\]'
                    " \ '\(#\('. b:vikiAnchorNameRx .'\)\)\?\]\(\[\([^]]\+\)\]\)\?[!~*\-]*\]'
        let b:vikiExtendedNameSimpleRx = 
                    \ '\[\[\('. b:vikiSpecialProtocols .'://[^]]\+\|[^]#]\+\)\?'.
                    \ '\(#[^]]*\)\?\]\(\[[^]]\+\]\)\?[!~*\-]*\]'
                    " \ '\(#'. b:vikiAnchorNameRx .'\)\?\]\(\[[^]]\+\]\)\?[!~*\-]*\]'
        let b:vikiExtendedNameNameIdx   = 6
        let b:vikiExtendedNameModIdx    = 7
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

    if a:state == 2
        if g:vikiAutoMarks
            call VikiSetAnchorMarks()
        endif
        if g:vikiNameSuffix != ''
            exec 'setlocal suffixesadd+='. g:vikiNameSuffix
        endif
        if exists('b:vikiNameSuffix') && b:vikiNameSuffix != '' && b:vikiNameSuffix != g:vikiNameSuffix
            exec 'setlocal suffixesadd+='. b:vikiNameSuffix
        endif
    endif
endf

fun! VikiDefineMarkup(state) "{{{3
    if s:IsSupportedType("sS") && b:vikiSimpleNameSimpleRx != ""
        exe "syntax match vikiLink /" . b:vikiSimpleNameSimpleRx . "/"
    endif
    if s:IsSupportedType("e") && b:vikiExtendedNameSimpleRx != ""
        exe "syntax match vikiExtendedLink '" . b:vikiExtendedNameSimpleRx . "' skipnl"
    endif
    if s:IsSupportedType("u") && b:vikiUrlSimpleRx != ""
        exe "syntax match vikiURL /" . b:vikiUrlSimpleRx . "/"
    endif
endf

fun! VikiGetSimpleRx4SimpleWikiName() "{{{3
    let upper = s:UpperCharacters()
    let lower = s:LowerCharacters()
    let simpleWikiName = '\<['.upper.']['.lower.']\+\(['.upper.']['.lower.'0-9]\+\)\+\>'
    " This will mistakenly highlight words like LaTeX
    " let simpleWikiName = '\<['.upper.']['.lower.']\+\(['.upper.']['.lower.'0-9]\+\)\+'
    return simpleWikiName
endf

" VikiMakeName(iviki, name, ?quote=1)
fun! VikiMakeName(iviki, name, ...) "{{{3
    let quote = a:0 >= 1 ? a:1 : 1
    let name  = a:name
    if quote && name !~ '\C'. VikiGetSimpleRx4SimpleWikiName()
        let name = '[-'. name .'-]'
    endif
    if a:iviki != ''
        let name = a:iviki .'::'. name
    endif
    return name
endf

fun! s:UpperCharacters() "{{{3
    return exists('b:vikiUpperCharacters') ? b:vikiUpperCharacters : g:vikiUpperCharacters
endf

fun! s:LowerCharacters() "{{{3
    return exists('b:vikiLowerCharacters') ? b:vikiLowerCharacters : g:vikiLowerCharacters
endf

fun! s:StripBackslash(string) "{{{3
    return substitute(a:string, '\\\(.\)', '\1', 'g')
endf

fun! VikiDefineHighlighting(state) "{{{3
    if version < 508
        command! -nargs=+ VikiHiLink hi link <args>
    else
        command! -nargs=+ VikiHiLink hi def link <args>
    endif

    exe "hi vikiInexistentLink term=bold,underline cterm=bold,underline gui=bold,underline". 
                \ " ctermfg=". VikiInexistentColor() ." guifg=". VikiInexistentColor()
    exe "hi vikiHyperLink term=bold,underline cterm=bold,underline gui=bold,underline". 
                \ " ctermfg=". VikiHyperLinkColor() ." guifg=". VikiHyperLinkColor()

    if s:IsSupportedType("sS")
        VikiHiLink vikiLink vikiHyperLink
        VikiHiLink vikiOkLink vikiHyperLink
        VikiHiLink vikiRevLink Normal
    endif
    if s:IsSupportedType("e")
        VikiHiLink vikiExtendedLink vikiHyperLink
        VikiHiLink vikiExtendedOkLink vikiHyperLink
        VikiHiLink vikiRevExtendedLink Normal
    endif
    if s:IsSupportedType("u")
        VikiHiLink vikiURL vikiHyperLink
    endif
    delcommand VikiHiLink
endf

fun! s:MapMarkInexistent(key, element) "{{{3
    if a:key == "\n"
        let key = '<cr>'
    elseif a:key == ' '
        let key = '<space>'
    else
        let key = a:key
    endif
    let arg = maparg(key, 'i')
    if arg == ''
        let arg = key
    endif
    let map = '<c-r>=VikiMarkInexistentInElement("'. a:element .'")<cr>'
    let map = stridx(g:vikiMapBeforeKeys, a:key) != -1 ? arg.map : map.arg
    exe 'inoremap <silent> <buffer> '. key .' '. map
endf

" VikiRestoreCursorPosition(?line, ?VCol, ?EOL, ?Winline)
fun! VikiRestoreCursorPosition(...) "{{{3
    " let li  = a:0 >= 1 && a:1 != '' ? a:1 : s:cursorLine
    " " let co  = a:0 >= 2 && a:2 != '' ? a:2 : s:cursorVCol
    " let co  = a:0 >= 2 && a:2 != '' ? a:2 : s:cursorCol
    " " let eol = a:0 >= 3 && a:3 != '' ? a:3 : s:cursorEol
    " let wli = a:0 >= 4 && a:4 != '' ? a:4 : s:cursorWinTLine
    let li  = s:cursorLine
    let co  = s:cursorCol
    let wli = s:cursorWinTLine
    if li >= 0
        let ve = &virtualedit
        set virtualedit=all
        if wli > 0
            exe 'keepjumps norm! '. wli .'zt'
        endif
        call cursor(li, co)
        let &virtualedit = ve
    endif
endf

fun! VikiSaveCursorPosition() "{{{3
    let ve = &virtualedit
    set virtualedit=all
    " let s:lazyredraw   = &lazyredraw
    " set nolazyredraw
    let s:cursorSet     = 1
    let s:cursorCol     = col('.')
    let s:cursorEol     = (col('.') == col('$'))
    let s:cursorVCol    = virtcol('.')
    if s:cursorEol
        let s:cursorVCol = s:cursorVCol + 1
    endif
    let s:cursorLine    = line('.')
    keepjumps norm! H
    let s:cursorWinTLine = line('.')
    call cursor(s:cursorLine, s:cursorCol)
    let &virtualedit    = ve
    " call VikiDebugCursorPosition()
    return ''
endf

fun! VikiDebugCursorPosition(...) "{{{3
    let msg = 'DBG '
    if a:0 >= 1 && a:1 != ''
        let msg = msg . a:1 .' '
    endif
    let msg = msg . "s:cursorCol=". s:cursorCol
                \ ." s:cursorEol=". s:cursorEol
                \ ." ($=". col('$') .')'
                \ ." s:cursorVCol=". s:cursorVCol
                \ ." s:cursorLine=". s:cursorLine
                \ ." s:cursorWinTLine=". s:cursorWinTLine
    if a:0 >= 2 && a:2
        echo msg
    else
        echom msg
    endif
endf

fun! VikiMapKeys(state) "{{{3
    if exists('b:vikiDidMapKeys')
        return
    endif
    if a:state == 1
        if exists('b:vikiMapFunctionalityMinor') && b:vikiMapFunctionalityMinor
            let mf = b:vikiMapFunctionalityMinor
        else
            let mf = g:vikiMapFunctionalityMinor
        endif
    elseif exists('b:vikiMapFunctionality') && b:vikiMapFunctionality
        let mf = b:vikiMapFunctionality
    else
        let mf = g:vikiMapFunctionality
    endif

    " if !hasmapto('VikiMaybeFollowLink')
        if s:MapFunctionality(mf, 'c')
            nnoremap <buffer> <silent> <c-cr> :call VikiMaybeFollowLink(0,1)<cr>
            inoremap <buffer> <silent> <c-cr> <c-o>:call VikiMaybeFollowLink(0,1)<cr>
            " nnoremap <buffer> <silent> <LocalLeader><c-cr> :call VikiMaybeFollowLink(0,1,-1)<cr>
        endif
        if s:MapFunctionality(mf, 'f')
            " nnoremap <buffer> <silent> <c-cr> :call VikiMaybeFollowLink(0,1)<cr>
            " inoremap <buffer> <silent> <c-cr> <c-o>:call VikiMaybeFollowLink(0,1)<cr>
            " nnoremap <buffer> <silent> <LocalLeader><c-cr> :call VikiMaybeFollowLink(0,1,-1)<cr>
            exec 'nnoremap <buffer> <silent> '. g:vikiMapLeader .'f :call VikiMaybeFollowLink(0,1)<cr>'
            exec 'nnoremap <buffer> <silent> '. g:vikiMapLeader .'s :call VikiMaybeFollowLink(0,1,-1)<cr>'
            exec 'nnoremap <buffer> <silent> '. g:vikiMapLeader .'v :call VikiMaybeFollowLink(0,1,-2)<cr>'
            exec 'nnoremap <buffer> <silent> '. g:vikiMapLeader .'1 :call VikiMaybeFollowLink(0,1,1)<cr>'
            exec 'nnoremap <buffer> <silent> '. g:vikiMapLeader .'2 :call VikiMaybeFollowLink(0,1,2)<cr>'
            exec 'nnoremap <buffer> <silent> '. g:vikiMapLeader .'3 :call VikiMaybeFollowLink(0,1,3)<cr>'
            exec 'nnoremap <buffer> <silent> '. g:vikiMapLeader .'4 :call VikiMaybeFollowLink(0,1,4)<cr>'
            exec 'nnoremap <buffer> <silent> '. g:vikiMapLeader .'t :call VikiMaybeFollowLink(0,1,"tab")<cr>'
        endif
        if s:MapFunctionality(mf, 'mf')
            " && !hasmapto("VikiMaybeFollowLink")
            nnoremap <buffer> <silent> <m-leftmouse> <leftmouse>:call VikiMaybeFollowLink(0,1)<cr>
            inoremap <buffer> <silent> <m-leftmouse> <leftmouse><c-o>:call VikiMaybeFollowLink(0,1)<cr>
        endif
    " endif

    " if !hasmapto('VikiMarkInexistent')
        if s:MapFunctionality(mf, 'i')
            exec 'noremap <buffer> <silent> '. g:vikiMapLeader .'d :call VikiMarkInexistentInElement("Document")<cr>'
            exec 'noremap <buffer> <silent> '. g:vikiMapLeader .'p :call VikiMarkInexistentInElement("Paragraph")<cr>'
        endif
        if s:MapFunctionality(mf, 'I')
            if g:vikiMapInexistent
                let i = 0
                let m = strlen(g:vikiMapKeys)
                while i < m
                    let k = g:vikiMapKeys[i]
                    call s:MapMarkInexistent(k, "LineQuick")
                    let i = i + 1
                endwh
                let i = 0
                let m = strlen(g:vikiMapQParaKeys)
                while i < m
                    let k = g:vikiMapQParaKeys[i]
                    call s:MapMarkInexistent(k, "ParagraphVisible")
                    let i = i + 1
                endwh
            endif
        endif
    " endif

    if s:MapFunctionality(mf, 'e')
        " && !hasmapto("VikiEdit")
        exec 'noremap <buffer> '. g:vikiMapLeader .'e :VikiEdit '
    endif
    
    if s:MapFunctionality(mf, 'q') && exists("*VEnclose")
        " && !hasmapto("VikiQuote")
        exec 'vnoremap <buffer> <silent> '. g:vikiMapLeader .'q :VikiQuote<cr><esc>:call VikiMarkInexistentInElement("LineQuick")<cr>'
        exec 'nnoremap <buffer> <silent> '. g:vikiMapLeader .'q viw:VikiQuote<cr><esc>:call VikiMarkInexistentInElement("LineQuick")<cr>'
        exec 'inoremap <buffer> <silent> '. g:vikiMapLeader .'q <esc>viw:VikiQuote<cr>:call VikiMarkInexistentInElement("LineQuick")<cr>i'
    endif
    
    if s:MapFunctionality(mf, 'p')
        exec 'nnoremap <buffer> <silent> '. g:vikiMapLeader .'<bs> :call VikiGoParent()<cr>'
        exec 'nnoremap <buffer> <silent> '. g:vikiMapLeader .'<up> :call VikiGoParent()<cr>'
    endif

    if s:MapFunctionality(mf, 'b')
        " && !hasmapto("VikiGoBack")
        exec 'nnoremap <buffer> <silent> '. g:vikiMapLeader .'b :call VikiGoBack()<cr>'
        exec 'nnoremap <buffer> <silent> '. g:vikiMapLeader .'<left> :call VikiGoBack()<cr>'
    endif
    if s:MapFunctionality(mf, 'mb')
        nnoremap <buffer> <silent> <m-rightmouse> <leftmouse>:call VikiGoBack(0)<cr>
        inoremap <buffer> <silent> <m-rightmouse> <leftmouse><c-o>:call VikiGoBack(0)<cr>
    endif
    
    if s:MapFunctionality(mf, 'F')
        " && !hasmapto(":VikiFind")
        exec 'nnoremap <buffer> <silent> '. g:vikiMapLeader .'n :VikiFindNext<cr>'
        exec 'nnoremap <buffer> <silent> '. g:vikiMapLeader .'N :VikiFindPrev<cr>'
        exec 'nmap <buffer> <silent> '. g:vikiMapLeader .'F '. g:vikiMapLeader .'n'. g:vikiMapLeader .'f'
    endif
    if s:MapFunctionality(mf, 'tF')
        " && !hasmapto(":VikiFind")
        nnoremap <buffer> <silent> <c-tab>   :VikiFindNext<cr>
        nnoremap <buffer> <silent> <c-s-tab> :VikiFindPrev<cr>
    endif
    if s:MapFunctionality(mf, 'Files')
        exec 'nnoremap <buffer> <silent> '. g:vikiMapLeader .'u :VikiFilesUpdate<cr>'
        exec 'nnoremap <buffer> <silent> '. g:vikiMapLeader .'U :VikiFilesUpdateAll<cr>'
        exec 'nnoremap <buffer> '. g:vikiMapLeader .'x :VikiFilesExec '
        exec 'nnoremap <buffer> '. g:vikiMapLeader .'X :VikiFilesExec! '
    endif
    let b:vikiDidMapKeys = 1
endf

fun! s:MapFunctionality(mf, key)
    return a:mf == 'ALL' || (a:mf =~# '\<'. a:key .'\>')
endf

"state ... no-op:0, minor:1, major:2
fun! VikiMinorMode(state) "{{{3
    if !g:vikiEnabled
        return 0
    endif
    if a:state == 0
        return 0
    endif
    let state = a:state < 0 ? -a:state : a:state
    let vf = s:Family(1)
    " c ... CamelCase 
    " s ... Simple viki name 
    " S ... Simple quoted viki name
    " e ... Extended viki name
    " u ... URL
    " i ... InterViki
    " call VikiSetBufferVar('vikiNameTypes', 'g:vikiNameTypes', "*'csSeui'")
    call VikiSetBufferVar('vikiNameTypes')
    call VikiDispatchOnFamily('VikiSetupBuffer', vf, state)
    call VikiDispatchOnFamily('VikiDefineMarkup', vf, state)
    call VikiDispatchOnFamily('VikiDefineHighlighting', vf, state)
    call VikiDispatchOnFamily('VikiMapKeys', vf, state)
    if !exists('b:vikiEnabled') || b:vikiEnabled < state
        let b:vikiEnabled = state
    endif
    " call VikiDispatchOnFamily('VikiDefineMarkup', vf, state)
    " call VikiDispatchOnFamily('VikiDefineHighlighting', vf, state)
    return 1
endf

fun! VikiMinorModeReset() "{{{3
    if exists("b:vikiEnabled") && b:vikiEnabled == 1
        call VikiMinorMode(1)
    endif
endf

command! VikiMinorMode call VikiMinorMode(1)
command! VikiMinorModeMaybe echom "Deprecated command: VikiMinorModeMaybe" | call VikiMinorMode(1)
" this requires imaps to be installed
command! -range VikiQuote :call VEnclose("[-", "-]", "[-", "-]")

fun! VikiMode(state) "{{{3
    " if exists('b:vikiEnabled')
    "     if b:vikiEnabled
    "         return 0
    "     endif
    "     " if b:vikiEnabled && a:state < 0
    "     "     return 0
    "     " endif
    "     " echom "VIKI: Viki mode already set."
    " endif
    unlet b:did_ftplugin
    set filetype=viki
endf

command! VikiMode call VikiMode(2)
command! VikiModeMaybe echom "Deprecated command: VikiModeMaybe" | call VikiMode(2)
" command! VikiModeMaybe call VikiMode(-2)

fun! VikiIsInRegion(line) "{{{3
    let i   = 0
    let max = col('$')
    while i < max
        if synIDattr(synID(a:line, i, 1), "name") == "vikiRegion"
            return 1
        endif
        let i = i + 1
    endw
    return 0
endf

fun! s:VikiSetBackRef(file, li, co) "{{{3
    let br = s:GetBackRef()
    call filter(br, 'v:val[0] != a:file')
    call insert(br, [a:file, a:li, a:co])
endf

fun! s:VikiSelectThisBackRef(n) "{{{3
    return 'let [vbf, vbl, vbc] = s:GetBackRef()['. a:n .']'
endf

fun! s:VikiSelectBackRef(...) "{{{3
    if a:0 >= 1 && a:1 >= 0
        let s = a:1
    else
        let br  = s:GetBackRef()
        let br0 = map(copy(br), 'v:val[0]')
        let st  = tlib#InputList('s', 'Select Back Reference', br0)
        if st != ''
            let s = index(br0, st)
        else
            let s = -1
        endif
    endif
    if s >= 0
        return s:VikiSelectThisBackRef(s)
    endif
    return ''
endf

fun! s:GetBackRef()
    if g:vikiSaveHistory
        let id = expand('%:p')
        if empty(id)
            return []
        else
            if !has_key(g:VIKIBACKREFS, id)
                let g:VIKIBACKREFS[id] = []
            endif
            return g:VIKIBACKREFS[id]
        endif
    else
        if !exists('b:VIKIBACKREFS')
            let b:VIKIBACKREFS = []
        endif
        return b:VIKIBACKREFS
    endif
endf

fun! VikiGoParent() "{{{3
    if exists('b:vikiParent')
        call VikiEdit(b:vikiParent)
    else
        call VikiGoBack()
    endif
endf

fun! VikiGoBack(...) "{{{3
    let s  = (a:0 >= 1) ? a:1 : -1
    let br = s:VikiSelectBackRef(s)
    if br == ''
        echomsg "Viki: No back reference defined? (". s ."/". br .")"
    else
        exe br
        let buf = bufnr("^". vbf ."$")
        if buf >= 0
            call s:EditWrapper('buffer', buf)
        else
            call s:EditWrapper('edit', vbf)
        endif
        if vbf == expand("%:p")
            call cursor(vbl, vbc)
        else
            throw "Viki: Couldn't open file: ". vbf
        endif
    endif
endf

command! -narg=? VikiGoBack call VikiGoBack(<f-args>)

fun! VikiSubstituteArgs(str, ...) "{{{3
    let i  = 1
    " let rv = escape(a:str, '\')
    let rv = a:str
    let default = ''
    let done = 0
    while a:0 >= i
        exec "let lab = a:". i
        exec "let val = a:". (i+1)
        if lab == ''
            let default = val
        else
            let rv0 = substitute(rv, '\C\(^\|[^%]\)\zs%{'. lab .'}', escape(val, '\&'), "g")
            if rv != rv0
                let done = 1
                let rv = rv0
            endif
        endif
        let i = i + 2
    endwh
    if !done
        let rv .= ' '. default
    end
    let rv = substitute(rv, '%%', "%", "g")
    return rv
endf

if !exists('*VikiAnchor_l') "{{{2
    fun! VikiAnchor_l(arg) "{{{3
        if a:arg =~ '^\d\+$'
            exec a:arg
        endif
    endf
endif

if !exists('*VikiAnchor_line') "{{{2
    fun! VikiAnchor_line(arg) "{{{3
        call VikiAnchor_l(a:arg)
    endf
endif

if !exists('*VikiAnchor_rx') "{{{2
    fun! VikiAnchor_rx(arg) "{{{3
        let arg = escape(s:StripBackslash(a:arg), '/')
        exec 'keepjumps norm! gg/'. arg .''
    endf
endif

if !exists('*VikiAnchor_vim') "{{{2
    fun! VikiAnchor_vim(arg) "{{{3
        exec s:StripBackslash(a:arg)
    endf
endif

fun! s:GetAnchorRx(anchor)
    let anchorRx = '\^\s\*\('. b:vikiCommentStart .'\)\?\s\*'. b:vikiAnchorMarker . a:anchor
    if exists('b:vikiAnchorRx')
        " !!! b:vikiAnchorRx must be a very nomagic (\V) regexp 
        "     expression
        let varx = VikiSubstituteArgs(b:vikiAnchorRx, 'ANCHOR', a:anchor)
        let anchorRx = '\('.anchorRx.'\|'. varx .'\)'
    endif
    return '\V'. anchorRx
endf

fun! VikiFindAnchor(anchor) "{{{3
    if a:anchor == g:vikiDefNil || a:anchor == ''
        return
    endif
    let mode = matchstr(a:anchor, '^\(l\(ine\)\?\|rx\|vim\)\ze=')
    if exists('*VikiAnchor_'. mode)
        let arg  = matchstr(a:anchor, '=\zs.\+$')
        call VikiAnchor_{mode}(arg)
    else
        let co = col('.')
        let li = line('.')
        let anchorRx = s:GetAnchorRx(a:anchor)
        keepjumps norm! $
        let found = search(anchorRx, 'w')
        if !found
            call cursor(li, co)
            if g:vikiFreeMarker
                call search('\c\V'. escape(a:anchor, '\'), 'w')
            endif
        endif
    endif
endf

fun! VikiSetAnchorMarks() "{{{3
    let pos = getpos(".")
    let sr  = @/
    let anchorRx = s:GetAnchorRx('m\(\[a-zA-Z0-9]\)\s\*\$')
    exec 'silent keepjumps g /'. anchorRx .'/exec "norm! m". substitute(getline("."), anchorRx, ''\2'', "")'
    let @/ = sr
    call setpos('.', pos)
endf

fun! VikiGetWinNr(...) "{{{3
    let winNr = a:0 >= 1 ? a:1 : 0
    " TLogVAR winNr
    if type(winNr) == 0 && winNr == 0
        if exists('b:vikiSplit')
            let winNr = b:vikiSplit
        elseif exists('g:vikiSplit')
            let winNr = g:vikiSplit
        else
            let winNr = 0
        endif
    endif
    return winNr
endf

fun! VikiSetWindow(winNr) "{{{3
    let winNr = VikiGetWinNr(a:winNr)
    " TLogVAR winNr
    if type(winNr) == 1 && winNr == 'tab'
        tabnew
    elseif winNr != 0
        let wm = s:HowManyWindows()
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
    let postcmd = a:0 >= 2 ? a:2 : ''
    if a:0 >= 3
        let winNr = a:3
    elseif exists('b:vikiNextWindow')
        let winNr = b:vikiNextWindow
    else
        let winNr = 0
    endif
    " TLogVAR winNr
    
    let li = line('.')
    let co = col('.')
    let fi = expand('%:p')
   
    let filename = exists('*simplify') ? simplify(a:filename) : a:filename
    let buf      = bufnr('^'. filename .'$')
    call VikiSetWindow(winNr)
    if buf >= 0
        call s:EditLocalFile('buffer', buf, fi, li, co, a:anchor)
    elseif create && exists('b:createVikiPage')
        call s:EditLocalFile(b:createVikiPage, filename, fi, li, co, g:vikiDefNil)
    elseif exists('b:editVikiPage')
        call s:EditLocalFile(b:editVikiPage, filename, fi, li, co, g:vikiDefNil)
    elseif isdirectory(filename)
        call s:EditLocalFile(g:vikiExplorer, filename, fi, li, co, g:vikiDefNil)
    else
        call s:EditLocalFile('edit', filename, fi, li, co, a:anchor)
    endif
    if postcmd != ''
        exec postcmd
    endif
endf

fun! s:EditLocalFile(cmd, fname, fi, li, co, anchor) "{{{3
    let vf = s:Family()
    let cb = bufnr('%')
    call tlib#EnsureDirectoryExists(fnamemodify(a:fname, ':p:h'))
    call s:EditWrapper(a:cmd, a:fname)
    if cb != bufnr('%')
        set buflisted
    endif
    if vf != ''
        let b:vikiFamily = vf
    endif
    call s:VikiSetBackRef(a:fi, a:li, a:co)
    if !exists('b:vikiEnabled') || !b:vikiEnabled
        call VikiDispatchOnFamily('VikiMinorMode', vf, 1)
    endif
    call VikiDispatchOnFamily('VikiFindAnchor', vf, a:anchor)
endf

fun! s:Family(...) "{{{3
    let anyway = a:0 >= 1 ? a:1 : 0
    if (anyway || (exists('b:vikiEnabled') && b:vikiEnabled)) && exists('b:vikiFamily')
        return b:vikiFamily
    else
        return g:vikiFamily
    endif
endf

fun! s:HowManyWindows() "{{{3
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

fun! s:GetSpecialFilesSuffixes() "{{{3
    " TAssert IsList(g:vikiSpecialFiles)
    if exists("b:vikiSpecialFiles")
        " TAssert IsList(b:vikiSpecialFiles)
        return b:vikiSpecialFiles + g:vikiSpecialFiles
    else
        return g:vikiSpecialFiles
    endif
endf

fun! s:GetSpecialFilesSuffixesRx(...) "{{{3
    let sfx = a:0 >= 1 ? a:1 : s:GetSpecialFilesSuffixes()
    return join(sfx, '\|')
endf

fun! VikiIsSpecialFile(dest) "{{{3
    return (a:dest =~ '\.\('. s:GetSpecialFilesSuffixesRx() .'\)$' &&
                \ (g:vikiSpecialFilesExceptions == "" ||
                \ !(a:dest =~ g:vikiSpecialFilesExceptions)))
endf

fun! VikiIsSpecialProtocol(dest) "{{{3
    return a:dest =~ '^\('.b:vikiSpecialProtocols.'\):' &&
                \ (b:vikiSpecialProtocolsExceptions == "" ||
                \ !(a:dest =~ b:vikiSpecialProtocolsExceptions))
endf

fun! VikiIsSpecial(dest) "{{{3
    return VikiIsSpecialProtocol(a:dest) || 
                \ VikiIsSpecialFile(a:dest) ||
                \ isdirectory(a:dest)
endf

fun! s:VikiFollowLink(def, ...) "{{{3
    let winNr = a:0 >= 1 ? a:1 : 0
    " TLogVAR winNr
    exec VikiSplitDef(a:def)
    if type(winNr) == 0 && winNr == 0
        " TAssert IsNumber(winNr)
        if exists('v_winnr')
            let winNr = v_winnr
        elseif exists('b:vikiOpenInWindow')
            if b:vikiOpenInWindow =~ '^l\(a\(s\(t\)\?\)\?\)\?'
                let winNr = s:HowManyWindows()
            elseif b:vikiOpenInWindow =~ '^[+-]\?\d\+$'
                if b:vikiOpenInWindow[0] =~ '[+-]'
                    exec 'let winNr = '. bufwinnr("%") . b:vikiOpenInWindow
                else
                    let winNr = b:vikiOpenInWindow
                endif
            endif
        endif
    endif
    let inter = s:GuessInterViki(a:def)
    let bn    = bufnr('%')
    if v_name == g:vikiSelfRef || v_dest == g:vikiSelfRef
        call VikiDispatchOnFamily('VikiFindAnchor', '', v_anchor)
    elseif v_dest == g:vikiDefNil
		throw 'No target? '.a:def
    else
        call s:OpenLink(v_dest, v_anchor, winNr)
    endif
    if exists('b:vikiEnabled') && b:vikiEnabled && inter != '' && !exists('b:vikiInter')
        let b:vikiInter = inter
    endif
    return ""
endf

fun! s:OpenLink(dest, anchor, winNr)
    let b:vikiNextWindow = a:winNr
    " TLogVAR a:winNr
    try
        if VikiIsSpecialProtocol(a:dest)
            call VikiOpenSpecialProtocol(a:dest)
        elseif VikiIsSpecialFile(a:dest)
            call VikiOpenSpecialFile(a:dest)
        elseif isdirectory(a:dest)
            " exec g:vikiExplorer .' '. a:dest
            call VikiOpenLink(a:dest, a:anchor, 0, '', a:winNr)
        elseif filereadable(a:dest) "reference to a local, already existing file
            call VikiOpenLink(a:dest, a:anchor, 0, '', a:winNr)
        elseif bufexists(a:dest)
            call s:EditWrapper('buffer', a:dest)
        else
            let ok = input("File doesn't exists. Create '".a:dest."'? (Y/n) ", "y")
            if ok != "" && ok != "n"
                let b:vikiCheckInexistent = line(".")
                call VikiOpenLink(a:dest, a:anchor, 1, '', a:winNr)
            endif
        endif
    finally
        let b:vikiNextWindow = 0
    endtry
endf

fun! s:GuessInterViki(def) "{{{3
    exec VikiSplitDef(a:def)
    if v_type == 's'
        let exp = v_name
    elseif v_type == 'e'
        let exp = v_dest
    else
        return ''
    endif
    if s:IsInterViki(exp)
        return s:InterVikiName(exp)
    else
        return ''
    endif
endf

fun! s:MakeVikiDefPart(txt) "{{{3
    if a:txt == ''
        return g:vikiDefNil
    else
        return a:txt
    endif
endf

fun! VikiMakeDef(v_name, v_dest, v_anchor, v_part, v_type) "{{{3
    if a:v_name =~ g:vikiDefSep || a:v_dest =~ g:vikiDefSep || a:v_anchor =~ g:vikiDefSep 
                \ || a:v_part =~ g:vikiDefSep
        throw "Viki: A viki definition must not include ".g:vikiDefSep
                    \ .": ".a:v_name.", ".a:v_dest.", ".a:v_anchor ." (". a:v_part .")"
    else
        let arr = map([a:v_name, a:v_dest, a:v_anchor, a:v_part, a:v_type, 0], 's:MakeVikiDefPart(v:val)')
        " TLogDBG string(arr)
        return arr
    endif
endf

fun! VikiSplitDef(def) "{{{3
    " TAssert IsList(a:def)
    " TLogDBG string(a:def)
    if empty(a:def)
        let rv = 'let [v_name, v_dest, v_anchor, v_part, v_type, v_winnr] = ["", "", "", "", "", ""]'
    else
        if a:def[4] == 'e'
            let mod = s:ExtendedModifier(a:def[3])
            if mod =~# '*'
                let a:def[5] = -1
            endif
        endif
        let rv = 'let [v_name, v_dest, v_anchor, v_part, v_type, v_winnr] = '. string(a:def)
    endif
    return rv
endf

fun! s:GetVikiNamePart(txt, erx, idx, errorMsg) "{{{3
    if a:idx
        let rv = substitute(a:txt, '^\C'. a:erx ."$", '\'.a:idx, "")
        if rv == ''
            return g:vikiDefNil
        else
            return rv
        endif
    else
        return g:vikiDefNil
    endif
endf

fun! VikiLinkDefinition(txt, col, compound, ignoreSyntax, type) "{{{3
    " echom "DBG VikiLinkDefinition: ". a:txt ." ". a:compound
    " TLogDBG 'txt='. a:txt
    " TLogDBG 'col='. a:col
    " TLogDBG 'compound='. a:compound
    exe a:compound
    if erx != ''
        let ebeg = -1
        let cont = match(a:txt, erx, 0)
        " TLogDBG 'cont='. cont .'('. a:col .')'
        while (ebeg >= 0 || (0 <= cont) && (cont <= a:col))
            let contn = matchend(a:txt, erx, cont)
            " TLogDBG 'contn='. contn .'('. cont.')'
            if (cont <= a:col) && (a:col < contn)
                let ebeg = match(a:txt, erx, cont)
                let elen = contn - ebeg
                break
            else
                let cont = match(a:txt, erx, contn)
            endif
        endwh
        " TLogDBG 'ebeg='. ebeg
        if ebeg >= 0
            let part   = strpart(a:txt, ebeg, elen)
            let name   = s:GetVikiNamePart(part, erx, nameIdx,   "no name")
            let dest   = s:GetVikiNamePart(part, erx, destIdx,   "no destination")
            let anchor = s:GetVikiNamePart(part, erx, anchorIdx, "no anchor")
            return VikiMakeDef(name, dest, anchor, part, a:type)
        elseif a:ignoreSyntax
            return []
        else
            throw "Viki: Malformed viki v_name: " . a:txt . " (". erx .")"
        endif
    else
        return []
    endif
endf

fun! s:WithSuffix(fname)
    if isdirectory(a:fname)
        return a:fname
    else
        return a:fname.s:VikiGetSuffix()
    endif
endf

fun! s:VikiGetSuffix() "{{{3
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
    if a:name == ''
        return a:dest
    else
        if a:dest == ''
            let dest = a:name
        else
            let dest = a:dest . g:vikiDirSeparator . a:name
        endif
        if a:suffix == g:vikiDefSep
            return s:WithSuffix(dest)
        elseif isdirectory(dest)
            return dest
        else
            return dest . a:suffix
        endif
    endif
endf

fun! s:IsInterViki(vikiname)
    return  s:IsSupportedType('i') && a:vikiname =~# s:InterVikiRx
endf

fun! s:InterVikiName(vikiname)
    return substitute(a:vikiname, s:InterVikiRx, '\1', '')
endf

fun! s:InterVikiPart(vikiname)
    return substitute(a:vikiname, s:InterVikiRx, '\2', '')
endf

fun! s:InterVikiDef(vikiname, ...)
    let ow = a:0 >= 1 ? a:1 : s:InterVikiName(a:vikiname)
    let vd = s:VikiLetVar('i_dest', 'vikiInter'.ow)
    let id = s:VikiLetVar('i_index', 'vikiInter'.ow.'_index')
    if !empty(id)
        let vd .= '|'. id
    endif
    if vd != ''
        exec vd
        if i_dest =~ '^\*\S\+('
            let it = 'fn'
        elseif i_dest[0] =~ '%'
            let it = 'fmt'
        else
            let it = 'prefix'
        endif
        return vd .'|let i_type="'. it .'"|let i_name="'. ow .'"'
    end
    return vd
endf

fun! s:InterVikiDest(vikiname, ...)
    if a:0 >= 1  && a:1 != ''
        let ow = a:1
        let v_dest = a:vikiname
    else
        let ow = s:InterVikiName(a:vikiname)
        let v_dest = s:InterVikiPart(a:vikiname)
    endif
    let vd = s:InterVikiDef(a:vikiname, ow)
    if vd != ''
        exec vd
        if i_type == 'fn'
            let f = strpart(i_dest, 1)
            exec 'let v_dest = '. s:sprintf1(f, v_dest)
        elseif i_type == 'fmt'
            let f = strpart(i_dest, 1)
            let v_dest = s:sprintf1(f, v_dest)
        else
            if empty(v_dest) && exists('i_index')
                let v_dest = i_index
            endif
            let v_dest = expand(i_dest) . g:vikiDirSeparator . v_dest
        endif
        return v_dest
    else
        echoerr "Viki: InterViki is not defined: ". ow
        return g:vikiDefNil
    endif
endf

fun! s:InterVikiSuffix(vikiname)
    let ow = s:InterVikiName(a:vikiname)
    let vd = s:InterVikiDef(a:vikiname, ow)
    if vd != ''
        exec vd
        if i_type =~ 'fn'
            return ''
        else
            if fnamemodify(a:vikiname, ':e') != ''
                let useSuffix = ''
            else
                exec s:VikiLetVar('useSuffix', 'vikiInter'.ow.'_suffix')
            endif
            return useSuffix
        endif
    else
        return ''
    endif
endf

fun! VikiCompleteSimpleNameDef(def) "{{{3
    " echom "DBG VikiCompleteSimpleNameDef: ". a:def
    exec VikiSplitDef(a:def)
    if v_name == g:vikiDefNil
        throw "Viki: Malformed simple viki name (no name): ". string(a:def)
    endif

    if !(v_dest == g:vikiDefNil)
        throw "Viki: Malformed simple viki name (destination=".v_dest."): ". string(a:def)
    endif

    if s:IsInterViki(v_name)
        let i_name = s:InterVikiName(v_name)
        let useSuffix = s:InterVikiSuffix(v_name)
        let v_name = s:InterVikiPart(v_name)
    elseif exists('b:vikiHyperWordTable') && has_key(b:vikiHyperWordTable, v_name)
        let i_name = ''
        let useSuffix = ''
        let v_name = b:vikiHyperWordTable[v_name]
    else
        let i_name = ''
        let v_dest = expand("%:p:h")
        let useSuffix = g:vikiDefSep
    endif
    
    if s:IsSupportedType("S")
        " echom "DBG: ". v_name
        if v_name =~ b:vikiQuotedSelfRef
            let v_name  = g:vikiSelfRef
        elseif v_name =~ b:vikiQuotedRef
            let v_name = matchstr(v_name, "^". b:vikiSimpleNameQuoteBeg .'\zs.\+\ze'. b:vikiSimpleNameQuoteEnd ."$")
        endif
    elseif !s:IsSupportedType("c")
        throw "Viki: CamelCase names not allowed"
    endif

    if v_name != g:vikiSelfRef
        let rdest = VikiExpandSimpleName(v_dest, v_name, useSuffix)
    else
        let rdest = g:vikiDefNil
    endif

    if i_name != ''
        let rdest = s:InterVikiDest(rdest, i_name)
        " let v_name = ''
    endif

    let v_type   = v_type == g:vikiDefNil ? 's' : v_type
    return VikiMakeDef(v_name, rdest, v_anchor, v_part, v_type)
endf

fun! s:ExtendedModifier(part)
    let mod = substitute(a:part, b:vikiExtendedNameRx, '\'.b:vikiExtendedNameModIdx, '')
    if mod != a:part
        return mod
    else
        return ''
    endif
endf

fun! VikiCompleteExtendedNameDef(def) "{{{3
    exec VikiSplitDef(a:def)
    if v_dest == g:vikiDefNil
        if v_anchor == g:vikiDefNil
            throw "Viki: Malformed extended viki name (no destination): ".a:def
        else
            let v_dest = g:vikiSelfRef
        endif
    elseif s:IsInterViki(v_dest)
        let useSuffix = s:InterVikiSuffix(v_dest)
        let v_dest = s:InterVikiDest(v_dest)
        if v_dest != g:vikiDefNil
            let v_dest = VikiExpandSimpleName('', v_dest, useSuffix)
        endif
    else
        if v_dest =~? '^[a-z]:'                      " an absolute dos path
        elseif v_dest =~? '^\/'                          " an absolute unix path
        elseif v_dest =~? '^'.b:vikiSpecialProtocols.':' " some protocol
        elseif v_dest =~ '^\~'                           " user home
            " let v_dest = $HOME . strpart(v_dest, 1)
            let v_dest = fnamemodify(v_dest, ':p')
            let v_dest = s:CanonicFilename(v_dest)
        else                                           " a relative path
            let v_dest = expand("%:p:h") .g:vikiDirSeparator. v_dest
            let v_dest = s:CanonicFilename(v_dest)
        endif
        if v_dest != '' && v_dest != g:vikiSelfRef && !VikiIsSpecial(v_dest)
            let mod = s:ExtendedModifier(v_part)
            if fnamemodify(v_dest, ':e') == '' && mod !~# '!'
                let v_dest = s:WithSuffix(v_dest)
            endif
        endif
    endif
    if v_name == g:vikiDefNil
        let v_name = fnamemodify(v_dest, ':t:r')
    endif
    let v_type = v_type == g:vikiDefNil ? 'e' : v_type
    return VikiMakeDef(v_name, v_dest, v_anchor, v_part, v_type)
endf
 
fun! s:FindFileWithSuffix(filename, suffixes) "{{{3
    " TAssert IsList(a:suffixes)
    " echom "DBG FindFileWithSuffix: filename=". a:filename ." ". a:suffixes
    if filereadable(a:filename)
        return a:filename
    else
        for elt in a:suffixes
            if elt != ''
                let fn = a:filename .".". elt
                if filereadable(fn)
                    return fn
                endif
            else
                return g:vikiDefNil
            endif
        endfor
    endif
    return g:vikiDefNil
endf

fun! VikiCompleteCmdDef(def) "{{{3
    exec VikiSplitDef(a:def)
    " echom "DBG VikiCompleteCmdDef: v_name=". v_name ." v_dest=". v_dest
    let args     = v_anchor
    let v_anchor = g:vikiDefNil
    if v_name ==# "#IMG" || v_name =~# "{img"
        let v_dest = s:FindFileWithSuffix(v_dest, s:GetSpecialFilesSuffixes())
        " echom "DBG VikiCompleteCmdDef#IMG: v_dest=". v_dest
    elseif v_name ==# "#Img"
        let id = matchstr(args, '\sid=\zs\w\+')
        if id != ''
            let v_dest = s:FindFileWithSuffix(id, s:GetSpecialFilesSuffixes())
        endif
    elseif v_name =~ "^#INC"
        " <+TBD+> Search path?
    else
        " throw "Viki: Unknown command: ". v_name
        let v_name = g:vikiDefNil
        let v_dest = g:vikiDefNil
        " let v_anchor = g:vikiDefNil
    endif
    let v_type = v_type == g:vikiDefNil ? 'cmd' : v_type
    let vdef   = VikiMakeDef(v_name, v_dest, v_anchor, v_part, v_type)
    " echom "DBG VikiCompleteCmdDef: ". vdef
    return vdef
endf

fun! s:VikiLinkNotFoundEtc(oldmap, ignoreSyntax) "{{{3
    if a:oldmap == ""
        echomsg "Viki: Show me the way to the next viki name or I have to ... ".a:ignoreSyntax.":".getline(".")
    elseif a:oldmap == 1
        return "\<c-cr>"
    else
        return a:oldmap
    endif
endf

" VikiGetLink(ignoreSyntax, ?txt, ?col=0, ?supported=b:vikiNameTypes)
fun! VikiGetLink(ignoreSyntax, ...) "{{{3
    let col   = a:0 >= 2 ? a:2 : 0
    let types = a:0 >= 3 ? a:3 : b:vikiNameTypes
    if a:0 >= 1 && a:1 != ''
        let txt      = a:1
        let vikiType = a:ignoreSyntax
        let tryAll   = 1
    else
        let synName = synIDattr(synID(line('.'), col('.'), 0), 'name')
        if synName ==# 'vikiLink'
            let vikiType = 1
            let tryAll   = 0
        elseif synName ==# 'vikiExtendedLink'
            let vikiType = 2
            let tryAll   = 0
        elseif synName ==# 'vikiURL'
            let vikiType = 3
            let tryAll   = 0
        elseif synName ==# 'vikiCommand' || synName ==# 'vikiMacro'
            let vikiType = 4
            let tryAll   = 0
        elseif a:ignoreSyntax
            let vikiType = a:ignoreSyntax
            let tryAll   = 1
        else
            return ''
        endif
        let txt = getline('.')
        let col = col('.') - 1
    endif
    " TLogDBG "txt=". txt
    " TLogDBG "col=". col
    " TLogDBG "tryAll=". tryAll
    " TLogDBG "vikiType=". tryAll
    if (tryAll || vikiType == 2) && s:IsSupportedType('e', types)
        if exists('b:getExtVikiLink')
            exe 'let def = ' . b:getExtVikiLink.'()'
        else
            let def = VikiLinkDefinition(txt, col, b:vikiExtendedNameCompound, a:ignoreSyntax, 'e')
        endif
        " TAssert IsList(def)
        if !empty(def)
            return VikiDispatchOnFamily('VikiCompleteExtendedNameDef', '', def)
        endif
    endif
    if (tryAll || vikiType == 3) && s:IsSupportedType('u', types)
        if exists('b:getURLViki')
            exe 'let def = ' . b:getURLViki . '()'
        else
            let def = VikiLinkDefinition(txt, col, b:vikiUrlCompound, a:ignoreSyntax, 'u')
        endif
        " TAssert IsList(def)
        if !empty(def)
            return VikiDispatchOnFamily('VikiCompleteExtendedNameDef', '', def)
        endif
    endif
    if (tryAll || vikiType == 4) && s:IsSupportedType('x', types)
        if exists('b:getCmdViki')
            exe 'let def = ' . b:getCmdViki . '()'
        else
            let def = VikiLinkDefinition(txt, col, b:vikiCmdCompound, a:ignoreSyntax, 'x')
        endif
        " TAssert IsList(def)
        if !empty(def)
            return VikiDispatchOnFamily('VikiCompleteCmdDef', '', def)
        endif
    endif
    if (tryAll || vikiType == 1) && s:IsSupportedType('s', types)
        if exists('b:getVikiLink')
            exe 'let def = ' . b:getVikiLink.'()'
        else
            let def = VikiLinkDefinition(txt, col, b:vikiSimpleNameCompound, a:ignoreSyntax, 's')
        endif
        " echom "DBG VikiGetLink1: ". def
        " TAssert IsList(def)
        if !empty(def)
            return VikiDispatchOnFamily('VikiCompleteSimpleNameDef', '', def)
        endif
    endif
    return []
endf

" VikiMaybeFollowLink(oldmap, ignoreSyntax, ?winNr=0)
fun! VikiMaybeFollowLink(oldmap, ignoreSyntax, ...) "{{{3
    let winNr = a:0 >= 1 ? a:1 : 0
    " TLogVAR winNr
    let def = VikiGetLink(a:ignoreSyntax)
    " TAssert IsList(def)
    if empty(def)
        return s:VikiLinkNotFoundEtc(a:oldmap, a:ignoreSyntax)
    else
        return s:VikiFollowLink(def, winNr)
    endif
endf
command! VikiJump call VikiMaybeFollowLink(0,1)

" VikiEdit(name, ?bang='', ?winNr=0)
fun! VikiEdit(name, ...) "{{{3
    let bang  = a:0 >= 1 ? a:1 : ''
    let winNr = a:0 >= 2 ? a:2 : 0
    " TLogVAR winNr
    if exists('b:vikiEnabled') && bang != '' && 
                \ exists('b:vikiFamily') && b:vikiFamily != ''
                " \ (!exists('b:vikiFamily') || b:vikiFamily != '')
        if g:vikiHomePage != ''
            call VikiOpenLink(g:vikiHomePage, '', '', '', winNr)
        else
            call s:EditWrapper('buffer', 1)
        endif
    endif
    if a:name == '*'
        let name = g:vikiHomePage
    else
        let name = a:name
    end
    let name = substitute(name, '\\', '/', 'g')
    if !exists('b:vikiNameTypes')
        call VikiSetBufferVar('vikiNameTypes')
        call VikiDispatchOnFamily('VikiSetupBuffer', '', 0)
    endif
    let def = VikiGetLink(1, '[['. name .']]', 0, '')
    " TAssert IsList(def)
    if empty(def)
        call s:VikiLinkNotFoundEtc('', 1)
    else
        exec VikiSplitDef(def)
        " call VikiOpenLink(v_dest, '', '', '', winNr)
        call s:OpenLink(v_dest, '', winNr)
    endif
endf

fun! s:VikiEditCompleteAgent(interviki, afname, fname) "{{{3
    if isdirectory(a:afname)
        return a:afname .'/'
    else
        if exists('g:vikiInter'. a:interviki .'_suffix')
            let sfx = g:vikiInter{a:interviki}_suffix
        else
            let sfx = s:VikiGetSuffix()
        endif
        if sfx != '' && sfx == '.'. fnamemodify(a:fname, ':e')
            let name = fnamemodify(a:fname, ':t:r')
        else
            let name = a:fname
        endif
        " if name !~ '\C'. VikiGetSimpleRx4SimpleWikiName()
        "     let name = '[-'. a:fname .'-]'
        " endif
        if a:interviki != ''
            let name = a:interviki .'::'. name
        endif
        return name
    endif
endf

fun! s:VikiEditCompleteMapAgent1(val, sfx, iv, rx) "{{{3
    if isdirectory(a:val)
        let rv = a:val .'/'
    else
        let rsfx = '\V'. a:sfx .'\$'
        if a:sfx != '' && a:val !~ rsfx
            return ''
        else
            let rv = substitute(a:val, rsfx, '', '')
            if isdirectory(rv)
                let rv = a:val
            endif
        endif
    endif
    return a:iv .'::'. substitute(rv, a:rx, '\1', '')
endf

fun! VikiEditComplete(ArgLead, CmdLine, CursorPos) "{{{3
    " let i = matchstr(a:ArgLead, '^\zs.\{-}\ze::')
    " echom "DBG a:ArgLead=". a:ArgLead
    let i = s:InterVikiName(a:ArgLead)
    if index(s:InterVikis, i.'::') >= 0
        if exists('g:vikiInter'. i .'_suffix')
            let sfx = g:vikiInter{i}_suffix
        else
            let sfx = s:VikiGetSuffix()
        endif
    else
        let i = ''
        let sfx = s:VikiGetSuffix()
    endif
    if i != '' && exists('g:vikiInter'. i)
        let f  = matchstr(a:ArgLead, '::\(\[-\)\?\zs.*$')
        let d  = s:InterVikiDest(f.'*', i)
        let r  = '\V'. s:InterVikiDest('\(\.\{-}\)', i)
        let d  = substitute(d, '\', '/', 'g')
        let rv = split(glob(d), '\n')
        if sfx != ''
            call filter(rv, 'isdirectory(v:val) || ".". fnamemodify(v:val, ":e") == sfx')
        endif
        call map(rv, 's:VikiEditCompleteMapAgent1(v:val, sfx, i, r)')
        call filter(rv, '!empty(v:val)')
        " call map(rv, string(i). '."::". substitute(v:val, r, ''\1'', "")')
    else
        let rv = split(glob(a:ArgLead.'*'.sfx), '\n')
        call map(rv, 's:VikiEditCompleteAgent('. string(i) .', v:val, v:val)')
        if a:ArgLead == ''
            let rv += s:InterVikis
        else
            let rv += filter(copy(s:InterVikis), 'v:val =~ ''\V\^''.a:ArgLead')
        endif
    endif
    " call map(rv, 'escape(v:val, "%# ")')
    return rv
endf

fun! VikiIndex() "{{{3
    if exists('b:vikiIndex')
        let fname = s:WithSuffix(b:vikiIndex)
    else
        let fname = s:WithSuffix(g:vikiIndex)
    endif
    if filereadable(fname)
        return VikiOpenLink(fname, '')
    else
        echom "Index page not found: ". fname
    endif
endf

command! VikiIndex :call VikiIndex()

command! -nargs=1 -bang -complete=customlist,VikiEditComplete VikiEdit :call VikiEdit(<q-args>, "<bang>")
command! -nargs=1 -bang -complete=customlist,VikiEditComplete VikiEditTab :call VikiEdit(<q-args>, "<bang>", 'tab')
command! -nargs=1 -bang -complete=customlist,VikiEditComplete VikiEditInWin1 :call VikiEdit(<q-args>, "<bang>", 1)
command! -nargs=1 -bang -complete=customlist,VikiEditComplete VikiEditInWin2 :call VikiEdit(<q-args>, "<bang>", 2)
command! -nargs=1 -bang -complete=customlist,VikiEditComplete VikiEditInWin3 :call VikiEdit(<q-args>, "<bang>", 3)
command! -nargs=1 -bang -complete=customlist,VikiEditComplete VikiEditInWin4 :call VikiEdit(<q-args>, "<bang>", 4)

command! VikiHome :call VikiEdit('*', '!')
command! VIKI :call VikiEdit('*', '!')

command! VikiFilesUpdate call viki#VikiFilesUpdate()
command! VikiFilesUpdateAll call viki#VikiFilesUpdateAll()

command! -nargs=* -bang -complete=command VikiFileExec call viki#VikiFilesExec(<q-args>, '<bang>', 1)
command! -nargs=* -bang -complete=command VikiFilesExec call viki#VikiFilesExec(<q-args>, '<bang>')
command! -nargs=* -bang VikiFilesCmd call viki#VikiFilesCmd(<q-args>, '<bang>')
command! -nargs=* -bang VikiFilesCall call viki#VikiFilesCall(<q-args>, '<bang>')

augroup viki
    au!
    autocmd BufEnter * call VikiMinorModeReset()
    autocmd BufEnter * call VikiCheckInexistent()
    autocmd VimLeavePre * let g:vikiEnabled = 0
    if g:vikiSaveHistory
        autocmd VimEnter * if exists('VIKIBACKREFS_STRING') | exec 'let g:VIKIBACKREFS = '. VIKIBACKREFS_STRING | unlet VIKIBACKREFS_STRING | endif
        autocmd VimLeavePre * let VIKIBACKREFS_STRING = string(g:VIKIBACKREFS)
    endif
augroup END

finish "{{{1
______________________________________________________________________________

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
- changed g:vikiDefSep to ''

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

1.9
- Register mp3, ogg and some other multimedia related suffixes as 
special files
- Add a menu of Intervikis if g:vikiMenuPrefix is != ''
- g:vikiMapKeys can contain "\n" and " " (supplement g:vikiMapKeys with 
the variables g:vikiMapQParaKeys and g:vikiMapBeforeKeys)
- FIX: <SID>IsSupportedType
- FIX: Only the first inexistent link in a line was highlighted
- FIX: Set &buflisted when editing an existing buffer
- FIX: VikiDefine: Non-viki index names weren't quoted
- FIX: In "minor mode", vikiFamily wasn't correctly set in some 
situations; other problems related to b:vikiFamily
- FIX: AnyWord works again
- Removed: VikiMinorModeMaybe
- VikiDefine now takes an optional fourth argument (an index file; 
default=Index) and automatically creates a vim command with the name of 
the interviki that opens this index file

1.10
- Pseudo anchors (not supported by deplate):
-- Jump to a line number, e.g. [[file#l=10]] or [[file#line=10]]
-- Find an regexp, e.g. [[file#rx=\\d]]
-- Execute some vim code, e.g. [[file#vim=call Whatever()]]
-- You can define your own handlers: VikiAnchor_{type}(arg)
- g:vikiFolds: new 'b' flag: the body has a higher level than all 
headings (gives you some kind of outliner experience; the default value 
for g:vikiFolds was changed to 'h')
- FIX: VikiFindAnchor didn't work properly in some situations
- FIX: Escape blanks when following a link (this could cause problems in 
some situations, not always)
- FIX: Don't try to mark inexistent links when pressing enter if the current 
line is empty.
- FIX: Restore vertical cursor position in window after looking for 
inexistent links.
- FIX: Backslashes got lost in some situations.

1.11
- Enable [[INTERVIKI::]]
- VikiEdit also creates commands for intervikis that have no index
- Respect "!" and "*" modifiers in extended viki links
- New g:vikiMapFunctionalityMinor variable
- New g:vikiMapLeader variable
- CHANGE: Don't map VikiMarkInexistent in minor mode (see 
g:vikiMapFunctionalityMinor)
- CHANGE: new attributes for g:vikiMapFunctionality: c, m[fb], i, I
- SYNTAX: cterm support for todo lists, emphasize
- FIX: Erroneous cursor movement
- FIX: VikiEdit didn't check if a file was already opened, which caused 
a file to be opened in two buffers under certain conditions
- FIX: Error in <SID>MapMarkInexistent()
- FIX: VikiEdit: Non-viki names were not quoted
- FIX: Use fnamemodify() to expand tildes in filenames
- FIX: Inexistent quoted viki names with an interviki prefix weren't 
properly highlighted
- FIX: Minor problem with suffixes & extended viki names
- FIX: Use keepjumps
- FIX: Catch E325
- FIX: Don't catch errors in <SID>EditWrapper() if the command matches 
g:vikiNoWrapper (due to possible compatibility problems eg with :Explore 
in vim 6.4)
- OBSOLETE: Negative arguments to VikiMode or VikiMinorMode are obsolete 
(or they became the default to be precise)
- OBSOLETE: g:vikiMapMouse
- REMOVED: mapping to <LocalLeader><c-cr>
- DEPRECATED: VikiModeMaybe

1.12
- Define some keywords in syntax file (useful for omnicompletion)
- Define :VIKI command as an alias for :VikiHome
- FIX: Problem with names containing spaces
- FIX: Extended names with suffix & interviki
- FIX: Indentation of priority lists.
- FIX: VikiDefine created wrong (old-fashioned) VikiEdit commands under 
certain conditions.
- FIX: Directories in extended viki names + interviki names were marked 
as inexistent
- FIX: Syntax highlighting of regions or commands the headline of which 
spanned several lines
- Added ppt to g:vikiSpecialFiles.

1.13
- Intervikis can now be defined as function ('*Function("%s")', this 
breaks conversion via deplate) or format string ('%/foo/%s/bar', not yet 
supported by deplate)
- Task lists take optional tags, eg #A [tag] foo; they may also be 
tagged with the letters G-Z, which are highlighted as general task (not 
supported by deplate)
- Automatically set marks for labels prefixed with "m" (eg #ma -> 'a, 
#mB -> 'B)
- Two new g:vikiNameTypes: w = (Hyper)Words, f = File names in cwd as 
hyperwords (experimental, not implemented in deplate)
- In extended viki names: add the suffix only if the destination hasn't 
got one
- A buffer local b:vikiOpenInWindow allows links to be redirected to a 
certain window (ie, if b:vikiOpenInWindow = 2, pressing <c-cr> behaves 
like <LocalLeader>v2); this is useful if you use some kind of 
directory/catalog metafile; possible values: absolute number, +/- 
relative number, "last"
- Switched back to old regexp for simple names in order to avoid 
highlighting of names like LaTeX
- VikiEdit opens the homepage only if b:vikiFamily is set
- Map <LocalLeader>vF to <LocalLeader>vn<LocalLeader>vf
- Improved syntax for (nested) macros
- Set &suffixesadd so that you can use vim's own gf in some situations
- SYNTAX: Allow empty lines as region delimiters (deplate 0.8.1)
- FIX: simple viki names with anchors where not recognised
- FIX: don't mark simple (inter)viki names as inexistent that expand to 
links matching g:vikiSpecialProtocols
- FIX: file names containing %
- FIX: added a patch (VikiMarkInexistentInElement) by Kevin Kleinfelter 
for compatibility with an unpatched vim70 (untested)
- FIX: disabling simple names (s) also properly disables the name types: 
Scwf

2.0
- Got rid of multvals & genutils dependencies (use vim7 lists instead)
- New dependency: tlib.vim (vimscript #1863)
- INCOMPATIBLE CHANGE: The format of g:vikiMapFunctionality has changed.
- INCOMPATIBLE CHANGE: g:vikiSpecialFiles is now a list!
- Viki now has a special #Files region that can be automatically 
updated. This way we can start thinking about using viki for as 
project/file management tool. This is for vim only and not supported yet 
in deplate. New related maps & commands: :VikiFilesUpdate (<LL>vu), 
:VikiFilesUpdateAll (<LL>vU), :VikiFilesCmd, :VikiFilesCall, 
:VikiFilesExec (<LL>vx), and VikiFileExec.
- VikiGoParent() (mapped to <LL>v<bs> or <LL>v<up>): If b:vikiParent is 
defined, open this viki name, otherwise follow the backlink.
- New :VikiEditTab command.
- Map <LL>vt to open in tab.
- Map <LL>v<left> to open go back.
- Keys listed in g:vikiMapQParaKeys are now mapped to 
s:VikiMarkInexistentInParagraphVisible() which checks only the visible 
area and thus avoids scrolling.
- Highlight lines containing blanks (which vim doesn't treat as 
paragraph separators)
- When following a link, check if it is an special viki name before 
assuming it's a simple one.
- Map [[, ]], [], ][
- If an interviki has an index file, a viki name like [[INTERVIKI::]] 
will now open the index file. In order to browse the directory, use 
[[INTERVIKI::.]]. If no index file is defined, the directory will be 
opened either way.
- Set the default value of g:vikiFeedbackMin to &lines.
- Added ws as special files to be opened with :WsOpen if existent.
- Replaced most occurences of <SID> with s:
- Use tlib#InputList() for selecting back references.
- g:vikiOpenFileWith_ANY now uses g:netrw_browsex_viewer by default.
- CHANGE: g:vikiSaveHistory: We now rely on viminfo's "!" option to save 
back-references.
- FIX: VikiEdit now works properly with protocols that are to be opened 
with an external viewer
- FIX: VikiEdit completion, which is more usable now

" vim: ff=unix
