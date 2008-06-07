" SearchHighlighting.vim: Highlighting of searches via star, auto-search. 
"
" DESCRIPTION:
" Changes the "star" command '*', so that it doesn't jump to the next match. 
" (Unless you supply a <count>, so '1*' now restores the old '*' behavior.)
" If you issue a star command on the same text as before, the search
" highlighting is turned off (via :nohlsearch); the search pattern remains set,
" so a 'n' / 'N' command will turn highlighting on again. With this, you can
" easily toggle highlighting for the current word / visual selection. 
"
" With the disabling of the jump to the next match, there is no difference
" between * and # any more, so the # key can now be used for some other mapping. 
"
" The auto-search functionality instantly highlights the word under the cursor
" when typing or moving around. This can be helpful while browsing source code;
" whenever you position the cursor on an identifier, all other occurrences are
" instantly highlighted. This functionality is toggled on/off via <Leader>*. You
" can also :nohlsearch to temporarily disable the highlighting. 
"
" USAGE:
"   *		Toggle search highlighting for the current whole \<word\> on/off. 
"   g*	    	Toggle search highlighting for the current word on/off. 
"   {Visual}*  	Toggle search highlighting for the selection on/off. 
"
"   <count>*,	Search forward for the <count>'th occurrence of the word nearest
"   <count>g*	to the cursor.
"
"   <Leader>*   Toggle auto-search highlighting. 
"
" INSTALLATION:
" DEPENDENCIES:
" CONFIGURATION:
"   To restore the original '*' behavior, i.e. jumping to the next match, use:
"	let g:SearchHighlighting_NoJump = 0
"   Then, the star commands will behave as usual; they only also turn off
"   auto-search. 
"
" LIMITATIONS:
" ASSUMPTIONS:
" KNOWN PROBLEMS:
" TODO:
"   - VIM versions ???
"   - escaping of search pat. 
"
" Copyright: (C) 2008 by Ingo Karkat
"   The VIM LICENSE applies to this script; see ':help copyright'. 
"
" Maintainer:	Ingo Karkat <ingo@karkat.de>
"
" REVISION	DATE		REMARKS 
"	003	08-Jun-2008	Added original star command behavior. 
"				Made jump behavior configurable. 
"				New star command now also echoes search pattern. 
"	002	07-Jun-2008	Implemented toggling of search highlighting. 
"				Implemented auto-search highlighting. 
"	001	06-Jun-2008	file creation

" Avoid installing twice or when in unsupported VIM version. 
if exists('g:loaded_SearchHighlighting')
    finish
endif
let g:loaded_SearchHighlighting = 1

if ! exists('g:SearchHighlighting_NoJump')
    let g:SearchHighlighting_NoJump = 1
endif

" For the toggling of hlsearch, we would need to be able to query the current
" hlsearch state from VIM. (No this is not &hlsearch, we want to know whether
" :nohlsearch has been issued; &hlsearch is on all the time.) Since there is no
" such way, we work around this with a global flag. There will be discrepancies
" if the user changes the hlsearch state outside of the s:Search() function,
" e.g. by :nohlsearch or 'n' / 'N'. In these cases, the user would need to
" invoke the mapping a second time to get the desired result. 
let s:isSearchOn = 0

