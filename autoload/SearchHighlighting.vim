" SearchHighlighting.vim: Highlighting of searches via star, auto-highlighting.
"
" DEPENDENCIES:
"   - ingo-library.vim plugin
"
" Copyright: (C) 2009-2019 Ingo Karkat
"   The VIM LICENSE applies to this script; see ':help copyright'.
"
" Maintainer:	Ingo Karkat <ingo@karkat.de>
let s:save_cpo = &cpo
set cpo&vim

function! SearchHighlighting#LastSearchPatternChanged()
    call ingo#event#TriggerCustom('LastSearchPatternChanged')
endfunction

function! s:SetSearchPatternAndHistory( searchPattern )
    let @/ = a:searchPattern

    " The search pattern is added to the search history, as '/' or '*' would do.
    call histadd('/', @/)

    call SearchHighlighting#LastSearchPatternChanged()
endfunction


"- Toggle hlsearch ------------------------------------------------------------

if ! exists('v:hlsearch')
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

function! s:ToggleHighlighting( searchPattern )
    if @/ == a:searchPattern && s:isSearchOn
	" Note: If simply @/ is reset, one couldn't turn search back on via 'n'
	" / 'N'. So, just return 0 to signal to the mapping to do :nohlsearch.
	"let @/ = ''

	let s:isSearchOn = 0
	return 0
    endif

    let s:isSearchOn = 1
    call s:SetSearchPatternAndHistory(a:searchPattern)
    return 1
endfunction
else
function! SearchHighlighting#SearchOff()
endfunction
function! SearchHighlighting#SearchOn()
endfunction
function! SearchHighlighting#IsSearch()
    return v:hlsearch
endfunction
function! SearchHighlighting#ToggleHlsearch()
    if ! &hlsearch
	echo 'hlsearch turned off'
	return 0
    elseif v:hlsearch
	" Setting this from within a function has no effect.
	"nohlsearch
	echo ':nohlsearch'
	return 0
    else
	" Setting this from within a function has no effect.
	"set hlsearch
	return 1
    endif
endfunction

function! s:ToggleHighlighting( searchPattern )
    if @/ == a:searchPattern && v:hlsearch
	" Note: If simply @/ is reset, one couldn't turn search back on via 'n'
	" / 'N'. So, just return 0 to signal to the mapping to do :nohlsearch.
	"let @/ = ''

	return 0
    endif

    call s:SetSearchPatternAndHistory(a:searchPattern)
    return 1
endfunction
endif



"- Search Highlighting --------------------------------------------------------

function! s:DefaultCountStar( starCommand )
    " Note: When typed, [*#nN] open the fold at the search result, but inside a
    " mapping or :normal this must be done explicitly via 'zv'.
    execute 'normal!' a:starCommand . 'zv'

    " Note: Without this self-assignment, the former search pattern is
    " highlighted!
    let @/ = @/
    call SearchHighlighting#SearchOn()

    call SearchHighlighting#LastSearchPatternChanged()

    " With a count, search is always on; toggling is only done without a count.
    return 1
endfunction

function! s:VisualCountStar( count, searchPattern )
    call SearchHighlighting#SearchOn()

    call s:SetSearchPatternAndHistory(a:searchPattern)

    " Note: When typed, [*#nN] open the fold at the search result, but inside a
    " mapping or :normal this must be done explicitly via 'zv'.
    execute 'normal!' a:count . 'nzv'

    return 1
endfunction

function! s:OffsetStar( count, searchPattern, offsetFromEnd )
    call SearchHighlighting#SearchOn()

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

    return l:prefix . ' ' .
    \   s:OffsetCommand(a:count, '/', a:searchPattern, 'e' . (a:offsetFromEnd > 0 ? -1 * a:offsetFromEnd : '')) .
    \   l:suffix
endfunction
function! s:OffsetCommand( count, searchCommand, searchPattern, offset ) abort
    " XXX: We cannot just :execute the command here, the offset part would be
    " lost on search repetitions via n/N. So instead return the Ex command to
    " the mapping for execution. This is possible here because we don't need the
    " return value to indicate the toggle state, as in the other mappings.
    return printf("normal! %s%s%s%s%s\<CR>",
    \   (a:count > 1 ? a:count : ''),
    \   a:searchCommand,
    \   ingo#escape#OnlyUnescaped(a:searchPattern, a:searchCommand),
    \   a:searchCommand,
    \   a:offset
    \)
endfunction
let s:offsetPostCommand = ''
function! SearchHighlighting#OffsetPostCommand()
    call SearchHighlighting#LastSearchPatternChanged()
    execute s:offsetPostCommand
    let s:offsetPostCommand = ''
endfunction

