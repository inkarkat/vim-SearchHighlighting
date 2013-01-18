" SearchHighlighting.vim: Highlighting of searches via star, auto-highlighting.
"
" DEPENDENCIES:
"   - ingosearch.vim autoload script
"
" Copyright: (C) 2009-2013 Ingo Karkat
"   The VIM LICENSE applies to this script; see ':help copyright'.
"
" Maintainer:	Ingo Karkat <ingo@karkat.de>
"
" REVISION	DATE		REMARKS
"   1.02.009	17-Jan-2013	Do not trigger modeline processing when enabling
"				auto-search highlighting.
"   1.01.008	03-Dec-2012	FIX: Prevent repeated error message when
"				an invalid {what} was given to
"				:SearchAutoHighlighting.
"   1.00.007	04-Jul-2012	Minor: Tweak command completion.
"	006	18-Apr-2012	Make the {what} argument to
"				:SearchAutoHighlighting optional.
"	005	17-Feb-2012	Add :AutoSearch {what} and :NoAutoSearch
"				commands.
"				ENH: Extend Autosearch to highlight other
"				occurrences of the line, cWORD, etc.
"				Restore the last used search pattern when
"				Autosearch is turned off.
"				Use SearchHighlighting#AutoSearchOff() instead
"				of modifying s:isSearchOn directly.
"	004	14-Jan-2011	FIX: Auto-search could clobber the blockwise
"				yank mode of the unnamed register.
"	003	05-Jan-2010	Moved SearchHighlighting#GetSearchPattern() into
"				separate ingosearch.vim utility module and
"				renamed to
"				ingosearch#LiteralTextToSearchPattern().
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
    let l:searchPattern = ingosearch#LiteralTextToSearchPattern( a:text, a:isWholeWordSearch, '/' )

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
    let l:searchPattern = ingosearch#LiteralTextToSearchPattern( a:text, 0, '/' )

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

let s:AutoSearchWhat = 'wword'
let s:AutoSearchWhatValues = ['wword', 'wWORD', 'cword', 'cWORD', 'exactline', 'line']
function! SearchHighlighting#AutoSearchComplete( ArgLead, CmdLine, CursorPos )
    return filter(copy(s:AutoSearchWhatValues), 'v:val =~# "\\V" . escape(a:ArgLead, "\\")')
endfunction
function! s:AutoSearch()
    if stridx("sS\<C-S>vV\<C-V>", mode()) != -1
	" In visual and select mode, search for the selected text.

	let l:captureTextCommands = 'ygv'
	if stridx("sS\<C-S>", mode()) != -1
	    " To be able to yank in select mode, we need to temporarily switch
	    " to visual mode, then back to select mode.
	    let l:captureTextCommands = "\<C-G>" . l:captureTextCommands . "\<C-G>"
	endif

	let l:save_clipboard = &clipboard
	set clipboard= " Avoid clobbering the selection and clipboard registers.
	let l:save_reg = getreg('"')
	let l:save_regmode = getregtype('"')

	execute 'normal!' l:captureTextCommands
	let @/ = ingosearch#LiteralTextToSearchPattern(@@, 0, '/')

	call setreg('"', l:save_reg, l:save_regmode)
	let &clipboard = l:save_clipboard
    else
	" Search for the configured entity.
	if s:AutoSearchWhat ==# 'line'
	    let l:lineText = substitute(getline('.'), '^\s*\(.\{-}\)\s*$', '\1', '')
	    if ! empty(l:lineText)
		let @/ = '^\s*' . ingosearch#LiteralTextToSearchPattern(l:lineText, 0, '/') . '\s*$'
	    endif
	elseif s:AutoSearchWhat ==# 'exactline'
	    let l:lineText = getline('.')
	    if ! empty(l:lineText)
		let @/ = '^' . ingosearch#LiteralTextToSearchPattern(l:lineText, 0, '/') . '$'
	    endif
	elseif s:AutoSearchWhat ==# 'wword'
	    let @/ = ingosearch#LiteralTextToSearchPattern(expand('<cword>'), 1, '/')
	elseif s:AutoSearchWhat ==# 'wWORD'
	    let @/ = '\%(^\|\s\)\zs' . ingosearch#LiteralTextToSearchPattern(expand('<cWORD>'), 0, '/') . '\ze\%(\s\|$\)'
	elseif s:AutoSearchWhat ==? 'cword'
	    let @/ = ingosearch#LiteralTextToSearchPattern(expand('<'. s:AutoSearchWhat . '>'), 0, '/')
	else
	    throw 'ASSERT: Unknown search entity ' . string(s:AutoSearchWhat)
	endif
    endif
endfunction

function! SearchHighlighting#AutoSearchOn()
    augroup SearchHighlightingAutoSearch
	autocmd!
	autocmd CursorMoved  * call <SID>AutoSearch()
	autocmd CursorMovedI * call <SID>AutoSearch()
    augroup END
    if v:version == 703 && has('patch438') || v:version > 703
	doautocmd <nomodeline> SearchHighlightingAutoSearch CursorMoved
    else
	doautocmd              SearchHighlightingAutoSearch CursorMoved
    endif
endfunction

function! SearchHighlighting#AutoSearchOff()
    if ! exists('#SearchHighlightingAutoSearch#CursorMoved#*')
	" Short-circuit optimization.
	return 0
    endif
    augroup SearchHighlightingAutoSearch
	autocmd!
    augroup END

    " Restore the last used search pattern.
    let @/ = histget('search', -1)

    " If auto-search was turned off by the star command, inform the star command
    " that it must have turned the highlighting on, not off. (This improves the
    " accuracy of the s:isSearchOn workaround.)
    call SearchHighlighting#SearchOff()

    return 1
endfunction

function! SearchHighlighting#ToggleAutoSearch()
    if exists('#SearchHighlightingAutoSearch#CursorMoved#*')
	call SearchHighlighting#AutoSearchOff()
	echomsg 'Disabled search auto-highlighting'
	return 0
    else
	call SearchHighlighting#AutoSearchOn()
	echomsg 'Enabled search auto-highlighting of' s:AutoSearchWhat
	return 1
    endif
endfunction

function! SearchHighlighting#SetAutoSearch( ... )
    if a:0
	if index(s:AutoSearchWhatValues, a:1) == -1
	    let v:errmsg = 'Unknown search entity "' . a:1 . '"; must be one of: ' . join(s:AutoSearchWhatValues, ', ')
	    echohl ErrorMsg
	    echomsg v:errmsg
	    echohl None

	    return 0
	endif
	let s:AutoSearchWhat = a:1
    endif

    return 1
endfunction

" vim: set ts=8 sts=4 sw=4 noexpandtab ff=unix fdm=syntax :
