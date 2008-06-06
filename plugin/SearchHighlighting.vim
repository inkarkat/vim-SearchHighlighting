" ingosearch.vim: Define custom search commands used by ingo. 
"
" Changes the "star" command '*', so that it doesn't jump to the next match. 
" If you issue a star command on the same text as before, the search
" highlighting is turned off (via :nohlsearch); the search pattern remains set,
" so a 'n' / 'N' command will turn highlighting on again. With this, you can
" easily toggle highlighting for the current word / visual selection. 
"
" With the disabling of the jump to the next match, there is no difference
" between * and # any more, so the # key can now be used for some other mapping. 
"
" Maintainer:	Ingo Karkat <ingo@karkat.de>
"
" REVISION	DATE		REMARKS 
"	002	07-Jun-2008	Implemented toggling of search highlighting. 
"	001	06-Jun-2008	file creation

" Avoid installing twice or when in unsupported VIM version. 
if exists('g:loaded_ingosearch')
    finish
endif
let g:loaded_ingosearch = 1

" For the toggling of hlsearch, we would need to be able to query the current
" hlsearch state from VIM. (No this is not &hlsearch, we want to know whether
" :nohlsearch has been issued; &hlsearch is on all the time.) Since there is no
" such way, we work around this with a global flag. There will be discrepancies
" if the user changes the hlsearch state outside of the s:Search() function,
" e.g. by :nohlsearch or 'n' / 'N'. In these cases, the user would need to
" invoke the mapping a second time to get the desired result. 
let s:isSearchOn = 0

function! s:Search( text, isWholeWordSearch )
    " Atom \V sets following pattern to "very nomagic", i.e. only the backslash
    " has special meaning.
    " For \V, \ still must be escaped. We also escape /, because that's done in
    " a search via '/' or '*', too. This works well even with <Tab> (no need to
    " change ^I into \t), but not with a line break, which must be changed from
    " ^M to \n. This is done with the substitute() function.
    let l:searchPattern = '\V' . (a:isWholeWordSearch ? '\<' : '') . substitute( escape(a:text, '/\'), "\n", '\\n', 'ge' ) . (a:isWholeWordSearch ? '\>' : '')

    if @/ == l:searchPattern && s:isSearchOn
	" Note: If simply @/ is reset, one couldn't turn search back on via 'n'
	" / 'N'. So, just return 0 to signal to the mapping to do :nohlsearch. 
	"let @/ = ''
	
	let s:isSearchOn = 0
	return 0
    endif

    let @/ = l:searchPattern
    let s:isSearchOn = 1

    " The search pattern is added to the search history, as '/' or '*' would do. 
    call histadd('/', @/)

    " To enable highlighting of the search pattern (in case it was temporarily
    " turned off via :nohlsearch), we :set hlsearch, but only if that option is
    " globally set. 
    " Note: This somehow cannot be done inside the function, it must be part of
    " the mapping! 
    "if &hlsearch
    "    set hlsearch
    "endif

    return 1
endfunction

" Highlight current word as search pattern, but do not jump to next match. 
"
" <cword> selects the (key)word under or after the cursor, just like the '*' command. 
nmap <silent> * :if <SID>Search(expand('<cword>'),1)<bar>if &hlsearch<bar>set hlsearch<bar>endif<bar>else<bar>nohlsearch<bar>endif<CR>
nmap <silent> g* :if <SID>Search(expand('<cword>'),0)<bar>if &hlsearch<bar>set hlsearch<bar>endif<bar>else<bar>nohlsearch<bar>endif<CR>

" Highlight selected text in visual mode as search pattern, but do not jump to
" next match. 
" gV avoids automatic re-selection of the Visual area in select mode. 
vmap <silent> * :<C-U>let save_unnamedregister=@@<CR>gvy:<C-U>if <SID>Search(@@,0)<bar>if &hlsearch<bar>set hlsearch<bar>endif<bar>else<bar>nohlsearch<bar>endif<bar>:let @@=save_unnamedregister<bar>unlet save_unnamedregister<CR>gV

" vim: set sts=4 sw=4 noexpandtab ff=unix fdm=syntax :
