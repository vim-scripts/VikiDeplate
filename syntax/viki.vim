" viki.vim -- the viki syntax file
" @Author:      Thomas Link (samul AT web.de)
" @License:     GPL (see http://www.gnu.org/licenses/gpl.txt)
" @Created:     30-Dez-2003.
" @Last Change: 01-Feb-2004.
" @Revision: 0.117

if version < 600
  syntax clear
elseif exists("b:current_syntax")
  finish
endif

" This command sets up buffer variables and adds some basic highlighting.
VikiMinorModeMaybe
let b:VikiEnabled = 2

if b:vikiMarkupEndsWithNewline == 1
    let s:markUpEndlineEnd  = '\|\n\{2,}'
elseif b:vikiMarkupEndsWithNewline == 2
    let s:markUpEndlineEnd  = ''
else
    let s:markUpEndlineEnd  = '\|\n'
endif

" syn match vikiLiteral /\\["*_{}#|/\\]/
" syn match vikiEscapedChars /[ "*_{}#|/\\]/
syn match vikiEscape /\\/
syn match vikiEscapedChar /\\[ "*_{}#|/\\\n]/ contains=vikiEscape

exe "syn match vikiAnchor /^". b:vikiCommentStart ."\\?#[".g:vikiLowerCharacters."0-9]\\+/"
syn match vikiMarkers /\([#?!+]\{3,3}\)/
syn match vikiSymbols /\(--\|!=\|==\+\|\~\~\+\|<-\+>\|<=\+>\|<\~\+>\|<-\+\|-\+>\|<=\+\|=\+>\|<\~\+\|\~\+>\|\.\.\.\)/

exe 'syn region vikiComment start=/^\s*'. b:vikiCommentStart .'/ end=/$/ contains=vikiAnchor'
exe 'syn region vikiString start=+"+ skip=+\\"+  end=+"'. s:markUpEndlineEnd .'+'

let b:vikiHeadingStart = '^\*\+\s\+'
" exe 'syn region vikiHeading start=/'. b:vikiHeadingStart .'/ end=/\n/ skip=/\\\n/ '
exe 'syn region vikiHeading start=/'. b:vikiHeadingStart .'/ end=/\n/ contains=ALL'

" syn match vikiList /^\s\+\([-+*]\|[0-9]\+\.\|[a-zA-Z]\.\|(\([0-9]\+\|[a-zA-Z]\))\)\ze\s/
syn match vikiList /^\s\+\([-+*]\|[0-9]\+\.\|[a-zA-Z]\.\)\ze\s/
" syn match vikiDescription /^\s\+.\{-1,}\s\(::\|\.\.\.\)\ze\s/
syn match vikiDescription /^\s\+.\{-1,}\s::\ze\s/

" syn region vikiTableHead start=/^||\s/ end=/\s||$/ skip=/\\\n/
" syn region vikiTableRow start=/^|\s/ end=/\s|$/ skip=/\\\n/
syn match vikiTableHead /\(^\|\s\zs\)||\ze\(\s\+\|$\)/
" \(^\|\s\zs\)|\(\s\{-1,}\|$\)/
syn match vikiTableRow /\(^|\s\|\s\zs|\s\|\s|$\)/
syn match vikiTableRuler /^[+|]-\+\([ 	+=-]\|\\\n\)\+-\+[+|]$/

syn match vikiBold /\(^\|\s\zs\)\*\(\\\*\|[^ 	*]\)\{-1,}\*/
" syn match vikiBold /\(\_^\|\s\zs\)\*\(\\\*\|\S\)\{-1,}\*/
exe 'syn region vikiContinousBold start=/\(^\|\s\zs\)\*\*[^ 	*]/ end=/\*\*'. s:markUpEndlineEnd .'/ skip=/\\\n/'
syn match vikiItalic /\(^\|\s\zs\)\/\(\\\/\|[^ 	/]\)\{-1,}\//hs=s+1,he=e-1
exe 'syn region vikiContinousItalic start=/\(^\|\s\zs\)\/\/[^ 	/]/hs=s+2 end=/\/\/'. s:markUpEndlineEnd .'/he=e-2 skip=/\\\n/'
syn match vikiUnderline /\(^\|\s\zs\)_\(\\_\|[^ 	_]\)\{-1,}_/
exe 'syn region vikiContinousUnderline start=/\(^\|\s\zs\)__[^ 	_]/ end=/__'. s:markUpEndlineEnd .'/ skip=/\\\n/'
syn match vikiTypewriter /\(^\|\s\zs\)=\(\\=\|[^ 	=]\)\{-1,}=/
exe 'syn region vikiContinousTypewriter start=/\(^\|\s\zs\)==[^ 	=]/ end=/=='. s:markUpEndlineEnd .'/ skip=/\\\n/'

syn region vikiCommand start=/{/ skip=/\(\\{\|\\}\|\\\n\)/ end=/}/ contains=vikiCommand


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
 
  " HiLink vikiEscapedChars Normal
  exe "hi vikiEscape ctermfg=". s:cm2 ."grey guifg=". s:cm2 ."grey"
  exe "hi vikiHeading term=bold,underline cterm=bold gui=bold ctermfg=". s:cm1 ."Magenta guifg=".s:cm1."Magenta". s:hdfont
  exe "hi vikiList term=bold cterm=bold gui=bold ctermfg=". s:cm1 ."Cyan guifg=". s:cm1 ."Cyan"
  HiLink vikiDescription vikiList
  hi vikiTableHead term=bold cterm=bold gui=bold ctermbg=Grey guibg=Grey
  exe "hi vikiTableRow ctermbg=". s:cm2 ."Grey guibg=". s:cm2 ."Grey"
  HiLink vikiTableRuler vikiTableRow
  exe "hi vikiSymbols term=bold cterm=bold gui=bold ctermfg=". s:cm1 ."Red guifg=". s:cm1 ."Red"
  exe "hi vikiMarkers term=bold cterm=bold gui=bold ctermfg=". s:cm1 ."Red guifg=". s:cm1 ."Red ctermbg=yellow guibg=yellow"
  hi vikiAnchor term=italic cterm=italic gui=italic ctermfg=grey guifg=grey
  HiLink vikiComment Comment
  " exe "hi vikiString ctermfg=". s:cm1 ."Green guifg=". s:cm1 ."Green"
  HiLink  vikiString String
  hi vikiBold term=bold cterm=bold gui=bold
  HiLink vikiContinousBold vikiBold
  hi vikiItalic term=italic cterm=italic gui=italic
  HiLink vikiContinousItalic vikiItalic
  hi vikiUnderline term=underline cterm=underline gui=underline
  HiLink vikiContinousUnderline vikiUnderline
  exe "hi vikiTypewriter term=underline ctermfg=". s:cm1 ."Grey guifg=". s:cm1 ."Grey". s:twfont
  HiLink vikiContinousTypewriter vikiTypewriter
  exe "hi vikiCommand term=italic ctermfg=". s:cm1 ."Cyan guifg=". s:cm1 ."Cyan"
  
  delcommand HiLink
endif

" let b:current_syntax = "viki"

