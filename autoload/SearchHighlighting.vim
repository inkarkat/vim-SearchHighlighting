" SearchHighlighting.vim: Highlighting of searches via star, auto-highlighting.
"
" DEPENDENCIES:
"   - ingo/compat.vim autoload script
"   - ingo/err.vim autoload script
"   - ingo/regexp.vim autoload script
"   - ingo/register.vim autoload script
"
" Copyright: (C) 2009-2013 Ingo Karkat
"   The VIM LICENSE applies to this script; see ':help copyright'.
"
" Maintainer:	Ingo Karkat <ingo@karkat.de>
"
" REVISION	DATE		REMARKS
"   1.20.013	18-Nov-2013	Use ingo#register#KeepRegisterExecuteOrFunc().
"   1.20.012	07-Aug-2013	ENH: Add ,* search that keeps the current
"				position within the current word when jumping to
"				subsequent matches.
"				Correctly emulate * behavior on whitespace-only
"				lines where there's no cword: Issue "E348: No
"				string under cursor".
"   1.11.011	24-May-2013	Move ingosearch.vim to ingo-library.
"   1.10.010	19-Jan-2013	For a blockwise visual selection, don't just
"				match the block's lines on their own, but also
"				when contained in other text.
"				BUG: For {Visual}*, a [count] isn't considered.
"				The problem is that getting the visual selection
"				clobbers v:count. Instead of evaluating v:count
"				only inside
"				SearchHighlighting#SearchHighlightingNoJump(),
"				pass it into the function as an argument before
"				the selected text, so that it gets evaluated
"				before the normal mode command clears the count.
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
let s:save_cpo = &cpo
set cpo&vim

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

function! s:ToggleHighlighting( searchPattern )
    if @/ == a:searchPattern && s:isSearchOn
	" Note: If simply @/ is reset, one couldn't turn search back on via 'n'
	" / 'N'. So, just return 0 to signal to the mapping to do :nohlsearch.
	"let @/ = ''

	let s:isSearchOn = 0
	return 0
    endif

    let @/ = a:searchPattern
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

function! s:VisualCountStar( count, searchPattern )
    let @/ = a:searchPattern
    let s:isSearchOn = 1

    " The search pattern is added to the search history, as '/' or '*' would do.
    call histadd('/', @/)

    " Note: When typed, [*#nN] open the fold at the search result, but inside a
    " mapping or :normal this must be done explicitly via 'zv'.
    execute 'normal!' a:count . 'nzv'

    return 1
endfunction

function! s:OffsetStar( count, searchPattern, offsetFromEnd )
    let s:isSearchOn = 1

    if ! g:SearchHighlighting_NoJump || a:count
	let l:prefix = ''
	" Note: When typed, [*#nN] open the fold at the search result, but
	" inside a mapping or :normal this must be done explicitly via 'zv'.
	let l:suffix = 'zv'
	let s:offsetPostCommand = ''
    else
	let l:prefix = 'keepjumps'
	let l:suffix = ''
	let s:offsetPostCommand = 'call winrestview(' . string(winsaveview()) . ')'
	" When this is returned to the mapping and executed directly, it is
	" echoed in the command line, thereby obscuring the search command.
	" Instead, execute it separately.
    endif

    " XXX: We cannot just :execute the command here, the offset part would be
    " lost on search repetitions via n/N. So instead return the Ex command to
    " the mapping for execution. This is possible here because we don't need the
    " return value to indicate the toggle state, as in the other mappings.
    return printf("%s normal! %s/%s/e%s\<CR>%s",
    \   l:prefix,
    \   (a:count > 1 ? a:count : ''),
    \   a:searchPattern,
    \   (a:offsetFromEnd > 1 ? -1 * a:offsetFromEnd : ''),
    \   l:suffix
    \)
endfunction
function! SearchHighlighting#OffsetPostCommand()
    execute s:offsetPostCommand
    let s:offsetPostCommand = ''
endfunction

