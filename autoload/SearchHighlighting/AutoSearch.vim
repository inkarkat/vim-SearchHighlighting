" SearchHighlighting/AutoSearch.vim: Auto-highlighting of the stuff under the cursor.
"
" DEPENDENCIES:
"   - ingo-library.vim plugin
"   - SearchRepeat.vim autoload script (optional)
"
" Copyright: (C) 2009-2019 Ingo Karkat
"   The VIM LICENSE applies to this script; see ':help copyright'.
"
" Maintainer:	Ingo Karkat <ingo@karkat.de>
let s:save_cpo = &cpo
set cpo&vim

let g:AutoSearchWhat = 'wword'
let s:AutoSearchWhatValues = ['wword', 'wWORD', 'cword', 'cWORD', 'exactline', 'exactline-iw', 'exactline-nw', 'line', 'line-iw', 'line-nw', 'from-cursor', 'from-cursor-iw', 'from-cursor-nw', 'to-cursor', 'to-cursor-iw', 'to-cursor-nw', 'selection', 'selection-iw', 'selection-nw']
call ingo#plugin#cmdcomplete#MakeFirstArgumentFixedListCompleteFunc(s:AutoSearchWhatValues, '', 'SearchHighlightingAutoSearchCompleteFunc')
function! SearchHighlighting#AutoSearch#Complete( ... )
    return call('SearchHighlightingAutoSearchCompleteFunc', a:000)
endfunction
function! s:SetLiteralSearch( prefixExpr, text, suffixExpr, AutoSearchWhat )
    if a:AutoSearchWhat =~# '-[in]w$'
	let l:flexibleWhitespaceAndCommentPrefixPattern = ingo#regexp#comments#GetFlexibleWhitespaceAndCommentPrefixPattern(a:AutoSearchWhat =~# 'nw')

	" Note: When splitting, need to always use isAllowEmpty = 0, as the
	" algorithm requires non-empty separators (and we don't want to allow
	" whitespace between any character, just optional whitespace where
	" there's currently some).
	let @/ = join(
	\   ingo#collections#fromsplit#MapItemsAndSeparators(
	\       a:text,
	\       ingo#regexp#comments#GetFlexibleWhitespaceAndCommentPrefixPattern(0),
	\       'ingo#regexp#EscapeLiteralText(v:val, "/")',
	\       string(l:flexibleWhitespaceAndCommentPrefixPattern)
	\   ),
	\   ''
	\)
    else
	let @/ = (empty(a:text) ?
	\   '' :
	\   a:prefixExpr . ingo#regexp#EscapeLiteralText(a:text, '/') . a:suffixExpr
	\)
    endif
endfunction
function! s:GetFromScope( variableName, defaultValue )
    return ingo#plugin#setting#GetFromScope(a:variableName, ['w', 't', 'g'], a:defaultValue)
endfunction
function! s:GetScope( variableName )
    return ingo#plugin#setting#GetScope(a:variableName, ['w', 't', 'g'])
