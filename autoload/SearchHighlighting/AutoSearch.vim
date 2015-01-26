" SearchHighlighting/AutoSearch.vim: Auto-highlighting of the stuff under the cursor.
"
" DEPENDENCIES:
"   - ingo/err.vim autoload script
"   - ingo/event.vim autoload script
"   - ingo/plugin/setting.vim autoload script
"   - ingo/regexp.vim autoload script
"   - ingo/register.vim autoload script
"
" Copyright: (C) 2009-2015 Ingo Karkat
"   The VIM LICENSE applies to this script; see ':help copyright'.
"
" Maintainer:	Ingo Karkat <ingo@karkat.de>
"
" REVISION	DATE		REMARKS
"   2.00.020	26-Jan-2015	Re-enable search highlighting when switching
"				to a window that has Auto Search. Clear search
"				highlighting when switching from a window that
"				has Auto Search to one that hasn't, and search
"				highlighting was previously turned off.
"   1.50.019	20-Jan-2015	Use ingo#event#Trigger().
"				Don't show strange whitespace matches on
"				":SearchAutoHighlighting wWORD" caused by empty
"				\%(^\|\s\)\zs\ze\%(\s\|$\) pattern. Set
"				completely empty pattern then. Factor out
"				s:SetLiteralSearch().
"   1.50.018	07-Dec-2014	Split off Auto Search stuff into separate
"				SearchHighlighting/AutoSearch.vim.
"   1.50.017	06-Dec-2014	Change s:AutoSearchWhat to global variable and
"				allow for separately tab page- and window-scoped ones.
"				Extend SearchHighlighting#AutoSearchOff() logic
"				to account for different scopes and only remove
"				the autocmd hooks when no Auto Search at all is
"				active any more.
"				Consider the scopes in s:AutoSearch().
"   1.22.016	13-Jun-2014	Add auto-search value of "selection" to only
"				highlight selected text.
"				Implement toggling of auto-search in visual
"				mode. Save the original configured value and
"				restore that for a later normal mode toggling.
"   1.21.015	22-May-2014	Remove duplicate .*.* in pattern for visual
"				blockwise search.
"   1.21.014	05-May-2014	Also abort on :SearchAutoHighlighting error.
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

let g:AutoSearchWhat = 'wword'
let s:AutoSearchWhatValues = ['wword', 'wWORD', 'cword', 'cWORD', 'exactline', 'line', 'selection']
function! SearchHighlighting#AutoSearch#Complete( ArgLead, CmdLine, CursorPos )
    return filter(copy(s:AutoSearchWhatValues), 'v:val =~# "\\V" . escape(a:ArgLead, "\\")')
endfunction
function! s:SetLiteralSearch( prefixExpr, text, suffixExpr )
    let @/ = (empty(a:text) ?
    \   '' :
    \   a:prefixExpr . ingo#regexp#EscapeLiteralText(a:text, '/') . a:suffixExpr
    \)
endfunction
function! s:GetFromScope( variableName, defaultValue )
    return ingo#plugin#setting#GetFromScope(a:variableName, ['w', 't', 'g'], a:defaultValue)
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

	call ingo#register#KeepRegisterExecuteOrFunc(
	\   'execute "normal! ' . l:captureTextCommands . '" | let @/ = ingo#regexp#EscapeLiteralText(@", "/")'
	\)
	let w:AutoSearch_SelectedPattern = @/
    else
	" Search for the configured entity.
	let l:AutoSearchWhat = s:GetFromScope('AutoSearchWhat', 'wword')
	if l:AutoSearchWhat ==# 'line'
	    let l:lineText = substitute(getline('.'), '^\s*\(.\{-}\)\s*$', '\1', '')
	    call s:SetLiteralSearch('^\s*', l:lineText, '\s*$')
	elseif l:AutoSearchWhat ==# 'exactline'
	    let l:lineText = getline('.')
	    call s:SetLiteralSearch('^', l:lineText, '$')
	elseif l:AutoSearchWhat ==# 'wword'
	    let @/ = ingo#regexp#FromLiteralText(expand('<cword>'), 1, '/')
	elseif l:AutoSearchWhat ==# 'wWORD'
	    let l:cWORD = expand('<cWORD>')
	    call s:SetLiteralSearch('\%(^\|\s\)\zs', l:cWORD, '\ze\%(\s\|$\)')
	elseif l:AutoSearchWhat ==? 'cword'
	    let @/ = ingo#regexp#EscapeLiteralText(expand('<'. l:AutoSearchWhat . '>'), '/')
	elseif l:AutoSearchWhat ==# 'selection'
	    if l:isLocationChange && exists('w:AutoSearch_SelectedPattern')
		let @/ = w:AutoSearch_SelectedPattern
	    endif
	    " Else: Just search for the selected text, nothing in normal mode.
	else
	    throw 'ASSERT: Unknown search entity ' . string(l:AutoSearchWhat)
	endif
    endif

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
