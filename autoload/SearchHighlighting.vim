" SearchHighlighting.vim: Highlighting of searches via star, auto-search. 
"
" DEPENDENCIES:
"   - ingosearch.vim autoload script. 
"
" Copyright: (C) 2009 by Ingo Karkat
"   The VIM LICENSE applies to this script; see ':help copyright'. 
"
" Maintainer:	Ingo Karkat <ingo@karkat.de>
"
" REVISION	DATE		REMARKS 
"	003	05-Jan-2010	Moved SearchHighlighting#GetSearchPattern() into
"				separate ingosearch.vim utility module. 
"	002	03-Jul-2009	Replaced global g:SearchHighlighting_IsSearchOn
"				flag with s:isSearchOn and
"				SearchHighlighting#SearchOn(),
"				SearchHighlighting#SearchOff() and
"				SearchHighlighting#IsSearch() functions. 
"				The toggle algorithm now only assumes that the hlsearch
"				state is "on" if the state was not explicitly
"				turned on. This allows third parties to :call
"				SearchHighlighting#SearchOff() and have the next
"				toggle command correctly turn highlighting back
"				on. 
"	001	30-May-2009	Moved functions from plugin to separate autoload
"				script.
"				file creation

"- Toggle hlsearch ------------------------------------------------------------
" For the toggling of hlsearch, we would need to be able to query the current
" hlsearch state from Vim. (No this is not &hlsearch, we want to know whether
" :nohlsearch has been issued; &hlsearch is on all the time.) Since there is no
" such way, we work around this with a separate flag, s:isSearchOn. There will
" be discrepancies if the user changes the hlsearch state outside of the
" SearchHighlighting#SearchHighlightingNoJump() function, e.g. by :nohlsearch or
" 'n' / 'N'. In these cases, the user would need to invoke the mapping a second
" time to get the desired result. Other mappings or scripts that change the
" hlsearch state can update the flag by calling SearchHighlighting#SearchOn() /
" SearchHighlighting#SearchOff(). 
let s:isSearchOn = 0


" The last toggle position is initialized with an invalid position. It will be
" set on every toggle, and is invalidated when the search highlighting is
" explicitly set via SearchHighlighting#SearchOn() / 
" SearchHighlighting#SearchOff. 
let s:lastToggleHlsearchPos = []
function! SearchHighlighting#SearchOff()
    let s:isSearchOn = 0
    unlet! s:lastToggleHlsearchPos
endfunction
function! SearchHighlighting#SearchOn()
    let s:isSearchOn = 1
    unlet! s:lastToggleHlsearchPos
endfunction
function! SearchHighlighting#IsSearch()
    return s:isSearchOn
endfunction

" The toggle algorithm assumes that the hlsearch state is "on" unless the state
" was explicitly turned on, or a preceding toggle to "off" happened at the
" current cursor position. 
" With this, the built-in search commands ('/', '?', '*', '#', 'n', 'N') can
" turn on hlsearch without informing us (as long as the jump does not position
" the cursor to the position where the last toggle "off" was done; in this case,
" the algorithm will be wrong and the toggle must be repeated). 
function! SearchHighlighting#ToggleHlsearch()
    let l:currentPos = [ tabpagenr(), winnr(), getpos('.') ]

    let l:isExplicitSetting = ! exists('s:lastToggleHlsearchPos')
    if ! &hlsearch
	let s:isSearchOn = 0
	echo 'hlsearch turned off'
    elseif ! s:isSearchOn && (l:isExplicitSetting || (! l:isExplicitSetting && l:currentPos == s:lastToggleHlsearchPos))
	" Setting this from within a function has no effect. 
	"set hlsearch
	let s:isSearchOn = 1
    else
	" Setting this from within a function has no effect. 
	"nohlsearch
	let s:isSearchOn = 0
	echo ':nohlsearch'
    endif
    let s:lastToggleHlsearchPos = l:currentPos

    return s:isSearchOn
endfunction



"- Search Highlighting --------------------------------------------------------
function! s:ToggleHighlighting( text, isWholeWordSearch )
    let l:searchPattern = ingosearch#GetSearchPattern( a:text, a:isWholeWordSearch, '/' )

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

function! s:DefaultCountStar( starCommand )
    " Note: When typed, [*#nN] open the fold at the search result, but inside a
    " mapping or :normal this must be done explicitly via 'zv'. 
    execute 'normal!' a:starCommand . 'zv'

    " Note: Without this self-assignment, the former search pattern is
    " highlighted! 
    let @/ = @/

    let s:isSearchOn = 1
    " With a count, search is always on; toggling is only done without a count. 
    return 1
endfunction

function! s:VisualCountStar( count, starCommand, text )
    let l:searchPattern = ingosearch#GetSearchPattern( a:text, 0, '/' )

    let @/ = l:searchPattern
    let s:isSearchOn = 1

    " The search pattern is added to the search history, as '/' or '*' would do. 
    call histadd('/', @/)

    " Note: When typed, [*#nN] open the fold at the search result, but inside a
    " mapping or :normal this must be done explicitly via 'zv'. 
    execute 'normal!' a:count . 'nzv'
    return 1
endfunction

" This function can also be used in other scripts, to avoid complicated
" invocations of (and the echoing inside)
" execute "normal \<Plug>SearchHighlightingStar"
function! SearchHighlighting#SearchHighlightingNoJump( starCommand, text, isWholeWordSearch )
    call SearchHighlighting#AutoSearchOff()

    if v:count
	if a:starCommand =~# '^gv'
	    return s:VisualCountStar( v:count, a:starCommand, a:text )
	else
	    return s:DefaultCountStar( v:count . a:starCommand )
	endif
    else
	return s:ToggleHighlighting( a:text, a:isWholeWordSearch )
    endif
endfunction



"- Autosearch -----------------------------------------------------------------
function! s:AutoSearch()
    if stridx("sS\<C-S>vV\<C-V>", mode()) != -1
	let l:save_unnamedregister = @@

	let l:captureTextCommands = 'ygv'
	if stridx("sS\<C-S>", mode()) != -1
	    " To be able to yank in select mode, we need to temporarily switch
	    " to visual mode, then back to select mode. 
	    let l:captureTextCommands = "\<C-G>" . l:captureTextCommands . "\<C-G>"
	endif
	execute 'normal!' l:captureTextCommands
	let @/ = ingosearch#GetSearchPattern(@@, 0, '/')

	let @@ = l:save_unnamedregister
    else
	let @/ = ingosearch#GetSearchPattern(expand('<cword>'), 1, '/')
    endif
endfunction

function! SearchHighlighting#AutoSearchOn()
    augroup SearchHighlightingAutoSearch
	autocmd!
	autocmd CursorMoved  * call <SID>AutoSearch()
	autocmd CursorMovedI * call <SID>AutoSearch()
    augroup END
    doautocmd SearchHighlightingAutoSearch CursorMoved
endfunction

function! SearchHighlighting#AutoSearchOff()
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

function! SearchHighlighting#ToggleAutoSearch()
    if exists('#SearchHighlightingAutoSearch#CursorMoved#*')
	call SearchHighlighting#AutoSearchOff()
	echomsg "Disabled auto-search highlighting."
	return 0
    else
	call SearchHighlighting#AutoSearchOn()
	echomsg "Enabled auto-search highlighting."
	return 1
    endif
endfunction

" vim: set sts=4 sw=4 noexpandtab ff=unix fdm=syntax :