" This function can also be used in other scripts, to avoid complicated
" invocations of (and the echoing inside)
" execute "normal \<Plug>SearchHighlightingStar"
function! SearchHighlighting#SearchHighlightingNoJump( starCommand, count, text, isWholeWordSearch )
    if empty(a:text)
	call ingo#err#Set('E348: No string under cursor')
	return 0
    else
	call ingo#err#Clear()
    endif

    call SearchHighlighting#AutoSearchOff()

    let l:searchPattern = ingo#regexp#FromLiteralText(a:text, a:isWholeWordSearch, '/')

    if a:starCommand ==# 'c*'
	let [l:startPos, l:endPos] = ingo#selection#frompattern#GetPositions('\%' . col('.') . 'c\%(\%(\k\@!.\)*\zs\k\+\|\%(\k*\|\s*\)\zs\%(\k\@!\S\)\+\)', line('.'))
	if l:startPos != [0, 0]
	    let l:cwordAfterCursor = ingo#text#Get(l:startPos, l:endPos)
	    if strpart(a:text, len(a:text) - len(l:cwordAfterCursor)) ==# l:cwordAfterCursor
		let l:offsetFromEnd = ingo#compat#strchars(l:cwordAfterCursor) - 1
"****D echomsg '****' string(l:cwordAfterCursor) l:offsetFromEnd
		return s:OffsetStar( count, l:searchPattern, l:offsetFromEnd)
	    endif
	endif
	return 'echoerr "E348: No string under cursor"'
    elseif a:starCommand ==# 'gv*'
	if visualmode() ==# "\<C-v>"
	    " For a blockwise visual selection, don't just match the block's
	    " lines on their own, but also when contained in other text.
	    " To completely implement this, we would need a backreference to the
	    " match's start virtual column, but there's no such atom. So we can
	    " just build a reguluar expression that matches each block's line
	    " anywhere in subsequent lines, not necessarily left-aligned.
	    " To avoid matching the text in between, we stop the match after the
	    " first block's line.
	    let l:searchPattern = substitute(l:searchPattern, '\\n', '\\ze.*\\n.*', '')
	    let l:searchPattern = substitute(l:searchPattern, '\\n', '.*\\n.*', 'g')
	endif

	if a:count
	    return s:VisualCountStar(a:count, l:searchPattern)
	else
	    return s:ToggleHighlighting(l:searchPattern)
	endif
    else
	if a:count
	    return s:DefaultCountStar(a:count . a:starCommand)
	else
	    return s:ToggleHighlighting(l:searchPattern)
	endif
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

	call ingo#register#KeepRegisterExecuteOrFunc(
	\   'execute "normal! ' . l:captureTextCommands . '" | let @/ = ingo#regexp#EscapeLiteralText(@", "/")'
	\)
    else
	" Search for the configured entity.
	if s:AutoSearchWhat ==# 'line'
	    let l:lineText = substitute(getline('.'), '^\s*\(.\{-}\)\s*$', '\1', '')
	    if ! empty(l:lineText)
		let @/ = '^\s*' . ingo#regexp#EscapeLiteralText(l:lineText, '/') . '\s*$'
	    endif
	elseif s:AutoSearchWhat ==# 'exactline'
	    let l:lineText = getline('.')
	    if ! empty(l:lineText)
		let @/ = '^' . ingo#regexp#EscapeLiteralText(l:lineText, '/') . '$'
	    endif
	elseif s:AutoSearchWhat ==# 'wword'
	    let @/ = ingo#regexp#FromLiteralText(expand('<cword>'), 1, '/')
	elseif s:AutoSearchWhat ==# 'wWORD'
	    let @/ = '\%(^\|\s\)\zs' . ingo#regexp#EscapeLiteralText(expand('<cWORD>'), '/') . '\ze\%(\s\|$\)'
	elseif s:AutoSearchWhat ==? 'cword'
	    let @/ = ingo#regexp#EscapeLiteralText(expand('<'. s:AutoSearchWhat . '>'), '/')
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

let &cpo = s:save_cpo
unlet s:save_cpo
" vim: set ts=8 sts=4 sw=4 noexpandtab ff=unix fdm=syntax :
