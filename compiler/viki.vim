" viki.vim
" @Author:      Thomas Link (samul AT web.de)
" @License:     GPL (see http://www.gnu.org/licenses/gpl.txt)
" @Created:     25-Apr-2004.
" @Last Change: 02-Mai-2004.
" @Revision:    0.20
" 
" Description:
" Use deplate as the "compiler" for viki files.
" 

let g:current_compiler="viki"

let s:cpo_save = &cpo
set cpo&vim

if exists("g:deplatePrg")
    exec "setlocal makeprg=".escape(g:deplatePrg, " ")."\\ $*\\ %"
else
    setlocal makeprg=deplate\ $*\ %
endif

setlocal errorformat=%f\ %l:%m,%f\ %l-%*\\d:%m

let &cpo = s:cpo_save
unlet s:cpo_save

" vim: ff=unix
