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

" Highlight current word as search pattern, but do not jump to next match. 
"
" Atom \V sets following pattern to "very nomagic", i.e. only the backslash has special meaning.
" <cword> selects the (key)word under or after the cursor, just like the '*' command. 
" For \V, \ still must be escaped. We also escape /, because that's done in a search via '/' or '*', too. 
" The search pattern is added to the search history, as '/' or '*' would do. 
" To enable highlighting of the search pattern (in case it was temporarily
" turned off via :nohlsearch), we :set hlsearch, but only if that option is
" globally set. 
nmap * :let @/='\V\<'.escape(expand('<cword>'),'/\').'\>'<bar>call histadd('/',@/)<bar>if &hlsearch<bar>set hlsearch<bar>endif<CR>
nmap g* :let @/='\V'.escape(expand('<cword>'),'/\')<bar>call histadd('/',@/)<bar>if &hlsearch<bar>set hlsearch<bar>endif<CR>

" Highlight selected text in visual mode as search pattern, but do not jump to
" next match. 
"
" Atom \V sets following pattern to "very nomagic", i.e. only the backslash has special meaning.
" As a search pattern we insert an expression (= register) that 
" calls the 'escape()' function on the unnamed register content '@@',
" and escapes the backslash and the character that still has a special 
" meaning in the search command (/|?, respectively).
" This works well even with <Tab> (no need to change ^I into \t),
" but not with a linebreak, which must be changed from ^M to \n.
" This is done with the substitute() function.
" gV avoids automatic reselection of the Visual area in select mode. 
vmap <silent> * :<C-U>let save_unnamedregister=@@<CR>gvy:<C-U>let @/='\V'.substitute(escape(@@,'/\'),"\n",'\\n','ge')<bar>call histadd('/',@/)<bar>if &hlsearch<bar>set hlsearch<bar>endif<bar>:let @@=save_unnamedregister<bar>unlet save_unnamedregister<CR>gV

" vim: set sts=4 sw=4 noexpandtab ff=unix fdm=syntax :
