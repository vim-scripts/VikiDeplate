" viki.vim -- the viki syntax file
" @Author:      Thomas Link (samul AT web.de)
" @License:     GPL (see http://www.gnu.org/licenses/gpl.txt)
" @Created:     30-Dez-2003.
" @Last Change: 04-Mai-2004.
" @Revision: 0.317

if version < 600
  syntax clear
elseif exists("b:current_syntax")
  finish
endif

" This command sets up buffer variables and adds some basic highlighting.
let b:VikiEnabled = 0
VikiMinorModeMaybe
let b:VikiEnabled = 2

syn match vikiEscape /\\/ contained containedin=vikiEscapedChar
syn match vikiEscapedChar /\\\_./ contains=vikiEscape,vikiChar

exe "syn match vikiAnchor /^". escape(b:vikiCommentStart, '\/.*^$~[]') .'\?\s*#'. b:vikiAnchorNameRx ."/"
syn match vikiMarkers /\(\([#?!+]\)\2\{2,2}\)/
syn match vikiSymbols /\(--\|!=\|==\+\|\~\~\+\|<-\+>\|<=\+>\|<\~\+>\|<-\+\|-\+>\|<=\+\|=\+>\|<\~\+\|\~\+>\|\.\.\.\)/

syn match vikiBold /\(^\|\W\zs\)\*\(\\\*\|\w\)\{-1,}\*/
syn region vikiContinousBold start=/\(^\|\W\zs\)\*\*[^ 	*]/ end=/\*\*\|\n\{2,}/ skip=/\\\n/

syn match vikiItalic /\(^\|\W\zs\)\/\(\\\/\|\w\)\{-1,}\//hs=s+1,he=e-1
syn region vikiContinousItalic start=/\(^\|\W\zs\)\/\/[^ 	/]/hs=s+2 end=/\/\/\|\n\{2,}/he=e-2 skip=/\\\n/

syn match vikiUnderline /\(^\|\W\zs\)_\(\\_\|\w\)\{-1,}_/
syn region vikiContinousUnderline start=/\(^\|\W\zs\)__[^ 	_]/ end=/__\|\n\{2,}/ skip=/\\\n/

syn match vikiTypewriter /\(^\|\W\zs\)=\(\\=\|\w\)\{-1,}=/
syn region vikiContinousTypewriter start=/\(^\|\W\zs\)==[^ 	=]/ end=/==\|\n\{2,}/ skip=/\\\n/

syn cluster vikiTextstyles contains=vikiBold,vikiContinousBold,vikiItalic,vikiContinousItalic,vikiTypewriter,vikiContinousTypewriter,vikiUnderline,vikiContinousUnderline,vikiEscapedChar

exe 'syn region vikiComment start=/^\s*'. escape(b:vikiCommentStart, '\/.*^$~[]') .'/ end=/$/ contains=ALL'

syn region vikiString start=+"+ end=+"+ contains=@vikiTextstyles

let b:vikiHeadingStart = '*'
exe 'syn region vikiHeading start=/\V\^'. escape(b:vikiHeadingStart, '\') .'\+\s\+/ end=/\n/ contains=@vikiTextstyles'

syn match vikiList /^\s\+\([-•+*#]\|[0-9#]\+\.\|[a-zA-Z?]\.\)\ze\s/
syn match vikiDescription /^\s\+.\{-1,}\s::\ze\s/

syn match vikiTableRowSep /||\?/ contained containedin=vikiTableRow,vikiTableHead
syn match vikiTableHead /^||\s\(.\|\\\n\)\+\s||$/ contains=ALL transparent
syn match vikiTableRow  /^|\s\(.\|\\\n\)\+\s|$/ contains=ALL transparent

" syn match vikiLayoutMarker /[/|%_^]/ containedin=vikiLayout contained
" syn match vikiLayout /|\S.\{-}\S|/
            " \ contains=vikiLayoutMarker,@vikiTextstyles,vikiEscape,vikiEscapedChar,vikiCommand

syn region vikiCommand matchgroup=vikiCommandDelim start=/{[^:{}]\+:\?/ end=/}/ transparent

syn match vikiOption /^\C#\([A-Z]\+\)\>.*$/
syn region vikiRegion matchgroup=vikiCommandDelim 
            \ start=/#\([A-Z][a-z]\+\>\|!!!\).\{-}<<\z(.\+\)$/ end=/^\z1$/ contains=ALL


" Define the default highlighting.
" For version 5.7 and earlier: only when not done already
" For version 5.8 and later: only when an item doesn't have highlighting yet
if version >= 508 || !exists("did_viki_syntax_inits")
  if version < 508
    let did_viki_syntax_inits = 1
    command! -nargs=+ HiLink hi link <args>
  else
    command! -nargs=+ HiLink hi def link <args>
  endif
  
  if &background == "light"
      let s:cm1="Dark"
      let s:cm2="Light"
  else
      let s:cm1="Light"
      let s:cm2="Dark"
  endif

  if exists("g:vikiHeadingFont")
      let s:hdfont = " font=". g:vikiHeadingFont
  else
      let s:hdfont = ""
  endif
  
  if exists("g:vikiTypewriterFont")
      let s:twfont = " font=". g:vikiTypewriterFont
  else
      let s:twfont = ""
  endif
 
  HiLink vikiEscapedChars Normal
  exe "hi vikiEscape ctermfg=". s:cm2 ."grey guifg=". s:cm2 ."grey"
  exe "hi vikiHeading term=bold,underline cterm=bold gui=bold ctermfg=". s:cm1 ."Magenta guifg=".s:cm1."Magenta". s:hdfont
  exe "hi vikiList term=bold cterm=bold gui=bold ctermfg=". s:cm1 ."Cyan guifg=". s:cm1 ."Cyan"
  HiLink vikiDescription vikiList
  
  exe "hi vikiTableRowSep term=bold cterm=bold gui=bold ctermbg=". s:cm2 ."Grey guibg=". s:cm2 ."Grey"
  
  exe "hi vikiSymbols term=bold cterm=bold gui=bold ctermfg=". s:cm1 ."Red guifg=". s:cm1 ."Red"
  exe "hi vikiMarkers term=bold cterm=bold gui=bold ctermfg=". s:cm1 ."Red guifg=". s:cm1 ."Red ctermbg=yellow guibg=yellow"
  hi vikiAnchor term=italic cterm=italic gui=italic ctermfg=grey guifg=grey
  HiLink vikiComment Comment
  HiLink  vikiString String
  hi vikiBold term=bold cterm=bold gui=bold
  HiLink vikiContinousBold vikiBold
  hi vikiItalic term=italic cterm=italic gui=italic
  HiLink vikiContinousItalic vikiItalic
  hi vikiUnderline term=underline cterm=underline gui=underline
  HiLink vikiContinousUnderline vikiUnderline
  exe "hi vikiTypewriter term=underline ctermfg=". s:cm1 ."Grey guifg=". s:cm1 ."Grey". s:twfont
  HiLink vikiContinousTypewriter vikiTypewriter
  " hi vikiLayout term=standout cterm=standout gui=standout
  HiLink vikiLayoutMarker PreProc
  HiLink vikiCommandHead Statement
  HiLink vikiCommandDelim Identifier
 
  HiLink vikiOption Statement
  HiLink vikiRegion Statement
  
  delcommand HiLink
endif

" vim: ff=unix