function! s:GetSearchPattern( text, isWholeWordSearch )
    " Atom \V sets following pattern to "very nomagic", i.e. only the backslash
    " has special meaning.
    " For \V, \ still must be escaped. We also escape /, because that's done in
    " a search via '/' or '*', too. This works well even with <Tab> (no need to
    " change ^I into \t), but not with a line break, which must be changed from
    " ^M to \n. This is done with the substitute() function.
    return '\V' . (a:isWholeWordSearch ? '\<' : '') . substitute( escape(a:text, '/\'), "\n", '\\n', 'ge' ) . (a:isWholeWordSearch ? '\>' : '')
endfunction
function! s:GetBackwardsSearchPattern( text, isWholeWordSearch )
    return '\V' . (a:isWholeWordSearch ? '\<' : '') . substitute( escape(a:text, '?\'), "\n", '\\n', 'ge' ) . (a:isWholeWordSearch ? '\>' : '')
endfunction

function! s:Search( text, isWholeWordSearch )
    let l:searchPattern = s:GetSearchPattern( a:text, a:isWholeWordSearch )

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

function! s:CountGiven(starCommand)
    if v:count
	execute 'normal! ' . v:count . a:starCommand

	" Note: Without this self-assignment, the former search pattern is
	" highlighted! 
	let @/ = @/

	let s:isSearchOn = 1
	return 1
    else
	return 0
    endif
endfunction

if g:SearchHighlighting_NoJump
    " Highlight current word as search pattern, but do not jump to next match. 
    "
    " If a count is given, preserve the default behavior and jump to the
    " <count>'th occurence. 
    " <cword> selects the (key)word under or after the cursor, just like the star command. 
    " If highlighting is turned on, the search pattern is echoed, just like the star command does. 
    nnoremap <silent>  * :<C-U>call <SID>AutoSearchOff()<bar>if <SID>CountGiven( '*')<bar><bar><SID>Search(expand('<cword>'),1)<bar>if &hlsearch<bar>set hlsearch<bar>endif<bar>echo '/'.@/<bar>else<bar>nohlsearch<bar>endif<CR>
    nnoremap <silent> g* :<C-U>call <SID>AutoSearchOff()<bar>if <SID>CountGiven('g*')<bar><bar><SID>Search(expand('<cword>'),0)<bar>if &hlsearch<bar>set hlsearch<bar>endif<bar>echo '/'.@/<bar>else<bar>nohlsearch<bar>endif<CR>

    " Highlight selected text in visual mode as search pattern, but do not jump to
    " next match. 
    " gV avoids automatic re-selection of the Visual area in select mode. 
    vnoremap <silent> * :<C-U>call <SID>AutoSearchOff()<bar>let save_unnamedregister=@@<CR>gvy:<C-U>if <SID>Search(@@,0)<bar>if &hlsearch<bar>set hlsearch<bar>endif<bar>echo '/'.@/<bar>else<bar>nohlsearch<bar>endif<bar>:let @@=save_unnamedregister<bar>unlet save_unnamedregister<CR>gV
else
    " Search for the [count]'th occurrence of the word nearest to the cursor. 
    "
    " We need <silent>, so that the :call isn't echoed. But this also swallows
    " the echoing of the search pattern done by the star commands. Thus, we
    " explicitly echo the search pattern. 
    "
    " The star command must come first so that it receives the optional [count]. 
    nnoremap <silent>  *  *:call <SID>AutoSearchOff()<bar>echo '/'.@/<CR>
    nnoremap <silent> g* g*:call <SID>AutoSearchOff()<bar>echo '/'.@/<CR>
    nnoremap <silent>  #  #:call <SID>AutoSearchOff()<bar>echo '?'.@/<CR>
    nnoremap <silent> g# g#:call <SID>AutoSearchOff()<bar>echo '?'.@/<CR>

    " Search for selected text in visual mode. 
    vnoremap <silent> * :<C-U>call <SID>AutoSearchOff()<bar>let save_unnamedregister=@@<CR>gvy/<C-R>=<SID>GetSearchPattern(@@,0)<CR><CR>:let @@=save_unnamedregister<bar>unlet save_unnamedregister<bar>echo '/'.@/<CR>gV
    vnoremap <silent> # :<C-U>call <SID>AutoSearchOff()<bar>let save_unnamedregister=@@<CR>gvy?<C-R>=<SID>GetBackwardsSearchPattern(@@,0)<CR><CR>:let @@=save_unnamedregister<bar>unlet save_unnamedregister<bar>echo '?'.@/<CR>gV
endif



function! s:AutoSearch()
    if stridx('sSvV', mode()) != -1
	let l:save_unnamedregister = @@

	let l:captureTextCommands = 'ygv'
	if stridx('sS', mode()) != -1
	    " To be able to yank in select mode, we need to temporarily switch
	    " to visual mode, then back to select mode. 
	    let l:captureTextCommands = "\<C-G>" . l:captureTextCommands . "\<C-G>"
	endif
	execute 'normal! ' . l:captureTextCommands
	let @/ = <SID>GetSearchPattern(@@, 0)

	let @@ = l:save_unnamedregister
    else
	let @/ = <SID>GetSearchPattern(expand('<cword>'), 1)
    endif
endfunction

function! s:AutoSearchOn()
    augroup SearchHighlightingAutoSearch
	autocmd!
	autocmd CursorMoved  * call <SID>AutoSearch()
	autocmd CursorMovedI * call <SID>AutoSearch()
    augroup END
    doautocmd SearchHighlightingAutoSearch CursorMoved
endfunction

function! s:AutoSearchOff()
    if ! exists('#SearchHighlightingAutoSearch#CursorMoved#*')
	" Short-circuit optimization. 
	return
    endif
    augroup SearchHighlightingAutoSearch
	autocmd!
    augroup END

    " If auto-search was turned off by the star command, inform the star command
    " that it must have turned the highlighting on, not off. (This improves the
    " accuracy of the s:isSearchOn workaround.)
    let s:isSearchOn = 0
endfunction

function! s:ToggleAutoSearch()
    if exists('#SearchHighlightingAutoSearch#CursorMoved#*')
	call s:AutoSearchOff()
	echomsg "Disabled auto-search highlighting."
	return 0
    else
	call s:AutoSearchOn()
	echomsg "Enabled auto-search highlighting."
	return 1
    endif
endfunction

nnoremap <script> <Plug>SearchHighlightingAutoSearch :if <SID>ToggleAutoSearch()<bar>if &hlsearch<bar>set hlsearch<bar>endif<bar>else<bar>nohlsearch<bar>endif<CR>
if ! hasmapto('<Plug>SearchHighlightingAutoSearch', 'n')
    nmap <silent> <Leader>* :if <SID>ToggleAutoSearch()<bar>if &hlsearch<bar>set hlsearch<bar>endif<bar>else<bar>nohlsearch<bar>endif<CR>
endif

" vim: set sts=4 sw=4 noexpandtab ff=unix fdm=syntax :
