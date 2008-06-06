" ingosearch.vim: Define custom search commands used by ingo. 
"
"TODO:
" Changes *, so that it doesn't jump to the next match. 
" With this, there is no difference between * and #, so the # key can be used
" for some other mapping. 
"
" Maintainer:	Ingo Karkat <ingo@karkat.de>
"
" REVISION	DATE		REMARKS 
"	001	06-Jun-2008	file creation

" Avoid installing twice or when in unsupported VIM version. 
if exists('g:loaded_ingosearch')
    finish
endif
let g:loaded_ingosearch = 1

" 08/15 47\11 12?34

function! s:Search( text, isWholeWordSearch )
    " Atom \V sets following pattern to "very nomagic", i.e. only the backslash
    " has special meaning.
    " For \V, \ still must be escaped. We also escape /, because that's done in
    " a search via '/' or '*', too. This works well even with <Tab> (no need to
    " change ^I into \t), but not with a linebreak, which must be changed from
    " ^M to \n. This is done with the substitute() function.
    let @/ = '\V' . (a:isWholeWordSearch ? '\<' : '') . substitute( escape(a:text, '/\'), "\n", '\\n', 'ge' ) . (a:isWholeWordSearch ? '\>' : '')

    " The search pattern is added to the search history, as '/' or '*' would do. 
    call histadd('/', @/)

    " To enable highlighting of the search pattern (in case it was temporarily
    " turned off via :nohlsearch), we :set hlsearch, but only if that option is
    " globally set. 
    if &hlsearch
	set hlsearch
    endif
endfunction

" Highlight current word as search pattern, but do not jump to next match. 
"
" <cword> selects the (key)word under or after the cursor, just like the '*' command. 
nmap * :call <SID>Search(expand('<cword>'),1)<CR>
nmap g* :call <SID>Search(expand('<cword>'),0)<CR>

" Highlight selected text in visual mode as search pattern, but do not jump to
" next match. 
" gV avoids automatic reselection of the Visual area in select mode. 
vmap <silent> * :<C-U>let save_unnamedregister=@@<CR>gvy:<C-U>call <SID>Search(@@,0)<bar>:let @@=save_unnamedregister<bar>unlet save_unnamedregister<CR>gV

" vim: set sts=4 sw=4 noexpandtab ff=unix fdm=syntax :