" This function can also be used in other scripts, to avoid complicated
" invocations of (and the echoing inside)
" execute "normal \<Plug>SearchHighlightingStar"
function! SearchHighlighting#SearchHighlightingNoJump( starCommand, count, text )
    if empty(a:text)
	if a:starCommand =~# 'c'
	    " Note: Different return type (command vs. success flag) for "c*".
	    return 'echoerr "E348: No string under cursor"'
	else
	    call ingo#err#Set('E348: No string under cursor')
	    return 0
	endif
    else
	call ingo#err#Clear()
    endif

    if exists('#SearchHighlightingAutoSearch#CursorMoved#*')
	call SearchHighlighting#AutoSearch#Off()
    endif

    if a:starCommand =~# 'W' && a:starCommand !~# 'g'
	let l:searchPattern = ingo#regexp#MakeWholeWORDSearch(a:text, ingo#regexp#EscapeLiteralText(a:text, '/'))
    else
	let l:searchPattern = ingo#regexp#FromLiteralText(a:text, (a:starCommand !~# 'g'), '/')
    endif

    if a:starCommand =~# 'c'
	if a:starCommand =~# 'W'
	    let [l:startPos, l:endPos] = ingo#selection#frompattern#GetPositions('\%' . col('.') . 'c\s*\zs\S\+', line('.'))
	else
	    let [l:startPos, l:endPos] = ingo#selection#frompattern#GetPositions('\%' . col('.') . 'c\%(\%(\k\@!.\)*\zs\k\+\|\%(\k*\|\s*\)\zs\%(\k\@!\S\)\+\)', line('.'))
	endif
	if l:startPos != [0, 0]
	    let l:cwordAfterCursor = ingo#text#Get(l:startPos, l:endPos)
	    if strpart(a:text, len(a:text) - len(l:cwordAfterCursor)) ==# l:cwordAfterCursor
		let l:offsetFromEnd = ingo#compat#strchars(l:cwordAfterCursor) - 1
"****D echomsg '****' string(l:cwordAfterCursor) l:offsetFromEnd
		" Note: Different return type (command vs. success flag) for "c*".
		return s:OffsetStar(a:count, l:searchPattern, l:offsetFromEnd)
	    endif
	endif
	return 'echoerr "E348: No string under cursor"'
    elseif a:starCommand ==# 'gv*'
	if visualmode() ==# "\<C-v>"
	    " For a blockwise visual selection, don't just match the block's
	    " lines on their own, but also when contained in other text. To
	    " completely implement this, we would need a back-reference to the
	    " match's start virtual column, but there's no such atom. So we can
	    " just build a regular expression that matches each block's line
	    " anywhere in subsequent lines, not necessarily left-aligned.
	    " To avoid matching the text in between, we stop the match after the
	    " first block's line.
	    let l:searchPattern = substitute(l:searchPattern, '\\n', '.*\\n.*', 'g')
	    let l:searchPattern = substitute(l:searchPattern, '\.\*\\n\.\*', '\\ze&', '')
	endif

	if a:count
	    return s:VisualCountStar(a:count, l:searchPattern)
	else
	    return s:ToggleHighlighting(l:searchPattern)
	endif
    else
	if a:count
	    if a:starCommand =~# 'W$'
		return s:VisualCountStar(a:count, l:searchPattern)
	    else
		return s:DefaultCountStar(a:count . a:starCommand)
	    endif
	else
	    return s:ToggleHighlighting(l:searchPattern)
	endif
    endif
endfunction

function! SearchHighlighting#RepeatWithCurrentPosition( isBackward, count )
    let [l:isFound, l:offset] = s:GetOffsetFromInsideMatch(a:isBackward)
    if ! l:isFound
	let [l:isFound, l:offset] = s:GetOffsetFromSameLine(a:isBackward)
    endif

    if l:isFound
	call SearchHighlighting#SearchOn()
	return s:OffsetCommand(a:count, (a:isBackward ? '?' : '/'), @/, l:offset)
    else
	return 'echoerr printf("Could not find a nearby match for %s", @/)'
    endif
endfunction
function! s:GetOffset( isBackward, match ) abort
    let l:here = getpos('.')[1:2]
    let l:referencePos = (a:isBackward ? a:match[0] : a:match[1])
    let l:textToCursor = call('ingo#text#Get', ingo#pos#Sort([l:referencePos, l:here]))
    let l:offsetFromReference = ingo#compat#strchars(l:textToCursor) - 1
    return (l:offsetFromReference == 0 ?
    \   '' :
    \   (a:isBackward ? 's' : 'e') .
    \       string((ingo#pos#IsBefore(l:here, l:referencePos) ? -1 : 1) * l:offsetFromReference)
    \)
endfunction
function! s:GetOffsetFromInsideMatch( isBackward ) abort
    let l:match = ingo#area#frompattern#GetCurrent(@/)
    return (l:match[0] == [0, 0] ?
    \   [0, ''] :
    \   [1, s:GetOffset(a:isBackward, l:match)]
    \)
endfunction
function! s:GetOffsetFromSameLine( isBackward ) abort
    let l:thisLnum = line('.')
    let l:matches = ingo#area#frompattern#Get(l:thisLnum, l:thisLnum, @/, 0, 0)

    if empty(l:matches)
	return [0, '']
    elseif len(l:matches) == 1
	return [1, s:GetOffset(a:isBackward, l:matches[0])]
    else
	" Choose the one match with the smallest offset.
	let l:offsets = map(l:matches, 's:GetOffset(a:isBackward, v:val)')
	let l:smallestOffset = sort(l:offsets, 's:OffsetCompare')[0]
	return [1, l:smallestOffset]
    endif
endfunction
function! s:OffsetCompare( ... ) abort
    let l:absoluteOffsets = map(copy(a:000), 'matchstr(v:val, "\\d\\+$")')
    return call('ingo#collections#numsort', l:absoluteOffsets)
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo
" vim: set ts=8 sts=4 sw=4 noexpandtab ff=unix fdm=syntax :