endfunction
let s:isNormalSearch = SearchHighlighting#IsSearch()
let s:isAutoSearch = 0
let s:currentLocation = [0, 0]
function! s:AutoSearch( mode )
    let l:currentLocation = [tabpagenr(), winnr()]
    let l:isLocationChange = (l:currentLocation != s:currentLocation)
    let s:currentLocation = l:currentLocation

    let l:isAutoSearch = s:GetFromScope('AutoSearch', 0)
    let l:isAutoSearchScopeChange = (l:isAutoSearch != s:isAutoSearch)
    let s:isAutoSearch = l:isAutoSearch

    if ! l:isAutoSearch
	call s:RestoreLastSearchPattern()
	return l:isAutoSearchScopeChange
    elseif l:isAutoSearchScopeChange
	" Record whether normal search highlighting was on in order to be able
	" to restore that highlighting state when going to a window that doesn't
	" have Auto Search on.
	let s:isNormalSearch = SearchHighlighting#IsSearch()
    endif


    if stridx("sS\<C-s>vV\<C-v>", a:mode) != -1
	" In visual and select mode, search for the selected text.

	let l:captureTextCommands = 'ygv'
	if stridx("sS\<C-s>", a:mode) != -1
	    " To be able to yank in select mode, we need to temporarily switch
	    " to visual mode, then back to select mode.
	    let l:captureTextCommands = "\<C-g>" . l:captureTextCommands . "\<C-g>"
	endif

	let l:scope = s:GetScope('AutoSearch')
	call ingo#register#KeepRegisterExecuteOrFunc(
	\   'execute "normal! ' . l:captureTextCommands . '" | let ' . l:scope . ':AutoSearch_SelectedText = @" | let @/ = ingo#regexp#EscapeLiteralText(@", "/")'
	\)
    else
	" Search for the configured entity.
	let l:AutoSearchWhat = s:GetFromScope('AutoSearchWhat', 'wword')
	if l:AutoSearchWhat =~# '^line'
	    let l:lineText = substitute(getline('.'), '^\s*\(.\{-}\)\s*$', '\1', '')
	    call s:SetLiteralSearch('^\s*', l:lineText, '\s*$', l:AutoSearchWhat)
	elseif l:AutoSearchWhat =~# '^exactline'
	    call s:SetLiteralSearch('^', getline('.'), '$', l:AutoSearchWhat)
	elseif l:AutoSearchWhat ==# 'wword'
	    let @/ = ingo#regexp#FromLiteralText(expand('<cword>'), 1, '/')
	elseif l:AutoSearchWhat ==# 'wWORD'
	    let l:cWORD = expand('<cWORD>')
	    call s:SetLiteralSearch('\%(^\|\s\)\zs', l:cWORD, '\ze\%(\s\|$\)', l:AutoSearchWhat)
	elseif l:AutoSearchWhat ==? 'cword'
	    let @/ = ingo#regexp#EscapeLiteralText(expand('<'. l:AutoSearchWhat . '>'), '/')
	elseif l:AutoSearchWhat =~# '^from-cursor'
	    let l:cursorText = ingo#strdisplaywidth#CutLeft(getline('.'), virtcol('.') - 1)[1]
	    call s:SetLiteralSearch('', l:cursorText, '$', l:AutoSearchWhat)
	elseif l:AutoSearchWhat =~# '^to-cursor'
	    let l:cursorText = ingo#strdisplaywidth#strleft(getline('.'), virtcol('.'))
	    call s:SetLiteralSearch('^', l:cursorText, '', l:AutoSearchWhat)
	elseif l:AutoSearchWhat =~# '^selection'
	    let l:scope = s:GetScope('AutoSearch')
	    if l:isLocationChange && exists(l:scope . ':AutoSearch_SelectedText')
		execute 'call s:SetLiteralSearch("", ' l:scope . ':AutoSearch_SelectedText, "", l:AutoSearchWhat)'
	    endif
		" Else: Just search for the selected text, nothing in normal mode.
	else
	    throw 'ASSERT: Unknown search entity ' . string(l:AutoSearchWhat)
	endif
    endif

    " Inform SearchRepeat.vim that this change was "automatic", not initiated by
    " the user, so that the repeated search does not revert to standard search.
    silent! call SearchRepeat#UpdateLastSearchPattern()

    return l:isAutoSearchScopeChange
endfunction
function! SearchHighlighting#AutoSearch#RestoreHighlightCommand()
    if s:isAutoSearch && &hlsearch && ! SearchHighlighting#IsSearch()
	call SearchHighlighting#SearchOn()
	return 'set hlsearch'
    elseif ! s:isAutoSearch && ! s:isNormalSearch && &hlsearch
	call SearchHighlighting#SearchOff()
	return 'nohlsearch'
    else
	return ''
    endif
endfunction

function! SearchHighlighting#AutoSearch#On()
    augroup SearchHighlightingAutoSearch
	autocmd!
	autocmd CursorMoved  *
	\   if <SID>AutoSearch(mode()) && ! empty(SearchHighlighting#AutoSearch#RestoreHighlightCommand()) |
	\       call feedkeys("\<C-\>\<C-n>:" . SearchHighlighting#AutoSearch#RestoreHighlightCommand() . "\<CR>", 'n') |
	\   endif
	autocmd CursorMovedI *
	\   if <SID>AutoSearch(mode()) && ! empty(SearchHighlighting#AutoSearch#RestoreHighlightCommand()) |
	\       call feedkeys("\<C-\>\<C-o>:" . SearchHighlighting#AutoSearch#RestoreHighlightCommand() . "\<CR>", 'n') |
	\   endif
    augroup END

    call s:TriggerAutoSaveUpdate()
endfunction
function! s:TriggerAutoSaveUpdate()
    call ingo#event#Trigger('SearchHighlightingAutoSearch CursorMoved')
endfunction

function! SearchHighlighting#AutoSearch#Off( ... )
    if ! exists('#SearchHighlightingAutoSearch#CursorMoved#*')
	" Short-circuit optimization; Auto Search already disabled.
	return 0
    endif

    if a:0
	let l:isExplicitTurnOff = a:2

	if a:1 ==# 'g'
	    let l:isExplicitTurnOff = 1 " The distinction doesn't make sense for the global flag.
	    if a:2
		" Turn off all other scopes, too.
		call s:RemoveScopedAutoSearches()
	    endif
	endif

	if l:isExplicitTurnOff
	    execute 'let' a:1 . ':AutoSearch = 0'
	else
	    execute 'unlet!' a:1 . ':AutoSearch'
	endif
    else
	" Find the scope where Auto Search is active and turn off that scope.
	if exists('w:AutoSearch')
	    let w:AutoSearch = 0
	elseif exists('t:AutoSearch')
	    let t:AutoSearch = 0
	elseif exists('g:AutoSearch')
	    let g:AutoSearch = 0
	endif
    endif

    call s:TriggerAutoSaveUpdate()
    call s:DisableHooksIfNoAutoSearchAtAll()
    return 1
endfunction
function! s:RemoveScopedAutoSearches()
    " Since there's no unlettabwinvar(), we have to visit every tab page /
    " window that has a AutoSearch variable defined.
    let [l:currentTabNr, l:currentWinNr] = [tabpagenr(), winnr()]
    for l:tabNr in range(1, tabpagenr('$'))
	for l:winNr in range(1, tabpagewinnr(l:tabNr, '$'))
	    if gettabwinvar(l:tabNr, l:winNr, 'AutoSearch') isnot# ''
		noautocmd execute l:tabNr . 'tabnext'
		noautocmd execute l:winNr . 'wincmd w'
		unlet! w:AutoSearch
	    endif

	    if gettabvar(l:tabNr, 'AutoSearch') isnot# ''
		noautocmd execute l:tabNr . 'tabnext'
		unlet! t:AutoSearch
	    endif
	endfor
    endfor

    if l:currentTabNr != tabpagenr()
	noautocmd execute l:currentTabNr . 'tabnext'
    endif
    if l:currentWinNr != winnr()
	noautocmd execute l:currentWinNr . 'wincmd w'
    endif
endfunction
function! s:RestoreLastSearchPattern()
    " Restore the last used search pattern.
    let @/ = histget('search', -1)

    " If auto-search was turned off by (before executing) the star command,
    " inform the star command that it must have turned the highlighting on, not
    " off (by setting the search state before the star command to off). This
    " improves the accuracy of the s:isSearchOn workaround.
    call SearchHighlighting#SearchOff()
endfunction
function! s:DisableHooksIfNoAutoSearchAtAll()
    " Find out whether there's no window / tab page / global Auto Search, and
    " only then turn off the autocmds.
    if exists('g:AutoSearch') && g:AutoSearch || s:HasTabScopedAutoSearch() || s:HasWindowScopedAutoSearch()
	return
    endif

    augroup SearchHighlightingAutoSearch
	autocmd!
    augroup END
endfunction
function! s:HasTabScopedAutoSearch()
    for l:tabNr in range(1, tabpagenr('$'))
	if gettabvar(l:tabNr, 'AutoSearch')
	    return 1
	endif
    endfor
    return 0
endfunction
function! s:HasWindowScopedAutoSearch()
    for l:tabNr in range(1, tabpagenr('$'))
	for l:winNr in range(1, tabpagewinnr(l:tabNr, '$'))
	    if gettabwinvar(l:tabNr, l:winNr, 'AutoSearch')
		return 1
	    endif
	endfor
    endfor
    return 0
endfunction


function! SearchHighlighting#AutoSearch#Toggle( isVisualMode )
    if exists('g:AutoSearch') && g:AutoSearch
	let s:isAutoSearch = 0  " Avoid triggering a :nohlsearch from s:AutoSearch() by keeping l:isAutoSearchScopeChange false. The command is already done by the toggle vmap.
	call SearchHighlighting#AutoSearch#Off('g', 0)

	if exists('s:normalModeAutoSearchWhat')
	    let g:AutoSearchWhat = s:normalModeAutoSearchWhat
	    unlet s:normalModeAutoSearchWhat
	    echomsg printf('Disabled search auto-highlighting (and revert to %s)', g:AutoSearchWhat)
	else
	    echomsg 'Disabled search auto-highlighting'
	endif


	if a:isVisualMode
	    " Keep the selection when turning off auto-search. One doesn't need
	    " to go to visual mode in order to do this, so this probably means
	    " that the highlighting is irritating while selecting.
	    normal! gv
	endif

	return 0
    else
	let g:AutoSearch = 1
	let s:isAutoSearch = 1  " Avoid triggering a :set hlsearch from s:AutoSearch() by keeping l:isAutoSearchScopeChange false. The command is already done by the toggle vmap.

	if a:isVisualMode && g:AutoSearchWhat !=# 'selection'
	    let s:normalModeAutoSearchWhat = g:AutoSearchWhat
	    let g:AutoSearchWhat = 'selection'
	endif

	call SearchHighlighting#AutoSearch#On()
	echomsg 'Enabled search auto-highlighting of' g:AutoSearchWhat
	return 1
    endif
endfunction

function! SearchHighlighting#AutoSearch#Set( scope, ... )
    if a:0
	if index(s:AutoSearchWhatValues, a:1) == -1
	    call ingo#err#Set('Unknown search entity "' . a:1 . '"; must be one of: ' . join(s:AutoSearchWhatValues, ', '))
	    return 0
	endif
	execute 'let' a:scope . ':AutoSearchWhat = a:1'
    endif

    execute 'let' a:scope . ':AutoSearch= 1'

    return 1
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo
" vim: set ts=8 sts=4 sw=4 noexpandtab ff=unix fdm=syntax :
